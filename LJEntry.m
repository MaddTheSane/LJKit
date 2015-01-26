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
 2004-03-13 [BPR] Added setAccount:
 */

#import "LJEntry_Private.h"
#import "LJJournal.h"
#import "LJGroup.h"
#import "Miscellaneous.h"
#import "URLEncoding.h"
#import "LJAccount.h"
#import "LJAccount_EditFriends.h"
#import "LJMoods.h"

NSString * const LJEntryWillSaveToJournalNotification =
@"LJEntryWillSaveToJournal";
NSString * const LJEntryDidSaveToJournalNotification =
@"LJEntryDidSaveToJournal";
NSString * const LJEntryDidNotSaveToJournalNotification =
@"LJEntryDidNotSaveToJournal";

@interface LJEntry ()
- (instancetype)initWithReply:(NSDictionary *)info prefix:(NSString *)prefix journal:(LJJournal *)journal NS_DESIGNATED_INITIALIZER;

@end

@implementation LJEntry
@synthesize edited = _isEdited;
@synthesize subject = _subject;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _date = [[NSDate alloc] init];
        _properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithReply:(NSDictionary *)info prefix:(NSString *)prefix journal:(LJJournal *)journal
{
    self = [super initWithReply:info prefix:prefix journal:journal];
    if (self) {
        _subject = info[[prefix stringByAppendingString:@"subject"]];
        /*
         Parse Entry Metadata

         Unlike the other data, which has keys of the form event_n_something,
         LiveJournal sends metadata in a series of three keys: prop_n_itemid,
         prop_n_name, and prop_n_value.  Thus, we must work backwards.  We use
         allKeysForObject: with the entry's itemID.  Most keys will be of the
         form prop_n_itemid.  We parse out the n using NSScanner to find the
         property name and value, and place the pair in the _properties dictionary.
         */
        _properties = [[NSMutableDictionary alloc] init];
        if (info[@"prop_count"]) {
            NSScanner *scanner;
            NSString *infoKey, *propName, *propValue;
            int propIndex;
            NSArray *infoKeys;
            NSEnumerator *enumerator;

            infoKeys = [info allKeysForObject:[NSString stringWithFormat:@"%u", _itemID]];
            enumerator = [infoKeys objectEnumerator];
            while (infoKey = [enumerator nextObject]) {
                scanner = [[NSScanner alloc] initWithString:infoKey];
                if ([scanner scanString:@"prop_" intoString:nil] &&
                    [scanner scanInt:&propIndex] &&
                    [scanner scanString:@"_itemid" intoString:nil])
                {
                    propName = [NSString stringWithFormat:@"prop_%d_name", propIndex];
                    propValue = [NSString stringWithFormat:@"prop_%d_value", propIndex];
                    _properties[info[propName]] = info[propValue];
                }
            }
        }
		if (_properties[@"current_moodid"] != nil) {
			// Save Mood Name for this ID
			NSString *moodName = [[[_journal account] moods] MoodNameFromID: _properties[@"current_moodid"]];
			if (moodName != nil ) {
				_properties[@"current_mood_id_name"] = moodName;
			}
		}
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (self) {
        _subject = [decoder decodeObjectForKey:@"LJEntrySubject"];
        _properties = [[decoder decodeObjectForKey:@"LJEntryProperties"] mutableCopy];
        _customInfo = [[decoder decodeObjectForKey:@"LJEntryCustomInfo"] mutableCopy];
        _isEdited = [decoder decodeBoolForKey:@"LJEntryIsEdited"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:_subject forKey:@"LJEntrySubject"];
    [encoder encodeObject:_properties forKey:@"LJEntryProperties"];
    [encoder encodeBool:_isEdited forKey:@"LJEntryIsEdited"];
    if ([_customInfo count] > 0) {
        [encoder encodeObject:_customInfo forKey:@"LJEntryCustomInfo"];
    }
}

- (void)setJournal:(LJJournal *)journal
{
    NSAssert(_itemID == 0, @"Cannot change the journal of a posted entry. "
             @"Remove from journal first.");
    if (![_account isEqual:[journal account]]) {
		_account = journal.account;
        // If we have changed accounts, clear the allowMask, because the
        // groups are not the same.
        _allowGroupMask = 0;
    }
    if (![_journal isEqual:journal]) {
		_journal = journal;
        _isEdited = YES;
    }
}

- (void)setAccount:(LJAccount *)account
{
    if ([_journal account] != account) {
        [self setJournal:[account defaultJournal]];
    }
}

- (void)setDate:(NSDate *)date
{
	if (![_date isEqualToDate:date]) {
		_date = date;
		self.edited = YES;
	}
}

- (void)setSubject:(NSString *)subject
{
	if (![_subject isEqualToString:subject]) {
		_subject = [subject copy];
		self.edited = YES;
	}
}

- (NSString *)content
{
    return _content ? _content : @"";
}

- (void)setContent:(NSString *)content
{
	if (![_content isEqualToString:content]) {
		_content = [content copy];
		self.edited = YES;
	}
}

- (LJSecurityMode)securityMode
{
    return _security;
}

- (void)setSecurityMode:(LJSecurityMode)security
{
    if (_security == LJSecurityModeGroup)
        NSAssert(_journal != nil, (@"Cannot set LJSecurityModeGroup without "
                                   @"associating entry with a journal."));
    // check for proper input
    _security = security;
    _allowGroupMask = 0;
    self.edited = YES;
}

- (void)setAccessAllowed:(BOOL)allowed forGroup:(LJGroup *)group
{
    NSAssert(_journal != nil, (@"Cannot use group security methods with "
                               @"unassociated entries."));
    NSAssert(_security == LJSecurityModeGroup, @"Entry security must be "
             @"LJGroupSecurity to allow/deny access by a group.");
    if (allowed) {
        _allowGroupMask |= [group mask];
    } else {
        _allowGroupMask &= ~[group mask];
    }
    self.edited = YES;
}

- (void)setGroupsAllowedAccessMask:(unsigned int)mask
{
    if (_allowGroupMask != mask) {
        _allowGroupMask = mask;
        self.edited = YES;
    }
}

- (void)saveToJournal
{
    NSMutableDictionary *request;
    NSDictionary *reply, *info;
    NSString *mode, *propertyKey, *moodName, *moodID, *s;
    NSEnumerator *propertyKeys;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    NSAssert(_journal != nil, (@"Must set a journal before attempting to save entry."));
    [center postNotificationName:LJEntryWillSaveToJournalNotification
                          object:self];
    // Compile the request to be sent to the server
    request = [NSMutableDictionary dictionaryWithCapacity:20];
    if (![_journal isDefault]) {
        request[@"usejournal"] = [_journal name];
    }
    if (_itemID == 0) {
        mode = @"postevent";
    } else {
        mode = @"editevent";
        request[@"itemid"] = [NSString stringWithFormat:@"%u", _itemID];
    }
    if (_subject) request[@"subject"] = _subject;
    if (_content) request[@"event"] = _content;
    if (_date) {
        s = [_date descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:nil];
        request[@"year"] = s;
        s = [_date descriptionWithCalendarFormat:@"%m" timeZone:nil locale:nil];
        request[@"mon"] = s;
        s = [_date descriptionWithCalendarFormat:@"%d" timeZone:nil locale:nil];
        request[@"day"] = s;
        s = [_date descriptionWithCalendarFormat:@"%H" timeZone:nil locale:nil];
        request[@"hour"] = s;
        s = [_date descriptionWithCalendarFormat:@"%M" timeZone:nil locale:nil];
        request[@"min"] = s;
    }
    switch (_security) {
        case LJSecurityModePublic:
            request[@"security"] = @"public";
            break;
        case LJSecurityModePrivate:
            request[@"security"] = @"private";
            break;
        case LJSecurityModeFriend:
            request[@"security"] = @"usemask";
            request[@"allowmask"] = @"1";
            break;
        case LJSecurityModeGroup:
            request[@"security"] = @"usemask";
            s = [NSString stringWithFormat:@"%u", _allowGroupMask];
            request[@"allowmask"] = s;
            break;
    }
    // If current mood is set, check the moods object for the account and set
    // the mood ID automatically.  Doing it this way makes it impossible to
    // have a conflicting mood name and ID --- but we assume nobody would want that.
    // We can't do this in the setCurrentMood: method because the entry's journal
    // may not be set, or may change afterwards.
	// This has been split out now. The mood name *can* be different from the ID.
    moodName = (NSString *)_properties[@"current_mood_id_name"];
    if (moodName) {
        moodID = [[[_journal account] moods] IDStringForMoodName:moodName];
    } else {
        moodID = nil;
    }
    if (moodID) {
        _properties[@"current_moodid"] = moodID;
    } else {
        [_properties removeObjectForKey:@"current_moodid"];
    }
	[_properties removeObjectForKey:@"current_mood_id_name"]; // Never sent to the server
    // properties: must prefix "prop_" before keys
    propertyKeys = [_properties keyEnumerator];
    while (propertyKey = [propertyKeys nextObject]) {
        request[[@"prop_" stringByAppendingString:propertyKey]] = _properties[propertyKey];
    }
    request[@"lineendings"] = @"unix";
    // Send to the server
    @try {
        reply = [[_journal account] getReplyForMode:mode parameters:request];
    } @catch (NSException *localException) {
        info = @{@"LJException": localException};
        [center postNotificationName:LJEntryDidNotSaveToJournalNotification
                              object:self userInfo:info];
        [localException raise];
    }
    // Handle reply
    if (_itemID == 0) {
        _itemID = [reply[@"itemid"] intValue];
        _aNum = [reply[@"anum"] intValue];
    }
    [center postNotificationName:LJEntryDidSaveToJournalNotification
                          object:self];
    _isEdited = NO;
}

- (void)removeFromJournal
{
    [super removeFromJournal];
    self.edited = YES;
}

- (NSMutableDictionary *)customInfo
{
    if (_customInfo == nil) _customInfo = [[NSMutableDictionary alloc] init];
    return _customInfo;
}

@end
