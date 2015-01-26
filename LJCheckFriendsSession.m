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

#define kCheckFriendsSessionAccount @"LJCheckFriendsSessionAccount"
#define kCheckFriendsSessionInterval @"LJCheckFriendsSessionInterval"
#define kCheckFriendsSessionParameters @"LJCheckFriendsSessionParameters"

@interface LJCheckFriendsSession ()
- (void)_checkThread:(id)object;
- (void)_checkTick;
@end

@implementation LJCheckFriendsSession
{
    NSLock *_parametersLock;
    NSMutableDictionary *_parameters;
}
@synthesize checking = _isChecking;

- (instancetype)initWithAccount:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(account);
        _account = account;
        _interval = 300; // five minute default
        _parameters = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _account = [decoder decodeObjectForKey:kCheckFriendsSessionAccount];
        _interval = [decoder decodeDoubleForKey:kCheckFriendsSessionInterval];
        _parameters = [[decoder decodeObjectForKey:kCheckFriendsSessionParameters] mutableCopy];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeConditionalObject:_account forKey:kCheckFriendsSessionAccount];
    [encoder encodeDouble:_interval forKey:kCheckFriendsSessionInterval];
    [encoder encodeObject:_parameters forKey:kCheckFriendsSessionParameters];
}

- (unsigned int)checkGroupMask
{
    return [_parameters[@"mask"] intValue];
}

- (void)setCheckGroupMask:(unsigned int)mask
{
    [_parametersLock lock];
    if (mask) {
        NSString *maskString = [NSString stringWithFormat:@"%u", mask];
        _parameters[@"mask"] = maskString;
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
	@autoreleasepool {
    NSDate *wakeTime;

    _isChecking = YES;
    while (_isChecking) {
        [_parametersLock lock];
        [self _checkTick];
        wakeTime = [NSDate dateWithTimeIntervalSinceNow:_interval];
        [_parametersLock unlock];
        [NSThread sleepUntilDate:wakeTime];
    }
    _parametersLock = nil;
	}
}

- (void)_checkTick
{
    NSDictionary *reply, *userInfo = nil;
    NSString *lastUpdate, *name = nil;
    NSTimeInterval newInterval;
    NSNotification *notice;

    @try {
        reply = [_account getReplyForMode:@"checkfriends"
                               parameters:_parameters];
        // Save the lastupdate key if it exists
        lastUpdate = reply[@"lastupdate"];
        if (lastUpdate) {
            _parameters[@"lastupdate"] = lastUpdate;
        }
        // If the friends page has been updated...
        if ([reply[@"new"] intValue] > 0) {
            // ...then stop checking and post a notification
            _isChecking = NO;
            name = LJFriendsPageUpdatedNotification;
        } else {
            // If the server is asking us to slow down...
            newInterval = [reply[@"interval"] doubleValue];
            if (newInterval > _interval) {
                // ...then be a good citizen.
                _interval = newInterval;
                name = LJCheckFriendsIntervalChangedNotification;
            }
        };
    } @catch (NSException *localException) {
        _isChecking = NO;
        name = LJCheckFriendsErrorNotification;
        userInfo = @{@"LJException": localException};
    }
    if (name) {
        notice = [NSNotification notificationWithName:name object:self
                                             userInfo:userInfo];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:notice];
        });
    }
}

- (void)stopChecking
{
    _isChecking = NO;
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
