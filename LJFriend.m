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

#import "LJFriend_Private.h"
#import "LJUserEntity_Private.h"
#import "LJGroup.h"
#import "LJAccount_EditFriends.h"
#import "Miscellaneous.h"

@interface LJFriend ()
- (instancetype)initWithUsername:(NSString *)username account:(LJAccount *)account NS_DESIGNATED_INITIALIZER;
@property (weak) LJAccount *account;
@end

@implementation LJFriend
@synthesize backgroundColorForYou = _bgColorForYou;
@synthesize foregroundColorForYou = _fgColorForYou;
@synthesize backgroundColor = _bgColor;
@synthesize foregroundColor = _fgColor;

+ (LJFriend *)_friendWithReply:(NSDictionary *)reply prefix:(NSString *)prefix
                       account:(LJAccount *)account
{
    NSString *key = [prefix stringByAppendingString:@"user"];
    NSString *value = reply[key];
    LJFriend *amigo = [account friendNamed:value];
    if (amigo == nil) {
        amigo = [[LJFriend alloc] initWithUsername:value account:account];
    }
    // Parse field common to friendof and getfriends modes
    key = [prefix stringByAppendingString:@"name"];
    [amigo _setFullname:reply[key]];
    key = [prefix stringByAppendingString:@"type"];
	amigo.accountType = reply[key];
    key = [prefix stringByAppendingString:@"status"];
	amigo.accountStatus = reply[key];
    return amigo;
}

+ (void)updateFriendSet:(NSMutableSet *)friends withReply:(NSDictionary *)reply
                account:(LJAccount *)account
{
    NSDate *bd;

    NSInteger count = [reply[@"friend_count"] integerValue];
    NSMutableSet *workingSet = [[NSMutableSet alloc] initWithCapacity:count];
    for (NSInteger i = 1; i <= count; i++ ) {
        NSString *prefix = [NSString stringWithFormat:@"friend_%ld_", (long)i];
        LJFriend *amigo = [self _friendWithReply:reply prefix:prefix account:account];
        [workingSet addObject:amigo];
        [friends removeObject:amigo];
        NSString *key = [prefix stringByAppendingString:@"fg"];
        [amigo setForegroundColor:ColorForHTMLCode(reply[key])];
        key = [prefix stringByAppendingString:@"bg"];
        [amigo setBackgroundColor:ColorForHTMLCode(reply[key])];
        key = [prefix stringByAppendingString:@"groupmask"];
        [amigo setGroupMask:[reply[key] intValue]];
        [amigo _setOutgoingFriendship:YES];
        key = [prefix stringByAppendingString:@"birthday"];
        NSString *birthday = reply[key];
        if (birthday) {
            // Parse it ourselves because NSCalendarDate initWithString: won't
            // accept a 0000 year, but initWithYear:... does.  The format is
            // YYYY-MM-DD.
            NSString *yr = [birthday substringWithRange:NSMakeRange(0, 4)];
            NSString *mo = [birthday substringWithRange:NSMakeRange(5, 2)];
            NSString *dy = [birthday substringWithRange:NSMakeRange(8, 2)];
            NSDateComponents *dc = [NSDateComponents new];
            dc.year = [yr integerValue];
            dc.month = [mo integerValue];
            dc.day = [dy integerValue];
            NSCalendar *greg = [NSCalendar calendarWithIdentifier:NSGregorianCalendar];
            bd = [greg dateFromComponents:dc];
        } else {
            bd = nil;
        }
		amigo.birthDate = bd;
        bd = nil;
    }
    // Objects left in friends no longer have outgoing friendship
    for (LJFriend *amigo in friends) {
        [amigo _setOutgoingFriendship:NO];
    }
    [friends setSet:workingSet];
}

