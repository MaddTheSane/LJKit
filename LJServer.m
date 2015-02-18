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

#ifdef ENABLE_REACHABILITY_MONITORING
NSString * const LJServerReachabilityDidChangeNotification = @"LJServerReachabilityDidChange";
#endif

static NSString *				gUserAgent = nil;

// Globals Required for Proxy Detection
static CFIndex					gStoreRefCount = 0;
static SCDynamicStoreRef 		gStore = NULL;
static SCDynamicStoreContext 	gStoreContext;
static CFRunLoopSourceRef 		gRunLoopSource = NULL;
static NSDictionary				*gProxyInfo = NULL;

static void LJServerStoreCallback(SCDynamicStoreRef store, CFArrayRef changedKeys, void *info);

#ifdef ENABLE_REACHABILITY_MONITORING
static void LJServerReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info);
#endif

@interface LJServer ()
- (void)enableProxyDetection;
- (void)disableProxyDetection;
- (void)updateRequestTemplate;
@end

@implementation LJServer
{
@private
	NSData *_loginData;
#ifdef ENABLE_REACHABILITY_MONITORING
	SCNetworkReachabilityContext _reachContext;
	SCNetworkReachabilityRef _target;
#endif
	CFHTTPMessageRef _requestTemplate;

}
@synthesize URL = _serverURL;
@synthesize useFastServers = _isUsingFastServers;

+ (void)initialize
{
    if (gUserAgent == nil) {
        NSBundle *myBundle = LJKitBundle;
        gUserAgent = [[NSString alloc] initWithFormat:@"%@/%@ (Mac_x86-64)",
            [myBundle objectForInfoDictionaryKey:@"CFBundleName"],
            [LJAccount _clientVersionForBundle:myBundle]];
        NSLog(@"LJKit User-Agent: %@", gUserAgent);
    }
}

- (instancetype)initWithURL:(NSURL *)url account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        _account = account; // don't retain (to avoid a cycle)
        [self setURL:url];
		[self enableProxyDetection];
    }
    return self;
}

- (void)dealloc
{
    if (_requestTemplate) CFRelease(_requestTemplate);
#ifdef ENABLE_REACHABILITY_MONITORING
    [self disableReachabilityMonitoring];
#endif
    [self disableProxyDetection];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    return [self initWithURL:[decoder decodeObjectForKey:@"LJServerURL"]
                     account:[decoder decodeObjectForKey:@"LJServerAccount"]];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_serverURL forKey:@"LJServerURL"];
    [encoder encodeConditionalObject:_account forKey:@"LJServerAccount"];
}

- (void)setURL:(NSURL *)url
{
    NSAssert([[url scheme] isEqualToString:@"http"], @"URL scheme must be http");
    
    if (![_serverURL isEqual:url]) {
		_serverURL = url;
        if (_requestTemplate) CFRelease(_requestTemplate);
        _requestTemplate = NULL;
#ifdef ENABLE_REACHABILITY_MONITORING
        // If we were monitoring reachability, the target needs to be updated.
        if (_target != NULL) {
            [self disableReachabilityMonitoring];
            [self enableReachabilityMonitoring];
        }
#endif
    }
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
    if (loginDict != nil) {
        _loginData = LJCreateURLEncodedFormData(loginDict);
    } else {
        _loginData = nil;
    }
}

 - (void)enableProxyDetection
{
    if (gStoreRefCount == 0) {
        gStore = SCDynamicStoreCreate(kCFAllocatorDefault,
                                      (__bridge CFStringRef)[[NSProcessInfo processInfo] processName], 
                                      LJServerStoreCallback, &gStoreContext);
        NSString *proxiesKey = CFBridgingRelease(SCDynamicStoreKeyCreateProxies(kCFAllocatorDefault));
        NSArray *keyArray = @[proxiesKey];
        SCDynamicStoreSetNotificationKeys(gStore, (__bridge CFArrayRef)(keyArray), NULL);
        gRunLoopSource = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, gStore, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), gRunLoopSource, kCFRunLoopDefaultMode);
        // The callback won't be called unless the proxy *changes*, so we make an initial copy here.
        gProxyInfo = CFBridgingRelease(SCDynamicStoreCopyProxies(gStore));
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
        gProxyInfo = nil;
    }
}

