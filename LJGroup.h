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

@class LJAccount, LJFriend;

/*!
 @class LJGroup
 @abstract Represents a friend group.
 */
@interface LJGroup : NSObject <NSCoding>
{
    LJAccount *_account;
    unsigned int _number;
    unsigned int _mask;
    NSString *_name;
    unsigned char _sortOrder;
    BOOL _isPublic;
    NSDate *_createdDate;
    NSDate *_modifiedDate;
}
+ (void)updateGroupSet:(NSMutableSet *)groups withReply:(NSDictionary *)reply account:(LJAccount *)account;

- (instancetype)initWithNumber:(int)number account:(LJAccount *)account NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @method number
 @abstract Obtain the group's number.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) unsigned int number;

/*!
 @method mask
 @abstract Obtain the group's bit mask.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) unsigned int mask;

/*!
 @method name
 @abstract Obtain the name of the receiver.
 */
@property (nonatomic, copy) NSString *name;

/*!
 @method setName:
 @abstract Sets the name of the receiver.
 */

/*!
 @method sortOrder
 @abstract Obtain the sort order index of the receiver.
 */
@property (nonatomic) unsigned char sortOrder;

/*!
 @method setSortOrder:
 @abstract Sets the sort order index of the receiver.
 */

/*!
 @method isPublic
 @abstract Determine whether the receiver is visible to other users.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isPublic) BOOL public;

/*!
 @method setPublic:
 @abstract Sets whether the receiver is visible to other users.
 */

/*!
 @method createdDate
 @abstract Returns the date the receiver was created.
 @discussion
 This method returns the date the receiver was created; this is not
 necessarily the date the group it represents was created.  If the
 group was created externally, this will be the date that the LJKit
 first learned of its existence.  Because of this, this method is
 somewhat unreliable.  For instance, if the user deletes a group, then
 creates a new one with the same number, then logs in with the LJKit,
 it will appear to be the same group.  For this reason it is advised
 that users not manipulate groups outside of the LJKit.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *createdDate;

/*!
 @method modifiedDate
 @abstract Returns the date the receiver was modified.
 @discussion
 This method returns the date the receiver was changed in some way.
 It is used to determine which groups have changes that need to be
 synchronized with the server.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *modifiedDate;

- (void)_updateModifiedDate;

/*!
 @method addFriend:
 @abstract Add a friend to the receiver.
 */
- (void)addFriend:(LJFriend *)amigo;

/*!
 @method removeFriend:
 @abstract Remove a friend from the receiver.
 */
- (void)removeFriend:(LJFriend *)amigo;

/*!
 @method isMember:
 @abstract Determine membership of a friend.
 @discussion
 If the receiver belongs to a different account than amigo, the
 result is undefined.
 @result YES if amigo is a member of this group; NO otherwise.
 */
- (BOOL)isMember:(LJFriend *)amigo;

/*!
 @method memberArray
 @abstract Returns the members of the receiver as a sorted array.
 @result An NSArray of LJFriend objects.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *memberArray;

/*!
 @method memberSet
 @abstract Returns the members of the receiver as a set.
 @result An NSSet of LJFriend objects.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSSet *memberSet;

/*!
 @method nonMemberArray
 @abstract Returns the non-members of the receiver.
 @result A sorted NSArray of LJFriend objects.
 @discussion
 This method returns users who are friends of the parent account but are not
 members of this group.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *nonMemberArray;

/*!
 @method nonMemberSet
 @abstract Returns the non-members of the receiver.
 @result An NSSet of LJFriend objects.
 @discussion
 This method returns users who are friends of the parent account but are not
 members of this group.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSSet *nonMemberSet;

@end
