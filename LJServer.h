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

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

/*!
 @class LJServer
 @abstract Represents a LiveJournal server.
 @discussion
 This class represents the LiveJournal server on the network.  LJServer does
 all the work of translating messages into HTTP traffic and back.
 */
@interface LJServer : NSObject <NSCoding>
{
    NSURL *_serverURL, *_proxyURL;
    BOOL _isUsingFastServers;
    BOOL _templateNeedsUpdate;
    NSData *_loginData;
    CFHTTPMessageRef _requestTemplate;
}
- (id)initWithURL:(NSURL *)url;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @method setURL:
 @abstract Set the URL of the host to communicate with.
 @param url The URL of the host to connect to.
 */
- (void)setURL:(NSURL *)url;

/*!
 @method hostname
 @abstract Obtain the hostname of the receiver.
 */
- (NSURL *)url;

/*!
 @method setProxyURL:
 @abstract Set the URL of a proxy server.
 @discussion
 To enable proxy support, call this method with the URL of the proxy server.
 To disable proxy support, set proxyHostname to nil.
 */
- (void)setProxyURL:(NSURL *)url;

/*!
 @method proxyURL
 @abstract Obtain the URL of the proxy server.
 @result The URL of a the proxy server, or nil if proxy is disabled.
 */
- (NSURL *)proxyURL;

- (void)setUseFastServers:(BOOL)flag;

/*!
 @method isUsingFastServers
 @abstract Determine if fast server access is enabled.
 */
- (BOOL)isUsingFastServers;

- (void)setLoginInfo:(NSDictionary *)loginDict;

/*!
 @method getReplyForMode:parameters:
 @abstract Sends a message to the server and returns the reply.
 @discussion
 This method takes a mode and a set of variable parameters, encodes them as an HTTP
 POST request, sends them to the server, parses the reply, and returns it as a
 dictionary.  If a network error occurs, nil is returned.  This method is only concerned
 with network transport.  If the LiveJournal server returns an error, this method
 will not detect it.  You should use the corresponding method in LJAccount instead.
 */
- (NSDictionary *)getReplyForMode:(NSString *)mode parameters:(NSDictionary *)parameters;

@end