+ (void)updateFriendOfSet:(NSMutableSet *)friendOfs
                withReply:(NSDictionary *)reply account:(LJAccount *)account
{
    NSInteger count = [reply[@"friendof_count"] integerValue];
    NSMutableSet *workingSet = [[NSMutableSet alloc] initWithCapacity:count];
    for (NSInteger i = 1; i <= count; i++ ) {
        NSString *prefix = [NSString stringWithFormat:@"friendof_%ld_", (long)i];
        LJFriend *amigo = [self _friendWithReply:reply prefix:prefix account:account];
        [workingSet addObject:amigo];
        [friendOfs removeObject:amigo];
        NSString *key = [prefix stringByAppendingString:@"fg"];
        NSColor *color = ColorForHTMLCode(reply[key]);
		amigo.foregroundColorForYou = color;
        key = [prefix stringByAppendingString:@"bg"];
        color = ColorForHTMLCode(reply[key]);
		amigo.backgroundColorForYou = color;
        [amigo _setIncomingFriendship:YES];
    }
    // Objects left in friendOfs no longer have incoming friendship
    for (LJFriend *amigo in friendOfs) {
        [amigo _setIncomingFriendship:NO];
    }
    [friendOfs setSet:workingSet];
}

+ (void)updateFriendSet:(NSSet *)friends withEditReply:(NSDictionary *)reply
{
    NSInteger count = [reply[@"friends_added"] integerValue];
    for (NSInteger i = 1; i <= count; i++ ) {
        NSString *userKey = [NSString stringWithFormat:@"friend_%ld_user", (long)i];
        NSString *nameKey = [NSString stringWithFormat:@"friend_%ld_name", (long)i];
        // Because LJFriend considers a string with the friends's name to be
        // equal, we can use member: to retrieve the friend object.
        LJFriend *amigo = [friends member:reply[userKey]];
        if (amigo) {
            [amigo _setFullname:reply[nameKey]];
        } else {
            NSLog(@"Server says friend %@ was added, but friend doesn't appear"
                  @" in set.", reply[userKey]);
        }
    }
}

- (instancetype)initWithUsername:(NSString *)username account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(username);
        _account = account;
        [self _setUsername:username];
        [self _setFullname:username];
        _bgColor = [NSColor whiteColor];
        _fgColor = [NSColor blackColor];
        _bgColorForYou = [NSColor whiteColor];
        _fgColorForYou = [NSColor blackColor];
        _modifiedDate = [[NSDate alloc] init];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _account = [decoder decodeObjectForKey:@"LJFriendAccount"];
        _username = [decoder decodeObjectForKey:@"LJFriendUsername"];
        _fullname = [decoder decodeObjectForKey:@"LJFriendFullname"];
        _birthDate = [decoder decodeObjectForKey:@"LJFriendBirthdate"];
        _fgColor = [decoder decodeObjectForKey:@"LJFriendForegroundColor"];
        _bgColor = [decoder decodeObjectForKey:@"LJFriendBackgroundColor"];
        _fgColorForYou = [decoder decodeObjectForKey:@"LJFriendForegroundColorForYou"];
        _bgColorForYou = [decoder decodeObjectForKey:@"LJFriendBackgroundColorForYou"];
        _groupMask = [decoder decodeInt32ForKey:@"LJFriendGroupMask"];
        _accountType = [decoder decodeObjectForKey:@"LJFriendAccountType"];
        _accountStatus = [decoder decodeObjectForKey:@"LJFriendAccountStatus"];
        _friendship = [decoder decodeIntForKey:@"LJFriendFriendship"];
        _modifiedDate = [decoder decodeObjectForKey:@"LJFriendModifiedDate"];
        _addedIncomingDate = [decoder decodeObjectForKey:@"LJFriendAddedIncomingDate"];
        _addedOutgoingDate = [decoder decodeObjectForKey:@"LJFriendAddedOutgoingDate"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeConditionalObject:_account forKey:@"LJFriendAccount"];
        [encoder encodeObject:_username forKey:@"LJFriendUsername"];
        [encoder encodeObject:_fullname forKey:@"LJFriendFullname"];
        [encoder encodeObject:_birthDate forKey:@"LJFriendBirthdate"];
        [encoder encodeObject:_fgColor forKey:@"LJFriendForegroundColor"];
        [encoder encodeObject:_bgColor forKey:@"LJFriendBackgroundColor"];
        [encoder encodeObject:_fgColorForYou forKey:@"LJFriendForegroundColorForYou"];
        [encoder encodeObject:_bgColorForYou forKey:@"LJFriendBackgroundColorForYou"];
        [encoder encodeInt32:_groupMask forKey:@"LJFriendGroupMask"];
        [encoder encodeObject:_accountType forKey:@"LJFriendAccountType"];
        [encoder encodeObject:_accountStatus forKey:@"LJFriendAccountStatus"];
        [encoder encodeInt:_friendship forKey:@"LJFriendFriendship"];
        [encoder encodeObject:_modifiedDate forKey:@"LJFriendModifiedDate"];
        [encoder encodeObject:_addedIncomingDate forKey:@"LJFriendAddedIncomingDate"];
        [encoder encodeObject:_addedOutgoingDate forKey:@"LJFriendAddedOutgoingDate"];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"LJKit requires keyed coding."];
    }
}

