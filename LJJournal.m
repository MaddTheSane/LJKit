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

@implementation LJJournal

+ (void)initialize
{
    entrySummaryLength = [@"30" retain];
}

+ (void)setEntrySummaryLength:(int)length
{
    NSParameterAssert(length > 3);
    [entrySummaryLength release];
    entrySummaryLength = [[NSString alloc] initWithFormat:@"%u", length];
}

+ (LJJournal *)_journalWithName:(NSString *)name account:(LJAccount *)account
{
    LJJournal *journal;

    journal = [account journalNamed:name];
    if (journal == nil) {
        journal = [[[LJJournal alloc] initWithName:name account:account] autorelease];
    }
    return journal;
}

+ (NSArray *)_journalArrayFromLoginReply:(NSDictionary *)reply account:(LJAccount *)account
{
    NSMutableArray *array;
    NSString *name;
    LJJournal *journal;
    int count, i;

    count = [[reply objectForKey:@"access_count"] intValue];
    array = [NSMutableArray arrayWithCapacity:(count + 1)];
    // add user's own journal (not part of login reply)
    [array addObject:[account defaultJournal]];
    // add others, if present
    for (i = 1; i <= count; i++) {
        name = [reply objectForKey:[NSString stringWithFormat:@"access_%d", i]];
        journal = [account journalNamed:name];
        if (journal == nil) {
            journal = [self _journalWithName:name account:account];
        }
        [array addObject:journal];
    }
    return array;
}

- (id)initWithName:(NSString *)name account:(LJAccount *)account
{
    self = [super init];
    if (self) {
        NSParameterAssert(name);
        NSParameterAssert(account);
        _name = [name retain];
        _account = account; // Don't retain the account to avoid retain-release cycles
        _isNotDefault = ![_name isEqualToString:[_account username]];
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        _name = [[decoder decodeObjectForKey:@"LJJournalName"] retain];
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

- (NSString *)name
{
    return _name;
}

- (LJAccount *)account
{
    return _account;
}

- (BOOL)isDefault
{
    return !_isNotDefault;
}

- (NSMutableDictionary *)parametersForItemID:(int)itemID
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"one" forKey:@"selecttype"];
    [parameters setObject:[NSString stringWithFormat:@"%d", itemID] forKey:@"itemid"];
    return parameters;
}

- (NSMutableDictionary *)parametersLastN:(int)n beforeDate:(NSDate *)date
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"lastn" forKey:@"selecttype"];
    [parameters setObject:[NSString stringWithFormat:@"%u", n] forKey:@"howmany"];
    if (date) {
        NSString *s = [date descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S"
                                                 timeZone:nil locale:nil];
        [parameters setObject:s forKey:@"beforedate"];
    }
    return parameters;
}

- (NSMutableDictionary *)parametersForDay:(NSDate *)date
{
    NSString *s;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"day" forKey:@"selecttype"];
    s = [date descriptionWithCalendarFormat:@"%Y" timeZone:nil locale:nil];
    [parameters setObject:s forKey:@"year"];
    s = [date descriptionWithCalendarFormat:@"%m" timeZone:nil locale:nil];
    [parameters setObject:s forKey:@"month"];
    s = [date descriptionWithCalendarFormat:@"%d" timeZone:nil locale:nil];
    [parameters setObject:s forKey:@"day"];
    return parameters;
}

- (NSDictionary *)getEventsReplyWithParameters:(NSMutableDictionary *)parameters
{
    [parameters setObject:@"unix" forKey:@"lineendings"];
    if (_isNotDefault) [parameters setObject:_name forKey:@"usejournal"];
    return [_account getReplyForMode:@"getevents" parameters:parameters];
}

- (NSArray *)getEntriesWithParameters:(NSMutableDictionary *)parameters
{
    NSDictionary *reply;
    NSMutableArray *workingArray;
    int count, i;
    
    reply = [self getEventsReplyWithParameters:parameters];
    count = [[reply objectForKey:@"events_count"] intValue];
    workingArray = [NSMutableArray arrayWithCapacity:count];
    for ( i = 1; i <= count; i++ ) {
        NSString *prefix = [[NSString alloc] initWithFormat:@"events_%d_", i];
        LJEntry *entry = [[LJEntry alloc] initWithReply:reply prefix:prefix journal:self];
        [workingArray addObject:entry];
        [entry release];
        [prefix release];
    }
    return workingArray;
}

- (NSArray *)getSummariesWithParameters:(NSMutableDictionary *)parameters
{
    NSDictionary *reply;
    NSMutableArray *workingArray;
    int count, i;

    [parameters setObject:entrySummaryLength forKey:@"truncate"];
    [parameters setObject:@"1" forKey:@"noprops"];
    [parameters setObject:@"1" forKey:@"prefersubject"];
    reply = [self getEventsReplyWithParameters:parameters];
    count = [[reply objectForKey:@"events_count"] intValue];
    workingArray = [NSMutableArray arrayWithCapacity:count];
    for ( i = 1; i <= count; i++ ) {
        NSString *prefix = [[NSString alloc] initWithFormat:@"events_%d_", i];
        LJEntrySummary *summary = [[LJEntrySummary alloc] initWithReply:reply prefix:prefix journal:self];
        [workingArray addObject:summary];
        [summary release];
        [prefix release];
    }
    return workingArray;
}

- (LJEntry *)getEntryForItemID:(int)itemID
{
    NSArray *array = [self getEntriesWithParameters:[self parametersForItemID:itemID]];
    return [array count] == 0 ? nil : [array objectAtIndex:0];
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
    return [array count] == 0 ? nil : [array objectAtIndex:0];
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
    NSDictionary *parameters = nil, *reply = nil;
    NSMutableDictionary *workingCounts;
    NSEnumerator *enumerator;
    NSString *key;

    if (_isNotDefault) {
        parameters = [NSDictionary dictionaryWithObject:_name forKey:@"usejournal"];
    }
    reply = [_account getReplyForMode:@"getdaycounts" parameters:parameters];
    workingCounts = [NSMutableDictionary dictionary];
    enumerator = [reply keyEnumerator];
    while (key = [enumerator nextObject]) {
        NSCalendarDate *date = [[NSCalendarDate alloc] initWithString:key calendarFormat:@"%Y-%m-%d"];
        if (date) {
            int c = [[reply objectForKey:key] intValue];
            [workingCounts setObject:[NSNumber numberWithInt:c] forKey:date];
            [date release];
        }
    }
    return workingCounts;
}

- (unsigned)hash
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

- (NSMutableArray *)tags
{
    return _tags;
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
    [parameters setObject:@"unix" forKey:@"lineendings"];
    if (_isNotDefault) [parameters setObject:_name forKey:@"usejournal"];
    return [_account getReplyForMode:@"getusertags" parameters:parameters];
}

- (int)createJournalTagsArray:(NSDictionary *)reply
{
    int count, i;
    NSString *key, *tagName;
	
    count = [[reply objectForKey:@"tag_count"] intValue];
    NSMutableArray *tagArray = [[NSMutableArray alloc] initWithCapacity:count];
    for (i = 1; i <= count; i++) {
        key = [NSString stringWithFormat:@"tag_%d_name", i];
        tagName = [reply objectForKey:key];
        [tagArray addObject:tagName];
    }
	_tags = [(NSMutableArray *)[tagArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] copy];
	[tagArray release];
	NSLog(@"Found %d tag%s for journal %@", count, (count == 1 ? "" : "s"), [self name]);
	return count;
}

@end
