//
//  GCXMLRequestOperation.m
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 16/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

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
