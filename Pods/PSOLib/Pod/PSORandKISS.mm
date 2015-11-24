//
//  PSORandKISS.mm
//  PSOLib
//
//  Ported by Ivan Rublev on 11/6/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//
//  Ported from Standard PSO 2011
//  http://www.particleswarm.info/standard_pso_2011_c.zip
//  Original file: KISS.c
//

//================================================== KISS
/*
 A good pseudo-random numbers generator

 The idea is to use simple, fast, individually promising
 generators to get a composite that will be fast, easy to code
 have a very long period and pass all the tests put to it.
 The three components of KISS are
 x(n)=a*x(n-1)+1 mod 2^32
	 y(n)=y(n-1)(I+L^13)(I+R^17)(I+L^5),
	 z(n)=2*z(n-1)+z(n-2) +carry mod 2^32
		 The y's are a shift register sequence on 32bit binary vectors
		 period 2^32-1;
	 The z's are a simple multiply-with-carry sequence with period
		 2^63+2^32-1.  The period of KISS is thus
		 2^32*(2^32-1)*(2^63+2^32-1) > 2^127
			 */

#import "PSORandKISS.h"

static PSOUint pso_kiss_x; //= 1;
static PSOUint pso_kiss_y; //= 2;
static PSOUint pso_kiss_z; //= 4;
static PSOUint pso_kiss_w; //= 8;
static PSOUint pso_kiss_carry = 0;
static PSOUint pso_kiss_k;
static PSOUint pso_kiss_m;



void PSOSeedRandKISS(PSOUint seed) 
{
	pso_kiss_x = seed | 1;
	pso_kiss_y = seed | 2;
	pso_kiss_z = seed | 4;
	pso_kiss_w = seed | 8;
	pso_kiss_carry = 0;
}

PSOUint PSORandKISS() 
{
	pso_kiss_x = pso_kiss_x * 69069 + 1;
	pso_kiss_y ^= pso_kiss_y << 13;
	pso_kiss_y ^= pso_kiss_y >> 17;
	pso_kiss_y ^= pso_kiss_y << 5;
	pso_kiss_k = (pso_kiss_z >> 2) + (pso_kiss_w >> 3) + (pso_kiss_carry >> 2);
	pso_kiss_m = pso_kiss_w + pso_kiss_w + pso_kiss_z + pso_kiss_carry;
	pso_kiss_z = pso_kiss_w;
	pso_kiss_w = pso_kiss_m;
	pso_kiss_carry = pso_kiss_k >> 30;
	//printf("\n%f ",(double) (pso_kiss_x + pso_kiss_y + pso_kiss_w));
	return pso_kiss_x + pso_kiss_y + pso_kiss_w;
}
