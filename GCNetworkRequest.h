//
//  GCNetworkRequest.h
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 15-07-12.
//  Copyright (c) 2012 Dot Square. All rights reserved.
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