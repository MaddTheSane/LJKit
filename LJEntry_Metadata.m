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
#import "LJEntry_Metadata.h"

@implementation LJEntry (Metadata)

- (void)setString:(NSString *)string forProperty:(NSString *)property
{
    if (string) {
        [_properties setObject:string forKey:property];
    } else {
        [_properties removeObjectForKey:property];
    }
}

- (NSString *)stringForProperty:(NSString *)property
{
    return [_properties objectForKey:property];
}

- (void)setBoolean:(BOOL)flag forProperty:(NSString *)property
{
    [_properties setObject:(flag ? @"1" : @"0") forKey:property];
}

- (BOOL)booleanForProperty:(NSString *)property
{
    return [[_properties objectForKey:property] intValue] != 0;
}

- (NSString *)currentMood
{
    return [self stringForProperty:@"current_mood"];
}

- (void)setCurrentMood:(NSString *)moodName
{
    [self setString:moodName forProperty:@"current_mood"];
    // The mood ID is set in [LJEntry saveToJournal]
}

- (NSString *)currentMusic
{
    return [self stringForProperty:@"current_music"];
}

- (void)setCurrentMusic:(NSString *)music
{
    [self setString:music forProperty:@"current_music"];
}

- (BOOL)optionPreformatted
{
    return [self booleanForProperty:@"opt_preformatted"];
}

- (void)setOptionPreformatted:(BOOL)flag
{
    [self setBoolean:flag forProperty:@"opt_preformatted"];
}

- (BOOL)optionNoComments
{
    return [self booleanForProperty:@"opt_nocomments"];
}

- (void)setOptionNoComments:(BOOL)flag
{
    [self setBoolean:flag forProperty:@"opt_nocomments"];
}

- (NSString *)pictureKeyword
{
    return [self stringForProperty:@"picture_keyword"];
}

- (void)setPictureKeyword:(NSString *)keyword
{
    [self setString:keyword forProperty:@"picture_keyword"];
}

- (BOOL)optionBackdated
{
    return [self booleanForProperty:@"opt_backdated"];
}

- (void)setOptionBackdated:(BOOL)flag
{
    [self setBoolean:flag forProperty:@"opt_backdated"];
}

- (BOOL)optionNoEmail
{
    return [self booleanForProperty:@"opt_noemail"];
}

- (void)setOptionNoEmail:(BOOL)flag
{
    [self setBoolean:flag forProperty:@"opt_noemail"];
}

@end
