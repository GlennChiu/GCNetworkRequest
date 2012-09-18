//
//  GCJSONRequestOperation.h
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 14/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

#import "GCHTTPRequestOperation.h"

@class GCNetworkRequest;

@interface GCJSONRequestOperation : GCHTTPRequestOperation

+ (id)JSONRequest:(GCNetworkRequest *)networkRequest
    callBackQueue:(dispatch_queue_t)queue
completionHandler:(void(^)(id JSON, NSHTTPURLResponse *response))completionBlock
     errorHandler:(void(^)(id JSON, NSHTTPURLResponse *response, NSError *error))errorBlock;

@end
