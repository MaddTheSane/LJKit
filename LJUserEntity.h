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

@class LJAccount;

NS_ASSUME_NONNULL_BEGIN

@interface LJUserEntity : NSObject
{
@protected
    NSString *_username, *_fullname;
}

/*!
 @property username
 @abstract The username of the receiver.
 */
@property (nonatomic, readonly, copy) NSString *username;

/*!
 @property fullname
 @abstract The full name of the receiver.
 @discussion
 Returns the receiver's full name, as reported by the server.  If not
 available, this method returns the receiver's username.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *fullname;

@end

NS_ASSUME_NONNULL_END
