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

@class LJEntry;

/*!
 @category LJEntry(Metadata)
 */
@interface LJEntry (Metadata)

/*!
 @method setString:forProperty:
 @abstract Set the string value of a metadata property.
 @discussion
 Sets the string value of a metadata property.  To remove a property,
 set its value to nil.
 */
- (void)setString:(NSString *)string forProperty:(NSString *)property;

/*!
 @method stringForProperty:
 @abstract Obtain the string value of a metadata property.
 @result The string value of a metadata property, or nil if it has no value.
 */
- (NSString *)stringForProperty:(NSString *)property;

/*!
 @method setBoolean:forProperty:
 @abstract Set the boolean value of a metadata property.
 */
- (void)setBoolean:(BOOL)flag forProperty:(NSString *)property;

/*!
 @method booleanForProperty:
 @abstract Returns the boolean value for a property.
 */
- (BOOL)booleanForProperty:(NSString *)property;

/*!
 @property currentMood
 @abstract The mood associated with the receiver.
 @discussion
 The current mood for this entry.  Set to nil to remove the
 mood property.
 If the mood has an associated ID number, it will be set by the LJKit in
 [LJEntry saveToJournal]; this allows LiveJournal to display the graphic
 for that mood on the web.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *currentMood;

/*!
 @property currentMoodName
 @abstract The mood name associated with the receiver, or nil.
 @discussion
 Set moodName to nil to remove the mood property.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *currentMoodName;

/*!
 @property currentMusic
 @abstract The music associated with the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *currentMusic;

/*!
 @property optionPreformatted
 @abstract The preformatted setting of the receiver.
 @discussion
 If this option is enabled, LiveJournal will not apply the usually formatting,
 such as changing newlines to &lt;br&gt; tags.  Enable this option if you want
 to control the receivers appearance with HTML tags.
 You may still include HTML in your entry if this option is disabled.
 */
@property (NS_NONATOMIC_IOSONLY) BOOL optionPreformatted;

/*!
 @property optionNoComments
 @abstract The "don't allow comments setting" of the receiver.
 @discussion
 If you don't want to allow users to write comments about the receiver,
 set this to true.
 */
@property (NS_NONATOMIC_IOSONLY) BOOL optionNoComments;

/*!
 @property pictureKeyword
 @abstract The picture keyword associated with the receiver.
 @discussion
 The set of available picture keywords can be obtained from the
 <code>[LJAccount userPicturesDictionary]</code> method, using the keys from the
 resulting NSDictionary.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *pictureKeyword;

/*!
 @property optionBackdated
 @abstract The backdated setting of the receiver.
 @discussion
 If an entry is backdated, it will not appear on other users' friends views.
 You must backdate an entry if it bears a date earlier than the latest entry
 posted to the journal.
 */
@property (NS_NONATOMIC_IOSONLY) BOOL optionBackdated;

/*!
 @property optionNoEmail
 @abstract The "don't email comments" setting of the receiver.
 @discussion
 LiveJournal provides to option to email a copy of comments that are posted to your
 journal.  This method allows you to override this option for this one entry.
 */
@property (NS_NONATOMIC_IOSONLY) BOOL optionNoEmail;

/*!
 @property hasUnknown8bitData
 @abstract Post contains unknown 8-bit data.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasUnknown8bitData;

/*!
 @method optionScreenReplies
 */
- (unichar)optionScreenReplies;

/*!
 @method setOptionScreenReplies
 */
- (void)setOptionScreenReplies:(NSString *)singleChar;

/*!
 @property hasScreenedReplies
 */
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasScreenedReplies;

/*!
 @property revisionNumber
 */
@property (NS_NONATOMIC_IOSONLY, readonly) int revisionNumber;

/*!
 @property revisionDate
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *revisionDate;

/*!
 @property commentsAlteredDate
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDate *commentsAlteredDate;

/*!
 @property syndicatedItemID
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *syndicatedItemID;

/*!
 @property syndicatedItemURL
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *syndicatedItemURL;

/*!
 @property currentLocation
 @abstract The location of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *currentLocation;

/*!
 @property tags
 @abstract The tag string of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *tags;

/*!
 @method addTag:
 @abstract If the new tag isn't already in the tag list, add it
 */
- (void)addTag:(NSString *)newTag;
@end
