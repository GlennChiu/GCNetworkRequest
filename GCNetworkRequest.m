//
//  GCNetworkRequest.m
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 15-07-12.
//  Copyright (c) 2012 Dot Square. All rights reserved.
//

//  This code is distributed under the terms and conditions of the MIT license.

//  Copyright (c) 2012 Glenn Chiu
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

#import "GCNetworkRequest.h"
#import "GCHTTPRequestOperation.h"

#if ! __has_feature(objc_arc)
#error GCNetworkRequest is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

#ifdef DEBUG
#   define GCNRLog(fmt, ...) NSLog((@"%s [Line %d]\n" fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define GCNRLog(...) do {} while(0)
#endif

static NSString * GCGenerateBoundary();
static inline NSString * GCURLEncodedString(NSString *string);
static inline NSData * GCUTF8EncodedStringToData(NSString *string);

@interface GCNetworkRequestMultiPartFormData : NSObject <GCMultiPartFormData>

- (id)initWithNetworkRequest:(GCNetworkRequest *)request;
- (void)finishMultiPartFormData;

@end

static NSString * const kGCMultiPartFormDataCRLF = @"\r\n";

static NSString * GCGenerateBoundary()
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    NSString *result = (__bridge_transfer NSString *)uuidStr;
    CFRelease(uuid);
    return result;
}

static inline NSString * GCURLEncodedString(NSString *string)
{
	return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,  (CFStringRef)string,  NULL,  CFSTR(":/.?&=;+!@$()~"),  kCFStringEncodingUTF8);
}

static inline NSData * GCUTF8EncodedStringToData(NSString *string)
{
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

@interface GCNetworkRequest ()

@end

@implementation GCNetworkRequest

+ (GCNetworkRequest *)requestWithURLString:(NSString *)url
{
    return [[[self class] alloc] initWithURLString:url HTTPMethod:nil parameters:nil encoding:0 multiPartFormDataHandler:nil];
}

+ (GCNetworkRequest *)requestWithURLString:(NSString *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)parameters
{
    return [[[self class] alloc] initWithURLString:url HTTPMethod:method parameters:parameters encoding:0 multiPartFormDataHandler:nil];
}

+ (GCNetworkRequest *)requestWithURLString:(NSString *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)parameters encoding:(GCParameterEncoding)encoding
{
    return [[[self class] alloc] initWithURLString:url HTTPMethod:method parameters:parameters encoding:encoding multiPartFormDataHandler:nil];
}

+ (GCNetworkRequest *)requestWithURLString:(NSString *)url parameters:(NSDictionary *)parameters multiPartFormDataHandler:(void(^)(id <GCMultiPartFormData> formData))block
{
    return [[[self class] alloc] initWithURLString:url HTTPMethod:@"POST" parameters:parameters encoding:0 multiPartFormDataHandler:block];
}

- (id)initWithURLString:(NSString *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)parameters encoding:(GCParameterEncoding)encoding multiPartFormDataHandler:(void(^)(id <GCMultiPartFormData> formData))block
{
    self = [super initWithURL:[NSURL URLWithString:url]];
    if (self)
    {
        assert(url);
        
        if (!method && !block) method = @"GET";
        else if (block) method = @"POST";
        [self setHTTPMethod:method];
        
        if (!block)
        {
            if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"]) [self setHTTPShouldUsePipelining:YES];
            
            if (parameters)
            {
                if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"])
                {
                    [self addQueryStringToURLWithURLString:url parameters:parameters];
                }
                else
                {
                    switch (encoding)
                    {
                        case GCParameterEncodingURL:
                            [self URLEncodingFromParameters:parameters];
                            break;
                        case GCParameterEncodingJSON:
                            [self JSONEncodingFromParameters:parameters];
                            break;
                    }
                }
            }
        }
        else
        {
            __block void(^multipart_blk)(id <GCMultiPartFormData>) = [block copy];
            
            dispatch_block_t blk = ^{
                
                GCNetworkRequestMultiPartFormData *multiPartFormData = [[GCNetworkRequestMultiPartFormData alloc] initWithNetworkRequest:self];
                
                if (parameters)
                {
                    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
                        
                        NSData *data = ([value isKindOfClass:[NSData class]]) ? value : GCUTF8EncodedStringToData([value description]);
                        [multiPartFormData addData:data name:[key description]];
                    }];
                }
                
                multipart_blk(multiPartFormData);
                
                [multiPartFormData finishMultiPartFormData];
                
                multipart_blk = nil;
            };
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), blk);
        }
    }
    return self;
}

- (NSString *)queryStringFromParameters:(NSDictionary *)parameters
{
    NSMutableString *string = [@"" mutableCopy];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        
        if ([value isKindOfClass:[NSString class]])
        {
            [string appendFormat:@"%@=%@&", GCURLEncodedString(key), GCURLEncodedString((NSString *)value)];
        }
        else
        {
            [string appendFormat:@"%@=%@&", GCURLEncodedString(key), value];
        }
    }];
    
    if ([string length] > 0) [string deleteCharactersInRange:NSMakeRange([string length]-1, 1)];
    
    return string;
}

- (void)URLEncodingFromParameters:(NSDictionary *)parameters
{
    dispatch_block_t block = ^{
        
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        NSData *urlEncodedData = GCUTF8EncodedStringToData([self queryStringFromParameters:parameters]);
        if (!urlEncodedData) GCNRLog(@"Error: Encoding query URL parameters failed");
        [self setHTTPBody:urlEncodedData];
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), block);
}

- (void)JSONEncodingFromParameters:(NSDictionary *)parameters
{
    dispatch_block_t block = ^{
        
        [self setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSData *jsonData = [self dataFromJSON:parameters];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self setHTTPBody:GCUTF8EncodedStringToData(jsonString)];
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), block);
}

