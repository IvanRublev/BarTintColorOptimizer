//
//  PSOStandardOptimizer2011.m
//  PSOLib
//
//  Created by Ivan Rublev on 11/4/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import "PSOStandardOptimizer2011.h"
#import "PSOSearchSpace.h"
#import "PSOAlea.h"
#import "PSOImmutableProxy.h"
#import <libkern/OSAtomic.h>

NSUInteger const PSOPopulationSizeMin = 2;
NSUInteger const PSOPopulationSizeMax = 100;
int const PSODefaultK = 3;

@interface PSOStandardOptimizer2011 () {
    OSSpinLock _vectorsLock;
}
@property (nonatomic) double bestFitness;
@property (atomic) NSUInteger iteration;

@property (nonatomic) NSUInteger bunchSize;
@property (nonatomic) double w;
@property (nonatomic) double c1;
@property (nonatomic) double c2;
@property (nonatomic) NSUInteger K;

@property (nonatomic) double informantProbability;
@property (nonatomic, readonly) BOOL normalizeSearchSpace;

@property (nonatomic, unsafe_unretained) double* xMinOriginal;
@property (nonatomic, unsafe_unretained) double* xMaxOriginal;
@property (nonatomic, unsafe_unretained) double* xDiffMinMaxOriginal;
@property (nonatomic, unsafe_unretained) double* xMin;
@property (nonatomic, unsafe_unretained) double* xMax;
@property (nonatomic, unsafe_unretained) double** x;
@property (nonatomic, unsafe_unretained) double** v;
@property (nonatomic, unsafe_unretained) double* f;
@property (nonatomic) NSUInteger bestParticleIndex;
@property (nonatomic, unsafe_unretained) double** personalBestX;
@property (nonatomic, unsafe_unretained) double* personalBestF;
@property (nonatomic, unsafe_unretained) uint8_t** informantsTopology;
@end

@implementation PSOStandardOptimizer2011
@synthesize particlesPositions=_particlesPositions;

+ (void)initialize {
    if (self == [PSOStandardOptimizer2011 self]) {
        PSOAleaSeeddevRand();
    }
}

+ (instancetype)optimizerForSearchSpace:(PSOSearchSpace*)searchSpace
                                optimum:(double)optimum
                                fitness:(PSOFitnessBlock)fitness
                                 before:(PSOBlock)before
                              iteration:(PSOBlock)iterationCompleted
                               finished:(PSOBlock)finished {
    PSOStandardOptimizer2011* optimizer = [self new];
    optimizer.searchSpace = searchSpace;
    optimizer.optimum = optimum;
    optimizer.fitnessFunction = fitness;
    optimizer.before = before;
    optimizer.iterationCompleted = iterationCompleted;
    optimizer.finished = finished;
    return optimizer;
}

+ (instancetype)optimizerForSearchSpace:(PSOSearchSpace *)searchSpace
                                optimum:(double)optimum
                        fitnessCalculator:(id<PSOFitnessCalculating>)fitnessCalculator
                                 before:(PSOBlock)before
                              iteration:(PSOBlock)iterationCompleted
                               finished:(PSOBlock)finished {
    PSOStandardOptimizer2011* optimizer = [self new];
    optimizer.searchSpace = searchSpace;
    optimizer.optimum = optimum;
    optimizer.fitnessCalculator = fitnessCalculator;
    optimizer.before = before;
    optimizer.iterationCompleted = iterationCompleted;
    optimizer.finished = finished;
    return optimizer;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.populationSize = 40;
        self.searchSpace = nil;
        _fitnessFunction = nil;
        _optimum = 0.;
        _fitnessError = DBL_EPSILON;
        self.maxIterations = 1e5;
        _before = nil;
        _iterationCompleted = nil;
        _finished = nil;
        _particlesPositions = nil;
        _dimensions = 0;
        _bestParticleIndex = NSNotFound;
        _bestFitness = DBL_MAX;
        _iteration = 0;
        
        _bunchSize = 0;
        _w = 1./(2.*log(2.));
        _c1 = 0.5 + log(2.);
        _c2 = _c1;
        self.K = PSODefaultK;
        
        _vectorsLock = OS_SPINLOCK_INIT;
    }
    return self;
}

