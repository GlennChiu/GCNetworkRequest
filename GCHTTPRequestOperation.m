//
//  GCHTTPRequestOperation.m
//  GCNetworkRequest
//
//  Created by Glenn Chiu on 05/09/2012.
//  Copyright (c) 2012 Glenn Chiu. All rights reserved.
//

#import "GCHTTPRequestOperation.h"
#import "GCNetworkRequest.h"

#if ! __has_feature(objc_arc)
#error GCNetworkRequest is ARC only. Use -fobjc-arc as compiler flag for this library
#endif

enum
{
    GCOperationStateReady           = 1 << 1,
    GCOperationStateExecuting       = 1 << 2,
    GCOperationStateFinished        = 1 << 3
};
typedef signed char GCOperationState;

const struct _userinfo_keys _userinfo_keys = {
    .userinfo_key = @"userinfo_key",
    .keys = {
        .username = @"username",
        .password = @"password"
    }
};

extern inline dispatch_queue_t gc_dispatch_queue(dispatch_queue_t queue)
{
    return queue ?: dispatch_get_main_queue();
}

@interface GCHTTPRequestOperation ()

@end

@implementation GCHTTPRequestOperation
{
    NSHTTPURLResponse *_response;
    NSString *_username, *_password;
    NSURLConnection *_connection;
    NSURLRequest *_request;
    NSOutputStream *_oStream;
    NSDictionary *_userInfo;
    
#if TARGET_OS_IPHONE
    UIBackgroundTaskIdentifier _bgTaskIdentifier;
#endif
    
    BOOL _isExecuting, _isFinished, _isReady, _isCancelled;
    
    dispatch_queue_t _con_queue, _dispatch_queue;
    dispatch_semaphore_t _cancel_lock, _bg_lock;
    
    GCOperationState _operationState;
    
    void(^_completion_block)(NSData *data, NSHTTPURLResponse *response);
    void(^_error_block)(NSData *data, NSHTTPURLResponse *response, NSError *error);
    void(^_downloadProgressBlock)(NSUInteger bytesRead, NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead);
    void(^_uploadProgressBlock)(NSUInteger bytesWritten, NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite);
}

+ (id)HTTPRequest:(GCNetworkRequest *)networkRequest callBackQueue:(dispatch_queue_t)queue completionHandler:(void(^)(NSData *data, NSHTTPURLResponse *response))completionBlock errorHandler:(void(^)(NSData *data, NSHTTPURLResponse *response, NSError *error))errorBlock
{
    return [[self alloc] initWithHTTPRequest:networkRequest callBackQueue:queue completionHandler:completionBlock errorHandler:errorBlock];
}

- (id)initWithHTTPRequest:(GCNetworkRequest *)networkRequest callBackQueue:(dispatch_queue_t)queue completionHandler:(void(^)(NSData *data, NSHTTPURLResponse *response))completionBlock errorHandler:(void(^)(NSData *data, NSHTTPURLResponse *response, NSError *error))errorBlock
{
    self = [super init];
    if (self)
    {
        assert([[[[networkRequest URL] scheme] lowercaseString] isEqual:@"http"] || [[[[networkRequest URL] scheme] lowercaseString] isEqual:@"https"]);
        
        self->_request = networkRequest;
        self->_userInfo = [NSURLProtocol propertyForKey:_userinfo_keys.userinfo_key inRequest:networkRequest];
        [NSURLProtocol removePropertyForKey:_userinfo_keys.userinfo_key inRequest:networkRequest];
        
        self->_completion_block = [completionBlock copy];
        self->_error_block = [errorBlock copy];
        
        self->_con_queue = dispatch_queue_create("com.gcnetworkrequest.httpoperation.queue", DISPATCH_QUEUE_CONCURRENT);
        self->_cancel_lock = dispatch_semaphore_create(1);
        self->_bg_lock = dispatch_semaphore_create(1);
        
        self->_oStream = [[NSOutputStream alloc] initToMemory];
        
        [self setCallbackQueue:queue];
        
        self->_operationState = GCOperationStateReady;
    }
    return self;
}

- (void)dealloc
{
    GC_DISPATCH_RELEASE(self->_con_queue);
    GC_DISPATCH_RELEASE(self->_cancel_lock);
    GC_DISPATCH_RELEASE(self->_bg_lock);
}

+ (void)threadMain
{
    do
    {
        @autoreleasepool
        {
            [[NSRunLoop currentRunLoop] run];
        }
    }
    while (![[NSThread currentThread] isCancelled]);
}

+ (NSThread *)workerThread
{
    static NSThread *workerThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        if (!workerThread)
        {
            workerThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
            [workerThread start];
        }
    });
    return workerThread;
}

