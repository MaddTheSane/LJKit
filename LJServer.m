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

#import "LJServer.h"
#import "Miscellaneous.h"
#import "URLEncoding.h"
#import "LJAccount.h"

static NSString *LJUserAgent = nil;

@implementation LJServer

+ (void)initialize
{
    if (LJUserAgent == nil) {
        NSBundle *myBundle = LJKitBundle;
        LJUserAgent = [[NSString alloc] initWithFormat:@"%@/%@ (Mac_PowerPC)",
            [myBundle objectForInfoDictionaryKey:@"CFBundleName"],
            [LJAccount _clientVersionForBundle:myBundle]];
        NSLog(@"LJKit User-Agent: %@", LJUserAgent);
    }
}

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        [self setURL:url];
    }
    return self;
}

- (id)init
{
    return [self initWithURL:[NSURL URLWithString:@"http://www.livejournal.com/"]];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [self initWithURL:[decoder decodeObjectForKey:@"LJServerURL"]];
    if (self) {
        _proxyURL = [decoder decodeObjectForKey:@"LJServerProxyURL"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_serverURL forKey:@"LJServerURL"];
    [encoder encodeObject:_proxyURL forKey:@"LJServerProxyURL"];
}

- (void)dealloc
{
    [_serverURL release];
    [_proxyURL release];
    [_loginData release];
    if (_requestTemplate) CFRelease(_requestTemplate);
    [super dealloc];
}

- (void)setURL:(NSURL *)url
{
    NSAssert([[url scheme] isEqualToString:@"http"], @"URL scheme must be http");
    if (SafeSetObject(&_serverURL, url)) {
        _templateNeedsUpdate = YES;
    }
}

- (NSURL *)url
{
    return _serverURL;
}

- (void)setProxyURL:(NSURL *)url
{
    // nil to disable proxy
    if (SafeSetObject(&_proxyURL, url)) {
        _templateNeedsUpdate = YES;
    }
}

- (NSURL *)proxyURL
{
    return _proxyURL;
}

- (void)setUseFastServers:(BOOL)flag
{
    if (_isUsingFastServers != flag) {
        _isUsingFastServers = flag;
        _templateNeedsUpdate = YES;
    }
}

- (BOOL)isUsingFastServers
{
    return _isUsingFastServers;
}

- (void)setLoginInfo:(NSDictionary *)loginDict
{
    [_loginData release];
    _loginData = CreateURLEncodedFormData(loginDict);
    [_loginData retain];
}

- (void)updateRequestTemplate
{
    CFURLRef url;

    url = CFURLCreateWithString(kCFAllocatorDefault,
                                CFSTR("/interface/flat"), (CFURLRef)_serverURL);
    if (_requestTemplate) CFRelease(_requestTemplate);
    _requestTemplate = CFHTTPMessageCreateRequest(kCFAllocatorDefault,
                                                  CFSTR("POST"), url,
                                                  kCFHTTPVersion1_0);
    CFRelease(url);
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Host"),
                                     (CFStringRef)[_serverURL host]);
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Content-Type"),
                                     CFSTR("application/x-www-form-urlencoded"));
    CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("User-Agent"),
                                     (CFStringRef)LJUserAgent);
    if (_isUsingFastServers)
        CFHTTPMessageSetHeaderFieldValue(_requestTemplate, CFSTR("Set-Cookie"),
                                         CFSTR("ljfastservers=1"));
    _templateNeedsUpdate = NO;
}

- (void)_raiseExceptionWithNameFormat:(NSString *)format, ...
{
    NSBundle *bundle = LJKitBundle;
    NSString *key, *reason;
    va_list args;

    va_start(args, format);
    key = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
    va_end(args);
    reason = [bundle localizedStringForKey:key value:@"?" table:nil];
    if ([reason isEqualToString:@"?"]) {
        reason = [bundle localizedStringForKey:format value:nil table:nil];
    }
    va_start(args, format);
    [NSException raise:key format:reason arguments:args];
    va_end(args);
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
    if (parameters) [contentData appendData:CreateURLEncodedFormData(parameters)];
    // Copy the template HTTP message and set the data and content length.
    if (_templateNeedsUpdate) [self updateRequestTemplate];
    request = CFHTTPMessageCreateCopy(kCFAllocatorDefault, _requestTemplate);
    CFHTTPMessageSetBody(request, (CFDataRef)contentData);
    tmpString = [NSString stringWithFormat:@"%u", [contentData length]];
    CFHTTPMessageSetHeaderFieldValue(request, CFSTR("Content-Length"), (CFStringRef)tmpString);
    // Connect to the server.
    stream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, request);
    if (_proxyURL) {
        CFHTTPReadStreamSetProxy(stream, (CFStringRef)[_proxyURL host],
                                 [[_proxyURL port] intValue]);
        //CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPProxy,
        // <a CFDictionary object>);
    }
    CFReadStreamOpen(stream);
    // Build an HTTP response from the data read.
    response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, FALSE);
    while (bytesRead = CFReadStreamRead(stream, bytes, 64)) {
        if (bytesRead == -1) {
            CFStreamError err = CFReadStreamGetError(stream);
            [self _raiseExceptionWithNameFormat:@"LJStreamError_%d_%d", err.domain, err.error];
        } else if (!CFHTTPMessageAppendBytes(response, bytes, bytesRead)) {
            CFReadStreamClose(stream);
            [self _raiseExceptionWithNameFormat:@"LJHTTPParseError"];
        }
    }
    statusCode = CFHTTPMessageGetResponseStatusCode(response);
    if (statusCode == 200) {
        CFDataRef responseData = CFHTTPMessageCopyBody(response);
        replyDictionary = ParseLJReplyData((NSData *)responseData);
        if (responseData) CFRelease(responseData);
    } else {
        [self _raiseExceptionWithNameFormat:@"LJHTTPStatusError_%d", statusCode];
    }
    if (stream) CFRelease(stream);
    if (response) CFRelease(response);
    if (request) CFRelease(request);
    return replyDictionary;
}

@end
