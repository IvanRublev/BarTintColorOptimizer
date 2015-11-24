//
//  PSOImmutableProxy.m
//  PSOLib
//
//  Created by Ivan Rublev on 11/15/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

#import "PSOImmutableProxy.h"

@implementation PSOImmutableProxy

- (instancetype)initWithObject:(id)object {
    NSParameterAssert(object);
    _object = object;
    return self;
}

- (BOOL)canPassSelector:(SEL)sel {
    NSString* selectorName = NSStringFromSelector(sel);
    return NO == [selectorName hasPrefix:@"set"];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_object respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (NO == [self canPassSelector:sel]) {
        NSAssert(YES, @"The object setters are not allowed to be called.");
        return nil;
    }
    return [_object methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:_object];
}

@end