- (void)startRequest
{
    [self start];
}

- (void)cancelRequest
{
    [self cancel];
}

- (BOOL)isReadyForExecution
{
    if ([self isCancelled] || ![self isReady])
    {
        [self finish];
        return NO;
    }
    return YES;
}

- (void)start
{
    if (![self isReadyForExecution]) return;
    
    self.operationState = GCOperationStateExecuting;
    
    [self performSelector:@selector(scheduleObjectsInRunLoop) onThread:[[self class] workerThread] withObject:nil waitUntilDone:NO];
    
    [self registerBackgroundTask];
}

- (void)scheduleObjectsInRunLoop
{
    self->_connection = [[NSURLConnection alloc] initWithRequest:self->_request delegate:self startImmediately:NO];
    [self->_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self->_connection start];
    
    [self->_oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)finish
{
    [self endBackgroundTask];
    
    [self cleanupStream:self->_oStream];
    
    NSThread *workerThread = [[self class] workerThread];
    if (![workerThread isCancelled]) [workerThread cancel];
    
    self.operationState = GCOperationStateFinished;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isReady
{
    return GCOperationStateReady == self.operationState;
}

- (BOOL)isExecuting
{
    return GCOperationStateExecuting == self.operationState;
}

- (BOOL)isFinished
{
    return GCOperationStateFinished == self.operationState;
}

- (void)cancel
{
    dispatch_semaphore_wait(self->_cancel_lock, DISPATCH_TIME_FOREVER);
    
    if (![self isCancelled])
    {
        [self willChangeValueForKey:@"isCancelled"];
        self->_isCancelled = YES;
        [self didChangeValueForKey:@"isCancelled"];
        
        [self performSelector:@selector(cancelConnection) onThread:[[self class] workerThread] withObject:nil waitUntilDone:NO];
    }
    
    dispatch_semaphore_signal(self->_cancel_lock);
}

- (void)cancelConnection
{
    if (self->_connection) [self->_connection cancel];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[self->_request URL] forKey:NSURLErrorFailingURLErrorKey];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    [self performSelector:@selector(connection:didFailWithError:) withObject:self->_connection withObject:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) return;
    
    self->_response = (NSHTTPURLResponse *)response;
    
    [self->_oStream open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([self->_oStream hasSpaceAvailable])
    {
        const uint8_t *buffer = (uint8_t *)[data bytes];
        [self->_oStream write:&buffer[0] maxLength:[data length]];
    }
    
    if (self->_downloadProgressBlock)
    {
        static uint64_t byteCount = (uint64_t)0;
        byteCount += [data length];
        dispatch_block_t block = ^{self->_downloadProgressBlock((NSUInteger)[data length], (NSUInteger)byteCount, (NSUInteger)self->_response.expectedContentLength);};
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSData *responseData = [self->_oStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [self cleanupStream:self->_oStream];
    
    if (self->_completion_block)
    {
        dispatch_block_t block = ^{self->_completion_block(responseData, self->_response);};
        [self performCallBackQueue:block];
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSData *responseData = [self->_oStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    [self cleanupStream:self->_oStream];
    
    [self setError:error];
    
    if (self->_error_block)
    {
        dispatch_block_t block = ^{self->_error_block(responseData, self->_response, [self error]);};
        [self performCallBackQueue:block];
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if (self->_uploadProgressBlock)
    {
        dispatch_block_t block = ^{self->_uploadProgressBlock((NSUInteger)bytesWritten, (NSUInteger)totalBytesWritten, (NSUInteger)totalBytesExpectedToWrite);};
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust] && [challenge previousFailureCount] == 0 && [challenge proposedCredential] == nil)
    {
        if ([self allowUntrustedServerCertificate])
        {
            [[challenge sender] useCredential:[NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]] forAuthenticationChallenge:challenge];
        }
        else
        {
            [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
        }
    }
    else
    {
        if ([[self username] length] > 0)
        {
            if ([challenge previousFailureCount] == 0)
            {
                NSURLCredential *newCredential = [NSURLCredential credentialWithUser:[self username]
                                                                            password:[self password]
                                                                         persistence:NSURLCredentialPersistenceForSession];
                [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
            }
            else
            {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
                
                NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
                [errorUserInfo setValue:@"Authentication error" forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:[@"com." stringByAppendingString:NSStringFromClass([self class])]
                                                     code:401
                                                 userInfo:errorUserInfo];
                GCNRLog(@"Error: %@", [error userInfo]);
            }
        }
        else
        {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    NSCachedURLResponse *newCachedResponse = cachedResponse;
    
    if ([self forceReloadConnection])
    {
        newCachedResponse = nil;
    }
    else
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSDate date] forKey:@"Cached Date"];
        newCachedResponse = [[NSCachedURLResponse alloc] initWithResponse:[cachedResponse response]
                                                                     data:[cachedResponse data]
                                                                 userInfo:userInfo
                                                            storagePolicy:[cachedResponse storagePolicy]];
    }
    return newCachedResponse;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    if ([self rejectRedirect])
    {
        return nil;
    }
    else if (response)
    {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        mutableRequest.URL = request.URL;
        return mutableRequest;
    }
    else
    {
        return request;
    }
}

- (void)endBackgroundTask
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] endBackgroundTask:self->_bgTaskIdentifier];
    self->_bgTaskIdentifier = UIBackgroundTaskInvalid;
#endif
}

- (void)registerBackgroundTask
{
#if TARGET_OS_IPHONE
    if (self->_bgTaskIdentifier != UIBackgroundTaskInvalid)
    {
        dispatch_block_t block = ^{[self endBackgroundTask];};
        self->_bgTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:block];
    }
#endif
}

#if TARGET_OS_IPHONE
- (void)endBackgroundTaskWithCompletionHandler:(void(^)(void))block
{
    dispatch_semaphore_wait(self->_bg_lock, DISPATCH_TIME_FOREVER);
    
    dispatch_block_t endBlock = ^{
        
        if (block) block();
        
        [self cancel];
        
        [self endBackgroundTask];
    };
    
    self->_bgTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:endBlock];
    
    dispatch_semaphore_signal(self->_bg_lock);
}
#endif

- (void)downloadProgressHandler:(void(^)(NSUInteger bytesRead, NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead))block
{
    self->_downloadProgressBlock = [block copy];
}

- (void)uploadProgressHandler:(void(^)(NSUInteger bytesWritten, NSUInteger totalBytesWritten, NSUInteger totalBytesExpectedToWrite))block
{
    self->_uploadProgressBlock = [block copy];
}

- (void)cleanupStream:(NSStream *)stream
{
    assert(stream);
    
    [stream close];
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    stream = nil;
}

- (NSInputStream *)inputStream
{
    return self->_request.HTTPBodyStream;
}

- (void)setInputStream:(NSInputStream *)stream
{
    NSMutableURLRequest *mutableRequest = [self->_request mutableCopy];
    mutableRequest.HTTPBodyStream = stream;
    self->_request = mutableRequest;
}

- (void)setCallbackQueue:(dispatch_queue_t)queue
{
    self->_dispatch_queue = gc_dispatch_queue(queue);
    GC_DISPATCH_RETAIN(self->_dispatch_queue);
}

- (void)performCallBackQueue:(dispatch_block_t)block
{
    assert(self->_dispatch_queue);
    
    dispatch_async(self->_dispatch_queue, block);
    GC_DISPATCH_RELEASE(self->_dispatch_queue);
}

- (NSString *)username
{
    return self->_username ?: (self->_username = [self->_userInfo objectForKey:_userinfo_keys.keys.username]);
}

- (NSString *)password
{
    return self->_password ?: (self->_password = [self->_userInfo objectForKey:_userinfo_keys.keys.password]);
}

- (GCOperationState)operationState
{
    __block GCOperationState state = (GCOperationState)0;
    dispatch_block_t block = ^{state = self->_operationState;};
    dispatch_sync(self->_con_queue, block);
    return state;
}

- (void)setOperationState:(GCOperationState)operationState
{
    dispatch_barrier_async(self->_con_queue, ^{
        
        assert(operationState > self->_operationState);
        
        switch (operationState)
        {
            case GCOperationStateReady:
                [self willChangeValueForKey:@"isReady"];
                break;
            case GCOperationStateExecuting:
                [self willChangeValueForKey:@"isExecuting"];
                [self willChangeValueForKey:@"isReady"];
                break;
            case GCOperationStateFinished:
                [self willChangeValueForKey:@"isFinished"];
                [self willChangeValueForKey:@"isExecuting"];
                break;
        }
        
        self->_operationState = operationState;
        
        switch (operationState)
        {
            case GCOperationStateReady:
                [self didChangeValueForKey:@"isReady"];
                break;
            case GCOperationStateExecuting:
                [self didChangeValueForKey:@"isReady"];
                [self didChangeValueForKey:@"isExecuting"];
                break;
            case GCOperationStateFinished:
                [self didChangeValueForKey:@"isExecuting"];
                [self didChangeValueForKey:@"isFinished"];
                break;
        }
    });
}

@end
