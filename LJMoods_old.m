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

#import "LJMoods.h"

@interface LJMoods (TreeMethods)
- (void)treeInit;
- (void)treeBuildDictionary:(NSMutableDictionary *)dictionary
                  treeIndex:(int)treeIndex prefix:(NSMutableString *)prefix;
- (int)treeAddNodeWithLetter:(unichar)letter;
- (int)treeIndexForString:(NSString *)string index:(int)index
                treeIndex:(int)treeIndex createNodes:(BOOL)create;
- (void)treeAddMood:(NSString *)moodName withID:(int)moodID;
- (int)treeIndexForString:(NSString *)string;
- (NSString *)completedMoodForPrefix:(NSString *)prefix
                           treeIndex:(int)treeIndex;
@end

@implementation LJMoods

- (void)treeInit
{
    _highestMoodID = 0;
    _moodTreeSize = 0;
    _moodTree = NSZoneMalloc([self zone], _moodTreeCapacity * sizeof(MoodNode));
    NSAssert(_moodTree, @"Cannot allocate memory for moodTree.");
    [self treeAddNodeWithLetter:(unichar)'a']; // Create root node.
}

- (id)init
{
    self = [super init];
    if (self) {
        _moodTreeCapacity = 1024;
        [self treeInit];
        _moodNames = [[NSMutableArray alloc] initWithCapacity:_moodTreeCapacity];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        if ([decoder allowsKeyedCoding]) {
            NSDictionary *dictionary;
            NSString *moodName;
            int count, i, moodID;

            dictionary = [decoder decodeObjectForKey:@"LJMoodsDictionary"];
            _moodTreeCapacity = [dictionary count] * 4;
            [self treeInit];
            _moodNames = [[dictionary allKeys] mutableCopy];
            [_moodNames sortUsingSelector:@selector(compare:)];
            count = [_moodNames count];
            for (i = 0; i < count; i++) {
                moodName = [_moodNames objectAtIndex:i];
                moodID = [[dictionary objectForKey:moodName] intValue];
                [self treeAddMood:moodName withID:moodID];
            }
        } else {
            [self dealloc];
            [NSException raise:NSInvalidArgumentException
                        format:@"LJKit requires keyed coding."];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        NSMutableDictionary *dictionary;
        NSMutableString *prefix;
        
        dictionary = [[NSMutableDictionary alloc] initWithCapacity:
            [_moodNames count]];
        prefix = [[NSMutableString alloc] initWithCapacity:10];
        [self treeBuildDictionary:dictionary treeIndex:0 prefix:prefix];
        [encoder encodeObject:dictionary forKey:@"LJMoodsDictionary"];
        [prefix release];
        [dictionary release];
    } else {
        [NSException raise:NSInvalidArgumentException
                    format:@"LJKit requires keyed coding."];
    }
}

- (void)dealloc
{
    NSZoneFree([self zone], _moodTree);
    [_moodNames release];
    [super dealloc];
}

- (void)treeBuildDictionary:(NSMutableDictionary *)dictionary
                   treeIndex:(int)treeIndex prefix:(NSMutableString *)prefix
{
    NSString *letter;
    MoodNode *node;

    node = &_moodTree[treeIndex];
    // Append this node's letter to the prefix string.
    letter = [[NSString alloc] initWithCharactersNoCopy:&node->letter length:1
                                           freeWhenDone:NO];
    [prefix appendString:letter];
    [letter release];
    // If there is a mood ID for this node, add it to the dictionary.
    if (node->moodID)
        [dictionary setObject:[NSNumber numberWithInt:node->moodID]
                       forKey:prefix];
    // If this node has children, descend.
    if (node->downIndex)
        [self treeBuildDictionary:dictionary treeIndex:node->downIndex
                           prefix:prefix];
    // Remove the appended letter.
    [prefix deleteCharactersInRange:NSMakeRange([prefix length] - 1, 1)];
    // If this node has a sibling, move over.
    if (node->rightIndex)
        [self treeBuildDictionary:dictionary treeIndex:node->rightIndex
                           prefix:prefix];
}

- (int)treeAddNodeWithLetter:(unichar)letter
{
    if (_moodTreeSize == _moodTreeCapacity) {
        _moodTreeCapacity *= 2;
#ifdef DEBUG
        NSLog(@"Resizing mood tree.  New capacity = %u", _moodTreeCapacity);
#endif
        _moodTree = NSZoneRealloc([self zone], _moodTree,
                                  _moodTreeCapacity * sizeof(MoodNode));
    }
    _moodTree[_moodTreeSize].letter = letter;
    _moodTree[_moodTreeSize].rightIndex = 0;
    _moodTree[_moodTreeSize].downIndex = 0;
    _moodTree[_moodTreeSize].moodID = 0;
    _moodTreeSize++;
    return _moodTreeSize - 1;
}

- (int)treeIndexForString:(NSString *)string index:(int)index
                treeIndex:(int)treeIndex createNodes:(BOOL)create
{
    unichar letter;
    MoodNode *node;

    letter = [string characterAtIndex:index];
    node = &_moodTree[treeIndex];
    if (letter != node->letter) {
        // Node and name don't match.  Try a sibling.
        if (node->rightIndex == 0) {
            // Create one if necessary.
            if (create) {
                node->rightIndex = [self treeAddNodeWithLetter:letter];
            } else {
                return 0;
            }
        }
        return [self treeIndexForString:string index:index
                              treeIndex:node->rightIndex createNodes:create];
    } else {
        int nextIndex = index + 1;
        
        if (nextIndex < [string length]) {
            // There are characters left to process.  Move to children.
            if (node->downIndex == 0) {
                if (create) {
                    // Create a child if necessary.
                    unichar nextLetter = [string characterAtIndex:nextIndex];
                    node->downIndex = [self treeAddNodeWithLetter:nextLetter];
                } else {
                    return 0;
                }
            }
            return [self treeIndexForString:string index:nextIndex
                                  treeIndex:node->downIndex createNodes:create];
        } else {
            return treeIndex;
        }
    }
}

- (void)treeAddMood:(NSString *)moodName withID:(int)moodID
{
    int treeIndex = [self treeIndexForString:moodName index:0 treeIndex:0
                                 createNodes:YES];
    _moodTree[treeIndex].moodID = moodID;
    if (_highestMoodID < moodID) _highestMoodID = moodID;
}

- (int)treeIndexForString:(NSString *)string
{
    return [self treeIndexForString:string index:0 treeIndex:0 createNodes:NO];
}

- (int)IDForMoodName:(NSString *)moodName
{
    if ([moodName length]) {
        int treeIndex = [self treeIndexForString:moodName];
        return _moodTree[treeIndex].moodID;
    }
    return 0;
}

- (NSString *)IDStringForMoodName:(NSString *)moodName
{
    int moodID = [self IDForMoodName:moodName];
    if (moodID) {
        return [NSString stringWithFormat:@"%u", moodID];
    } else {
        return nil;
    }        
}

- (void)updateMoodsWithLoginReply:(NSDictionary *)reply
{
    int count, i;
    NSString *moodNameKey, *moodIDKey, *moodName;
    int moodID;

    count = [[reply objectForKey:@"mood_count"] intValue];
    for (i = 1; i <= count; i++) {
        moodNameKey = [NSString stringWithFormat:@"mood_%d_name", i];
        moodIDKey = [NSString stringWithFormat:@"mood_%d_id", i];
        moodName = [reply objectForKey:moodNameKey];
        moodID = [[reply objectForKey:moodIDKey] intValue];
        if ([moodName length] > 0) [self treeAddMood:moodName withID:moodID];
        [_moodNames addObject:moodName];
    }
    // Re-sort the mood names.
    [_moodNames sortUsingSelector:@selector(compare:)];
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

- (NSString *)completedMoodForPrefix:(NSString *)prefix treeIndex:(int)treeIndex
{
    int index;
    NSString *tryName;
    
    if (_moodTree[treeIndex].moodID) {
        return prefix;
    }
    index = _moodTree[treeIndex].downIndex;
    if (index) {
        NSString *letter;

        letter = [[NSString alloc] initWithCharactersNoCopy:&_moodTree[index].letter
                                                     length:1 freeWhenDone:NO];
        tryName = [self completedMoodForPrefix:[prefix stringByAppendingString:letter]
                                     treeIndex:index];
        [letter release];
        if (tryName) return tryName;
    }
    index = _moodTree[treeIndex].rightIndex;
    if (index) {
        tryName = [self completedMoodForPrefix:prefix treeIndex:index];
        if (tryName) return tryName;
    }
    return nil;
}

/* NSComboBoxDataSource  methods */

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [_moodNames count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    return [_moodNames objectAtIndex:index];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:
    (NSString *)aString
{
    int treeIndex = [self treeIndexForString:aString];
    if (treeIndex) {
        return [self completedMoodForPrefix:aString treeIndex:treeIndex];
    } else {
        return nil;
    }
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:
    (NSString *)aString
{
    // aString should be the string returned by comboBox:completedString:.
    // Knowing that, this method could be optimized.
    return [_moodNames indexOfObject:aString];
}

@end
