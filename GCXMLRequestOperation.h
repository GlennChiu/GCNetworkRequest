//
//  GCXMLRequestOperation.h
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 16/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

#import "GCHTTPRequestOperation.h"

@interface GCXMLRequestOperation : GCHTTPRequestOperation

#if TARGET_OS_IPHONE
+ (id)XMLParserRequest:(GCNetworkRequest *)networkRequest
         callBackQueue:(dispatch_queue_t)queue
     completionHandler:(void(^)(NSXMLParser *parser, NSHTTPURLResponse *response))completionBlock
          errorHandler:(void(^)(NSXMLParser *parser, NSHTTPURLResponse *response, NSError *error))errorBlock;
#endif

#if __MAC_OS_X_VERSION_MIN_REQUIRED
+ (id)XMLDocumentRequest:(GCNetworkRequest *)networkRequest
           callBackQueue:(dispatch_queue_t)queue
       completionHandler:(void(^)(NSXMLDocument *document, NSHTTPURLResponse *response))completionBlock
            errorHandler:(void(^)(NSXMLDocument *document, NSHTTPURLResponse *response, NSError *error))errorBlock;
#endif

@end
