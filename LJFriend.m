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

@implementation LJFriend

+ (LJFriend *)_friendWithReply:(NSDictionary *)reply prefix:(NSString *)prefix
                       account:(LJAccount *)account
{
    NSString *key, *value;
    LJFriend *amigo;
    
    key = [prefix stringByAppendingString:@"user"];
    value = [reply objectForKey:key];
    amigo = [account friendNamed:value];
    if (amigo == nil) {
        amigo = [[LJFriend alloc] initWithUsername:value account:account];
        [amigo autorelease];
    }
    // Parse field common to friendof and getfriends modes
    key = [prefix stringByAppendingString:@"name"];
    [amigo _setFullname:[reply objectForKey:key]];
    key = [prefix stringByAppendingString:@"type"];
    SafeSetString(&amigo->_accountType, [reply objectForKey:key]);
    key = [prefix stringByAppendingString:@"status"];
    SafeSetString(&amigo->_accountStatus, [reply objectForKey:key]);
    return amigo;
}

+ (void)updateFriendSet:(NSMutableSet *)friends withReply:(NSDictionary *)reply
                account:(LJAccount *)account
{
    int count, i;
    NSMutableSet *workingSet;
    NSString *prefix, *key, *birthday, *yr, *mo, *dy;
    LJFriend *amigo;
    NSCalendarDate *bd;
    NSEnumerator *e;

    count = [[reply objectForKey:@"friend_count"] intValue];
    workingSet = [[NSMutableSet alloc] initWithCapacity:count];
    for ( i = 1; i <= count; i++ ) {
        prefix = [NSString stringWithFormat:@"friend_%d_", i];
        amigo = [self _friendWithReply:reply prefix:prefix account:account];
        [workingSet addObject:amigo];
        [friends removeObject:amigo];
        key = [prefix stringByAppendingString:@"fg"];
        [amigo setForegroundColor:ColorForHTMLCode([reply objectForKey:key])];
        key = [prefix stringByAppendingString:@"bg"];
        [amigo setBackgroundColor:ColorForHTMLCode([reply objectForKey:key])];
        key = [prefix stringByAppendingString:@"groupmask"];
        [amigo setGroupMask:[[reply objectForKey:key] intValue]];
        [amigo _setOutgoingFriendship:YES];
        key = [prefix stringByAppendingString:@"birthday"];
        birthday = [reply objectForKey:key];
        if (birthday) {
            // Parse it ourselves because NSCalendarDate initWithString: won't
            // accept a 0000 year, but initWithYear:... does.  The format is
            // YYYY-MM-DD.
            yr = [birthday substringWithRange:NSMakeRange(0, 4)];
            mo = [birthday substringWithRange:NSMakeRange(5, 2)];
            dy = [birthday substringWithRange:NSMakeRange(8, 2)];
            bd = [[NSCalendarDate alloc] initWithYear:[yr intValue]
                                                month:[mo intValue]
                                                  day:[dy intValue]
                                                 hour:0 minute:0
                                               second:0 timeZone:nil];
        } else {
            bd = nil;
        }
        SafeSetObject(&amigo->_birthDate, bd);
        [bd release];
        bd = nil;
    }
    // Objects left in friends no longer have outgoing friendship
    e = [friends objectEnumerator];
    while (amigo = [e nextObject]) {
        [amigo _setOutgoingFriendship:NO];
    }
    [friends setSet:workingSet];
    [workingSet release];
}

