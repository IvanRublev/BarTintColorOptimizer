//
//  VRFoundationVersion.h
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 11/26/14.
//  Copyright (c) 2014 Ivan Rublev http://ivanrublev.me. All rights reserved.
//


// Macro to check iOS version. From https://github.com/carlj/CJAMacros/blob/master/CJAMacros/CJAMacros.h
// If the symbol for iOS 8 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_iOS_8_0 1134.10 //extracted with NSLog(@"%f", NSFoundationVersionNumber)
#endif

#ifdef NSFoundationVersionNumber_iOS_8_0
#define _iOS_8_0 NSFoundationVersionNumber_iOS_8_0
#endif

#define IS_IOS8_OR_LATER (fabs(NSFoundationVersionNumber-_iOS_8_0) < DBL_EPSILON || NSFoundationVersionNumber > _iOS_8_0)
