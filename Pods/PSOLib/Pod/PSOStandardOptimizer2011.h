//
//  PSOStandardOptimizer2011.h
//  PSOLib
//
//  Created by Ivan Rublev on 11/4/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

@import Foundation;
@import Accelerate;
#import "PSOFitnessCalculating.h"
@class PSOSearchSpace, PSOStandardOptimizer2011;

typedef double(^PSOFitnessBlock)(double* position, int dimensions);
typedef void(^PSOBlock)(PSOStandardOptimizer2011* optimizer);

/**
 *  The Standard Particle Swarm Optimizer 2011.
 *  Ported from MATLAB version http://www.particleswarm.info/PSOStandardOptimizer2011_matlab.zip made by Dr. Mahamed G.H. Omran and Maurice Clerc. See Readme.txt from the above archive for more details.
 *
 *  The Particle Swarm Optimization (PSO) is a computation algorithm that is intended to optimize non-linear multidimensional problems. The idea and algorithm of PSO was introduced by James Kennedy and Russel Ebhart in 1995. PSO find its roots in the social behavior of animals that is observed when they solve problem as a swarm. For example swarm of bees can explore the field searching for flowers and informing other members about their findings.
 *  The PSO algorithm uses the population of 'particles' each of them jumps through the multidimensional problem space. Each position in problem space is estimated for its goodness via fitness function. When the population is initialized the particles are given the random initial positions and velocities. Each iteration, each position velocity is stochastically accelerated towards average position between its previous best position and neighborhood best position. Then the positions of the particles are updated with calculated velocities. Algorithm stops when one of particles finds the best position for which the fitness value is close to the optimum value within the fitness error. Also algorithm stops when the iterations count reaches the maximum is set. Good description of PSO with formulas and examples is here http://web.ist.utl.pt/gdgp/VA/pso.htm
 *
 *  In this standard realization the neighbors (informants) topology is chosen randomly. Based on Clerc description http://clerc.maurice.free.fr/pso/random_topology.pdf P. 2 (Method 2). For circle topology use PSOStandardOptimizer2011CircleTopology class.
 *
 *  To find the best position in search space that is a solution for the problem do following. Make new optimizer object with one of the class methods. Then obtain the NSOperation object via the operation property of the made object. Add the operation to the queue or start it. When the operation finishes the finished block is called. Obtain the bestPosition property value in finished block that will be the best solution found by optimizer. To estimate the error of the solution compare the bestFitness value with the optimum value. 
 *  The optimizer object works as operations fabric. Each time you obtain the operation all optimizer input parameters are copied internally and a new operation object is returned. Thus you can change parameters you need and make as many appropriate operation objects from the same optimizer as necessary. Use tag property to identify the set of parameters.
 *
 *  Performance tips. This class uses Accelerate framework to calculate velocities and positions. The narrow place is a fitness function computation. Use Accelerate framework for fitness function calculation to improve the optimizer performance. Heavy fitness calculations can be parallelized to use multiple cores/processors. To do this obtain necessary amount of input positions at once using the fitnessCalculator and PSOFitnessCalculating protocol and use GCD to parallelize fitness calculations. See https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/ThreadMigration/ThreadMigration.html#//apple_ref/doc/uid/TP40008091-CH105-SW2 for concrete recommendations.
 *
 *  Quality considerations. The released algorithm is the universal standard algorithm that is good enough for many cases. To make improved versions for concrete problem with different informants topology selection or velocity calculation or start positions/velocity selection methods use the subclassing. Subclass this class and overload appropriate calculation methods.
 */
@interface PSOStandardOptimizer2011 : NSObject <NSMutableCopying> {
    double _w;     // Velocity inertia factor.
    double _c1;    // Cognition factor.
    double _c2;    // Social factor.
    NSUInteger _K; // Informants count for each particle.
}
/**
 *  Creates and returns new optimizer.
 *
 *  @param searchSpace         Search space to search for the solution.
 *  @param optimum             Optimum fitness value for the searched solution.
 *  @param fitness             Fitness function computation block.
 *  @param before              Block that is called just before search starts. Can be nil.
 *  @param iterationCompleted  Block that is called on each iteration completion. Can be nil.
 *  @param finished            Block that is called when operation is finished. Must be set, otherwise operation throws an exception.
 *
 *  @return New instance of the PSOStandardOptimizer2011 class.
 */
