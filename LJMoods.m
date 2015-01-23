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

@interface LJMoods ()
- (NSInteger)_indexForMoodName:(NSString *)moodName hypothetical:(BOOL)flag;
- (void)_addMoodID:(NSString *)moodID forName:(NSString *)moodName;
@end

@implementation LJMoods
@synthesize highestMoodID = _highestMoodID;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _moodNames = [[NSMutableArray alloc] initWithCapacity:64];
        _moodIDs = [[NSMutableArray alloc] initWithCapacity:64];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
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
            if ([moodID integerValue] > _highestMoodID) {
                _highestMoodID = [moodID integerValue];
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
}

- (NSInteger)_indexForMoodName:(NSString *)moodName hypothetical:(BOOL)flag
{
    NSInteger min, i, max;
    NSString *name;
    
    min = 0;
    max = [_moodNames count] - 1;
    while (min <= max) {
        i = (min + max) / 2;
        name = _moodNames[i];
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
        NSInteger index = [self _indexForMoodName:moodName hypothetical:YES];
        [_moodNames insertObject:moodName atIndex:index];
        [_moodIDs insertObject:moodID atIndex:index];
        if ([moodID integerValue] > _highestMoodID) {
            _highestMoodID = [moodID integerValue];
        }
    }
}

- (NSInteger)IDForMoodName:(NSString *)moodName
{
    return [[self IDStringForMoodName:moodName] integerValue];
}

- (NSString *)IDStringForMoodName:(NSString *)moodName
{
    NSInteger index = [self _indexForMoodName:moodName hypothetical:NO];
    return (index > -1) ? _moodIDs[index] : nil;
}

- (NSInteger)_indexForMoodID:(NSString *)moodID
{
    NSInteger min, i, max;
    NSString *ID;
    
    min = 0;
    max = [_moodIDs count] - 1;
	for (i = min; i <= max; i++) {
		ID = _moodIDs[i];
        if ([ID compare:moodID] == NSOrderedSame) {
			return i;
        }
    }
    return 0;
}

- (NSString *)MoodNameFromID:(NSString *)moodID
{
	NSString *moodName = nil;
	NSInteger index = [self _indexForMoodID: moodID];
	if (index != 0) {
		moodName = _moodNames[index];
	}
	return moodName;
}

- (void)updateMoodsWithLoginReply:(NSDictionary *)reply
{
    int count, i;
    NSString *moodNameKey, *moodIDKey;

    count = [reply[@"mood_count"] intValue];
    for (i = 1; i <= count; i++) {
        moodNameKey = [NSString stringWithFormat:@"mood_%d_name", i];
        moodIDKey = [NSString stringWithFormat:@"mood_%d_id", i];
        [self _addMoodID:reply[moodIDKey]
                 forName:reply[moodNameKey]];
    }
}

- (NSString *)highestMoodIDString
{
    return [NSString stringWithFormat:@"%ld", (long)_highestMoodID];
}

- (NSArray *)moodNames
{
    return [NSArray arrayWithArray:_moodNames];
}


- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [_moodNames count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return _moodNames[index];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)aString
{
    NSInteger index = [self _indexForMoodName:aString hypothetical:YES];
    if (index < [_moodNames count]) {
        NSString *moodName = _moodNames[index];
        if ([moodName hasPrefix:aString]) return moodName;
    }
    return nil;
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
    return [self _indexForMoodName:aString hypothetical:NO];
}

@end
