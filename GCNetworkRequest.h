//
//  GCNetworkRequest.h
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 15-07-12.
//  Copyright (c) 2012 Dot Square. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCNetworkQueue.h"
#import "GCJSONRequestOperation.h"
#import "GCXMLRequestOperation.h"

@interface GCNetworkRequest : NSMutableURLRequest

+ (id)requestWithURLString:(NSString *)url;

+ (id)requestWithURLString:(NSString *)url
                HTTPMethod:(NSString *)method
                parameters:(NSMutableDictionary *)body;

- (void)setUsername:(NSString *)username
           password:(NSString *)password;

- (void)addFileWithPath:(NSString *)file
                 forKey:(NSString *)key;

- (void)addData:(NSData *)data
         forKey:(NSString *)key;

- (void)sendRequestImmediatelyAfterPreviousRequest:(BOOL)send;

- (void)setTimeoutIntervalInSeconds:(NSTimeInterval)seconds;

@end

#ifdef DEBUG
#   define GCNRLog(fmt, ...) NSLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define GCNRLog(...) do {} while(0)
#endif

#if TARGET_OS_IPHONE
#   if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
#       define GC_DISPATCH_RELEASE(v) do {} while(0)
#       define GC_DISPATCH_RETAIN(v) do {} while(0)
#   else
#       define GC_DISPATCH_RELEASE(v) dispatch_release(v)
#       define GC_DISPATCH_RETAIN(v) dispatch_retain(v)
#   endif
#else
#   if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
#       define GC_DISPATCH_RELEASE(v) do {} while(0)
#       define GC_DISPATCH_RETAIN(v) do {} while(0)
#   else
#       define GC_DISPATCH_RELEASE(v) dispatch_release(v)
#       define GC_DISPATCH_RETAIN(v) dispatch_retain(v)
#   endif
#endif