+ (void)updateFriendOfSet:(NSMutableSet *)friendOfs
                withReply:(NSDictionary *)reply account:(LJAccount *)account
{
    int count, i;
    NSMutableSet *workingSet;
    NSString *prefix, *key;
    LJFriend *amigo;
    NSEnumerator *e;
    NSColor *color;

    count = [[reply objectForKey:@"friendof_count"] intValue];
    workingSet = [[NSMutableSet alloc] initWithCapacity:count];
    for ( i = 1; i <= count; i++ ) {
        prefix = [NSString stringWithFormat:@"friendof_%d_", i];
        amigo = [self _friendWithReply:reply prefix:prefix account:account];
        [workingSet addObject:amigo];
        [friendOfs removeObject:amigo];
        key = [prefix stringByAppendingString:@"fg"];
        color = ColorForHTMLCode([reply objectForKey:key]);
        SafeSetObject(&amigo->_fgColorForYou, color);
        key = [prefix stringByAppendingString:@"bg"];
        color = ColorForHTMLCode([reply objectForKey:key]);
        SafeSetObject(&amigo->_bgColorForYou, color);
        [amigo _setIncomingFriendship:YES];
    }
    // Objects left in friendOfs no longer have incoming friendship
    e = [friendOfs objectEnumerator];
    while (amigo = [e nextObject]) {
        [amigo _setIncomingFriendship:NO];
    }
    [friendOfs setSet:workingSet];
    [workingSet release];
}

+ (void)updateFriendSet:(NSSet *)friends withEditReply:(NSDictionary *)reply
{
    int count, i;

    count = [[reply objectForKey:@"friends_added"] intValue];
    for ( i = 1; i <= count; i++ ) {
        NSString *userKey = [NSString stringWithFormat:@"friend_%d_user", i];
        NSString *nameKey = [NSString stringWithFormat:@"friend_%d_name", i];
        // Because LJFriend considers a string with the friends's name to be
        // equal, we can use member: to retrieve the friend object.
        LJFriend *amigo = [friends member:[reply objectForKey:userKey]];
        if (amigo) {
            [amigo _setFullname:[reply objectForKey:nameKey]];
        } else {
            NSLog(@"Server says friend %@ was added, but friend doesn't appear"
                  @" in set.", [reply objectForKey:userKey]);
        }
    }
}

