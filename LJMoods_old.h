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

#import <Cocoa/Cocoa.h>

typedef struct _MoodNode {
    unichar letter;
    int rightIndex;
    int downIndex;
    int moodID;
} MoodNode;

/*!
 @class LJMoods
 @abstract Represents the set of moods known to a LiveJournal server.
 @discussion
 An LJMoods object represents a set of moods and their IDs.

 This class implements the NSComboBoxDataSource protocol, including
 autocompleting mood names, so it can be used as a data source for
 NSComboBoxes in your human interface.
 */
@interface LJMoods : NSObject <NSCoding>
{
    MoodNode *_moodTree;
    int _moodTreeSize;
    int _moodTreeCapacity;
    int _highestMoodID;
    NSMutableArray *_moodNames;
}

/*!
 @method init
 @abstract Initialize an LJMoods object.
 */
- (id)init;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;
- (void)updateMoodsWithLoginReply:(NSDictionary *)reply;

/*!
 @method highestMoodID
 @abstract Obtain the highest value mood ID.
 */
- (int)highestMoodID;

/*!
 @method highestMoodIDString
 @abstract Obtain the highest value mood ID as a string.
 */
- (NSString *)highestMoodIDString;

/*!
 @method IDForMoodName:
 @abstract Obtain the ID number for a given mood name.
 */
- (int)IDForMoodName:(NSString *)moodName;

/*!
 @method IDStringForMoodName:
 @abstract Obtain the ID number for a given mood name as a string.
 */
- (NSString *)IDStringForMoodName:(NSString *)moodName;

/*!
 @method moodNames
 @abstract Obtain a sorted array of all known moods.
 */
- (NSArray *)moodNames;

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index;
- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString;
- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)aString;
@end
