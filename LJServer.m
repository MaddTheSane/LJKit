/*
 LJKit: an Objective-C implementation of the LiveJournal client protocol
 Copyright (C) 2002-2003  Benjamin Peter Ragheb

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 You may contact the author via email at benzado@livejournal.com.
 */

/*
 2004-01-09 [BPR] 	Removed proxyURL and setProxyURL:.
 					Added proxy detection and reachability stuff.
 2004-01-10 [BPR]	Added account reference.  Moved exception code into LJAccount.
 2004-01-12 [BPR]	Used processName to identify self to SystemConfiguration.fmwk
 */

#import "LJServer_Private.h"
#import "LJAccount_Private.h"
#import "Miscellaneous.h"
#import "URLEncoding.h"

NSString * const LJServerReachabilityDidChangeNotification = @"LJServerReachabilityDidChange";

static NSString *				gUserAgent = nil;

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
static unsigned int 			gStoreRefCount = 0;
static SCDynamicStoreRef 		gStore = NULL;
static SCDynamicStoreContext 	gStoreContext;
static CFRunLoopSourceRef 		gRunLoopSource = NULL;
#endif
static CFDictionaryRef			gProxyInfo = NULL;

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
void LJServerStoreCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);
void LJServerReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info);
#endif

@interface LJServer (ClassPrivate)
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
- (void)enableProxyDetection;
- (void)disableProxyDetection;
#endif
- (void)updateRequestTemplate;
@end

@implementation LJServer

+ (void)initialize
{
    if (gUserAgent == nil) {
        NSBundle *myBundle = LJKitBundle;
        gUserAgent = [[NSString alloc] initWithFormat:@"%@/%@ (Mac_PowerPC)",
            [myBundle objectForInfoDictionaryKey:@"CFBundleName"],
            [LJAccount _clientVersionForBundle:myBundle]];
        NSLog(@"LJKit User-Agent: %@", gUserAgent);
    }
}

- (id)initWithURL:(NSURL *)url account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        _account = account; // don't retain (to avoid a cycle)
        [self setURL:url];
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
		[self enableProxyDetection];
#endif
    }
    return self;
}

- (void)dealloc
{
    [_serverURL release];
    [_loginData release];
    if (_requestTemplate) CFRelease(_requestTemplate);
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
    [self disableReachabilityMonitoring];
    [self disableProxyDetection];
#endif
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return [self initWithURL:[decoder decodeObjectForKey:@"LJServerURL"]
                     account:[decoder decodeObjectForKey:@"LJServerAccount"]];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_serverURL forKey:@"LJServerURL"];
    [encoder encodeConditionalObject:_account forKey:@"LJServerAccount"];
}

- (LJAccount *)account
{
    return _account;
}

- (void)setURL:(NSURL *)url
{
    NSAssert([[url scheme] isEqualToString:@"http"], @"URL scheme must be http");
    if (SafeSetObject(&_serverURL, url)) {
        if (_requestTemplate) CFRelease(_requestTemplate);
        _requestTemplate = NULL;
        // If we were monitoring reachability, the target needs to be updated.
        /* disabled for now.  Jag compat. */
#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
		 if (_target != NULL) {
            [self disableReachabilityMonitoring];
            [self enableReachabilityMonitoring];
        }
#endif
    }
}

- (NSURL *)URL
{
    return _serverURL;
}

- (void)setUseFastServers:(BOOL)flag
{
    if (_isUsingFastServers != flag) {
        _isUsingFastServers = flag;
        if (_requestTemplate) CFRelease(_requestTemplate);
        _requestTemplate = NULL;
    }
}

- (BOOL)isUsingFastServers
{
    return _isUsingFastServers;
}

- (void)setLoginInfo:(NSDictionary *)loginDict
{
    [_loginData release];
    _loginData = LJCreateURLEncodedFormData(loginDict);
    [_loginData retain];
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
 - (void)enableProxyDetection
{
    if (gStoreRefCount == 0) {
        CFStringRef proxiesKey;
        CFArrayRef keyArray;
        
        gStore = SCDynamicStoreCreate(kCFAllocatorDefault, 
                                      (CFStringRef)[[NSProcessInfo processInfo] processName], 
                                      LJServerStoreCallback, &gStoreContext);
        proxiesKey = SCDynamicStoreKeyCreateProxies(kCFAllocatorDefault);
        keyArray = CFArrayCreate(kCFAllocatorDefault, (const void * *)&proxiesKey, 1, NULL);
        SCDynamicStoreSetNotificationKeys(gStore, keyArray, NULL);
        CFRelease(keyArray);
        CFRelease(proxiesKey);
        gRunLoopSource = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, gStore, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), gRunLoopSource, kCFRunLoopDefaultMode);
        // The callback won't be called unless the proxy *changes*, so we make an initial copy here.
        gProxyInfo = SCDynamicStoreCopyProxies(gStore);
    }
    gStoreRefCount++;
}

