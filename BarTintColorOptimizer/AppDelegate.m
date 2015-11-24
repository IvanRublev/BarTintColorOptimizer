//
//  AppDelegate.m
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/25/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

#import "AppDelegate.h"
#import "VRFoundationVersion.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    if (IS_IOS8_OR_LATER) {
        [[UINavigationBar appearance] setTranslucent:YES];
    }
    return YES;
}

@end
