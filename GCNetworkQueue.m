//
//  GCNetworkQueue.m
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 15/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

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
