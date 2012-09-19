//
//  GCNetworkRequest.m
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

#import "GCNetworkRequest.h"
#import "GCHTTPRequestOperation.h"

#if ! __has_feature(objc_arc)
#error GCNetworkRequest is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

static NSString * GenerateBoundary()
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    assert(uuid);
    
    CFStringRef uuidStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    assert(uuidStr);
    
    NSString *result = (__bridge NSString *)uuidStr;
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

@interface GCNetworkRequest ()

@end

@implementation GCNetworkRequest
{
    NSMutableDictionary *_dataDict;
    NSString *_boundary;
}

+ (id)requestWithURLString:(NSString *)url
{
    return [[[self class] alloc] initWithURLString:url HTTPMethod:nil parameters:nil];
}

+ (id)requestWithURLString:(NSString *)url HTTPMethod:(NSString *)method parameters:(NSMutableDictionary *)body
{
    return [[[self class] alloc] initWithURLString:url HTTPMethod:method parameters:body];
}

- (id)initWithURLString:(NSString *)url HTTPMethod:(NSString *)method parameters:(NSMutableDictionary *)body
{
    self = [super initWithURL:[NSURL URLWithString:url]];
    if (self)
    {
        assert(url);
        
        if (!method) method = @"GET";
        [self setHTTPMethod:method];
        
        if (body) [self setAllHTTPHeaderFields:body];
    }
    return self;
}

- (void)addValue:(NSString *)value forHeaderField:(NSString *)field
{
    [self addValue:value forHTTPHeaderField:field];
}

- (void)setUsername:(NSString *)username password:(NSString *)password
{
    NSDictionary *userInfo = @{_userinfo_keys.keys.username : username, _userinfo_keys.keys.password : password};
    
    [NSURLProtocol setProperty:userInfo forKey:_userinfo_keys.userinfo_key inRequest:self];
}

- (NSData *)dataForPOSTWithDictionary:(NSDictionary *)dict
{
    NSArray *allDictKeys = [dict allKeys];
    NSMutableData *postData = [NSMutableData dataWithCapacity:1];
    
    NSString *boundary = [NSString stringWithFormat:@"--%@\r\n", self->_boundary];
    
    [allDictKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        @autoreleasepool {
            
            NSString *dictKey = (NSString *)obj;
            id dataValue = dict[dictKey];
            
            [postData appendData:[boundary dataUsingEncoding:NSUTF8StringEncoding]];
            
            if ([dataValue isKindOfClass:[NSString class]])
            {
                [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", dictKey] dataUsingEncoding:NSUTF8StringEncoding]];
                [postData appendData:[[NSString stringWithFormat:@"%@", dataValue] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            else if (([dataValue isKindOfClass:[NSURL class]]) && ([dataValue isFileURL]))
            {
                [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", dictKey, [[dataValue path] lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
                [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [postData appendData:[NSData dataWithContentsOfFile:[dataValue path]]];
            }
            else if (([dataValue isKindOfClass:[NSData class]]))
            {
                [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", dictKey, allDictKeys[idx]] dataUsingEncoding:NSUTF8StringEncoding]];
                [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [postData appendData:dataValue];
            }
            
            [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }];
    
    [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", self->_boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return postData;
}

- (NSMutableDictionary *)dataDict
{
    return self->_dataDict ?: (self->_dataDict = [@{} mutableCopy]);
}

- (void)addBodyData
{
    [self setHTTPMethod:@"POST"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        
        self->_boundary = GenerateBoundary();
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self->_boundary];
        [self addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSData *bodyData = [self dataForPOSTWithDictionary:[self dataDict]];
        [self setHTTPBody:bodyData];
    });
}

- (void)addData:(NSData *)data forKey:(NSString *)key
{
    [self dataDict][key] = data;
    
    [self addBodyData];
}

- (void)addFileWithPath:(NSString *)file forKey:(NSString *)key
{
    NSError *error = nil;
    NSData *fileData = [NSData dataWithContentsOfFile:file options:NSDataReadingMappedIfSafe error:&error];
    
    if (!fileData)
    {
        GCNRLog(@"Error: %@", [error userInfo]);
        return;
    }
    
    [self addData:fileData forKey:key];
}

- (void)requestShouldUseHTTPPipelining:(BOOL)shouldUsePipelining
{
    [self setHTTPShouldUsePipelining:shouldUsePipelining];
}

- (void)setTimeoutIntervalInSeconds:(NSTimeInterval)seconds
{
    [self setTimeoutInterval:seconds];
}

@end