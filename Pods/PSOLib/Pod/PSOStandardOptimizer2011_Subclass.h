//
//  PSOStandardOptimizer2011_Subclass.h
//  PSOLib
//
//  Created by Ivan Rublev on 11/15/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import <PSOLib/PSOStandardOptimizer2011.h>

/**
 *  Extension with protected properties and methods to use in subclass.
 */
@interface PSOStandardOptimizer2011 ()
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

- (void)selectInitialPositionsAndVelocities;
- (void)calculateNewPositionAndVelocityForParticleWithIndex:(NSUInteger)p;
- (void)randomizeInformantsTopology;

@end
