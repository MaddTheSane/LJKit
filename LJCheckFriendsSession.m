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

#import "LJCheckFriendsSession.h"
#import "LJAccount.h"
#import "LJAccount_EditFriends.h"
#import "LJGroup.h"
#import "LJHttpURLs.h"

NSString * const LJFriendsPageUpdatedNotification = @"LJFriendsPageUpdated";
NSString * const LJCheckFriendsErrorNotification = @"LJCheckFriendsError";
NSString * const LJCheckFriendsIntervalChangedNotification = @"LJCheckFriendsIntervalChanged";

@interface LJCheckFriendsSession (Private)
- (void)_checkThread:(id)object;
- (void)_checkTick;
@end

@implementation LJCheckFriendsSession

- (id)initWithAccount:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(account);
        _account = [account retain];
        _interval = 300; // five minute default
        _parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    NSString *key;
    
    self = [super init];
    if (self) {
        key = @"LJCheckFriendsSessionAccount";
        _account = [[decoder decodeObjectForKey:key] retain];
        key = @"LJCheckFriendsSessionInterval";
        _interval = [decoder decodeDoubleForKey:key];
        key = @"LJCheckFriendsSessionParameters";
        _parameters = [[decoder decodeObjectForKey:key] mutableCopy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSString *key;

    key = @"LJCheckFriendsSessionAccount";
    [encoder encodeConditionalObject:_account forKey:key];
    key = @"LJCheckFriendsSessionInterval";
    [encoder encodeDouble:_interval forKey:key];
    key = @"LJCheckFriendsSessionParameters";
    [encoder encodeObject:_parameters forKey:key];
}

- (void)dealloc
{
    [_account release];
    [_parameters release];
    [super dealloc];
}

- (LJAccount *)account
{
    return _account;
}

- (NSTimeInterval)interval
{
    return _interval;
}

- (void)setInterval:(NSTimeInterval)interval
{
    _interval = interval;
}

- (unsigned int)checkGroupMask
{
    return [[_parameters objectForKey:@"mask"] intValue];
}

- (void)setCheckGroupMask:(unsigned int)mask
{
    [_parametersLock lock];
    if (mask) {
        NSString *maskString = [NSString stringWithFormat:@"%u", mask];
        [_parameters setObject:maskString forKey:@"mask"];
    } else {
        [_parameters removeObjectForKey:@"mask"];
    }
    [_parametersLock unlock];
}

- (NSArray *)checkGroupArray
{
    return [_account groupArrayFromMask:[self checkGroupMask]];
}

- (void)setCheckGroupArray:(NSArray *)groupArray
{
    [self setCheckGroupMask:[_account groupMaskFromArray:groupArray]];
}

- (NSSet *)checkGroupSet
{
    return [_account groupSetFromMask:[self checkGroupMask]];
}

- (void)setCheckGroupSet:(NSSet *)groupSet
{
    [self setCheckGroupMask:[_account groupMaskFromSet:groupSet]];
}

- (void)setChecking:(BOOL)check forGroup:(LJGroup *)group
{
    unsigned int mask = [self checkGroupMask];

    if (check) {
        mask |= [group mask];
    } else {
        mask &= ~[group mask];
    }
    [self setCheckGroupMask:mask];
}

- (void)startChecking
{
    _parametersLock = [[NSLock alloc] init];
    [_parameters removeObjectForKey:@"lastupdate"];
    [NSThread detachNewThreadSelector:@selector(_checkThread:)
                             toTarget:self withObject:nil];
}

- (void)_checkThread:(id)object
{
    NSAutoreleasePool *pool;
    NSDate *wakeTime;

    _isChecking = YES;
    pool = [[NSAutoreleasePool alloc] init];
    while (_isChecking) {
        [_parametersLock lock];
        [self _checkTick];
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
        wakeTime = [NSDate dateWithTimeIntervalSinceNow:_interval];
        [_parametersLock unlock];
        [NSThread sleepUntilDate:wakeTime];
    }
    [_parametersLock release];
    _parametersLock = nil;
    [pool release];
}

- (void)_checkTick
{
    NSDictionary *reply, *userInfo = nil;
    NSString *lastUpdate, *name = nil;
    NSTimeInterval newInterval;
    NSNotification *notice;

    NS_DURING
        reply = [_account getReplyForMode:@"checkfriends"
                               parameters:_parameters];
        // Save the lastupdate key if it exists
        lastUpdate = [reply objectForKey:@"lastupdate"];
        if (lastUpdate) {
            [_parameters setObject:lastUpdate forKey:@"lastupdate"];
        }
        // If the friends page has been updated...
        if ([[reply objectForKey:@"new"] intValue] > 0) {
            // ...then stop checking and post a notification
            _isChecking = NO;
            name = LJFriendsPageUpdatedNotification;
        } else {
            // If the server is asking us to slow down...
            newInterval = [[reply objectForKey:@"interval"] doubleValue];
            if (newInterval > _interval) {
                // ...then be a good citizen.
                _interval = newInterval;
                name = LJCheckFriendsIntervalChangedNotification;
            }
        };
    NS_HANDLER
        _isChecking = NO;
        name = LJCheckFriendsErrorNotification;
        userInfo = [NSDictionary dictionaryWithObject:localException
                                               forKey:@"LJException"];
    NS_ENDHANDLER
    if (name) {
        notice = [NSNotification notificationWithName:name object:self
                                             userInfo:userInfo];
        [[NSNotificationCenter defaultCenter]
            performSelectorOnMainThread:@selector(postNotification:)
                             withObject:notice waitUntilDone:NO];
    }
}

- (void)stopChecking
{
    _isChecking = NO;
}

- (BOOL)isChecking
{
    return _isChecking;
}

- (BOOL)openFriendsPage
{
    NSURL *friendURL = [[_account defaultJournal] friendsEntriesHttpURL];
    unsigned int groupMask = [self checkGroupMask];

    if (groupMask != 0) {
        NSString *query = [NSString stringWithFormat:@"?filter=%u", groupMask];
        friendURL = [NSURL URLWithString:query relativeToURL:friendURL];
        friendURL = [friendURL absoluteURL];
    }
    return [[NSWorkspace sharedWorkspace] openURL:friendURL];
}

@end
