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
 2004-01-06 [BPR] Moved combo box delegate methods into category.
 */

#import "LJMoods.h"

@interface LJMoods (ClassPrivate)
- (int)_indexForMoodName:(NSString *)moodName hypothetical:(BOOL)flag;
- (void)_addMoodID:(NSString *)moodID forName:(NSString *)moodName;
@end

@implementation LJMoods

- (id)init
{
    self = [super init];
    if (self) {
        _moodNames = [[NSMutableArray alloc] initWithCapacity:64];
        _moodIDs = [[NSMutableArray alloc] initWithCapacity:64];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        NSDictionary *moodmap;
        NSEnumerator *moodIDEnumerator;
        id moodID;
        
        moodmap = [decoder decodeObjectForKey:@"LJMoodsDictionary"];
        _moodNames = [[moodmap allKeys] mutableCopy];
        [_moodNames sortUsingSelector:@selector(compare:)];
        _moodIDs = [[moodmap objectsForKeys:_moodNames
                             notFoundMarker:@""] mutableCopy];
        moodIDEnumerator = [_moodIDs objectEnumerator];
        while (moodID = [moodIDEnumerator nextObject]) {
            if ([moodID intValue] > _highestMoodID) {
                _highestMoodID = [moodID intValue];
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSDictionary *moodmap;

    moodmap = [[NSDictionary alloc] initWithObjects:_moodIDs forKeys:_moodNames];
    [encoder encodeObject:moodmap forKey:@"LJMoodsDictionary"];
    [moodmap release];
}

- (void)dealloc
{
    [_moodNames release];
    [_moodIDs release];
    [super dealloc];
}

- (int)_indexForMoodName:(NSString *)moodName hypothetical:(BOOL)flag
{
    int min, i, max;
    NSString *name;
    
    min = 0;
    max = [_moodNames count] - 1;
    while (min <= max) {
        i = (min + max) / 2;
        name = [_moodNames objectAtIndex:i];
        switch ([name compare:moodName]) {
            case NSOrderedAscending: min = i + 1; break;
            case NSOrderedDescending: max = i - 1; break;
            case NSOrderedSame: return i;
        }
    }
    // If flag is true, then we return the index that the moodname WOULD have
    // had WERE in the array.
    return (flag ? min : -1);
}

- (void)_addMoodID:(NSString *)moodID forName:(NSString *)moodName
{
    if ([moodID length] > 0 && [moodName length] > 0) {
        int index = [self _indexForMoodName:moodName hypothetical:YES];
        [_moodNames insertObject:moodName atIndex:index];
        [_moodIDs insertObject:moodID atIndex:index];
        if ([moodID intValue] > _highestMoodID) {
            _highestMoodID = [moodID intValue];
        }
    }
}

- (int)IDForMoodName:(NSString *)moodName
{
    return [[self IDStringForMoodName:moodName] intValue];
}

- (NSString *)IDStringForMoodName:(NSString *)moodName
{
    int index = [self _indexForMoodName:moodName hypothetical:NO];
    return (index > 0) ? [_moodIDs objectAtIndex:index] : nil;
}

- (void)updateMoodsWithLoginReply:(NSDictionary *)reply
{
    int count, i;
    NSString *moodNameKey, *moodIDKey;

    count = [[reply objectForKey:@"mood_count"] intValue];
    for (i = 1; i <= count; i++) {
        moodNameKey = [NSString stringWithFormat:@"mood_%d_name", i];
        moodIDKey = [NSString stringWithFormat:@"mood_%d_id", i];
        [self _addMoodID:[reply objectForKey:moodIDKey]
                 forName:[reply objectForKey:moodNameKey]];
    }
}

- (int)highestMoodID
{
    return _highestMoodID;
}

- (NSString *)highestMoodIDString
{
    return [NSString stringWithFormat:@"%u", _highestMoodID];
}

- (NSArray *)moodNames
{
    return _moodNames;
}

@end


@implementation LJMoods (NSComboBoxDelegate)

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [_moodNames count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    return [_moodNames objectAtIndex:index];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)aString
{
    int index = [self _indexForMoodName:aString hypothetical:YES];
    if (index < [_moodNames count]) {
        NSString *moodName = [_moodNames objectAtIndex:index];
        if ([moodName hasPrefix:aString]) return moodName;
    }
    return nil;
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
    return [self _indexForMoodName:aString hypothetical:NO];
}

@end
