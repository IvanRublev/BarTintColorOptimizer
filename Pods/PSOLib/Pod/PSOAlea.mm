//
//  PSOAlea.m
//  PSOLib
//
//  Ported by Ivan Rublev on 11/7/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//
//  Ported from matlab version of Standard PSO 2011
//  http://www.particleswarm.info/PSOStandard2011_matlab.zip
//  Original files: alea.m, alea_normal.m, alea_sphere.m
//  Developed by: Maurice Clerc (May 2011)
//

#import "PSOAlea.h"
#import "PSORandKISS.h"
#import <Security/Security.h>
#import <Accelerate/Accelerate.h>

void PSOAleaSrand (unsigned int seed) {
    static_assert(sizeof(seed)==sizeof(PSOUint), "seed parameter mus be of PSOUint size");
    PSOSeedRandKISS(seed);
}

void PSOAleaSeeddevRand () {
    PSOUint seed;
    SecRandomCopyBytes(kSecRandomDefault, sizeof(PSOUint), (uint8_t*)&seed);
    PSOSeedRandKISS(seed);
}

double PSOAlea (double from, double to) {
    // Return uniformly distributed pseudorandom number.
    // Fills first 32 bits of double value then zeros 0 and 11-th bit from end to make value positive and valid, then normalize value to provided bounds.
#define PSOUint_t uint64_t
    static_assert(sizeof(double)==8, "double expected to be of 8 bytes length");
    static_assert(sizeof(PSOUint_t)==sizeof(double), "PSOUint_t expected to same size as double");
    static_assert(sizeof(double)==sizeof(PSOUint)*2, "PSOUint expected to be half of double length");
#define pso_int_prep(INTNUM) (((PSOUint_t)INTNUM >> 1) & ~((PSOUint_t)1 << 52)) // makes the INTNUM value when casted to double to have sign = 0, exponent = 2 ** 0
#define pso_int_to_double(INTNUM) ((double)INTNUM)
#define pso_double_max pso_int_to_double(pso_int_prep(~(PSOUint_t)0)) // about 1.99

    PSOUint_t randomInt = 0;
    *((PSOUint*)&randomInt+0) = PSORandKISS();
    *((PSOUint*)&randomInt+1) = PSORandKISS();
    randomInt = pso_int_prep(randomInt);
    double randomDouble = pso_int_to_double(randomInt);
    randomDouble /= pso_double_max; // 0.0 - 1.0
    double normalizedRandomDouble = from + randomDouble * (to-from);
    return normalizedRandomDouble;
    
#undef PSOUint_t
#undef pso_int_prep
#undef pso_int_to_double
#undef pso_double_max
}

double PSOAleaNormal (double mean, double std_dev) {
    // Returns normally distributed pseudorandom number.
    double w = 2.;
    double x1 = 0;
    while (w >= 1.) {
        x1 = 2. * PSOAlea(0., 1.) - 1.;
        double x2 = 2. * PSOAlea(0., 1.) - 1.;
        w = x1*x1 + x2*x2;
    }
    w = sqrt(-2. * log(w) / w);
    double y1 = x1 * w;
    if (PSOAlea(0., 1.) < 0.5) {
        y1 = -y1;
    }
    
    y1 = y1 * std_dev + mean;
    return y1;
}

void PSOAleaInSphere(double radius, double* x, int dimensions) {
    if ( ! x) {
        assert("x must be allocated array of double of dimensions size.");
        return;
    }
    if ( ! dimensions) {
        assert("dimensions must be greater then zero.");
        return;
    }
    for (int d=0; d<dimensions; d++) { // random direction
        x[d] = PSOAleaNormal (0., 1.);
    }
    double l = cblas_dnrm2(dimensions, x, 1);
    double r = PSOAlea (0., 1.); // random radius
    r = r*radius/l;
    vDSP_vsmulD(x, 1, &r, x, 1, dimensions);
}