- (void)dealloc {
    [self syncVectors:^{
        [self vectorsFree];
    }];
}

- (void)setPopulationSize:(NSUInteger)populationSize {
    NSAssert(populationSize >= PSOPopulationSizeMin, @"populationSize (%lu) must be greater or equal %lu", (unsigned long)populationSize, (unsigned long)PSOPopulationSizeMin);
    NSAssert(populationSize <= PSOPopulationSizeMax, @"populationSize (%lu) must be less or equal %lu", (unsigned long)populationSize, (unsigned long)PSOPopulationSizeMax);
    _populationSize = populationSize;
    self.K = _K;
}

- (void)setSearchSpace:(PSOSearchSpace*)xBounds {
    NSAssert(xBounds.min.count <= INT_MAX, @"Count of array elements (%lu) can't be larger then %d", (unsigned long)xBounds.min.count, INT_MAX);
    NSAssert(xBounds.min.count == xBounds.max.count, @"Count of min array elements (%lu) must be equal to max array elements count (%lu)", (unsigned long)xBounds.min.count, (unsigned long)xBounds.max.count);
#if DEBUG
    [xBounds.min enumerateObjectsUsingBlock:^(NSNumber* minNumber, NSUInteger idx, BOOL *stop) {
        NSNumber* maxNumber = xBounds.max[idx];
        NSAssert(minNumber.doubleValue <= maxNumber.doubleValue, @"min array value (%@) at index %lu must be less then or equal to max value (%@)", minNumber, (unsigned long)idx, maxNumber);
    }];
#endif
    _dimensions = (int)xBounds.min.count;
    _normalizeSearchSpace = (_dimensions == 1);
    _searchSpace = xBounds;
}

- (void)setK:(NSUInteger)K {
    if (K >= self.populationSize && self.populationSize <= PSODefaultK) {
        K = self.populationSize-1;
    }
    NSAssert(K < self.populationSize, @"K (%lu) must be less or equal to swarm size %lu", (unsigned long)K, (unsigned long)self.populationSize);
    _K = K;
    self.informantProbability = 1-pow(1.-1./self.populationSize, K);
}

- (void)setMaxIterations:(NSUInteger)maxIterations {
    NSAssert(maxIterations > 0, @"maxIteration must be greater then zero.");
    _maxIterations = maxIterations;
}

