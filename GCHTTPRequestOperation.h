//
//  This code is distributed under the terms and conditions of the MIT license.
//
//  Copyright (c) 2013 Glenn Chiu
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

extern const struct _userinfo_keys {
    __unsafe_unretained NSString *userinfo_key;
    struct
    {
        __unsafe_unretained NSString *username;
        __unsafe_unretained NSString *password;
    } keys;
} _userinfo_keys;

extern dispatch_queue_t gc_dispatch_queue(dispatch_queue_t queue);

@class GCNetworkRequest;

@interface GCHTTPRequestOperation : NSOperation

@property (assign, nonatomic) BOOL forceReloadConnection;
@property (assign, nonatomic) BOOL rejectRedirect;
@property (assign, nonatomic) BOOL allowUntrustedServerCertificate;
@property (strong, nonatomic) NSInputStream *inputStream;
@property (strong, nonatomic) NSError *error;

+ (instancetype)HTTPRequest:(GCNetworkRequest *)networkRequest
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