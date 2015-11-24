//
//  PSOSearchSpace.m
//  PSOLib
//
//  Created by Ivan Rublev on 11/5/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import "PSOSearchSpace.h"

@implementation PSOSearchSpace

+ (instancetype)searchSpaceWithBoundsMin:(NSArray*)min max:(NSArray*)max {
    PSOSearchSpace* bounds = [PSOSearchSpace new];
    bounds.min = min;
    bounds.max = max;
    return bounds;
}

+ (instancetype)searchSpaceWithDimensionsMin:(double)min max:(double)max count:(size_t)dimensions {
    PSOSearchSpace* bounds = [PSOSearchSpace new];
    NSMutableArray* minBound = [NSMutableArray array];
    NSMutableArray* maxBound = [NSMutableArray array];
    for (size_t d=0; d<dimensions; d++) {
        [minBound addObject:@(min)];
        [maxBound addObject:@(max)];
    }
    bounds.min = minBound;
    bounds.max = maxBound;
    return bounds;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    PSOSearchSpace* aCopy = [PSOSearchSpace new];
    aCopy.min = self.min;
    aCopy.max = self.max;
    return aCopy;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@:%p %@ : %@>", NSStringFromClass(self.class), self, self.min, self.max];
}

@end
