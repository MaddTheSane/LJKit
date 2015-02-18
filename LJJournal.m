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
 2004-03-01 [BPR] Simplified implementation of getMostRecentEntry
 */

#import "LJAccount.h"
#import "LJEntry_Private.h"
#import "LJJournal_Private.h"
#import "Miscellaneous.h"
#import "URLEncoding.h"

static NSString *entrySummaryLength = nil;

@interface LJJournal ()
- (instancetype)initWithName:(NSString *)name account:(LJAccount *)account NS_DESIGNATED_INITIALIZER;
@end

@implementation LJJournal
{
@private
    BOOL _isNotDefault;
}

+ (void)initialize
{
    entrySummaryLength = @"30";
}

+ (void)setEntrySummaryLength:(int)length
{
    NSParameterAssert(length > 3);
    entrySummaryLength = [[NSString alloc] initWithFormat:@"%u", length];
}

+ (LJJournal *)_journalWithName:(NSString *)name account:(LJAccount *)account
{
    LJJournal *journal;

    journal = [account journalNamed:name];
    if (journal == nil) {
        journal = [[LJJournal alloc] initWithName:name account:account];
    }
    return journal;
}

+ (NSArray *)_journalArrayFromLoginReply:(NSDictionary *)reply account:(LJAccount *)account
{
    NSInteger count = [reply[@"access_count"] integerValue];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:(count + 1)];
    // add user's own journal (not part of login reply)
    [array addObject:[account defaultJournal]];
    // add others, if present
    for (NSInteger i = 1; i <= count; i++) {
        NSString *name = reply[[NSString stringWithFormat:@"access_%ld", (long)i]];
        LJJournal *journal = [account journalNamed:name];
        if (journal == nil) {
            journal = [self _journalWithName:name account:account];
        }
        [array addObject:journal];
    }
    return [array copy];
}

- (instancetype)initWithName:(NSString *)name account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(name);
        NSParameterAssert(account);
        _name = [name copy];
        _account = account; // Don't retain the account to avoid retain-release cycles
        _isNotDefault = ![_name isEqualToString:[_account username]];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _name = [decoder decodeObjectForKey:@"LJJournalName"];
        _account = [decoder decodeObjectForKey:@"LJJournalAccount"];
        NSAssert(_account != nil, @"LJJournal decoded without an account object.");
        _isNotDefault = ![_name isEqualToString:[_account username]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_name forKey:@"LJJournalName"];
    [encoder encodeConditionalObject:_account forKey:@"LJJournalAccount"];
}

- (BOOL)isDefault
{
    return !_isNotDefault;
}

- (NSMutableDictionary *)parametersForItemID:(int)itemID
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"selecttype"] = @"one";
    parameters[@"itemid"] = [NSString stringWithFormat:@"%d", itemID];
    return parameters;
}

- (NSMutableDictionary *)parametersLastN:(int)n beforeDate:(NSDate *)date
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"selecttype"] = @"lastn";
    parameters[@"howmany"] = [NSString stringWithFormat:@"%u", n];
    if (date) {
        NSDateFormatter *df = [NSDateFormatter new];
        df.dateFormat = @"%Y-%m-%d %H:%M:%S";
        
        NSString *s = [df stringFromDate:date];
        parameters[@"beforedate"] = s;
    }
    return parameters;
}

- (NSMutableDictionary *)parametersForDay:(NSDate *)date
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"selecttype"] = @"day";
#define ourUnits NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay 
    NSCalendar *gregCalendar = [NSCalendar calendarWithIdentifier:NSGregorianCalendar];
    NSDateComponents *comps = [gregCalendar components:ourUnits fromDate:date];
    parameters[@"year"] = [@(comps.year) stringValue];
    parameters[@"month"] = [@(comps.month) stringValue];
    parameters[@"day"] = [@(comps.day) stringValue];

    return parameters;
}

- (NSDictionary *)getEventsReplyWithParameters:(NSMutableDictionary *)parameters
{
    parameters[@"lineendings"] = @"unix";
    if (_isNotDefault) parameters[@"usejournal"] = _name;
    return [_account getReplyForMode:@"getevents" parameters:parameters];
}

- (NSArray *)getEntriesWithParameters:(NSMutableDictionary *)parameters
{
    NSDictionary *reply;
    NSMutableArray *workingArray;
    NSInteger count, i;
    
    reply = [self getEventsReplyWithParameters:parameters];
    count = [reply[@"events_count"] integerValue];
    workingArray = [NSMutableArray arrayWithCapacity:count];
    for ( i = 1; i <= count; i++ ) {
        NSString *prefix = [[NSString alloc] initWithFormat:@"events_%ld_", (long)i];
        LJEntry *entry = [[LJEntry alloc] initWithReply:reply prefix:prefix journal:self];
        [workingArray addObject:entry];
    }
    return workingArray;
}

