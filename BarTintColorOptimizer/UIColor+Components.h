//
//  UIColor+Components.h
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/26/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

@import UIKit;

typedef NS_ENUM(NSUInteger, ColorComponents) {
    redComponenet,
    greenComponenet,
    blueComponenet,
    alphaComponent
};

@interface UIColor (Components)

- (uint8_t)R;
- (uint8_t)G;
- (uint8_t)B;
- (uint8_t)A;
- (UIColor*)colorWithNewR:(uint8_t)R;
- (UIColor*)colorWithNewG:(uint8_t)G;
- (UIColor*)colorWithNewB:(uint8_t)B;
- (UIColor *)colorWithNewA:(uint8_t)A;

- (NSString*)rString;
- (NSString*)gString;
- (NSString*)bString;
- (NSString*)hexString;
- (NSString*)hexStringWithA;

- (UIColor*)colorByReplacingComponent:(ColorComponents)component withValueFromString:(NSString*)componentString;
+ (UIColor*)colorWithR:(uint8_t)r G:(uint8_t)g B:(uint8_t)b;
+ (UIColor*)colorWithR:(uint8_t)r G:(uint8_t)g B:(uint8_t)b A:(uint8_t)a;

@end
