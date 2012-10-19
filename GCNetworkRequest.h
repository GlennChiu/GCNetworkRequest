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

typedef enum : unsigned char
{
    GCParameterEncodingURL = 1,
    GCParameterEncodingJSON
} GCParameterEncoding;

@protocol GCMultiPartFormData;

@interface GCNetworkRequest : NSMutableURLRequest

+ (id)requestWithURLString:(NSString *)url;

+ (id)requestWithURLString:(NSString *)url
                HTTPMethod:(NSString *)method
                parameters:(NSDictionary *)parameters;

+ (id)requestWithURLString:(NSString *)url
                HTTPMethod:(NSString *)method
                parameters:(NSDictionary *)parameters
                  encoding:(GCParameterEncoding)encoding;

+ (id)requestWithURLString:(NSString *)url
                parameters:(NSDictionary *)parameters
  multiPartFormDataHandler:(void(^)(id <GCMultiPartFormData> formData))block;

- (void)addValue:(NSString *)value
  forHeaderField:(NSString *)field;

- (void)setUsername:(NSString *)username
           password:(NSString *)password;

- (void)requestShouldUseHTTPPipelining:(BOOL)shouldUsePipelining;

- (void)setTimeoutIntervalInSeconds:(NSTimeInterval)seconds;

@end

@protocol GCMultiPartFormData <NSObject>

- (void)addTextData:(NSString *)string
                 name:(NSString *)name;

- (void)addData:(NSData *)data
           name:(NSString *)name;

- (void)addData:(NSData *)data
           name:(NSString *)name
       filename:(NSString *)filename
       mimeType:(NSString *)mimeType;

- (void)addFileFromPath:(NSString *)filePath
                   name:(NSString *)name;

- (void)addFileFromPath:(NSString *)filePath
                   name:(NSString *)name
               mimeType:(NSString *)mimeType;

@end

#ifdef DEBUG
#   define GCNRLog(fmt, ...) NSLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define GCNRLog(...) do {} while(0)
#endif