- (void)_updateModifiedDate
{
    _modifiedDate = [[NSDate alloc] init];
}

- (void)setBackgroundColor:(NSColor *)bgColor
{
	if (![_bgColor isEqual:bgColor]) {
		_bgColor = bgColor;
		[self _updateModifiedDate];
	}
}

- (void)setForegroundColor:(NSColor *)fgColor
{
	if (![_fgColor isEqual:fgColor]) {
		_fgColor = fgColor;
		[self _updateModifiedDate];
	}
}

- (void)setGroupMask:(unsigned int)newMask
{
    if (_groupMask != newMask) {
        _groupMask = newMask;
        [self _updateModifiedDate];
    }
}

- (NSUInteger)hash
{
    return [[self username] hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        return [[self username] isEqualToString:[object lowercaseString]];
    }
    if ([object isKindOfClass:[LJFriend class]]) {
        return (_account == ((LJFriend*)object).account &&
                [[self username] isEqualToString:[object username]]);
    }
    return NO;
}

- (NSComparisonResult)compare:(id)object
{
    if ([object isKindOfClass:[LJFriend class]]) {
        return [[self username] compare:[object username]];
    }
    if ([object isKindOfClass:[NSString class]]) {
        return [[self username] compare:[object lowercaseString]];
    }
    NSAssert1(YES, @"Can't compare an LJFriend to %@", object);
    return NSOrderedSame;
}

- (void)_addAddFieldsToParameters:(NSMutableDictionary *)parameters index:(int)i
{
    NSString *key;

    // editfriend_add_i_user
    key = [NSString stringWithFormat:@"editfriend_add_%d_user", i];
    parameters[key] = [self username];
    // editfriend_add_i_fg
    key = [NSString stringWithFormat:@"editfriend_add_%d_fg", i];
    parameters[key] = HTMLCodeForColor(_fgColor);
    // editfriend_add_i_bg
    key = [NSString stringWithFormat:@"editfriend_add_%d_bg", i];
    parameters[key] = HTMLCodeForColor(_bgColor);
    // editfriend_add_i_groupmask
    key = [NSString stringWithFormat:@"editfriend_add_%d_groupmask", i];
    parameters[key] = [NSString stringWithFormat:@"%u", _groupMask];
}

- (void)_addDeleteFieldsToParameters:(NSMutableDictionary *)parameters
{
    NSString *key = [NSString stringWithFormat:@"editfriend_delete_%@", [self username]];
    parameters[key] = @"1";
}

- (void)_setOutgoingFriendship:(BOOL)flag
{
    if (flag) {
        _friendship |= LJFriendshipOutgoing;
        if (_addedOutgoingDate == nil) {
            _addedOutgoingDate = [[NSDate alloc] init];
        }
    } else {
        _friendship &= ~LJFriendshipOutgoing;
        if (_addedOutgoingDate != nil) {
            _addedOutgoingDate = nil;
        }
    }
    [self _updateModifiedDate];
}

- (void)_setIncomingFriendship:(BOOL)flag
{
    if (flag) {
        _friendship |= LJFriendshipIncoming;
        if (_addedIncomingDate == nil) {
            _addedIncomingDate = [[NSDate alloc] init];
        }
    } else {
        _friendship &= ~LJFriendshipIncoming;
        if (_addedIncomingDate != nil) {
            _addedIncomingDate = nil;
        }
    }
}

@end