- (NSOperation*)operation {
    PSOStandardOptimizer2011* swarm = [self mutableCopy];
    NSAssert(swarm.finished != nil, @"finihed block must be set to obtain operation results.");
    PSOStandardOptimizer2011* immutableSwarm = (PSOStandardOptimizer2011*)[[PSOImmutableProxy alloc] initWithObject:swarm];
    
    NSBlockOperation* searchOp = [NSBlockOperation new];
    __weak NSBlockOperation* searchOp_weak_ = searchOp;
    [searchOp addExecutionBlock:^{
        __strong NSBlockOperation* searchOp = searchOp_weak_;
        if (searchOp.isCancelled) {
            return;
        }

        if (swarm.fitnessCalculator) {
            if ([swarm.fitnessCalculator respondsToSelector:@selector(numberOfPositionsInBunch:)]) {
                swarm.bunchSize = MAX(MIN([swarm.fitnessCalculator numberOfPositionsInBunch:swarm], swarm.populationSize), 1);
            } else {
                swarm.bunchSize = swarm.populationSize;
            }
        } else {
            swarm.bunchSize = 0;
        }
        
        [swarm syncVectors:^{
            [swarm vectorsAlloc]; // cleanup will occur on the swarm object deallocation.
        }];
        
        swarm.iteration = 0;
        NSUInteger noimproveIterationsCount = 1;
        
        if (swarm.before) {
            swarm.before(immutableSwarm);
        }
        
        BOOL stop = NO;
        while ( ! stop) {
            if (searchOp.isCancelled) {
                return;
            }
            
            [swarm lockVectors];
            
            if (noimproveIterationsCount) {
                [swarm randomizeInformantsTopology];
            }
            
            // For each particle calculate new x and velocity
            for (NSUInteger p=0; p<swarm.populationSize; p++) {
                if (searchOp.isCancelled) {
                    return;
                }
                [swarm calculateNewPositionAndVelocityForParticleWithIndex:p];
            }
            if (searchOp.isCancelled) {
                break;
            }
            
            // Update personal and global bests
            [swarm calculateFitness];
            for (NSUInteger p=0; p<swarm.populationSize; p++) {
                if (swarm.f[p] <= swarm.personalBestF[p]) {
                    memcpy(swarm.personalBestX[p], swarm.x[p], sizeof(double)*swarm.dimensions);
                    swarm.personalBestF[p] = swarm.f[p];
                }
            }
            if ([swarm findGlobalBest]) {
                noimproveIterationsCount = 0;
            } else {
                noimproveIterationsCount++;
            }
            
            [swarm unlockVectors];
            
            if (swarm.iterationCompleted) {
                swarm.iterationCompleted(immutableSwarm);
            }
            
            // Stop condition
            swarm.iteration++;
            stop = swarm.iteration == swarm.maxIterations;
            if ( ! stop) {
                stop = (fabs(swarm.bestFitness) < swarm.fitnessError);
            }
        }

        swarm.bestFitness += swarm.optimum; // denormalize
        swarm.finished(immutableSwarm);
    }];
    
    return searchOp;
}

- (void)calculateFitness {
    NSAssert(self.areVectorsLocked, @"%s must be called with vectors are locked first!", __func__);
    NSParameterAssert(self.populationSize);
    NSParameterAssert(self.dimensions);
    NSParameterAssert(self.x);
    NSParameterAssert(self.f);
    NSAssert(self.fitnessFunction || self.fitnessCalculator, @"fitnessFunction block or fitnessCalculator must be set.");
#if DEBUG
    if ( ! self.fitnessFunction && self.fitnessCalculator) {
        NSParameterAssert(self.bunchSize);
    }
#endif
    NSUInteger populationSize = self.populationSize;
    int dimensions = self.dimensions;
    
    double* f = [self allocSwarmVector];
    double** xValues = [self allocSwarmDimMatrix];
    for (NSUInteger p=0; p<populationSize; p++) {
        [self getDenormalizedXValues:xValues[p] count:dimensions ofParticleWithIndex:p];
    }
    
    if (self.fitnessFunction) {
        for (NSUInteger p=0; p<populationSize; p++) {
            double fitnessValue = self.fitnessFunction(xValues[p], dimensions)-self.optimum;
            f[p] = fitnessValue;
        }
    } else { // self.fitnessCalculator is set.
        double** xValuesWindow;
        double* fWindow;
        NSUInteger bunchSize = self.bunchSize;
        for (NSUInteger bunch=0; bunch<populationSize; bunch+=bunchSize) {
            xValuesWindow = &xValues[bunch];
            fWindow = &f[bunch];
            [self.fitnessCalculator optimizer:self
                           getFitnessValues:fWindow
                          forPositionsBunch:xValuesWindow
                                       size:(bunch+bunchSize>populationSize) ? populationSize-bunch : bunchSize
                                 dimensions:dimensions];
        }
    }
    
    memcpy(self.f, f, sizeof(double)*populationSize);
    
    // clean mem
    [self freeSwarmDimMatrix:&xValues count:populationSize];
    [self freeVector:&f];
}

- (BOOL)findGlobalBest { // returns YES if global best was updated
    BOOL updated = NO;
    for (NSUInteger p=0; p<self.populationSize; p++) {
        if (self.personalBestF[p] < self.bestFitness) {
            _bestFitness = self.personalBestF[p];
            self.bestParticleIndex = p;
            updated = YES;
        }
    }
    return updated;
}


