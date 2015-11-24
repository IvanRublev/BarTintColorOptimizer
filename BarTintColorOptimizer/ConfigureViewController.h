//
//  ConfigureViewController.h
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 10/25/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

@import UIKit;
#import "NavbarView.h"

@interface ConfigureViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic) BOOL hasAlphaComponent;
@end

