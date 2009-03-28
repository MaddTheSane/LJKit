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

#import "LJAccount_EditFriends.h"
#import "LJAccount_Private.h"
#import "LJGroup_Private.h"
#import "LJFriend_Private.h"
#import "Miscellaneous.h"

@implementation LJAccount (EditFriends)

- (void)updateGroupSetWithReply:(NSDictionary *)reply
{
    [_removedGroupSet release];
    _removedGroupSet = nil;
    if (_groupSet == nil) _groupSet = [[NSMutableSet alloc] initWithCapacity:30];
    [LJGroup updateGroupSet:_groupSet withReply:reply account:self];
    [_groupsSyncDate release];
    _groupsSyncDate = [[NSDate alloc] init];
	
	// Update the static ordered array cache
	if(_orderedGroupArrayCache) {
		[self willChangeValueForKey: @"groupArray"];
		[_orderedGroupArrayCache release];
		_orderedGroupArrayCache = [[[_groupSet allObjects] sortedArrayUsingSelector: @selector(compare:)] retain];
		[self didChangeValueForKey: @"groupArray"];
	}
}

- (void)downloadFriends
{
	// [FS]
	NSNotification *note = [NSNotification notificationWithName: LJAccountWillDownloadFriendsNotification object: self];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread: @selector(postNotification:)
														   withObject: note
														waitUntilDone: YES];
    NSDictionary *parameters, *reply;

    parameters = [NSDictionary dictionaryWithObjectsAndKeys:
        @"1", @"includebdays",
        @"1", @"includefriendof",
        @"1", @"includegroups", nil];
    reply = [self getReplyForMode:@"getfriends" parameters:parameters];
    [_removedFriendSet release];
    _removedFriendSet = nil;
    if (_friendSet == nil) _friendSet = [[NSMutableSet alloc] init];
    [LJFriend updateFriendSet:_friendSet withReply:reply account:self];
    if (_friendOfSet == nil) _friendOfSet = [[NSMutableSet alloc] init];
    [LJFriend updateFriendOfSet:_friendOfSet withReply:reply account:self];
    [_friendsSyncDate release];
    _friendsSyncDate = [[NSDate alloc] init];
    [self updateGroupSetWithReply:reply];
	
	note = [NSNotification notificationWithName: LJAccountDidDownloadFriendsNotification object: self];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread: @selector(postNotification:)
														   withObject: note
														waitUntilDone: NO];
}

- (BOOL)_uploadFriends
{
    NSMutableDictionary *parameters;
    NSEnumerator *e;
    int i;
    LJFriend *buddy;
    NSDictionary *reply;

    parameters = [NSMutableDictionary dictionary];
    // Add Parameters for Friends to Remove
    e = [_removedFriendSet objectEnumerator];
    while (buddy = [e nextObject]) {
        [buddy _addDeleteFieldsToParameters:parameters];
    }
    // Add Parameters for Friends to Add/Change
    e = [_friendSet objectEnumerator];
    i = 1;
    while (buddy = [e nextObject]) {
        if ([_friendsSyncDate compare:[buddy modifiedDate]] == NSOrderedAscending) {
            [buddy _addAddFieldsToParameters:parameters index:(i++)];
        }
    }
    // If there is nothing to change, quit.
    if ([parameters count] == 0) return NO;
    // Send information to the server.
    reply = [self getReplyForMode:@"editfriends" parameters:parameters];
    // Update the friend objects.
    [LJFriend updateFriendSet:_friendSet withEditReply:reply];
    // Clean up.
    [_removedFriendSet release];
    _removedFriendSet = nil;
    [_friendsSyncDate release];
    _friendsSyncDate = [[NSDate alloc] init];
	
	if(_orderedFriendArrayCache) {
		// The underlying set changed, so update the cache
		[self willChangeValueForKey: @"friendArray"];
		[_orderedFriendArrayCache release];
		_orderedFriendArrayCache = [[[_friendSet allObjects] sortedArrayUsingSelector:@selector(compare:)] retain];
		[self didChangeValueForKey: @"friendArray"];
	}

    return YES;
}

- (BOOL)_uploadGroups
{
    NSMutableDictionary *parameters;
    NSEnumerator *e;
    LJGroup *group;

    parameters = [NSMutableDictionary dictionary];
    // Add Parameters for Friends to Remove
    e = [_removedGroupSet objectEnumerator];
    while (group = [e nextObject]) {
        [group _addDeleteFieldsToParameters:parameters];
    }
    // Add Parameters for Friends to Add/Change
    e = [_groupSet objectEnumerator];
    while (group = [e nextObject]) {
        NSDate *modDate = [group modifiedDate];
        if ([_groupsSyncDate compare:modDate] == NSOrderedAscending) {
            [group _addAddFieldsToParameters:parameters];
        }
    }
    // If there is nothing to change, quit.
    if ([parameters count] == 0) return NO;
    // Send information to the server.
    [self getReplyForMode:@"editfriendgroups" parameters:parameters];
    // Clean up.
    [_removedGroupSet release];
    _removedGroupSet = nil;
    [_groupsSyncDate release];
    _groupsSyncDate = [[NSDate alloc] init];
    return YES;
}

