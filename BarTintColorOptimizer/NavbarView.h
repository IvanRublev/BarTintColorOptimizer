//
//  NavbarView.h
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 11/9/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

@import UIKit;
@class NavbarView;

typedef void(^ColorNavbarBlock)(NavbarView *navbarView, UIColor *barColor, UIColor* underlyingColor);

@interface NavbarView : UIView
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIView *underlyingView;
- (void)addSelfToContainerView:(UIView*)container;
@end
