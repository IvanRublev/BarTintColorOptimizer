//
//  NavbarView.m
//  BarTintColorOptimizer
//
//  Created by Ivan Rublev on 11/9/15.
//  Copyright (c) 2015 Ivan Rublev http://ivanrublev.me. All rights reserved.
//

#import "NavbarView.h"

@implementation NavbarView

- (void)addSelfToContainerView:(UIView *)container {
    NSParameterAssert(container);
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:self];
    [container addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[self]|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(self)]];
    [container addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[self]|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(self)]];
}

@end
