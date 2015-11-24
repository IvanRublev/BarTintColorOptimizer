//
//  PSOStandardOptimizer2011CircleTopology.h
//  PSOLib
//
//  Created by Ivan Rublev on 11/15/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import <PSOLib/PSOStandardOptimizer2011_Subclass.h>

/**
 *  Standard optimizer 2011 with circle topology of particles informants. Each particle is informed by its left and right neighbours. First and last particles in array are left/right informants for each other.
 */
@interface PSOStandardOptimizer2011CircleTopology : PSOStandardOptimizer2011

@end