#ifdef ENABLE_REACHABILITY_MONITORING
- (void)enableReachabilityMonitoring
{
    if (_target == NULL) {
        _reachContext.info = (__bridge void *)(self);
        _target = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [[[self URL] host] UTF8String]);
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
	SCNetworkReachabilityRef	target;
	
	target = SCNetworkReachabilityCreateWithName(NULL, [[[self URL] host] UTF8String]);
	Boolean ok = SCNetworkReachabilityGetFlags(target, flags);
	CFRelease(target);

    return ok;
}

- (void)updateRequestTemplate
{
    NSURL *url = [NSURL URLWithString:@"/interface/flat" relativeToURL:_serverURL];

    if (_requestTemplate) CFRelease(_requestTemplate);
    _requestTemplate = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
                                                  CFSTR("POST"), (__bridge CFURLRef)(url),
                                                  kCFHTTPVersion1_0);
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Host"),
                                     (__bridge CFStringRef)[_serverURL host]);
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Content-Type"),
                                     CFSTR("application/x-www-form-urlencoded"));
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("User-Agent"),
                                     (__bridge CFStringRef)gUserAgent);
    if (_isUsingFastServers) {
        CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Set-Cookie"),
                                         CFSTR("ljfastservers=1"));
    }
}


#define STREAM_BUFFER_SIZE 256

- (NSDictionary *)getReplyForMode:(NSString *)mode parameters:(NSDictionary *)parameters
{
    CFIndex bytesRead;
    NSDictionary *replyDictionary = nil;
    NSMutableData *contentData;
    UInt8 bytes[STREAM_BUFFER_SIZE];

    // Compile HTTP POST variables into a data object.
    contentData = [[NSMutableData alloc] init];
    NSString *tmpString = [NSString stringWithFormat:@"mode=%@", mode];
    [contentData appendData:[tmpString dataUsingEncoding:NSUTF8StringEncoding]];
    if (_loginData) [contentData appendData:_loginData];
    if (parameters) [contentData appendData:LJCreateURLEncodedFormData(parameters)];

    // Copy the template HTTP message and set the data and content length.
    if (_requestTemplate == NULL) [self updateRequestTemplate];
    CFHTTPMessageRef request = CFHTTPMessageCreateCopy(kCFAllocatorDefault, _requestTemplate);
    CFHTTPMessageSetBody(request, (__bridge CFDataRef)contentData);
    tmpString = [NSString stringWithFormat:@"%lu", (unsigned long)[contentData length]];
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Content-Length"), (__bridge CFStringRef)tmpString);
    
	// Connect to the server.
	CFReadStreamRef stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
	if (gProxyInfo) {
		CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPProxy, (__bridge CFTypeRef)(gProxyInfo));
	}
	CFReadStreamOpen(stream);
	
	// Build an HTTP response from the data read.
	CFHTTPMessageRef response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
	while ((bytesRead = CFReadStreamRead(stream, bytes, STREAM_BUFFER_SIZE))) {
		if (bytesRead == -1) {
			CFStreamError err = CFReadStreamGetError(stream);
			[[_account _exceptionWithFormat:@"LJStreamError_%d_%d", err.domain, err.error] raise];
		} else if (!CFHTTPMessageAppendBytes(response, bytes, bytesRead)) {
			CFReadStreamClose(stream);
			[[_account _exceptionWithName:@"LJHTTPParseError"] raise];
		}
	}
	CFIndex statusCode = CFHTTPMessageGetResponseStatusCode(response);
	if (statusCode == 200) {
		NSData *responseData = CFBridgingRelease(CFHTTPMessageCopyBody(response));
		replyDictionary = ParseLJReplyData(responseData);
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
    gProxyInfo = CFBridgingRelease(SCDynamicStoreCopyProxies(store));
}

#ifdef ENABLE_REACHABILITY_MONITORING
void LJServerReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void *info)
{
    NSNotificationCenter *center;

    NSDictionary *userInfo = @{@"ConnectionFlags": @(flags)};
    center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:LJServerReachabilityDidChangeNotification
                          object:(__bridge LJServer *)info
                        userInfo:userInfo];
}
#endif
