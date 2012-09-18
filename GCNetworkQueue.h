//
//  GCNetworkQueue.h
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 15/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCHTTPRequestOperation;

@interface GCNetworkQueue : NSOperationQueue

- (void)enqueueOperation:(GCHTTPRequestOperation *)operation;

- (void)enqueueArrayOfOperations:(NSArray *)operations;

- (void)cancelAllNetworkOperations;

- (void)setMaximumConcurrentOperationsCount:(NSInteger)count;

#if TARGET_OS_IPHONE
- (void)enableNetworkActivityIndicator:(BOOL)enable;
#endif

@end