- (BOOL)uploadFriends
{
    BOOL groupsUpdated = [self _uploadGroups];
    BOOL friendsUpdated = [self _uploadFriends];
    return (groupsUpdated || friendsUpdated);
}

- (NSSet *)friendSet
{
    return [[_friendSet copy] autorelease];
}
        
- (NSArray *)friendArray
{
	// Lazily create the cache the first time it's needed
	 if(!_orderedFriendArrayCache)
		_orderedFriendArrayCache = [[[_friendSet allObjects] sortedArrayUsingSelector:@selector(compare:)] retain];
	
	// return the cached array
	return [[_orderedFriendArrayCache copy] autorelease];
}

- (NSEnumerator *)friendEnumerator
{
    return [_friendSet objectEnumerator];
}

- (NSSet *)groupSet
{
    return [[_groupSet copy] autorelease];
}

- (NSArray *)groupArray
{
	if(!_orderedGroupArrayCache)
		_orderedGroupArrayCache = [[[_groupSet allObjects] sortedArrayUsingSelector: @selector(compare:)] retain];
	
    return [[_orderedGroupArrayCache copy] autorelease];
}

- (NSEnumerator *)groupEnumerator
{
    return [_groupSet objectEnumerator];
}

- (NSSet *)friendOfSet
{
    return [[_friendOfSet copy] autorelease];
}

