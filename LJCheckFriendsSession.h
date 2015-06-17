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
 2004-02-20 [BPR] Documentation correction: LJCheckFriendsSession is 
                  the object for the notifications.
 */

#import <Foundation/Foundation.h>

@class LJAccount, LJGroup;

NS_ASSUME_NONNULL_BEGIN

/*!
@const LJFriendsPageUpdatedNotification
 Posted when the friends page has been updated.
 Checking is stopped before posting this notification; you must call
 startChecking to resume friends checking.
 The notification object is the LJCheckFriendsSession instance that
 posted the notification.
 */
FOUNDATION_EXPORT NSString * const LJFriendsPageUpdatedNotification;

/*!
@const LJCheckFriendsErrorNotification
 Posted when some kind of error occurs during friends checking.
 The exception that caused the error is available in the exception's
 userInfo dictionary for the key "LJException".
 Checking is stopped before posting this notification; you must call
 startChecking to resume friends checking.
 The notification object is the LJCheckFriendsSession instance that
 posted the notification.
 */
FOUNDATION_EXPORT NSString * const LJCheckFriendsErrorNotification;

/*!
@const LJCheckFriendsIntervalChangedNotification
 Posted when the checking interval had to change because the server
 said so.  The interval will never decrease unless you stop checking
 and start checking again with a shorter interval.
 Checking is not stopped after posting; no action is needed to continue
 checking.
 The notification object is the LJCheckFriendsSession instance that
 posted the notification.
 */
FOUNDATION_EXPORT NSString * const LJCheckFriendsIntervalChangedNotification;

/*!
@class LJCheckFriendsSession
@abstract Represents a session which checks for updates to a friends page.
@discussion
The LiveJournal protocol has a mode which allows the client to check if any new
posts have appeared on a user's friends page.  The LJKit implements this using a background thread, managed by an LJCheckFriendsSession object.  To implement
friends page checking in your client, you need only create an instance of this
class, register your class to receive LJFriendsPageUpdatedNotification and then
send startChecking to the session object.
*/
@interface LJCheckFriendsSession : NSObject <NSCoding>

/*!
 @method initWithAccount:
 @discussion
 Initializes the receiver to check the friends page for the given account.
 */
- (instancetype)initWithAccount:(LJAccount *)account NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @property account
 @discussion
 The account this session is associated with.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) LJAccount *account;

/*!
 @property interval
 @abstract The number of seconds between checks.
 @discussion
 If the interval is too short, the server will instruct the client to change
 the interval.
 */
@property (NS_NONATOMIC_IOSONLY) NSTimeInterval interval;

/*!
 @property checkGroupMask
 @abstract The bitmask which defines the groups to be checked.
 @discussion
 This value is not checked against the actual groups defined for the account.
 */
@property (NS_NONATOMIC_IOSONLY) unsigned int checkGroupMask;

/*!
 @property checkGroupArray
 @discussion
 Returns an array containing the groups included in checking.  If an empty
 array is returned, all friends are being checked.
 Sets the groups to be checked.  If groupArray is nil, all friends will be
 checked.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSArray *checkGroupArray;

/*!
 @property checkGroupSet
 @discussion
 Returns a set containing the groups included in checking.  If an empty set is
 returned, all friends are being checked.
 Sets the groups to be checked.  If groupSet is nil, all friends will be
 checked.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSSet *checkGroupSet;

/*!
 @method setChecking:forGroup:
 @discussion
 Includes or excludes a group from checking.
 */
- (void)setChecking:(BOOL)check forGroup:(LJGroup *)group;

/*!
 @method startChecking
 @discussion
 This method detaches a background thread which will poll the server, checking
 for updates on the predefined interval.  If an update occurs, checking is
 stopped and LJFriendsPageUpdatedNotification is posted.  If the interval is
 changed by the server, checking continues and LJCheckFriendsIntervalChanged-
 Notification is posted.  If an error occurs, checking is stopped and LJCheck-
 FriendsErrorNotification is posted.
 */
- (void)startChecking;

/*!
 @method stopChecking
 @discussion
 Stops checking.  No notifications are posted.
 */
- (void)stopChecking;

/*!
 @property checking
 @discussion
 Returns YES if the friends page checking thread is checking or waiting for to
 make its next check, NO otherwise.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isChecking, readonly) BOOL checking;

/*!
 @method openFriendsPage
 @discussion
 This is a convenience method to open the user's friends page.  If this session
 is checking certain groups, then ?filter={groupmask} will be appended to the
 URL.
 */
- (BOOL)openFriendsPage;

@end

NS_ASSUME_NONNULL_END
