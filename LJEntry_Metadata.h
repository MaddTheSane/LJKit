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
 @method currentMood
 @abstract Obtain the mood associated with the receiver.
 @result The mood name, or nil if none is set.
 */
- (NSString *)currentMood;

/*!
 @method setCurrentMood:
 @abstract Set the mood associated with the receiver.
 @discussion
 Sets the current mood for this entry.  Set moodName to nil to remove the
 mood property.
 If the mood has an associated ID number, it will be set by the LJKit in
 [LJEntry saveToJournal]; this allows LiveJournal to display the graphic
 for that mood on the web.
 */
- (void)setCurrentMood:(NSString *)moodName;

/*!
 @method currentMusic
 @abstract Obtain the music associated with the receiver.
 */
- (NSString *)currentMusic;

/*!
 @method setCurrentMusic:
 @abstract Sets the music associated with the receiver.
 */
- (void)setCurrentMusic:(NSString *)music;

/*!
 @method optionPreformatted
 @abstract Obtain the preformatted setting of the receiver.
 */
- (BOOL)optionPreformatted;

/*!
 @method setOptionPreformatted:
 @abstract Set the preformatted setting of the receiver.
 @discussion
 If this option is enabled, LiveJournal will not apply the usually formatting,
 such as changing newlines to &lt;br&gt; tags.  Enable this option if you want
 to control the receivers appearance with HTML tags.
 You may still include HTML in your entry if this option is disabled.
 */
- (void)setOptionPreformatted:(BOOL)flag;

/*!
 @method optionNoComments
 @abstract Obtain the don't allow comments setting of the receiver.
 */
- (BOOL)optionNoComments;

/*!
 @method setOptionNoComments:
 @abstract Set the don't allow comments setting of the receiver.
 @discussion
 If you don't want to allow users to write comments about the receiver,
 set this to true.
 */
- (void)setOptionNoComments:(BOOL)flag;

/*!
 @method pictureKeyword
 @abstract Obtain the picture keyword associated with the receiver.
 */
- (NSString *)pictureKeyword;

/*!
 @method setPictureKeyword:
 @abstract Set the picture keyword associated with the receiver.
 @discussion
 The set of available picture keywords can be obtained from the
 [LJAccount userPicturesDictionary] method, using the keys from the
 resulting NSDictionary.
 */
- (void)setPictureKeyword:(NSString *)keyword;

/*!
 @method optionBackdated
 @abstract Obtain the backdated setting of the receiver.
 */
- (BOOL)optionBackdated;

/*!
 @method setOptionBackdated:
 @abstract Sets the backdated setting of the receiver.
 @discussion
 If an entry is backdated, it will not appear on other users' friends views.
 You must backdate an entry if it bears a date earlier than the latest entry
 posted to the journal.
 */
- (void)setOptionBackdated:(BOOL)flag;

/*!
 @method optionNoEmail
 @abstract Obtain the don't email comments setting of the receiver.
 */
- (BOOL)optionNoEmail;

/*!
 @method setOptionNoEmail
 @abstract Sets the don't email comments setting of the receiver.
 @discussion
 LiveJournal provides to option to email a copy of comments that are posted to your
 journal.  This method allows you to override this option for this one entry.
 */
- (void)setOptionNoEmail:(BOOL)flag;

/*!
 @method hasUnknown8bitData
 @abstract Post contains unknown 8-bit data.
 */
- (BOOL)hasUnknown8bitData;

/*!
 @method optionScreenReplies
 */
- (unichar)optionScreenReplies;

/*!
 @method hasScreenedReplies
 */
- (BOOL)hasScreenedReplies;

/*!
 @method revisionNumber
 */
- (int)revisionNumber;

/*!
 @method revisionDate
 */
- (NSDate *)revisionDate;

/*!
 @method commentsAlteredDate
 */
- (NSDate *)commentsAlteredDate;

/*!
 @method syndicatedItemID
 */
- (NSString *)syndicatedItemID;

/*!
 @method syndicatedItemURL
 */
- (NSURL *)syndicatedItemURL;

@end
