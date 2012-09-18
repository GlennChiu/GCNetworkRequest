//
//  GCNetworkQueue.m
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 15/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2012 Glenn Chiu
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GCNetworkQueue.h"
#import "GCHTTPRequestOperation.h"

#if ! __has_feature(objc_arc)
#error GCNetworkRequest is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

static signed char kOperationCountStatusContext;
static NSString * const kOperationCountKey = @"operationCount";

@implementation GCNetworkQueue
{
    BOOL _enableNetworkActivityIndicator;
}

- (void)setMaximumConcurrentOperationsCount:(NSInteger)count
{
    [self setMaxConcurrentOperationCount:count];
}

- (void)enqueueOperation:(GCHTTPRequestOperation *)operation
{
    [self addOperation:operation];
}

- (void)enqueueArrayOfOperations:(NSArray *)operations
{
    [self addOperations:operations waitUntilFinished:NO];
}

- (void)cancelAllNetworkOperations
{
    [self cancelAllOperations];
}

- (void)dealloc
{
    if (self->_enableNetworkActivityIndicator) [self removeObserver:self forKeyPath:kOperationCountKey context:&kOperationCountStatusContext];
}

#if TARGET_OS_IPHONE
- (void)enableNetworkActivityIndicator:(BOOL)enable
{
    if (enable)
    {
        self->_enableNetworkActivityIndicator = enable;
        [self addObserver:self forKeyPath:kOperationCountKey options:0 context:&kOperationCountStatusContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &kOperationCountStatusContext)
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(self.operationCount > 0)];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#endif

@end
