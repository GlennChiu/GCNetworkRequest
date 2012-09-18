//
//  GCHTTPRequestOperation.h
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 05/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCNetworkRequest;

@interface GCHTTPRequestOperation : NSOperation

@property (assign, nonatomic) BOOL forceReloadConnection;
@property (assign, nonatomic) BOOL rejectRedirect;
@property (assign, nonatomic) BOOL allowUntrustedServerCertificate;
@property (strong, nonatomic) NSInputStream *inputStream;
@property (strong, nonatomic) NSError *error;

+ (id)HTTPRequest:(GCNetworkRequest *)networkRequest
    callBackQueue:(dispatch_queue_t)queue
completionHandler:(void(^)(NSData *data, NSHTTPURLResponse *response))completionBlock
     errorHandler:(void(^)(NSData *data, NSHTTPURLResponse *response, NSError *error))errorBlock;

- (id)initWithHTTPRequest:(GCNetworkRequest *)networkRequest
            callBackQueue:(dispatch_queue_t)queue
        completionHandler:(void(^)(NSData *data, NSHTTPURLResponse *response))completionBlock
             errorHandler:(void(^)(NSData *data, NSHTTPURLResponse *response, NSError *error))errorBlock;

- (void)startRequest;

- (void)cancelRequest;

- (void)downloadProgressHandler:(void(^)(NSUInteger bytesRead, NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead))block;

- (void)uploadProgressHandler:(void(^)(NSUInteger bytesWritten, NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite))block;

#if TARGET_OS_IPHONE
- (void)endBackgroundTaskWithCompletionHandler:(void(^)(void))block;
#endif

@end

extern const struct _userinfo_keys {
    __unsafe_unretained NSString *userinfo_key;
    struct
    {
        __unsafe_unretained NSString *username;
        __unsafe_unretained NSString *password;
    } keys;
} _userinfo_keys;

extern inline dispatch_queue_t gc_dispatch_queue(dispatch_queue_t queue);