- (void)disableProxyDetection
{
    gStoreRefCount--;
    if (gStoreRefCount == 0) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), gRunLoopSource, kCFRunLoopDefaultMode);
        CFRelease(gRunLoopSource); gRunLoopSource = NULL;
        CFRelease(gStore); gStore = NULL;
        if (gProxyInfo) CFRelease(gProxyInfo); gProxyInfo = NULL;
    }
}

- (void)enableReachabilityMonitoring
{
    if (_target == NULL) {
        _reachContext.info = self;
        _target = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [[[self url] host] UTF8String]);
        SCNetworkReachabilitySetCallback(_target, LJServerReachabilityCallback, &_reachContext);
        SCNetworkReachabilityScheduleWithRunLoop(_target, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void)disableReachabilityMonitoring
{
    if (_target != NULL) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_target, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(_target);
        _target = NULL;
    }
}
#endif

- (BOOL)getReachability:(SCNetworkConnectionFlags *)flags
{
    NSAssert(flags != NULL, @"Flags must not be NULL.");
    return SCNetworkCheckReachabilityByName([[[self URL] host] UTF8String], flags);
}

- (void)updateRequestTemplate
{
    CFURLRef url;

    url = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("/interface/flat"),
                                (CFURLRef)_serverURL);
    if (_requestTemplate) CFRelease(_requestTemplate);
    _requestTemplate = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
                                                  CFSTR("POST"), url,
                                                  kCFHTTPVersion1_0);
    //NSLog(@"_requestTemplate RC = %d", CFGetRetainCount(_requestTemplate));
    CFRetain(_requestTemplate);
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Host"),
                                     (CFStringRef)[_serverURL host]);
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Content-Type"),
                                     CFSTR("application/x-www-form-urlencoded"));
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("User-Agent"),
                                     (CFStringRef)gUserAgent);
    if (_isUsingFastServers) {
        CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Set-Cookie"),
                                         CFSTR("ljfastservers=1"));
    }
    CFRelease(url);
}

- (NSDictionary *)getReplyForMode:(NSString *)mode parameters:(NSDictionary *)parameters
{
    CFHTTPMessageRef request, response;
    CFIndex bytesRead;
    CFReadStreamRef stream;
    NSDictionary *replyDictionary = nil;
    NSMutableData *contentData;
    NSString *tmpString;
    UInt32 statusCode;
    UInt8 bytes[64];

    // Compile HTTP POST variables into a data object.
    contentData = [NSMutableData data];
    tmpString = [NSString stringWithFormat:@"mode=%@", mode];
    [contentData appendData:[tmpString dataUsingEncoding:NSUTF8StringEncoding]];
    if (_loginData) [contentData appendData:_loginData];
    if (parameters) [contentData appendData:LJCreateURLEncodedFormData(parameters)];

    // Copy the template HTTP message and set the data and content length.
    if (_requestTemplate == NULL) [self updateRequestTemplate];
    request = CFHTTPMessageCreateCopy(kCFAllocatorDefault, _requestTemplate);
    CFHTTPMessageSetBody(request, (CFDataRef)contentData);
    tmpString = [NSString stringWithFormat:@"%u", [contentData length]];
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Content-Length"), (CFStringRef)tmpString);
    
    // Connect to the server.
    stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    if (gProxyInfo) {
        CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPProxy, gProxyInfo);
    }
    CFReadStreamOpen(stream);
    
    // Build an HTTP response from the data read.
    response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    while (bytesRead = CFReadStreamRead(stream, bytes, 64)) {
        if (bytesRead == -1) {
            CFStreamError err = CFReadStreamGetError(stream);
            [[_account _exceptionWithFormat:@"LJStreamError_%d_%d", err.domain, err.error] raise];
        } else if (!CFHTTPMessageAppendBytes(response, bytes, bytesRead)) {
            CFReadStreamClose(stream);
            [[_account _exceptionWithName:@"LJHTTPParseError"] raise];
        }
    }
    statusCode = CFHTTPMessageGetResponseStatusCode(response);
    if (statusCode == 200) {
        CFDataRef responseData = CFHTTPMessageCopyBody(response);
        replyDictionary = ParseLJReplyData((NSData *)responseData);
        if (responseData) CFRelease(responseData);
    } else {
        [[_account _exceptionWithFormat:@"LJHTTPStatusError_%d", statusCode] raise];
    }
    if (stream) CFRelease(stream);
    if (response) CFRelease(response);
    if (request) CFRelease(request);
    return replyDictionary;
}

@end

void LJServerStoreCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info)
{
    // We're only monitoring one key, so it's a safe bet we can ignore the changedKeys parameter.
    if (gProxyInfo) CFRelease(gProxyInfo);
    gProxyInfo = SCDynamicStoreCopyProxies(store);
}

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_3
void LJServerReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
    NSDictionary *userInfo;
    NSNotificationCenter *center;

    userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:flags]
                                           forKey:@"ConnectionFlags"];
    center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:LJServerReachabilityDidChangeNotification
                          object:(LJServer *)info
                        userInfo:userInfo];
    [userInfo release];
}
#endif