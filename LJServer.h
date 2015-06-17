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
 2004-01-09 [BPR]	Removed proxyURL and setProxyURL:.
 					Added reachability methods.
 					Added account reference.
 */

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#if !TARGET_OS_IPHONE
#import <CoreServices/CoreServices.h>
#endif

#define ENABLE_REACHABILITY_MONITORING

@class LJAccount;

NS_ASSUME_NONNULL_BEGIN

#ifdef ENABLE_REACHABILITY_MONITORING
/*!
 @const LJServerReachabilityDidChangeNotification
 Posted if the system determines that the reachability of a server has changed.
 Reachability is not monitored by default.  If you want these notifications to
 be posted, you must enable reachability monitoring.
 
 <code>[[myAccount server] enableReachabilityMonitoring];</code>
 
 The notification object is the LJServer instance.  To find the corresponding
 LJAccount instance you will have to query the LJAccounts individually.
 
 The userInfo dictionary contains one key, @"ConnectionFlags" which is paired
 with an NSNumber instance.  This value is a bit field as returned by the
 SystemConfiguration framework.  You can learn more about the flags meanings in
 the SCNetwork header file.
 
 file:///System/Library/Frameworks/SystemConfiguration.framework/Headers/SCNetwork.h
 */
FOUNDATION_EXPORT NSString * const LJServerReachabilityDidChangeNotification;
#endif

/*!
 @class LJServer
 @abstract Represents a LiveJournal server.
 @discussion
 This class represents the LiveJournal server on the network.  LJServer does
 all the work of translating messages into HTTP traffic and back.
 */
@interface LJServer : NSObject <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @property account
 @abstract The account associated with the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, weak) LJAccount *account;

/*!
 @property URL
 @abstract The URL of host the receiver communicates with.
 @discussion
 The URL must be the base URL of the site, e.g. "http://www.livejournal.com/".
 */
@property (nonatomic, copy) NSURL *URL;

/*!
 @property usingFastServers
 @abstract Determine if fast server access is enabled.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isUsingFastServers, readonly) BOOL useFastServers;

#ifdef ENABLE_REACHABILITY_MONITORING
/*!
 @method enableReachabilityMonitoring
 @abstract Enables reachability monitoring.
 @discussion
 When monitoring is enabled, LJKit posts 
 LJServerReachabilityDidChangeNotification every time the reachability of the
 server changes for some reason.  You can call getReachability: to determine 
 the reachability of the server.
 Monitoring is only available on Mac OS X 10.3 or later.
 */
- (void)enableReachabilityMonitoring;

/*!
 @method disableReachabilityMonitoring
 @abstract Disables reachability monitoring.
 @discussion
 When monitoring is enabled, LJKit posts 
 LJServerReachabilityDidChangeNotification every time the reachability of the
 server changes for some reason.  You can call getReachability: to determine 
 the reachability of the server.
 Monitoring is only available on Mac OS X 10.3 or later.
 */
- (void)disableReachabilityMonitoring;
#endif

/*!
 @method getReachability:
 @discussion Determines if the receiver's target server is reachable using the 
	current network configuration.  See SCNetwork.h in the SystemConfiguration
    framework for an explanation.
 @abstract Determines the reachability of the server.
 @param flags A pointer to memory that will be filled with a
	set of SCNetworkConnectionFlags detailing the reachability
	of the specified node name.
 @returns YES if the flags are valid; NO if the status could not be determined.
 */
- (BOOL)getReachability:(SCNetworkConnectionFlags *)flags;

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
- (nullable NSDictionary *)getReplyForMode:(NSString *)mode parameters:(nullable NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
