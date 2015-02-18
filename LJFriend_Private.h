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
 2004-01-06 [BPR] Header added.
 */

#import "LJFriend.h"

@interface LJFriend ()
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSString *accountType;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSString *accountStatus;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSDate *birthDate;
#if !TARGET_OS_IPHONE
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSColor *backgroundColorForYou;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSColor *foregroundColorForYou;
#endif
+ (void)updateFriendSet:(NSMutableSet *)friends withReply:(NSDictionary *)reply account:(LJAccount *)account;
+ (void)updateFriendOfSet:(NSMutableSet *)friendOfs withReply:(NSDictionary *)reply account:(LJAccount *)account;
+ (void)updateFriendSet:(NSSet *)friends withEditReply:(NSDictionary *)reply;
- (id)initWithUsername:(NSString *)username account:(LJAccount *)account;
- (void)_addAddFieldsToParameters:(NSMutableDictionary *)parameters index:(int)i;
- (void)_addDeleteFieldsToParameters:(NSMutableDictionary *)parameters;
//- (void)_enqueueNotificationName:(NSString *)name;
- (void)_updateModifiedDate;
- (void)_setOutgoingFriendship:(BOOL)flag;
- (void)_setIncomingFriendship:(BOOL)flag;
@end
