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

/*!
 @class LJMoods
 @abstract Represents the set of moods known to a LiveJournal server.
 @discussion
 An LJMoods object represents a set of moods and their IDs.

 This class implements the NSComboBoxDataSource protocol, including
 autocompleting mood names, so it can be used as a data source for
 NSComboBoxes in your human interface.
 */
@interface LJMoods : NSObject <NSCoding, NSComboBoxDataSource>
{
    int _highestMoodID;
    NSMutableArray *_moodNames;
    NSMutableArray *_moodIDs;
}

/*!
 @method init
 @abstract Initialize an LJMoods object.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @method highestMoodID
 @abstract Obtain the highest value mood ID.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int highestMoodID;

/*!
 @method highestMoodIDString
 @abstract Obtain the highest value mood ID as a string.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *highestMoodIDString;

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
	@method - MoodNameFromIDString:
	@abstract Obtain the mood name for a given mood id.
*/
- (NSString *)MoodNameFromID:(NSString *)moodID;

/*!
 @method moodNames
 @abstract Obtain a sorted array of all known moods.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *moodNames;

@end