- (NSArray *)getSummariesWithParameters:(NSMutableDictionary *)parameters
{
    NSDictionary *reply;
    NSMutableArray *workingArray;
    NSInteger count, i;

    parameters[@"truncate"] = entrySummaryLength;
    parameters[@"noprops"] = @"1";
    parameters[@"prefersubject"] = @"1";
    reply = [self getEventsReplyWithParameters:parameters];
    count = [reply[@"events_count"] integerValue];
    workingArray = [NSMutableArray arrayWithCapacity:count];
    for ( i = 1; i <= count; i++ ) {
        NSString *prefix = [[NSString alloc] initWithFormat:@"events_%ld_", (long)i];
        LJEntrySummary *summary = [[LJEntrySummary alloc] initWithReply:reply prefix:prefix journal:self];
        [workingArray addObject:summary];
    }
    return workingArray;
}

- (LJEntry *)getEntryForItemID:(int)itemID
{
    NSArray *array = [self getEntriesWithParameters:[self parametersForItemID:itemID]];
    return [array count] == 0 ? nil : array[0];
}

- (LJEntry *)getMostRecentEntry
{
    return [self getEntryForItemID:-1];
}

- (NSArray *)getEntriesLastN:(int)n beforeDate:(NSDate *)date
{
    return [self getEntriesWithParameters:[self parametersLastN:n beforeDate:date]];
}

- (NSArray *)getEntriesLastN:(int)n
{
    return [self getEntriesWithParameters:[self parametersLastN:n beforeDate:nil]];
}

- (NSArray *)getEntriesForDay:(NSDate *)date
{
    return [self getEntriesWithParameters:[self parametersForDay:date]];
}

- (LJEntrySummary *)getSummaryForItemID:(int)itemID
{
    NSArray *array = [self getSummariesWithParameters:[self parametersForItemID:itemID]];
    return [array count] == 0 ? nil : array[0];
}

- (NSArray *)getSummariesLastN:(int)n beforeDate:(NSDate *)date
{
    return [self getSummariesWithParameters:[self parametersLastN:n beforeDate:date]];
}

- (NSArray *)getSummariesLastN:(int)n
{
    return [self getSummariesWithParameters:[self parametersLastN:n beforeDate:nil]];
}

- (NSArray *)getSummariesForDay:(NSDate *)date
{
    return [self getSummariesWithParameters:[self parametersForDay:date]];
}

- (NSDictionary *)getDayCounts
{
    NSDictionary *parameters;
    NSMutableDictionary *workingCounts = [[NSMutableDictionary alloc] init];

    if (_isNotDefault) {
        parameters = @{@"usejournal": _name};
    }
    NSDictionary *reply = [_account getReplyForMode:@"getdaycounts" parameters:parameters];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    //df.timeStyle = NSDateFormatterNoStyle;
    //df.dateStyle = NSDateFormatterMediumStyle;
    df.dateFormat = @"%Y-%M-%d";
    for (NSString *key in reply) {
        NSDate *date = [df dateFromString:key];
        if (date) {
            NSInteger c = [reply[key] integerValue];
            workingCounts[date] = @(c);
        }
    }
    return [NSDictionary dictionaryWithDictionary: workingCounts];
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NSString class]])
        return [_name isEqualToString:object];
    if ([object isKindOfClass:[LJJournal class]])
        return ([_name isEqualToString:[object name]] &&
                (_account == [(LJJournal *)object account]));
    return NO;
}

- (NSString *)description
{
    return _name;
}

- (void) updateTagsArray:(NSString *)newTag
{
	if ([_tags indexOfObject:newTag] != NSNotFound) {
		[_tags addObject:newTag];
	}
}

- (NSDictionary *)getTagsReplyForThisJournal
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"lineendings"] = @"unix";
    if (_isNotDefault) parameters[@"usejournal"] = _name;
    return [_account getReplyForMode:@"getusertags" parameters:parameters];
}

- (NSInteger)createJournalTagsArray:(NSDictionary *)reply
{
    NSInteger count, i;
    NSString *key, *tagName;
	
    count = [reply[@"tag_count"] integerValue];
    NSMutableArray *tagArray = [[NSMutableArray alloc] initWithCapacity:count];
    for (i = 1; i <= count; i++) {
        key = [NSString stringWithFormat:@"tag_%ld_name", (long)i];
        tagName = reply[key];
        [tagArray addObject:tagName];
    }
	_tags = [[tagArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
	NSLog(@"Found %ld tag%s for journal %@", (long)count, (count == 1 ? "" : "s"), [self name]);
	return count;
}

@end
