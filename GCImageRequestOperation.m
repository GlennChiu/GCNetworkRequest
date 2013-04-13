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

#import "GCImageRequestOperation.h"

#if ! __has_feature(objc_arc)
#   error GCNetworkRequest is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

@implementation GCImageRequestOperation

#if TARGET_OS_IPHONE
+ (instancetype)imageRequest:(GCNetworkRequest *)networkRequest callBackQueue:(dispatch_queue_t)queue completionHandler:(void(^)(UIImage *image, NSHTTPURLResponse *response))completionBlock errorHandler:(void(^)(UIImage *image, NSHTTPURLResponse *response, NSError *error))errorBlock
{
    __block GCImageRequestOperation *operation = nil;
    
    operation = [[GCImageRequestOperation alloc] initWithHTTPRequest:networkRequest
                                                       callBackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul)
                                                   completionHandler:^(NSData *data, NSHTTPURLResponse *response) {
                                                       
                                                       if (completionBlock)
                                                       {
                                                           UIImage *image = [UIImage imageWithData:data];
                                                           
                                                           dispatch_async(gc_dispatch_queue(queue), ^{completionBlock(image, response);});
                                                       };
                                                       
                                                   } errorHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                                                       
                                                       if (errorBlock)
                                                       {
                                                           UIImage *image = [UIImage imageWithData:data];
                                                           
                                                           dispatch_async(gc_dispatch_queue(queue), ^{errorBlock(image, response, error);});
                                                       };
                                                       
                                                   }];
    return operation;
}
#endif

#if __MAC_OS_X_VERSION_MIN_REQUIRED
+ (instancetype)imageRequest:(GCNetworkRequest *)networkRequest callBackQueue:(dispatch_queue_t)queue completionHandler:(void(^)(NSImage *image, NSHTTPURLResponse *response))completionBlock errorHandler:(void(^)(NSImage *image, NSHTTPURLResponse *response, NSError *error))errorBlock
{
    __block GCImageRequestOperation *operation = nil;
    
    operation = [[GCImageRequestOperation alloc] initWithHTTPRequest:networkRequest
                                                       callBackQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul)
                                                   completionHandler:^(NSData *data, NSHTTPURLResponse *response) {
                                                       
                                                       if (completionBlock)
                                                       {
                                                           NSImage *image = [[NSImage alloc] initWithData:data];
                                                           
                                                           dispatch_async(gc_dispatch_queue(queue), ^{completionBlock(image, response);});
                                                       };
                                                       
                                                   } errorHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                                                       
                                                       if (errorBlock)
                                                       {
                                                           NSImage *image = [[NSImage alloc] initWithData:data];
                                                           
                                                           dispatch_async(gc_dispatch_queue(queue), ^{errorBlock(image, response, error);});
                                                       };
                                                       
                                                   }];
    return operation;
}
#endif

@end
