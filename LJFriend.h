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
#import <LJKit/LJUserEntity.h>

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif
@class LJAccount, LJGroup;

/*!
 @enum Friendship Constants

 @constant LJFriendshipOutgoing
 You list the user as a friend.

 @constant LJFriendshipIncoming
 The friend lists you as a friend.

 @constant LJFriendshipMutual
 You list the user as a friend and he lists you as a friend.
 This is equal to the bitwise OR of the two other constants.
 */
typedef NS_OPTIONS(NSInteger, LJFriendship) {
    LJFriendshipOutgoing = 1,
    LJFriendshipIncoming = 2,
    LJFriendshipMutual = 3,
};

/*!
 @class LJFriend
 @abstract Represents a LiveJournal friend.
 */
@interface LJFriend : LJUserEntity <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @property birthDate
 @abstract The birthdate of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *birthDate;

/*!
 @property accountType
 @abstract The account type of the receiver.
 @discussion
 This property is blank if the receiver represents a regular user account.
 If the receiver is a community, this will return the string "community".
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *accountType;

/*!
 @property accountStatus
 @abstract The account status of the receiver.
 This property is blank if the receiver has normal active status.
 Other possible values are are "deleted", "suspended", and "purged". 
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *accountStatus;

/*!
 @property modifiedDate
 @abstract The receiver's modification date.
 @discussion
 This is the date that the receiver was most recently changed in some way.
 If this date is later than the last time the account's friends have been
 downloaded then its changes will be committed next time
 [LJAccount uploadFriends] is called.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *modifiedDate;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *addedIncomingDate;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *addedOutgoingDate;

/*!
 @property friendship
 @abstract The type of friendship for this friend.
 @discussion
 Returns the direction of friendship with this user.  If you list the receiver
 as a friend, the friendship is outgoing.  If the receiver lists you as a
 friend, the friendship is incoming.  If both cases are true, the friendship is
 mutual.  The result is one of the Friendship constants defined in the LJFriend
 header.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) LJFriendship friendship;

@property (nonatomic) unsigned int groupMask;

#if !TARGET_OS_IPHONE
/*!
 @property backgroundColor
 @abstract The background color of the receiver.
 */
@property (nonatomic, copy) NSColor *backgroundColor;

/*!
 @property foregroundColor
 @abstract The foreground color of the receiver.
 */
@property (nonatomic, copy) NSColor *foregroundColor;

/*!
 @property backgroundColorForYou
 @result The color this friend uses for your background.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSColor *backgroundColorForYou;

/*!
 @property foregroundColorForYou
 @result The color this friend uses for your foreground.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSColor *foregroundColorForYou;

#endif

@end
