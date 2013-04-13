GCNetworkRequest
================

An easy-to-use asynchronous HTTP networking library for iOS and OS X.

Features / Design
-----------------

* Fully concurrent / multithreaded design. Easy to apply in your own multithreaded environment.
* High performance. Modern libdispatch support for fast semaphores and reader/writer locks.
* Very easy-to-use API, even for developers who are new to HTTP networking or are unfamiliar with Cocoa's networking classes.
* Modular architecture. Easy to expand.

Requirements
------------

GCNetworkRequest requires iOS 5.0 and above or OS X 10.7 and above. It also requires Xcode 4.5 and above and LLVM Compiler 4.1.

Installation
------------

Clone the repository and add the files you need to your Xcode project. Check if the files show up in the 'compile sources' section of your target. Otherwise, assign the target to the files manually.

If you use the library in a non-ARC project, make sure you add the `-fobjc-arc` compiler flag for all implementation files.

This library was designed to be modular. The minimum required classes you need, in order to use this library properly, are `GCHTTPRequestOperation` and `GCNetworkRequest`.

When you have added the `GCNetworkReachability` class, you need to link your target against the `SystemConfiguration.framework`.

Classes
-------

| Network Operation | |
| :--- | :--- |
| [GCHTTPRequestOperation](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCHTTPRequestOperation.h) | Base class for network operations with completion and error handler blocks. |
| [GCJSONRequestOperaton](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCJSONRequestOperation.h) | A subclass of `GCHTTPRequestOperation` which downloads and parses JSON response data. |
| [GCXMLRequestOperation](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCXMLRequestOperation.h) | A subclass of `GCHTTPRequestOperation` which downloads XML response data. It uses NSXMLParser output for iOS or NSXMLDocument output for OS X via seperate methods. |
| [GCImageRequestOperation](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCImageRequestOperation.h) | A subclass of `GCHTTPRequestOperation` which downloads images. |
| **Network Request** | |
| [GCNetworkRequest](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCNetworkRequest.h) | Encapsulates an `NSMutableURLRequest` and adds simple-to-use methods for uploading data and user authentication. This class is needed as parameter for `GCHTTPRequestOperation` and its subclasses. |
| **Network Queue** | |
| [GCNetworkQueue](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCNetworkQueue.h) | A subclass of `NSOperationQueue`. This class makes it easy to use concurrency. It also activates the network indicator in the status bar. |
| **Network Reachability** | |
| [GCNetworkReachability](https://github.com/GlennChiu/GCNetworkRequest/blob/master/GCNetworkReachability.h)| This class allows an application to monitor the network state. It can check whether an internet connection is available and if so, report whether the device is on WiFi or WWAN connection (3G, Edge). |

Usage
-----

#### JSON Request

The **callbackQueue** parameter determines in which GCD queue the completion and error handlers gets called. When you pass in `nil` or `NULL` the block will be called on the main thread. When you want to perform a long task in the completion handler, it's better to insert a concurrent dispatch queue. This way it won't block the main thread and it keeps the app responsive.

If your application syncs data with a web-service, it's highly likely that it involves several serial HTTP requests. The API was designed to be inserted inline into a (private) GCD queue or added on a `NSOperationQueue`.

```objectivec
GCNetworkRequest *request = [GCNetworkRequest requestWithURLString:@"http://maps.googleapis.com/maps/api/geocode/json?address=Amsterdam,+Nederland&sensor=true"];
        
GCJSONRequestOperation *operation = [GCJSONRequestOperation JSONRequest:request
                                						  callBackQueue:nil
                              			      		  completionHandler:^(id JSON, NSHTTPURLResponse *response) {                              			      		  
                                  			  			  /* Do something with 'JSON'..
                                  			  			     Response status code: response.statusCode */		                     
                              			      		  } errorHandler:^(id JSON, NSHTTPURLResponse *response, NSError *error) {
                                  		 	 			  /* Do something with 'error'.. 
                                  	 		   			   	 If you get a JSON response as error, log the output of 'JSON' */                               
                              			      		  }];
[operation startRequest];
```
#### File Upload

File upload is done using multipart/form-data POST requests. The data can be added to the body by using the `multiPartFormDataHandler` block. It contains a `formData` object which allows you to add and specify the data needed for upload.

```objectivec
NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"thumbnail.png"]);

GCNetworkRequest *request = [GCNetworkRequest requestWithURLString:@"http://www.someurl.com/upload"
                                                        parameters:nil
                                          multiPartFormDataHandler:^(id <GCMultiPartFormData> formData) {
                                              
                                              [formData addData:imageData name:@"thumbnail" filename:@"thumbnail.png" mimeType:@"image/png"];
                                          }];

GCHTTPRequestOperation *operation = [GCHTTPRequestOperation HTTPRequest:request callBackQueue:nil completionHandler:nil errorHandler:nil];
[operation startRequest];
```

#### Cancel Network Request

A network request can be cancelled at any time.

```objectivec
[operation cancelRequest];
```
#### Track Download Progress

```objectivec
[operation downloadProgressHandler:^(NSUInteger bytesRead, NSUInteger totalBytesRead, NSUInteger totalBytesExpectedToRead) {
	// This handler gets a continuous callback and the parameters can be used to track the progress 
}];
```
#### HTTP Pipelining

HTTP pipelining is a technique in which multiple HTTP requests are sent on a single TCP connection without waiting for the corresponding responses. If your web server supports this, you can enable it via this method.
GET and HEAD requests are always pipelined. Please note that POST requests should not be pipelined.

```objectivec
[request requestShouldUseHTTPPipelining:YES];
```
#### Start Network Operation

There are two ways in which you can start a network operation. For a single operation you can call the `-startRequest:` method. If you have multiple operation scheduled, then you can use the `GCNetworkQueue` class to add operations on a single queue. A network queue allows you to control the maximum amount of concurrent connections.

#### Network Reachability

The `GCNetworkReachability` class allows you to monitor the network state of a device. More information can be found  [here](https://github.com/GlennChiu/GCNetworkReachability/blob/master/README.md).

License
-------

This code is distributed under the terms and conditions of the MIT license.

Copyright (c) 2013 Glenn Chiu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.