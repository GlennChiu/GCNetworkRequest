//
//  GCXMLRequestOperation.m
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 16/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
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

#import "GCXMLRequestOperation.h"

#if ! __has_feature(objc_arc)
#error GCNetworkRequest is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

@implementation GCXMLRequestOperation
{
    NSError *_XMLError;
}

#if TARGET_OS_IPHONE
+ (id)XMLParserRequest:(GCNetworkRequest *)networkRequest callBackQueue:(dispatch_queue_t)queue completionHandler:(void(^)(NSXMLParser *parser, NSHTTPURLResponse *response))completionBlock errorHandler:(void(^)(NSXMLParser *parser, NSHTTPURLResponse *response, NSError *error))errorBlock
{
    __block GCXMLRequestOperation *operation = nil;
    
    operation = [[GCXMLRequestOperation alloc] initWithHTTPRequest:networkRequest
                                                     callBackQueue:queue
                                                 completionHandler:^(NSData *data, NSHTTPURLResponse *response) {
                                                     
                                                     if (completionBlock)
                                                     {
                                                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                                                             
                                                             NSXMLParser *parser = [operation XMLParserFromData:data];
                                                             
                                                             dispatch_async(gc_dispatch_queue(queue), ^{completionBlock(parser, response);});
                                                         });
                                                     }
                                                     
                                                 } errorHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                                                     
                                                     if (errorBlock)
                                                     {
                                                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                                                             
                                                             NSXMLParser *parser = [operation XMLParserFromData:data];
                                                             
                                                             dispatch_async(gc_dispatch_queue(queue), ^{errorBlock(parser, response, error);});
                                                         });
                                                     }
                                                 }];
    return operation;
}

- (NSXMLParser *)XMLParserFromData:(NSData *)data
{
    return [[NSXMLParser alloc] initWithData:data];
}
#endif

#if __MAC_OS_X_VERSION_MIN_REQUIRED
+ (id)XMLDocumentRequest:(GCNetworkRequest *)networkRequest callBackQueue:(dispatch_queue_t)queue completionHandler:(void(^)(NSXMLDocument *document, NSHTTPURLResponse *response))completionBlock errorHandler:(void(^)(NSXMLDocument *document, NSHTTPURLResponse *response, NSError *error))errorBlock
{
    __block GCXMLRequestOperation *operation = nil;
    
    operation = [[GCXMLRequestOperation alloc] initWithHTTPRequest:networkRequest
                                                     callBackQueue:queue
                                                 completionHandler:^(NSData *data, NSHTTPURLResponse *response) {
                                                     
                                                     if (completionBlock)
                                                     {
                                                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                                                             
                                                             NSXMLDocument *document = [operation XMLDocumentFromData:data];
                                                             
                                                             dispatch_async(gc_dispatch_queue(queue), ^{completionBlock(document, response);});
                                                         });
                                                     }
                                                     
                                                 } errorHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
                                                     
                                                     if (errorBlock)
                                                     {
                                                         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
                                                             
                                                             NSXMLDocument *document = [operation XMLDocumentFromData:data];
                                                             
                                                             dispatch_async(gc_dispatch_queue(queue), ^{errorBlock(document, response, [operation error]);});
                                                         });
                                                     }
                                                 }];
    return operation;
}

- (NSXMLDocument *)XMLDocumentFromData:(NSData *)data
{
    NSXMLDocument *document = nil;
    
    if (data)
    {
        NSError *error = nil;
        document = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
        
        if (!document)
        {
            [self setError:error];
        }
    }
    return document;
}
#endif

- (NSError *)error
{
    if (self->_XMLError)
    {
        return self->_XMLError;
    }
    else
    {
        return [super error];
    }
}

@end
