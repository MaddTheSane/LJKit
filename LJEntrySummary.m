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

#import "LJEntry.h"
#import "LJJournal.h"
#import "LJEntrySummary.h"
#import "URLEncoding.h"

@implementation LJEntrySummary

- (NSString *)summary
{
    return [_content copy];
}

- (NSString *)descriptionWithFormat:(NSString *)format
{
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = format;
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    NSString *s = [df stringFromDate:_date];
    return [NSString stringWithFormat:s, _content];
}

- (NSString *)description
{
    return [self descriptionWithFormat:@"%Y-%M-%d %H:%m:%S: %%@"];
}

- (LJEntry *)getEntry
{
    return [_journal getEntryForItemID:_itemID];
}

@end