#pragma mark -
#pragma mark Calculation
- (void)selectInitialPositionsAndVelocities {
    // Fill positons and velocities with random start values
    for (NSUInteger p=0; p<self.populationSize; p++) {
        for (NSUInteger d=0; d<self.dimensions; d++) {
            double randX = PSOAlea(self.xMin[d], self.xMax[d]);
            self.v[p][d] = PSOAlea(self.xMin[d]-randX, self.xMax[d]-randX);
            self.x[p][d] = randX;
        }
    }
}

- (void)calculateNewPositionAndVelocityForParticleWithIndex:(NSUInteger)p {
    // Find particle informant with best personall fitness
    double minF = DBL_MAX;
    NSUInteger bestInformantIndex = NSNotFound;
    for (NSUInteger p2=0; p2<self.populationSize; p2++) {
        if (self.informantsTopology[p2][p] == 1) {
            if (self.personalBestF[p2] < minF) {
                minF = self.personalBestF[p2];
                bestInformantIndex = p2;
            }
        }
    }

    double const c1 = self.c1;
    double const c2 = self.c2;
    double const f0_5 = 0.5;
    double const f0_3 = 1./3.;
    double const w = self.w;

    double* cognitiveX = [self allocDimVector];
    double* socialX = [self allocDimVector];
    double* gravityCenterX = [self allocDimVector];
    double* gravityDiffX = [self allocDimVector];
    double* rndSpherePoint = [self allocDimVector];
    double* dumpedV = [self allocDimVector];

    // Calculate cognitive and social parts of new x
    vDSP_vsbsmD(self.personalBestX[p], 1, self.x[p], 1, &c1, cognitiveX, 1, self.dimensions); // cognitiveX = (personalBestX-x)*c1
    vDSP_vaddD(self.x[p], 1, cognitiveX, 1, cognitiveX, 1, self.dimensions); // x  + cognitiveX
    vDSP_vsbsmD(self.personalBestX[bestInformantIndex], 1, self.x[p], 1, &c2, socialX, 1, self.dimensions); // socialX = (InformantBestX-x)*c2
    vDSP_vaddD(self.x[p], 1, socialX, 1, socialX, 1, self.dimensions); // x+socialX
    
    // Find gravity center of x
    if (bestInformantIndex == p) { // best informant is particle itself, use only cognitiveX
        vDSP_vasmD(self.x[p], 1, cognitiveX, 1, &f0_5, gravityCenterX, 1, self.dimensions); // (x+cognitiveX)*0.5
    } else { // have socialX use it as also with cognitive.
        double cognitiveAndSocialX[self.dimensions];
        vDSP_vaddD(cognitiveX, 1, socialX, 1, cognitiveAndSocialX, 1, self.dimensions); // cognitiveAndSocialX = cognitiveX + socialX
        vDSP_vasmD(self.x[p], 1, cognitiveAndSocialX, 1, &f0_3, gravityCenterX, 1, self.dimensions); // G = (x+cognitiveAndSocialX)/0.333
    }
    // Find random point in hypersphere around G
    vDSP_vsubD(self.x[p], 1, gravityCenterX, 1, gravityDiffX, 1, self.dimensions); // gravityDiffX = (G-x)
    double radius = cblas_dnrm2(self.dimensions, gravityDiffX, 1); // radius = norm(gravityDiffX)
    PSOAleaInSphere(radius, rndSpherePoint, self.dimensions); // rndSpherePoint from shpere of radius
    vDSP_vaddD(rndSpherePoint, 1, gravityCenterX, 1, rndSpherePoint, 1, self.dimensions); // rndSpherePoint += gravityCenterX
    // Calculate new x and v
    vDSP_vsubD(self.x[p], 1, rndSpherePoint, 1, rndSpherePoint, 1, self.dimensions); // rndSpherePoint = rndSpherePoint-x
    vDSP_vsmulD(self.v[p], 1, &w, dumpedV, 1, self.dimensions); // dumpedV = v*w
    
    vDSP_vaddD(dumpedV, 1, rndSpherePoint, 1, self.v[p], 1, self.dimensions); // v(t+1)  =  dumpedV + rndSpherePoint  =  v(t)*w + (rndSpherePoint-x(t))
    vDSP_vaddD(self.x[p], 1, self.v[p], 1, self.x[p], 1, self.dimensions); // x(t+1) = x(t) + v(t+1);
    
    [self freeVector:&cognitiveX];
    [self freeVector:&socialX];
    [self freeVector:&gravityCenterX];
    [self freeVector:&gravityDiffX];
    [self freeVector:&rndSpherePoint];
    [self freeVector:&dumpedV];

    // Constrain new values
    for (int d=0; d<self.dimensions; d++) {
        if (self.x[p][d] > self.xMax[d]) {
            self.x[p][d] = self.xMax[d];
            self.v[p][d] = -0.5*self.v[p][d];
        }
        if (self.x[p][d] < self.xMin[d]) {
            self.x[p][d] = self.xMin[d];
            self.v[p][d] = -0.5*self.v[p][d];
        }
    }
}

