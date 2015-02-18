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
 2004-03-13 [BPR] Added account method.
 */

#import "LJEntryRoot.h"
#import "LJJournal.h"
#import "LJAccount.h"
#import "LJAccount_EditFriends.h"
#import "LJGroup.h"
#import "URLEncoding.h"
#import "Miscellaneous.h"

NSString * const LJEntryWillRemoveFromJournalNotification =
@"LJEntryWillRemoveFromJournal";
NSString * const LJEntryDidRemoveFromJournalNotification =
@"LJEntryDidRemoveFromJournal";
NSString * const LJEntryDidNotRemoveFromJournalNotification =
@"LJEntryDidNotRemoveFromJournal";

@interface LJEntryRoot ()
@property (NS_NONATOMIC_IOSONLY, readwrite, setter=_setSecurityMode:) LJSecurityMode securityMode;
@end

@implementation LJEntryRoot
@synthesize posterUsername = _posterUsername;
@synthesize itemID = _itemID;
@synthesize date = _date;
@synthesize securityMode = _security;
@synthesize journal = _journal;

- (instancetype)initWithReply:(NSDictionary *)info prefix:(NSString *)prefix
            journal:(LJJournal *)journal
{
    self = [super init];
    if (self) {
        id obj;

        // LJJournal does not retain its parent LJAccount.  We need the account
        // to stick around, though, so we must get a reference to the account
        // and retain it ourselves.
        _account = [journal account];
        _journal = journal;
        obj = info[[prefix stringByAppendingString:@"itemid"]];
        _itemID = [obj intValue];
        obj = info[[prefix stringByAppendingString:@"anum"]];
        _aNum = [obj intValue];
        obj = info[[prefix stringByAppendingString:@"event"]];
        _content = LJURLDecodeString(obj);
        obj = info[[prefix stringByAppendingString:@"poster"]];
        _posterUsername = obj;
        obj = info[[prefix stringByAppendingString:@"allowmask"]];
        _allowGroupMask = [obj intValue];
        obj = info[[prefix stringByAppendingString:@"security"]];
        if (obj == nil || [obj isEqualToString:@"public"]) {
            [self _setSecurityMode:LJSecurityModePublic];
        } else if ([obj isEqualToString:@"private"]) {
            [self _setSecurityMode:LJSecurityModePrivate];
        } else if ([obj isEqualToString:@"usemask"]) {
            [self _setSecurityMode:(_allowGroupMask == 1) ? LJSecurityModeFriend
                                                          : LJSecurityModeGroup];
        } else {
            NSAssert1(NO, @"Unknown entry security mode: %@", obj);
        }
        // parse the date
        obj = info[[prefix stringByAppendingString:@"eventtime"]];
        NSDateFormatter *df = [NSDateFormatter new];
        df.dateFormat = @"%Y-%m-%d %H:%M:%S";
        _date = [df dateFromString:obj];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        id obj;

        obj = [decoder decodeObjectForKey:@"LJEntryAccountIdentifier"];
        _account = [LJAccount accountWithIdentifier:obj];
        obj = [decoder decodeObjectForKey:@"LJEntryJournalName"];
        _journal = [_account journalNamed:obj];
        _itemID = [decoder decodeIntForKey:@"LJEntryItemID"];
        _aNum = [decoder decodeIntForKey:@"LJEntryANum"];
        _date = [decoder decodeObjectForKey:@"LJEntryDate"];
        _content = [decoder decodeObjectForKey:@"LJEntryContent"];
        obj = [decoder decodeObjectForKey:@"LJEntryPosterUsername"];
        _posterUsername = obj;
        _security = [decoder decodeIntForKey:@"LJEntrySecurityMode"];
        _allowGroupMask = [decoder decodeInt32ForKey:@"LJEntryGroupMask"];
    }
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)path
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    id obj;

    obj = [LJKitBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    [encoder encodeObject:obj forKey:@"LJKitVersion"];
    obj = [[_journal account] identifier];
    [encoder encodeObject:obj forKey:@"LJEntryAccountIdentifier"];
    [encoder encodeObject:[_journal name] forKey:@"LJEntryJournalName"];
    [encoder encodeInt:_itemID forKey:@"LJEntryItemID"];
    [encoder encodeInt:_aNum forKey:@"LJEntryANum"];
    [encoder encodeObject:_date forKey:@"LJEntryDate"];
    [encoder encodeObject:_content forKey:@"LJEntryContent"];
    [encoder encodeObject:_posterUsername forKey:@"LJEntryPosterUsername"];
    [encoder encodeInt:_security forKey:@"LJEntrySecurityMode"];
    [encoder encodeInt32:_allowGroupMask forKey:@"LJEntryGroupMask"];
}

- (BOOL)writeToFile:(NSString *)path
{
    return [NSKeyedArchiver archiveRootObject:self toFile:path];
}

- (LJAccount *)account
{
    return [_journal account];
}


- (BOOL)accessAllowedForGroup:(LJGroup *)group
{
    NSAssert(_journal != nil, (@"Cannot use group security methods with "
                               @"unassociated entries."));
    switch (_security) {
        case LJSecurityModePublic: return YES;
        case LJSecurityModePrivate: return NO;
        case LJSecurityModeFriend: return YES;
        case LJSecurityModeGroup: return (_allowGroupMask & [group mask]) != 0;
    }
    return NO;
}

- (unsigned int)groupsAllowedAccessMask
{
    return _allowGroupMask;
}

- (NSArray *)groupsAllowedAccessArray
{
    //NSAssert(_journal != nil, @"Cannot use group security methods with unassociated entries.");
    if (_journal == nil) return nil;
    if (_security == LJSecurityModePublic || _security == LJSecurityModeFriend)
        return [[_journal account] groupArray];
    if (_security == LJSecurityModePrivate)
        return @[];
    if (_security == LJSecurityModeGroup) {
        LJGroup *group;
        NSMutableArray *array;
        NSEnumerator *groupEnumerator;

        if (_allowGroupMask == 0) return @[];
        groupEnumerator = [[[_journal account] groupSet] objectEnumerator];
        array = [NSMutableArray arrayWithCapacity:8];
        while (group = [groupEnumerator nextObject]) {
            if ((_allowGroupMask & [group mask]) != 0) [array addObject:group];
        }
        return array;
    }
    return nil;
}

- (NSSet *)groupsAllowedAccessSet
{
    return [NSSet setWithArray:[self groupsAllowedAccessArray]];
}

- (void)removeFromJournal
{
    NSMutableDictionary *request;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSDictionary *info;
    
    NSAssert(_itemID != 0, @"Cannot remove a journal entry that has never been saved.");
    [center postNotificationName:LJEntryWillRemoveFromJournalNotification object:self];
    // Compile the request to be sent to the server
    request = [NSMutableDictionary dictionaryWithCapacity:3];
    request[@"event"] = @"";
    request[@"itemid"] = [NSString stringWithFormat:@"%u", _itemID];
    if (![_journal isDefault]) {
        request[@"usejournal"] = [_journal name];
    }
    // Send to the server
    @try {
        [[_journal account] getReplyForMode:@"editevent" parameters:request];
    } @catch (NSException *localException) {
        info = @{@"LJException": localException};
        [center postNotificationName:LJEntryDidNotRemoveFromJournalNotification 
                              object:self userInfo:info];
        [localException raise];
    }
    _itemID = 0;
    _aNum = 0;
    [center postNotificationName:LJEntryDidRemoveFromJournalNotification object:self];
}

@end
