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
 2004-01-06 [BPR] Removed calls to ImmutablizeObject()
 */

#import "LJGroup.h"
#import "LJFriend.h"
#import "LJAccount.h"
#import "LJAccount_EditFriends.h"
#import "Miscellaneous.h"

@implementation LJGroup

+ (void)updateGroupSet:(NSMutableSet *)groups withReply:(NSDictionary *)reply account:(LJAccount *)account
{
    int n;
    LJGroup *group;
    NSString *key, *name;

    for ( n = 1; n <= 30; n++ ) {
        group = [groups member:[NSNumber numberWithInt:n]];
        key = [NSString stringWithFormat:@"frgrp_%d_name", n];
        name = [reply objectForKey:key];
        if (name) {
            // Group exists on server
            if (group == nil) {
                // If it is new to us, create a group object
                group = [[LJGroup alloc] initWithNumber:n account:account];
                [groups addObject:group];
//                [group release];
            }
            // Update the group object
            [group setName:name];
            key = [NSString stringWithFormat:@"frgrp_%d_public", n];
            [group setPublic:([[reply objectForKey:key] intValue] != 0)];
            key = [NSString stringWithFormat:@"frgrp_%d_sortorder", n];
            [group setSortOrder:[[reply objectForKey:key] intValue]];
        } else {
            // Group doesn't exist on server
            if (group != nil) {
                // If we have a copy, remove it
                [groups removeObject:group];
            }
        }
    }
}

- (id)initWithNumber:(int)number account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(number > 0 && number < 31);
        _account = account; // Don't retain to avoid cycles.
        _number = number;
        _mask = (1 << _number);
        _sortOrder = 50; // LiveJournal default
        _createdDate = [[NSDate alloc] init];
        _modifiedDate = [_createdDate retain];
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [_createdDate release];
    [_modifiedDate release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _account = [decoder decodeObjectForKey:@"LJGroupAccount"];
        _number = [decoder decodeIntForKey:@"LJGroupNumber"];
        _mask = (1 << _number);
        _name = [[decoder decodeObjectForKey:@"LJGroupName"] retain];
        _sortOrder = (unsigned char)[decoder decodeIntForKey:@"LJGroupSortOrder"];
        _isPublic = [decoder decodeBoolForKey:@"LJGroupIsPublic"];
        _createdDate = [[decoder decodeObjectForKey:@"LJGroupCreatedDate"] retain];
        _modifiedDate = [[decoder decodeObjectForKey:@"LJGroupModifiedDate"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeConditionalObject:_account forKey:@"LJGroupAccount"];
    [encoder encodeInt:_number forKey:@"LJGroupNumber"];
    [encoder encodeObject:_name forKey:@"LJGroupName"];
    [encoder encodeInt:_sortOrder forKey:@"LJGroupSortOrder"];
    [encoder encodeBool:_isPublic forKey:@"LJGroupIsPublic"];
    [encoder encodeObject:_createdDate forKey:@"LJGroupCreatedDate"];
    [encoder encodeObject:_modifiedDate forKey:@"LJGroupModifiedDate"];
}

- (unsigned int)number
{
    return _number;
}

- (unsigned int)mask
{
    return _mask;
}

- (NSString *)name
{
    return _name;
}

- (void)setName:(NSString *)name
{
    if (SafeSetString(&_name, name)) [self _updateModifiedDate];
}

- (unsigned char)sortOrder
{
    return _sortOrder;
}

- (void)setSortOrder:(unsigned char)sortOrder
{
    if (_sortOrder != sortOrder) {
        _sortOrder = sortOrder;
        [self _updateModifiedDate];
    }
}

- (BOOL)isPublic
{
    return _isPublic;
}

- (void)setPublic:(BOOL)flag
{
    if (_isPublic != flag) {
        _isPublic = flag;
        [self _updateModifiedDate];
    }
}

- (NSDate *)createdDate
{
    return _createdDate;
}

- (NSDate *)modifiedDate
{
    return _modifiedDate;
}

- (void)_updateModifiedDate
{
    [_modifiedDate release];
    _modifiedDate = [[NSDate alloc] init];
}

- (void)addFriend:(LJFriend *)amigo
{
    NSAssert(([amigo friendship] & LJOutgoingFriendship) != 0,
             @"Must add friend to friend list before adding to a group.");
    [amigo setGroupMask:([amigo groupMask] | _mask)];
}

- (void)removeFriend:(LJFriend *)amigo
{
    NSAssert(([amigo friendship] & LJOutgoingFriendship) != 0,
             @"Must add friend to friend list before removing from a group.");
    [amigo setGroupMask:([amigo groupMask] & ~_mask)];
}

- (BOOL)isMember:(LJFriend *)amigo
{
    return (([amigo groupMask] & _mask) != 0);
}

- (void)_addMembersToContainer:(id)members
         nonMembersToContainer:(id)nonMembers
{
    NSEnumerator *allFriends;
    LJFriend *friend;
    
    allFriends = [_account friendEnumerator];
    while (friend = [allFriends nextObject]) {
        if ([self isMember:friend]) {
            [members addObject:friend];
        } else {
            [nonMembers addObject:friend];
        }
    }
}

- (NSArray *)memberArray
{
    NSMutableArray *members = [NSMutableArray array];
    [self _addMembersToContainer:members nonMembersToContainer:nil];
    [members sortUsingSelector:@selector(compare:)];
    return members;
}

- (NSSet *)memberSet
{
    NSMutableSet *members = [NSMutableSet set];
    [self _addMembersToContainer:members nonMembersToContainer:nil];
    return members;
}

- (NSArray *)nonMemberArray
{
    NSMutableArray *nonMembers = [NSMutableArray array];
    [self _addMembersToContainer:nil nonMembersToContainer:nonMembers];
    [nonMembers sortUsingSelector:@selector(compare:)];
    return nonMembers;
}

- (NSSet *)nonMemberSet
{
    NSMutableSet *nonMembers = [NSMutableSet set];
    [self _addMembersToContainer:nil nonMembersToContainer:nonMembers];
    return nonMembers;
}

- (unsigned)hash
{
    return _number;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[LJGroup class]]) {
        return ( _account == ((LJGroup *)object)->_account &&
                 _number == ((LJGroup *)object)->_number );
    }
    if ([object isKindOfClass:[NSNumber class]]) {
        return (_number == [object intValue]);
    }
    return NO;
}