- (void)randomizeInformantsTopology {
    NSParameterAssert(self.populationSize);
    NSParameterAssert(self.informantProbability);
    NSParameterAssert(self.informantsTopology);
    for (NSUInteger r=0; r<self.populationSize; r++) {
        for (NSUInteger c=0; c<self.populationSize; c++) {
            if (c == r) {
                self.informantsTopology[r][c] = 1;
            } else {
                double rand = PSOAlea(0., 1.);
                self.informantsTopology[r][c] = rand < self.informantProbability ? 1 : 0;
            }
        }
    }
}


#pragma mark -
#pragma mark Vector access synchronization
- (void)syncVectors:(void(^)())block {
    [self lockVectors];
    block();
    [self unlockVectors];
}

- (void)lockVectors {
    OSSpinLockLock(&_vectorsLock);
}

- (void)unlockVectors {
    OSSpinLockUnlock(&_vectorsLock);
}

- (BOOL)areVectorsLocked {
    BOOL lockSuccess = OSSpinLockTry(&_vectorsLock);
    if (lockSuccess) {
        OSSpinLockUnlock(&_vectorsLock);
    }
    return NO == lockSuccess;
}


#pragma mark -
#pragma mark Private state properties
- (void)vectorsAlloc {
    NSAssert(self.areVectorsLocked, @"%s must be called with vectors are locked first!", __func__);
    NSParameterAssert(self.populationSize);
    NSParameterAssert(self.dimensions);
    NSParameterAssert(self.searchSpace);
    
    [self vectorsFree];
    
    NSUInteger populationSize = self.populationSize;
    NSUInteger dimensions = self.dimensions;
    PSOSearchSpace* xBounds = self.searchSpace;
    
    // Allocate min and max positions on search space, normalize if needed.
    self.xMax = [self allocDimVector];
    self.xMin = [self allocDimVector];
    self.xMaxOriginal = [self allocDimVector];
    self.xMinOriginal = [self allocDimVector];
    [xBounds.min enumerateObjectsUsingBlock:^(NSNumber* minNumber, NSUInteger idx, BOOL *stop) {
        self.xMinOriginal[idx] = minNumber.doubleValue;
        double xMinDim = _normalizeSearchSpace ? 0. : self.xMinOriginal[idx];
        self.xMin[idx] = xMinDim;
    }];
    [xBounds.max enumerateObjectsUsingBlock:^(NSNumber* maxNumber, NSUInteger idx, BOOL *stop) {
        self.xMaxOriginal[idx] = maxNumber.doubleValue;
        double xMaxDim = _normalizeSearchSpace ? 1. : self.xMaxOriginal[idx];
        self.xMax[idx] = xMaxDim;
    }];
    self.xDiffMinMaxOriginal = [self allocDimVector];
    vDSP_vsubD(self.xMinOriginal, 1, self.xMaxOriginal, 1, self.xDiffMinMaxOriginal, 1, self.dimensions);
    
    // Allocate swarm positions and velocities
    self.x = [self allocSwarmDimMatrix];
    self.v = [self allocSwarmDimMatrix];
    [self selectInitialPositionsAndVelocities];
    
    // Allocate fitness and personal best vectors
    self.f = [self allocSwarmVector];
    [self calculateFitness];
    
    self.personalBestX = [self allocSwarmDimMatrix];
    for (NSUInteger p=0; p<populationSize; p++) {
        memcpy(self.personalBestX[p], self.x[p], sizeof(double)*dimensions);
    }
    self.personalBestF = [self allocSwarmVector];
    memcpy(self.personalBestF, self.f, sizeof(double)*self.populationSize);
    [self findGlobalBest];
    
    // Allocate informants topology matrix
    if (populationSize) {
        self.informantsTopology = calloc(sizeof(uint8_t*), populationSize);
        for (NSUInteger p=0; p<populationSize; p++) {
            self.informantsTopology[p] = calloc(sizeof(uint8_t), populationSize);
        }
    }
}

