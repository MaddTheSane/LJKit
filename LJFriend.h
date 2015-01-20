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

#import <Cocoa/Cocoa.h>
#import <LJKit/LJUserEntity.h>

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
typedef NS_OPTIONS(int, LJFriendship) {
    LJFriendshipOutgoing = 1,
    LJFriendshipIncoming = 2,
    LJFriendshipMutual = 3,
};

/*!
 @class LJFriend
 @abstract Represents a LiveJournal friend.
 */
@interface LJFriend : LJUserEntity <NSCoding>
{
    LJAccount *__weak _account;
    NSCalendarDate *_birthDate;
    NSColor *_fgColor, *_bgColor, *_fgColorForYou, *_bgColorForYou;
    unsigned int _groupMask;
    NSString *_accountType;
    NSString *_accountStatus;
    LJFriendship _friendship;
    NSDate *_addedIncomingDate;
    NSDate *_addedOutgoingDate;
    NSDate *_modifiedDate;
}

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @method birthDate
 @abstract Obtain the birthdate of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSCalendarDate *birthDate;

/*!
 @method accountType
 @abstract Obtain the account type of the receiver.
 @discussion
 This property is blank if the receiver represents a regular user account.
 If the receiver is a community, this will return the string "community".
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *accountType;

/*!
 @method accountStatus
 @abstract Obtain the account status of the receiver.
 This property is blank if the receiver has normal active status.
 Other possible values are are "deleted", "suspended", and "purged". 
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *accountStatus;

/*!
 @method modifiedDate
 @abstract Returns the receiver's modification date.
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
 @method backgroundColor
 @abstract Obtain the background color of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSColor *backgroundColor;

/*!
 @method setBackgroundColor:
 @abstract Sets the background color of the receiver.
 */

/*!
 @method foregroundColor
 @abstract Obtain the foreground color of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSColor *foregroundColor;

/*!
 @method setForegroundColor:
 @abstract Sets the foreground color of the receiver.
 */

@property (NS_NONATOMIC_IOSONLY) unsigned int groupMask;

/*!
 @method friendship
 @abstract Returns the type of friendship for this friend.
 @discussion
 Returns the direction of friendship with this user.  If you list the receiver
 as a friend, the friendship is outgoing.  If the receiver lists you as a
 friend, the friendship is incoming.  If both cases are true, the friendship is
 mutual.  The result is one of the Friendship constants defined in the LJFriend
 header.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) LJFriendship friendship;

/*!
 @method backgroundColorForYou
 @result The color this friend uses for your background.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSColor *backgroundColorForYou;

/*!
 @method foregroundColorForYou
 @result The color this friend uses for your foreground.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSColor *foregroundColorForYou;

@end
