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

@implementation LJEntryRoot

- (id)initWithReply:(NSDictionary *)info prefix:(NSString *)prefix
            journal:(LJJournal *)journal
{
    self = [super init];
    if (self) {
        id obj;

        // LJJournal does not retain its parent LJAccount.  We need the account
        // to stick around, though, so we must get a reference to the account
        // and retain it ourselves.
        _account = [[journal account] retain];
        _journal = [journal retain];
        obj = [info objectForKey:[prefix stringByAppendingString:@"itemid"]];
        _itemID = [obj intValue];
        obj = [info objectForKey:[prefix stringByAppendingString:@"anum"]];
        _aNum = [obj intValue];
        obj = [info objectForKey:[prefix stringByAppendingString:@"event"]];
        _content = LJURLDecodeString(obj);
        [_content retain];
        obj = [info objectForKey:[prefix stringByAppendingString:@"poster"]];
        _posterUsername = [obj retain];
        obj = [info objectForKey:[prefix stringByAppendingString:@"allowmask"]];
        _allowGroupMask = [obj intValue];
        obj = [info objectForKey:[prefix stringByAppendingString:@"security"]];
        if (obj == nil || [obj isEqualToString:@"public"]) {
            _security = LJPublicSecurityMode;
        } else if ([obj isEqualToString:@"private"]) {
            _security = LJPrivateSecurityMode;
        } else if ([obj isEqualToString:@"usemask"]) {
            _security = ((_allowGroupMask == 1) ? LJFriendSecurityMode
                                                : LJGroupSecurityMode);
        } else {
            NSAssert1(NO, @"Unknown entry security mode: %@", obj);
        }
        // parse the date
        obj = [info objectForKey:[prefix stringByAppendingString:@"eventtime"]];
        _date = [[NSCalendarDate alloc] initWithString:obj
                                        calendarFormat:@"%Y-%m-%d %H:%M:%S"];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        id obj;

        obj = [decoder decodeObjectForKey:@"LJEntryAccountIdentifier"];
        _account = [[LJAccount accountWithIdentifier:obj] retain];
        obj = [decoder decodeObjectForKey:@"LJEntryJournalName"];
        _journal = [[_account journalNamed:obj] retain];
        _itemID = [decoder decodeIntForKey:@"LJEntryItemID"];
        _aNum = [decoder decodeIntForKey:@"LJEntryANum"];
        _date = [[decoder decodeObjectForKey:@"LJEntryDate"] retain];
        _content = [[decoder decodeObjectForKey:@"LJEntryContent"] retain];
        obj = [decoder decodeObjectForKey:@"LJEntryPosterUsername"];
        _posterUsername = [obj retain];
        _security = [decoder decodeIntForKey:@"LJEntrySecurityMode"];
        _allowGroupMask = [decoder decodeInt32ForKey:@"LJEntryGroupMask"];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    [self dealloc];
    return [[NSKeyedUnarchiver unarchiveObjectWithFile:path] retain];
}

- (void)dealloc
{
    [_account release];
    [_journal release];
    [_date release];
    [_posterUsername release];
    [_content release];
    [super dealloc];
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

- (LJJournal *)journal
{
    return _journal;
}

- (NSString *)posterUsername
{
    return _posterUsername;
}

- (int)itemID
{
    return _itemID;
}

- (NSDate *)date
{
    return _date;
}

- (int)securityMode
{
    return _security;
}

- (BOOL)accessAllowedForGroup:(LJGroup *)group
{
    NSAssert(_journal != nil, (@"Cannot use group security methods with "
                               @"unassociated entries."));
    switch (_security) {
        case LJPublicSecurityMode: return YES;
        case LJPrivateSecurityMode: return NO;
        case LJFriendSecurityMode: return YES;
        case LJGroupSecurityMode: return (_allowGroupMask & [group mask]) != 0;
    }
    return NO;
}

- (unsigned int)groupsAllowedAccessMask
{
    return _allowGroupMask;
}

- (NSArray *)groupsAllowedAccessArray
{
    NSAssert(_journal != nil, @"Cannot use group security methods with unassociated entries.");
    if (_security == LJPublicSecurityMode || _security == LJFriendSecurityMode)
        return [[_journal account] groupArray];
    if (_security == LJPrivateSecurityMode)
        return [NSArray array];
    if (_security == LJGroupSecurityMode) {
        LJGroup *group;
        NSMutableArray *array;
        NSEnumerator *groupEnumerator;

        if (_allowGroupMask == 0) return [NSArray array];
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
    [request setObject:@"" forKey:@"event"];
    [request setObject:[NSString stringWithFormat:@"%u", _itemID] forKey:@"itemid"];
    if (![_journal isDefault]) {
        [request setObject:[_journal name] forKey:@"usejournal"];
    }
    // Send to the server
    NS_DURING
        [[_journal account] getReplyForMode:@"editevent" parameters:request];
    NS_HANDLER
        info = [NSDictionary dictionaryWithObject:localException forKey:@"LJException"];
        [center postNotificationName:LJEntryDidNotRemoveFromJournalNotification 
                              object:self userInfo:info];
        [localException raise];
    NS_ENDHANDLER
    _itemID = 0;
    _aNum = 0;
    [center postNotificationName:LJEntryDidRemoveFromJournalNotification object:self];
}

@end
