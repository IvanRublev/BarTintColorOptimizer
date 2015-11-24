//
//  PSOStandardOptimizer2011CircleTopology.m
//  PSOLib
//
//  Created by Ivan Rublev on 11/15/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import "PSOStandardOptimizer2011CircleTopology.h"

@implementation PSOStandardOptimizer2011CircleTopology

- (void)randomizeInformantsTopology {
    NSParameterAssert(self.populationSize > 1);
    NSParameterAssert(self.informantsTopology);
    
    for (NSUInteger r=0; r<self.populationSize; r++) {
        self.informantsTopology[r][r] = 1;
        NSUInteger leftNeighbourIdx = (r == 0) ? self.populationSize-1 : r-1;
        NSUInteger rightNeighbourIdx = (r == self.populationSize-1) ? 0 : r+1;
        self.informantsTopology[r][leftNeighbourIdx] = 1;
        self.informantsTopology[r][rightNeighbourIdx] = 1;
    }
}

@end
