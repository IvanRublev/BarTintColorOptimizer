//
//  PSOFitnessCalculating.h
//  PSOLib
//
//  Created by Ivan Rublev on 11/16/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

@import Foundation;
@class PSOStandardOptimizer2011;

/**
 *  Delegate protocol for calculation of fitness values.
 */
@protocol PSOFitnessCalculating <NSObject>

@optional
/**
 *  Returns the number of positions in a bunch that delegate can calculate fitness function values for.
 *
 *  @param optimizer  PSO optimizer object that requests the bunch size.
 *
 *  @discussion This method is called once before the optimizer operation starts. Delegate must return 1 or greater number. If returned value is greater then the swarm size then optimizers populationSize is used.
 *
 *  @return Size of bunch.
 */
- (NSUInteger)numberOfPositionsInBunch:(PSOStandardOptimizer2011*)optimizer;

@required
/**
 *  Calculates fitness values for provided bunch of multidimensional positions.
 *
 *  @param optimizer      PSO optimizer object that asks for fitness values.
 *  @param fitnessValues  Buffer in which the calculated fitness values must be copied. Its size is sizeof(double)*bunchSize bytes.
 *  @param positions      C array of pointers to array of doubles. Each array double value is particle position value for appropriate dimension.
 *  @param bunchSize      Count of positions in bunch.
 *  @param dimensions     Count of dimensions in particles position.
 */
- (void)optimizer:(PSOStandardOptimizer2011*)optimizer getFitnessValues:(out double*)fitnessValues forPositionsBunch:(double**)positions size:(NSUInteger)bunchSize dimensions:(int)dimensions;
@end
