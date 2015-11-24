//
//  UIColor+Components.m
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/26/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

#import "UIColor+Components.h"
#import <ColorUtils/ColorUtils.h>

@implementation UIColor (Components)

+ (NSUInteger)bitShiftForComponent:(ColorComponents)component {
    NSUInteger shift = 0;
    switch (component) {
        case redComponenet:
            shift = 24;
            break;
        case greenComponenet:
            shift = 16;
            break;
        case blueComponenet:
            shift = 8;
            break;
        case alphaComponent:
        default:
            break;
    }
    return shift;
}

- (uint8_t)component:(ColorComponents)component {
    NSUInteger shift = [self.class bitShiftForComponent:component];
    return (self.RGBAValue & (0xFF << shift)) >> shift;
}

- (NSString *)stringWithComponent:(ColorComponents)component {
    return [NSString stringWithFormat:@"%d", [self component:component]];
}

- (uint8_t)R {
    return [self component:redComponenet];
}

- (uint8_t)G {
    return [self component:greenComponenet];
}

- (uint8_t)B {
    return [self component:blueComponenet];
}

- (uint8_t)A {
    return [self component:alphaComponent];
}

- (UIColor *)colorWithNewR:(uint8_t)R {
    return [UIColor colorWithR:R G:self.G B:self.B];
}

- (UIColor *)colorWithNewG:(uint8_t)G {
    return [UIColor colorWithR:self.R G:G B:self.B];
}

- (UIColor *)colorWithNewB:(uint8_t)B {
    return [UIColor colorWithR:self.R G:self.G B:B];
}

- (UIColor *)colorWithNewA:(uint8_t)A {
    return [UIColor colorWithR:self.R G:self.G B:self.B A:A];
}

- (NSString *)rString {
    return [self stringWithComponent:redComponenet];
}

- (NSString *)gString {
    return [self stringWithComponent:greenComponenet];
}

- (NSString *)bString {
    return [self stringWithComponent:blueComponenet];
}

- (NSString *)hexString {
    return [NSString stringWithFormat:@"#%.6x", self.RGBValue];
}

- (NSString *)hexStringWithA {
    return [NSString stringWithFormat:@"#%.8x", self.RGBAValue];
}

- (UIColor *)colorByReplacingComponent:(ColorComponents)component withValueFromString:(NSString *)componentString {
    NSUInteger shift = [self.class bitShiftForComponent:component];
    uint32_t newColorValue = self.RGBAValue;
    newColorValue =  (newColorValue & (~(0xFF << shift))) | (([componentString intValue] & 0x0000FF) << shift);
    return [UIColor colorWithRGBAValue:newColorValue];
}

+ (UIColor *)colorWithR:(uint8_t)r G:(uint8_t)g B:(uint8_t)b {
    uint32_t value =
    r << [self.class bitShiftForComponent:redComponenet] |
    g << [self.class bitShiftForComponent:greenComponenet] |
    b << [self.class bitShiftForComponent:blueComponenet] |
    255 << [self.class bitShiftForComponent:alphaComponent];
    
    UIColor *color = [UIColor colorWithRGBAValue:value];
    return color;
}

+ (UIColor *)colorWithR:(uint8_t)r G:(uint8_t)g B:(uint8_t)b A:(uint8_t)a {
    uint32_t value =
    r << [self.class bitShiftForComponent:redComponenet] |
    g << [self.class bitShiftForComponent:greenComponenet] |
    b << [self.class bitShiftForComponent:blueComponenet] |
    a << [self.class bitShiftForComponent:alphaComponent];
    
    UIColor *color = [UIColor colorWithRGBAValue:value];
    return color;
}

@end
