//
//  PSOImmutableProxy.h
//  PSOLib
//
//  Created by Ivan Rublev on 11/15/15.
//  Copyright (c) 2015 Ivan Rublev. All rights reserved. http://ivanrublev.me
//
//  Distributed under the MIT license.
//

@import Foundation;

/**
 *  Proxy that passes only getter messages to specified object. When setter message is received the proxy object ignores the message and throws an assertion.
 */
@interface PSOImmutableProxy : NSProxy {
    __strong id _object;
}
- (instancetype)initWithObject:(id)object;
@end
