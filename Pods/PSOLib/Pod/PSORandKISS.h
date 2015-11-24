//
//  PSORandKISS.h
//  PSOLib
//
//  Ported by Ivan Rublev on 11/6/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

# define PSOUint unsigned int
# define PSORandKISSMax ((PSOUint) 4294967295) //  Needs ISO C90

/**
 *  Seeds the KISS random generator.
 *
 *  @param seed Seed value.
 */
FOUNDATION_EXPORT void PSOSeedRandKISS(PSOUint seed);
/**
 *  Returns pseudorandom number uniformely distributed from 0 to PSORandKISSMax.
 *
 *  @return Pseudorandom unsigned integer of PSOUint type.
 */
FOUNDATION_EXPORT PSOUint PSORandKISS();