- (void)vectorsFree {
    NSAssert(self.areVectorsLocked, @"%s must be called with vectors are locked first!", __func__);
    if (self.informantsTopology) {
        for (NSUInteger p=0; p<self.populationSize; p++) {
            free(self.informantsTopology[p]);
        }
        free(self.informantsTopology);
        self.informantsTopology = NULL;
    }
    [self freeSwarmDimMatrix:&_personalBestX count:self.populationSize];
    [self freeVector:&_personalBestF];
    [self freeVector:&_f];
    [self freeSwarmDimMatrix:&_x count:self.populationSize];
    [self freeSwarmDimMatrix:&_v count:self.populationSize];
    [self freeVector:&_xDiffMinMaxOriginal];
    [self freeVector:&_xMinOriginal];
    [self freeVector:&_xMaxOriginal];
    [self freeVector:&_xMin];
    [self freeVector:&_xMax];
}

- (void)getDenormalizedXValues:(out double*)buffer count:(int)count ofParticleWithIndex:(NSUInteger)index {
    NSAssert(self.areVectorsLocked, @"%s must be called with vectors are locked first!", __func__);
    NSAssert(index < self.populationSize, @"index (%lu) must be less then populationSize %lu", (unsigned long)index, (unsigned long)self.populationSize);
    NSParameterAssert(buffer);
    NSAssert(count == self.dimensions, @"values count %d must be equal to dimentios count %d", count, self.dimensions);
    
    int dimensions = self.dimensions;
    memcpy(buffer, self.x[index], sizeof(double)*dimensions);
    if (self.normalizeSearchSpace) {
        vDSP_vmaD(buffer, 1, self.xDiffMinMaxOriginal, 1, self.xMinOriginal, 1, buffer, 1, dimensions);
    }
}


#pragma mark -
#pragma mark Public state properties
- (NSArray*)particlesPositions {
    __block NSArray* particlesX = nil;
    [self syncVectors:^{
        NSMutableArray* particleValues = [NSMutableArray arrayWithCapacity:self.populationSize];
        double* xValues = [self allocDimVector];
        
        for (NSUInteger p=0; p<self.populationSize; p++) {
            [self getDenormalizedXValues:xValues count:self.dimensions ofParticleWithIndex:p];
            
            NSMutableArray* dimXValues = [NSMutableArray arrayWithCapacity:self.dimensions];
            for (int d=0; d<self.dimensions; d++) {
                [dimXValues addObject:@(xValues[d])];
            }
            
            [particleValues addObject:[dimXValues copy]];
        }
        
        [self freeVector:&xValues];
        particlesX = [particleValues copy];
    }];
    return particlesX;
}

- (NSArray*)particlesFitness {
    __block NSArray* particlesFitness = nil;
    [self syncVectors:^{
        NSMutableArray* particleValues = [NSMutableArray arrayWithCapacity:self.populationSize];
        for (NSUInteger p=0; p<self.populationSize; p++) {
            [particleValues addObject:@(self.f[p])];
        }
        particlesFitness = [particleValues copy];
    }];
    return particlesFitness;
}

