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

 @constant LJOutgoingFriendship
 You list the user as a friend.

 @constant LJIncomingFriendship
 The friend lists you as a friend.

 @constant LJMutualFriendship
 You list the user as a friend and he lists you as a friend.
 This is equal to the bitwise OR of the two other constants.
 */
enum {
    LJOutgoingFriendship = 1,
    LJIncomingFriendship = 2,
    LJMutualFriendship = 3,
};

/*!
 @class LJFriend
 @abstract Represents a LiveJournal friend.
 */
@interface LJFriend : LJUserEntity <NSCoding>
{
    LJAccount *_account;
    NSCalendarDate *_birthDate;
    NSColor *_fgColor, *_bgColor, *_fgColorForYou, *_bgColorForYou;
    unsigned int _groupMask;
    NSString *_accountType;
    NSString *_accountStatus;
    int _friendship;
    NSDate *_addedIncomingDate;
    NSDate *_addedOutgoingDate;
    NSDate *_modifiedDate;
}

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @method birthDate
 @abstract Obtain the birthdate of the receiver.
 */
- (NSCalendarDate *)birthDate;

/*!
 @method accountType
 @abstract Obtain the account type of the receiver.
 @discussion
 This property is blank if the receiver represents a regular user account.
 If the receiver is a community, this will return the string "community".
 */
- (NSString *)accountType;

/*!
 @method accountStatus
 @abstract Obtain the account status of the receiver.
 This property is blank if the receiver has normal active status.
 Other possible values are are "deleted", "suspended", and "purged". 
 */
- (NSString *)accountStatus;

/*!
 @method modifiedDate
 @abstract Returns the receiver's modification date.
 @discussion
 This is the date that the receiver was most recently changed in some way.
 If this date is later than the last time the account's friends have been
 downloaded then its changes will be committed next time
 [LJAccount uploadFriends] is called.
 */
- (NSDate *)modifiedDate;

- (NSDate *)addedIncomingDate;
- (NSDate *)addedOutgoingDate;

/*!
 @method backgroundColor
 @abstract Obtain the background color of the receiver.
 */
- (NSColor *)backgroundColor;

/*!
 @method setBackgroundColor:
 @abstract Sets the background color of the receiver.
 */
- (void)setBackgroundColor:(NSColor *)bgColor;

/*!
 @method foregroundColor
 @abstract Obtain the foreground color of the receiver.
 */
- (NSColor *)foregroundColor;

/*!
 @method setForegroundColor:
 @abstract Sets the foreground color of the receiver.
 */
- (void)setForegroundColor:(NSColor *)fgColor;

- (unsigned int)groupMask;
- (void)setGroupMask:(unsigned int)newMask;

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
- (int)friendship;

/*!
 @method backgroundColorForYou
 @result The color this friend uses for your background.
 */
- (NSColor *)backgroundColorForYou;

/*!
 @method foregroundColorForYou
 @result The color this friend uses for your foreground.
 */
- (NSColor *)foregroundColorForYou;

@end
