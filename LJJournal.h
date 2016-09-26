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

#import <Foundation/Foundation.h>

@class LJAccount, LJEntry, LJEntrySummary;

NS_ASSUME_NONNULL_BEGIN

/*!
 @class LJJournal
 @abstract A journal object.
 @discussion
 An LJJournal object allows access to the entries stored in that journal.
 You do not create instances of this class; rather, you get instances from
 the [LJAccount journals] method.
 The getEntry... methods will return LJEntry objects.
 The getSummary... methods will return LJEntrySummary objects.
 */
@interface LJJournal : NSObject <NSCoding>
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;

/*!
 @method setEntrySummaryLength:
 @param length The length of summary strings.
 @discussion
 This method allows you to choose the length of the summary string returned by
 the getSummaries... methods.
 */
+ (void)setEntrySummaryLength:(int)length;

/*!
 @property account
 @abstract The account the receiver belongs to.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, weak) LJAccount *account;

/*!
 @property name
 @abstract The name of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *name;

/*!
 @property isDefault
 @abstract Determine if the receiver is the default journal for its account.
 @discussion
 The default journal is the journal with the same name as the account's username.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL isDefault;

/*!
 @method getEntryForItemID:
 @param itemID The itemID of the desired entry.
 @discussion
 If an entry's itemID is known, you can retrieve it directly with this method.
 Note that the itemID is different from the itemID which appears on the web.
 @result The desired LJEntry object if found, nil otherwise.
 */
- (LJEntry *)getEntryForItemID:(int)itemID;

/*!
 @property mostRecentEntry
 @discussion
 This method returns the most recent entry posted to the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, getter=getMostRecentEntry, readonly, strong) LJEntry *mostRecentEntry;

/*!
 @method getEntriesLastN:beforeDate:
 @abstract Obtain an array of the n most recent entries.
 @param n The number of entries to download.
 @param date Retrieve entries posted before this date.
 @result An array of LJEntry objects.
 */
- (NSArray<LJEntry*> *)getEntriesLastN:(int)n beforeDate:(NSDate *)date;

/*!
 @method getEntriesLastN:
 @abstract Obtain an array of the n most recent entries before a specified date.
 @param n The number of entries to download.
 @result An array of LJEntry objects.
 */
- (NSArray<LJEntry*> *)getEntriesLastN:(int)n;

/*!
 @method getEntriesForDay:
 @abstract Obtain an array of all entries posted on a given day.
 @param date The date to retrieve entries for.
 @result An array of LJEntry objects.
 */
- (NSArray<LJEntry*> *)getEntriesForDay:(NSDate *)date;

/*!
 @method getSummaryForItemID:
 @param itemID The itemID of the desired entry.
 @discussion
 If an entry's itemID is known, you can retrieve a summary directly with this method.
 Note that the itemID is different from the itemID which appears on the web.
 @result The desired LJEntrySummary object if found, nil otherwise.
 */
- (nullable LJEntrySummary *)getSummaryForItemID:(int)itemID;

/*!
 @method getSummariesLastN:beforeDate:
 @abstract Obtain summaries of the n most recent entries before a specified date.
 @param n The number of summaries to download.
 @param date Retrieve summaries posted before this date.
 @result An array of \c LJEntrySummary objects.
 */
- (NSArray<LJEntrySummary*> *)getSummariesLastN:(int)n beforeDate:(NSDate *)date;

/*!
 @method getSummariesLastN:
 @abstract Obtain summaries of the n most recent entries.
 @param n The number of summaries to download.
 @result An array of \c LJEntrySummary objects.
 */
- (NSArray<LJEntrySummary*> *)getSummariesLastN:(int)n;

/*!
 @method getSummariesForDay:
 @abstract Obtain summaries of all entries posted on a given day.
 @param date The date to receive summaries for.
 @result An array of \c LJEntrySummary objects.
 */
- (NSArray<LJEntrySummary*> *)getSummariesForDay:(NSDate *)date;

/*!
 @property dayCounts
 @abstract A dictionary mapping days to entry counts.
 @discussion
 Returns an NSDictionary with NSCalendarDate objects as keys and NSNumbers as values,
 representing the number of entries available for the given date.
 */
@property (NS_NONATOMIC_IOSONLY, getter=getDayCounts, readonly, copy) NSDictionary<NSDate*,NSNumber*> *dayCounts;

/*!
 @property tags
 @abstract Obtain an array of user tags for this journal.
 @discussion
 This method returns an array of tags that are defined for
 this journal. Setting new tags should add to this array.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSMutableArray<NSString*> *tags;

/*!
 @method updateTagsArray
 @abstract updates the array of user tags for this journal
 @discussion
 This method update the array of tags for this journal with the new tag.
 We will ignore tags already in the array.
 */
- (void) updateTagsArray:(NSString *)newTag;

/*!
 @property tagsReplyForThisJournal
 @abstract The tags for journal from the server
 @discussion
 This method gets the list of tags for this journal from the server
 */
@property (NS_NONATOMIC_IOSONLY, getter=getTagsReplyForThisJournal, readonly, copy) NSDictionary *tagsReplyForThisJournal;

/*!
 @method createJournalTagsArray
 @abstract creates the tags array from a server reply
 @discussion
 This method parses through a reply from the server and creates the tags array. It
 returns the number of tags it found.
 */
- (NSInteger)createJournalTagsArray:(NSDictionary *)reply;

@end

NS_ASSUME_NONNULL_END
