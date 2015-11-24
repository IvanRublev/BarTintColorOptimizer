//
//  PSOAlea.h
//  PSOLib
//
//  Ported by Ivan Rublev on 11/7/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import <Foundation/Foundation.h>

/**
 *  Seeds random generator used for alea functions with data sample got from /dev/random.
 */
FOUNDATION_EXPORT void PSOAleaSeeddevRand ();
/**
 *  Seeds random generator used for alea functions. PSOAleaSeeddevRand is recommended to use instead.
 */
FOUNDATION_EXPORT void PSOAleaSrand (unsigned int seed);
/**
 *  Returns random double uniformly distributed in specified bounds. It uses KISS random generator to fill the first 30/62-bits of double number (depending on double type size) then normalizes it to provided bounds. See https://en.wikipedia.org/wiki/Double-precision_floating-point_format for details.
 *
 *  @param from Lower bound
 *  @param to   Upper bound
 *
 *  @return Random double value uniformly distributed in specified bounds.
 */
FOUNDATION_EXPORT double PSOAlea (double from, double to);

/**
 *  Returns random point from the hypersphere S(0,radius).
 *
 *  @param radius     Hyperspheres radius.
 *  @param x          Buffer in to which to copy the coordinates of the generated random point. Buffer must be of sizeof(double)*dimensions bytes length.
 *  @param dimensions Count of spheres dimensions.
 */
FOUNDATION_EXPORT void PSOAleaInSphere (double radius, double* x, int dimensions);