- (void)addQueryStringToURLWithURLString:(NSString *)url parameters:(NSDictionary *)parameters
{
    NSURL *convertedURL = [NSURL URLWithString:url];
    NSString *absoluteString = [convertedURL absoluteString];
    NSString *stringURL = [absoluteString stringByAppendingFormat:[url rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", [self queryStringFromParameters:parameters]];
    NSURL *encodedURL = [NSURL URLWithString:stringURL];
    [self setURL:encodedURL];
}

- (void)setValue:(NSString *)value forHeaderField:(NSString *)field
{
    [self setValue:value forHTTPHeaderField:field];
}

- (void)setUsername:(NSString *)username password:(NSString *)password
{
    NSDictionary *userInfo = @{_userinfo_keys.keys.username : username, _userinfo_keys.keys.password : password};
    [NSURLProtocol setProperty:userInfo forKey:_userinfo_keys.userinfo_key inRequest:self];
}

- (NSData *)dataFromJSON:(id)json
{
    if (![NSJSONSerialization isValidJSONObject:json]) GCNRLog(@"Error: JSONObject not valid");
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
    
    if (!jsonData) GCNRLog(@"Error: %@", [error userInfo]);
    
    return jsonData;
}

- (void)requestShouldUseHTTPPipelining:(BOOL)shouldUsePipelining
{
    if ([[self HTTPMethod] isEqualToString:@"POST"])
    {
        GCNRLog(@"Error: POST requests should not be pipelined");
        return;
    }
    
    [self setHTTPShouldUsePipelining:shouldUsePipelining];
}

- (void)setTimeoutIntervalInSeconds:(NSTimeInterval)seconds
{
    [self setTimeoutInterval:seconds];
}

@end

@interface GCNetworkRequestMultiPartFormData ()

@end

@implementation GCNetworkRequestMultiPartFormData
{
    GCNetworkRequest *_request;
    NSOutputStream *_oStream;
    NSString *_boundary;
}

- (id)initWithNetworkRequest:(GCNetworkRequest *)request
{
    self = [super init];
    if (self)
    {
        self->_request = request;
        
        self->_boundary = GCGenerateBoundary();
        
        self->_oStream = [[NSOutputStream alloc] initToMemory];
        [self->_oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self->_oStream open];
    }
    return self;
}

- (void)finishMultiPartFormData
{
    if ([[self->_oStream propertyForKey:NSStreamFileCurrentOffsetKey] integerValue] == 0)
    {
        [self cleanupStream:self->_oStream];
        return;
    }
    
    [self addStringData:[NSString stringWithFormat:@"--%@--%@", self->_boundary, kGCMultiPartFormDataCRLF]];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", GCGenerateBoundary()];
    [self->_request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSString *contentLength = [[self->_oStream propertyForKey:NSStreamFileCurrentOffsetKey] stringValue];
    [self->_request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    
    NSData *finalData = [self->_oStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    [self->_request setHTTPBodyStream:[NSInputStream inputStreamWithData:finalData]];
    
    [self cleanupStream:self->_oStream];
}

- (void)cleanupStream:(NSStream *)stream
{
    assert(stream);
    
    [stream close];
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    stream = nil;
}

- (void)addData:(NSData *)data
{
    if ([self->_oStream hasSpaceAvailable])
    {
        const uint8_t *buffer = (uint8_t *)[data bytes];
        [self->_oStream write:&buffer[0] maxLength:[data length]];
    }
}

- (void)addStringData:(NSString *)string
{
    [self addData:GCUTF8EncodedStringToData(string)];
}

- (void)generatePOSTMessage:(NSDictionary *)messageValues withBody:(NSData *)body
{
    [self addStringData:[NSString stringWithFormat:@"--%@%@", self->_boundary, kGCMultiPartFormDataCRLF]];
    
    [messageValues enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        
        [self addStringData:[NSString stringWithFormat:@"%@: %@%@", key, value, kGCMultiPartFormDataCRLF]];
    }];
    
    [self addStringData:kGCMultiPartFormDataCRLF];
    [self addData:body];
    [self addStringData:kGCMultiPartFormDataCRLF];
}

- (void)addTextData:(NSString *)string name:(NSString *)name
{
    NSDictionary *message = @{@"Content-Disposition" : [NSString stringWithFormat:@"form-data; name=\"%@\"", name]};
    NSData *body = GCUTF8EncodedStringToData([NSString stringWithFormat:@"%@", string]);
    [self generatePOSTMessage:message withBody:body];
}

- (void)addData:(NSData *)data name:(NSString *)name filename:(NSString *)filename mimeType:(NSString *)mimeType
{
    if (!mimeType) mimeType = @"application/octet-stream";
    
    NSDictionary *message = @{@"Content-Disposition" : [NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, filename], @"Content-Type" : [NSString stringWithFormat:@"%@", mimeType]};
    [self generatePOSTMessage:message withBody:data];
}

- (void)addData:(NSData *)data name:(NSString *)name
{
    [self addData:data name:name filename:name mimeType:nil];
}

- (void)addFileFromPath:(NSString *)filePath name:(NSString *)name mimeType:(NSString *)mimeType
{
    NSError *error = nil;
    NSData *fileData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    
    if (!fileData)
    {
        GCNRLog(@"Error: %@", [error userInfo]);
        return;
    }
    
    [self addData:fileData name:name filename:[filePath lastPathComponent] mimeType:mimeType];
}

- (void)addFileFromPath:(NSString *)filePath name:(NSString *)name
{
    [self addFileFromPath:filePath name:name mimeType:nil];
}

@end