- (NSComparisonResult)compare:(id)object
{
    signed int diff;
    
    if ([object isKindOfClass:[LJGroup class]]) {
        diff = [self sortOrder] - [object sortOrder];
        if (diff < 1) return NSOrderedAscending;
        else if (diff > 1) return NSOrderedDescending;
        else return [[self name] compare:[object name]];
    }
    if ([object isKindOfClass:[NSNumber class]]) {
        diff = [self number] - [object intValue];
        if (diff < 1) return NSOrderedAscending;
        else if (diff > 1) return NSOrderedDescending;
        else return NSOrderedSame;
    }
    NSAssert1(NO, @"Can't compare an LJGroup to %@", object);
    return nil;
}

- (NSString *)description
{
    return _name;
}

- (void)_addAddFieldsToParameters:(NSMutableDictionary *)parameters
{
    NSString *key, *value;

    // efg_set_groupnum_name
    key = [NSString stringWithFormat:@"efg_set_%d_name", _number];
    [parameters setObject:_name forKey:key];
    // efg_set_groupnum_sort
    key = [NSString stringWithFormat:@"efg_set_%d_sort", _number];
    value = [NSString stringWithFormat:@"%u", _sortOrder];
    [parameters setObject:value forKey:key];
    // efg_set_groupnum_public
    key = [NSString stringWithFormat:@"efg_set_%d_public", _number];
    [parameters setObject:(_isPublic ? @"1" : @"0") forKey:key];
}

- (void)_addDeleteFieldsToParameters:(NSMutableDictionary *)parameters
{
    NSString *key;
    
    // efg_delete_groupnum
    key = [NSString stringWithFormat:@"efg_delete_%d", _number];
    [parameters setObject:@"1" forKey:key];
}

@end
