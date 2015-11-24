//
//  PSOSearchSpace.h
//  PSOLib
//
//  Created by Ivan Rublev on 11/5/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

@import Foundation;

/**
 *  Search space, where particles of the swarm looks for solution of the problem.
 */
@interface PSOSearchSpace : NSObject <NSMutableCopying>
/**
 *  Creates and returns multidimensional search space bounded with provided min and max values.
 *
 *  @param min Minimum values array.
 *  @param max Maximum values array.
 *
 *  @discussion Values at same index from both min and max arrays are used in pair to bound the dimension with same index. Count of elements in both min and max arrays must be the same.
 *
 *  @return Search space with count of dimensions same as length of min and max arrays.
 */
+ (instancetype)searchSpaceWithBoundsMin:(NSArray*)min max:(NSArray*)max;
/**
 *  Creates and returns multidimensional search space of dimensions size, bounded with provided min and max values on each dimension.
 *
 *  @param min        Minimum double value.
 *  @param max        Maximum double values.
 *  @param dimensions Count of dimensions.
 *
 *  @return Search space with dimensions size bounded with min and max values on each dimension.
 */
+ (instancetype)searchSpaceWithDimensionsMin:(double)min max:(double)max count:(size_t)dimensions;
/**
 *  Search space minimum bound. Each element of the array is the minimum bound of spaces dimension with appropriate index. Array contains NSNumber with double value.
 */
@property (nonatomic, copy) NSArray* min;
/**
 *  Search space maximum bound. Each element of the array is the minimum bound of spaces dimension with appropriate index. Array contains NSNumber with double value.
 */
@property (nonatomic, copy) NSArray* max;
@end
