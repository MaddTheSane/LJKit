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
#import <LJKit/LJEntryRoot.h>

@class LJJournal, LJEntry;

NS_ASSUME_NONNULL_BEGIN

/*!
 @class LJEntrySummary
 @abstract Represents an entry summary.
 @discussion
 Rather than downloading an entire entry, the LiveJournal server permits the downloading
 of entry summaries, which consist of the entry's subject, if it has one, or the first
 few characters of the entry's text.  The number of characters is determined by the
 [LJJournal setEntrySummaryLength:] method.
 */
@interface LJEntrySummary : LJEntryRoot

/*!
 @property summary
 @abstract The entry's summary text.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *summary;

/*!
 @method descriptionWithFormat:
 @abstract Obtain a string containing the entry's date, time, and summary text.
 @discussion
 Returns a string based on the format string.  The format is first passed to
 [NSCalendarDate descriptionWithCalendarFormat:] to fill in date fields, then
 to [NSString stringWithFormat:] with the summary text as the argument.  Therefore,
 you can use any of the escape codes from NSCalendarDate to include the date fields,
 but you must use %%&#64; (two percent signs) to include the summary text.
 */
- (NSString *)descriptionWithFormat:(NSString *)format;

/*!
 @property description
 @abstract A string containing the entry's date, time, and summary text.
 @discussion
 Returns a string of the format: "YYYY-MM-DD HH:MM:SS: Summary text...".
 Calls descriptionWithFormat: with the format string "%Y-%m-%d %H:%M:%S: %%&#64;".
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *description;

/*!
 @property entry
 @abstract The entry the receiver summarizes.
 */
@property (NS_NONATOMIC_IOSONLY, getter=getEntry, readonly, strong) LJEntry *entry;

@end

NS_ASSUME_NONNULL_END
