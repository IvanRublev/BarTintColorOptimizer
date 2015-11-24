//
//  ProgressViewController.h
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/25/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

@import UIKit;

@interface ProgressViewController : UIViewController
@property (nonatomic) UIColor* designColor;
@property (nonatomic) UIColor* underviewColor;
@property (nonatomic) UIColor* optimizedColor;
@property (nonatomic) BOOL exactSearch;
@property (nonatomic, copy) ColorNavbarBlock colorNavigationbar;
@end