- (id)initWithUsername:(NSString *)username account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(username);
        _account = account;
        [self _setUsername:username];
        [self _setFullname:username];
        _bgColor = [[NSColor whiteColor] retain];
        _fgColor = [[NSColor blackColor] retain];
        _bgColorForYou = [[NSColor whiteColor] retain];
        _fgColorForYou = [[NSColor blackColor] retain];
        _modifiedDate = [[NSDate alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_bgColor release];
    [_fgColor release];
    [_birthDate release];
    [_accountType release];
    [_accountStatus release];
    [_modifiedDate release];
    [_addedIncomingDate release];
    [_addedOutgoingDate release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _account = [decoder decodeObjectForKey:@"LJFriendAccount"];
        _username = [[decoder decodeObjectForKey:@"LJFriendUsername"] retain];
        _fullname = [[decoder decodeObjectForKey:@"LJFriendFullname"] retain];
        _birthDate = [[decoder decodeObjectForKey:@"LJFriendBirthdate"] retain];
        _fgColor = [[decoder decodeObjectForKey:@"LJFriendForegroundColor"] retain];
        _bgColor = [[decoder decodeObjectForKey:@"LJFriendBackgroundColor"] retain];
        _fgColorForYou = [[decoder decodeObjectForKey:@"LJFriendForegroundColorForYou"] retain];
        _bgColorForYou = [[decoder decodeObjectForKey:@"LJFriendBackgroundColorForYou"] retain];
        _groupMask = [decoder decodeInt32ForKey:@"LJFriendGroupMask"];
        _accountType = [[decoder decodeObjectForKey:@"LJFriendAccountType"] retain];
        _accountStatus = [[decoder decodeObjectForKey:@"LJFriendAccountStatus"] retain];
        _friendship = [decoder decodeIntForKey:@"LJFriendFriendship"];
        _modifiedDate = [[decoder decodeObjectForKey:@"LJFriendModifiedDate"] retain];
        _addedIncomingDate = [[decoder decodeObjectForKey:@"LJFriendAddedIncomingDate"] retain];
        _addedOutgoingDate = [[decoder decodeObjectForKey:@"LJFriendAddedOutgoingDate"] retain];
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


- (LJAccount *)account
{
    return _account;
}


- (NSCalendarDate *)birthDate
{
    return _birthDate;
}

- (NSString *)accountType
{
    return _accountType;
}

- (NSString *)accountStatus
{
    return _accountStatus;
}

- (NSDate *)modifiedDate
{
    return _modifiedDate;
}

- (NSDate *)addedIncomingDate
{
    return _addedIncomingDate;
}

- (NSDate *)addedOutgoingDate
{
    return _addedOutgoingDate;
}

- (void)_updateModifiedDate
{
    [_modifiedDate release];
    _modifiedDate = [[NSDate alloc] init];
}

- (NSColor *)backgroundColor
{
    return _bgColor;
}

- (void)setBackgroundColor:(NSColor *)bgColor
{
    if (SafeSetObject(&_bgColor, bgColor)) [self _updateModifiedDate];
}

- (NSColor *)foregroundColor
{
    return _fgColor;
}

- (void)setForegroundColor:(NSColor *)fgColor
{
    if (SafeSetObject(&_fgColor, fgColor)) [self _updateModifiedDate];
}

- (unsigned int)groupMask
{
    return _groupMask;
}

- (void)setGroupMask:(unsigned int)newMask
{
    if (_groupMask != newMask) {
        _groupMask = newMask;
        [self _updateModifiedDate];
    }
}

- (int)friendship
{
    return _friendship;
}

- (NSColor *)backgroundColorForYou
{
    return _bgColorForYou;
}

- (NSColor *)foregroundColorForYou
{
    return _fgColorForYou;
}

- (unsigned)hash
{
    return [[self username] hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        return [[self username] isEqualToString:[object lowercaseString]];
    }
    if ([object isKindOfClass:[LJFriend class]]) {
        return (_account == ((LJFriend *)object)->_account &&
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
    return nil;
}

- (void)_addAddFieldsToParameters:(NSMutableDictionary *)parameters index:(int)i
{
    NSString *key;

    // editfriend_add_i_user
    key = [NSString stringWithFormat:@"editfriend_add_%d_user", i];
    [parameters setObject:[self username] forKey:key];
    // editfriend_add_i_fg
    key = [NSString stringWithFormat:@"editfriend_add_%d_fg", i];
    [parameters setObject:HTMLCodeForColor(_fgColor) forKey:key];
    // editfriend_add_i_bg
    key = [NSString stringWithFormat:@"editfriend_add_%d_bg", i];
    [parameters setObject:HTMLCodeForColor(_bgColor) forKey:key];
    // editfriend_add_i_groupmask
    key = [NSString stringWithFormat:@"editfriend_add_%d_groupmask", i];
    [parameters setObject:[NSString stringWithFormat:@"%u", _groupMask] forKey:key];
}

- (void)_addDeleteFieldsToParameters:(NSMutableDictionary *)parameters
{
    NSString *key;

    key = [NSString stringWithFormat:@"editfriend_delete_%@", [self username]];
    [parameters setObject:@"1" forKey:key];
}

- (void)_setOutgoingFriendship:(BOOL)flag
{
    if (flag) {
        _friendship |= LJOutgoingFriendship;
        if (_addedOutgoingDate == nil) {
            _addedOutgoingDate = [[NSDate alloc] init];
        }
    } else {
        _friendship &= ~LJOutgoingFriendship;
        if (_addedOutgoingDate != nil) {
            [_addedOutgoingDate release];
            _addedOutgoingDate = nil;
        }
    }
    [self _updateModifiedDate];
}

- (void)_setIncomingFriendship:(BOOL)flag
{
    if (flag) {
        _friendship |= LJIncomingFriendship;
        if (_addedIncomingDate == nil) {
            _addedIncomingDate = [[NSDate alloc] init];
        }
    } else {
        _friendship &= ~LJIncomingFriendship;
        if (_addedIncomingDate != nil) {
            [_addedIncomingDate release];
            _addedIncomingDate = nil;
        }
    }
}

@end