- (NSArray *)friendOfArray
{
    return [[_friendOfSet allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)relationshipArray {
	NSMutableSet *set = [[NSMutableSet alloc] init];
	[set autorelease];
	[set addObjectsFromArray: [self friendArray]];
	[set addObjectsFromArray: [self friendOfArray]];
	
	return [[set allObjects] sortedArrayUsingSelector: @selector(compare:)];
}

- (NSEnumerator *)friendOfEnumerator
{
    return [_friendOfSet objectEnumerator];
}

- (LJFriend *)friendNamed:(NSString *)username
{
    LJFriend *amigo;
    amigo = [_friendSet member:username];
    if (amigo) return amigo;
    amigo = [_friendOfSet member:username];
    return amigo;
}

- (void)_addFriendsToContainer:(id)container
                       fromSet:(NSSet *)sourceSet
                        ofType:(NSString *)accountType
{
    NSEnumerator *enumerator = [sourceSet objectEnumerator];
    LJFriend *friend;

    while (friend = [enumerator nextObject]) {
        if ([[friend accountType] isEqualToString:accountType]) {
            [container addObject:friend];
        }
    }
}

- (NSArray *)watchedCommunityArray
{
    NSMutableArray *communities;

    if (_friendSet == nil) return nil;
    communities = [NSMutableArray arrayWithCapacity:[_friendSet count]];
    [self _addFriendsToContainer:communities fromSet:_friendSet
                          ofType:@"community"];
    [communities sortUsingSelector:@selector(compare:)];
    return communities;
}

- (NSSet *)watchedCommunitySet
{
    NSMutableSet *communities;

    if (_friendSet == nil) return nil;
    communities = [NSMutableSet setWithCapacity:[_friendSet count]];
    [self _addFriendsToContainer:communities fromSet:_friendSet
                          ofType:@"community"];
    return communities;
}

- (NSArray *)joinedCommunityArray
{
    NSMutableArray *communities;

    if (_friendOfSet == nil) return nil;
    communities = [NSMutableArray arrayWithCapacity:[_friendOfSet count]];
    [self _addFriendsToContainer:communities fromSet:_friendOfSet
                          ofType:@"community"];
    [communities sortUsingSelector:@selector(compare:)];
    return communities;
}

- (NSSet *)joinedCommunitySet
{
    NSMutableSet *communities;

    if (_friendOfSet == nil) return nil;
    communities = [NSMutableSet setWithCapacity:[_friendOfSet count]];
    [self _addFriendsToContainer:communities fromSet:_friendOfSet
                          ofType:@"community"];
    return communities;
}

- (LJFriend *)addFriendWithUsername:(NSString *)username;
{
    LJFriend *buddy;

    buddy = [_friendSet member:username];
    if (buddy) {
        // Nothing to do.
        return buddy;
    }
    buddy = [_removedFriendSet member:username];
    if (buddy) {
        // Move back to friend set.
        [_friendSet addObject:buddy];
        [_removedFriendSet removeObject:buddy];
        [buddy _setOutgoingFriendship:YES];
        return buddy;
    }
    buddy = [_friendOfSet member:username];
    if (buddy) {
        // Move from friend of set.
        [_friendSet addObject:buddy];
        [buddy _setOutgoingFriendship:YES];
        return buddy;
    }
    buddy = [[LJFriend alloc] initWithUsername:username account:self];
    [buddy _setOutgoingFriendship:YES];
    [_friendSet addObject:buddy];
	
    [buddy release];

	if(_orderedFriendArrayCache) {
		// The underlying set changed, so change the cache
		[self willChangeValueForKey: @"friendArray"];
		[_orderedFriendArrayCache release];
		_orderedFriendArrayCache = [[[_friendSet allObjects] sortedArrayUsingSelector:@selector(compare:)] retain];
		[self didChangeValueForKey: @"friendArray"];
	}
	
    return buddy;
}

- (void)removeFriend:(LJFriend *)buddy
{
    if (_removedFriendSet == nil) {
        _removedFriendSet = [[NSMutableSet alloc] init];
    }
    [_removedFriendSet addObject:buddy];
    [_friendSet removeObject:buddy];
    [buddy _setOutgoingFriendship:NO];
	
	if(_orderedFriendArrayCache) {
		[self willChangeValueForKey: @"friendArray"];
		[_orderedFriendArrayCache release];
		_orderedFriendArrayCache = [[[_friendSet allObjects] sortedArrayUsingSelector:@selector(compare:)] retain];
		[self didChangeValueForKey: @"friendArray"];
	}
}

- (LJGroup *)newGroupWithName:(NSString *)name
{
    LJGroup *group;
    unsigned int allGroupsMask;
    int number;

    if ([_groupSet count] == 30) {
        [[self _exceptionWithName:@"LJGroupLimitReached"] raise];
    }
    allGroupsMask = [self groupMaskFromSet:_groupSet];
    for (number = 1; (1 << number) & allGroupsMask; number++);
    group = [[LJGroup alloc] initWithNumber:number account:self];
    [group setName:name];
    [_groupSet addObject:group];
    [group release];
	
	// Update the static ordered array cache
	if(_orderedGroupArrayCache) {
		[self willChangeValueForKey: @"groupArray"];
		[_orderedGroupArrayCache release];
		_orderedGroupArrayCache = [[[_groupSet allObjects] sortedArrayUsingSelector: @selector(compare:)] retain];
		[self didChangeValueForKey: @"groupArray"];
	}
	
    return group;
}

- (void)removeGroup:(LJGroup *)group
{
    NSEnumerator *e;
    LJFriend *buddy;
    
    if (_removedGroupSet == nil) {
        _removedGroupSet = [[NSMutableSet alloc] init];
    }
    [_removedGroupSet addObject:group];
    [_groupSet removeObject:group];
    // Remove all friends from this group.
    e = [_friendSet objectEnumerator];
    while (buddy = [e nextObject]) {
        [group removeFriend:buddy];
    }
    e = [_removedFriendSet objectEnumerator];
    while (buddy = [e nextObject]) {
        [group removeFriend:buddy];
    }
	
	// Update the static ordered array cache
	if(_orderedGroupArrayCache) {
		[self willChangeValueForKey: @"groupArray"];
		[_orderedGroupArrayCache release];
		_orderedGroupArrayCache = [[[_groupSet allObjects] sortedArrayUsingSelector: @selector(compare:)] retain];
		[self didChangeValueForKey: @"groupArray"];
	}
}

- (unsigned int)_groupMaskFromEnumerator:(NSEnumerator *)enumerator
{
    unsigned int mask = 0;
    LJGroup *group;

    while (group = [enumerator nextObject]) {
        mask |= [group mask];
    }
    return mask;
}

- (unsigned int)groupMaskFromSet:(NSSet *)groupSet
{
    return [self _groupMaskFromEnumerator:[groupSet objectEnumerator]];
}

- (unsigned int)groupMaskFromArray:(NSArray *)groupArray
{
    return [self _groupMaskFromEnumerator:[groupArray objectEnumerator]];
}

- (void)_addGroupsWithMask:(unsigned int)groupMask toContainer:(id)container
{
    NSEnumerator *groupEnumerator = [self groupEnumerator];
    LJGroup *group;

    while (group = [groupEnumerator nextObject]) {
        if ((groupMask & [group mask]) != 0) [container addObject:group];
    }
}

- (NSArray *)groupArrayFromMask:(unsigned int)groupMask
{
    id array = [NSMutableArray arrayWithCapacity:8];
    [self _addGroupsWithMask:groupMask toContainer:array];
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

- (NSSet *)groupSetFromMask:(unsigned int)groupMask
{
    id set = [NSMutableSet setWithCapacity:8];
    [self _addGroupsWithMask:groupMask toContainer:set];
    return set;
}

@end