+ (instancetype)optimizerForSearchSpace:(PSOSearchSpace*)searchSpace
                                optimum:(double)optimum
                                fitness:(PSOFitnessBlock)fitness
                                 before:(PSOBlock)before
                              iteration:(PSOBlock)iterationCompleted
                               finished:(PSOBlock)finished;
/**
 *  Creates and returns new optimizer.
 *
 *  @param searchSpace         Search space to search for the solution.
 *  @param optimum             Optimum fitness value for the searched solution.
 *  @param fitnessCalculator   Delegate that will compute fitness values under PSOFitnessBunchDelegateProtocol.
 *  @param before              Block that is called just before search starts. Can be nil.
 *  @param iterationCompleted  Block that is called on each iteration completion. Can be nil.
 *  @param finished            Block that is called when operation is finished. Must be set, otherwise operation throws an exception.
 *
 *  @return New instance of the PSOStandardOptimizer2011 class.
 */
+ (instancetype)optimizerForSearchSpace:(PSOSearchSpace*)searchSpace
                                optimum:(double)optimum
                      fitnessCalculator:(id<PSOFitnessCalculating>)fitnessCalculator
                                 before:(PSOBlock)before
                              iteration:(PSOBlock)iterationCompleted
                               finished:(PSOBlock)finished;
/**
 *  Tag to identify the optimizer in completion blocks.
 */
@property (nonatomic) NSUInteger tag;
/**
 *  Number of particles in a swarm. Could be in range from 2 to 100. By default is set to 40. For most cases it's good enough.
 */
@property (nonatomic) NSUInteger populationSize;
/**
 *  Bounded search space where particles of the swarm looks for the solution.
 */
@property (nonatomic) PSOSearchSpace* searchSpace;
/**
 *  Fitness function block. Should return fitness value to estimate the goodness of the position. The position is better as much as the fitness value is closer to optimum.
 *
 *  @param x           C array that represents the multi-dimensional position of particle in the search space.
 *  @param dimensions  The number of values in x array.
 *
 *  @discussion Use either fitnessFunction or fitnessCalculator property to calculate the fitness value. If fitnessFunction block is not nil it is instead of the delegate.
 *
 *  @return Returns fitness double value for position.
 */
@property (nonatomic, copy) PSOFitnessBlock fitnessFunction;
/**
 *  Delegate that calculates fitness values for bunch of positions.
 */
@property (nonatomic, weak) id<PSOFitnessCalculating> fitnessCalculator;
/**
 *  Optimum value. By default is set to zero.
 */
@property (nonatomic) double optimum;
/**
 *  Allowed error for the fitness optimum value. By default is set to DBL_EPSILON.
 */
@property (nonatomic) double fitnessError;
/**
 *  Maximum count of iterations algorithm should stop at. By default is set to 100,000.
 */
@property (nonatomic) NSUInteger maxIterations;


/**
 *  Block is called once before the first iteration is started.
 *  @param otimizer    Optimizer object that completed the iteration.
 */
@property (nonatomic, copy) PSOBlock before;
/**
 *  Block is called when each iteration is completed.
 *  @param otimizer    Optimizer object that completed the iteration.
 */
@property (nonatomic, copy) PSOBlock iterationCompleted;
/**
 *  Block is called after the last iteration is finished.
 *  @param otimizer    Optimizer object that completed the iteration.
 */
@property (nonatomic, copy) PSOBlock finished;
/**
 *  Array of current particles positions in the search space. The particles position is represented as subarray of NSNumbers with double values.
 */
@property (atomic, readonly) NSArray* particlesPositions;
/**
 *  Array of particles fitness values.
 */
@property (atomic, readonly) NSArray* particlesFitness;
/**
 *  Array of particles velocities values.
 */
@property (atomic, readonly) NSArray* particlesVelocity;
/**
 *  Number of dimensions of the search space.
 */
@property (nonatomic, readonly) int dimensions;
/**
 *  Current iteration number.
 */
@property (atomic, readonly) NSUInteger iteration;


/**
 *  Solution search operation.
 */
@property (nonatomic, copy, readonly) NSOperation* operation;


/**
 *  Best position found.
 */
@property (nonatomic, readonly) NSArray* bestPosition;
/**
 *  Fitness value of the best position.
 */
@property (nonatomic, readonly) double bestFitness;
@end