- (NSArray*)particlesVelocity {
    __block NSArray* particlesV = nil;
    [self syncVectors:^{
        NSMutableArray* particleValues = [NSMutableArray arrayWithCapacity:self.populationSize];
        for (NSUInteger p=0; p<self.populationSize; p++) {
            NSMutableArray* dimXValues = [NSMutableArray arrayWithCapacity:self.dimensions];
            for (int d=0; d<self.dimensions; d++) {
                double velocity = self.v[p][d];
                if (self.normalizeSearchSpace) {
                    velocity = velocity*self.xDiffMinMaxOriginal[d] + self.xMinOriginal[d];
                }
                [dimXValues addObject:@(velocity)];
            }
            [particleValues addObject:[dimXValues copy]];
        }
        particlesV = [particleValues copy];
    }];
    return particlesV;
}

- (NSArray*)bestPosition {
    __block NSArray* bestPosition = nil;
    [self syncVectors:^{
        int dimensions = self.dimensions;
        NSMutableArray* mutBestX = [NSMutableArray arrayWithCapacity:dimensions];
        double* xVec = [self allocDimVector];
        memcpy(xVec, self.personalBestX[self.bestParticleIndex], sizeof(double)*dimensions);
        if (self.normalizeSearchSpace) {
            vDSP_vmaD(xVec, 1, self.xDiffMinMaxOriginal, 1, self.xMinOriginal, 1, xVec, 1, dimensions);
        }
        for (int d=0; d<dimensions; d++) {
            [mutBestX addObject:@(xVec[d])];
        }
        [self freeVector:&xVec];
        bestPosition = [mutBestX copy];
    }];
    return bestPosition;
}


#pragma mark -
#pragma mark Malloc/free
- (double*)allocDimVector {
    NSParameterAssert(self.dimensions);
    return malloc(sizeof(double)*self.dimensions);
}

- (double*)allocSwarmVector {
    NSParameterAssert(self.populationSize);
    return malloc(sizeof(double)*self.populationSize);
}

- (double**)allocSwarmDimMatrix {
    NSParameterAssert(self.populationSize);
    double** matrix = malloc(sizeof(double*)*self.populationSize);
    for (NSUInteger p=0; p<self.populationSize; p++) {
        matrix[p] = [self allocDimVector];
    }
    return matrix;
}

- (void)freeVector:(double**)vectorRef {
    NSParameterAssert(vectorRef);
    if (NULL != *vectorRef) {
        free(*vectorRef);
        *vectorRef = NULL;
    }
}

- (void)freeSwarmDimMatrix:(double***)matrixRef count:(NSUInteger)populationSize  {
    NSParameterAssert(populationSize);
    NSParameterAssert(matrixRef);
    if (NULL != *matrixRef) {
        for (NSUInteger p=0; p<populationSize; p++) {
            double* col = (*matrixRef)[p];
            if (col) {
                free(col);
            }
        }
        free(*matrixRef);
        *matrixRef = NULL;
    }
}


#pragma mark -
#pragma mark NSMutableCopying
- (id)mutableCopyWithZone:(NSZone*)zone {
    PSOStandardOptimizer2011* aCopy = [PSOStandardOptimizer2011 new];
    aCopy.populationSize = self.populationSize;
    aCopy.searchSpace = [self.searchSpace mutableCopy];
    aCopy.fitnessFunction = self.fitnessFunction;
    aCopy.fitnessCalculator = self.fitnessCalculator;
    aCopy.bunchSize = self.bunchSize;
    aCopy.optimum = self.optimum;
    aCopy.fitnessError = self.fitnessError;
    aCopy.maxIterations = self.maxIterations;
    aCopy.before = self.before;
    aCopy.iterationCompleted = self.iterationCompleted;
    aCopy.finished = self.finished;
    aCopy.tag = self.tag;
    return aCopy;
}

@end
