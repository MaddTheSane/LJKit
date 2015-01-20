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

/*!
 @header LJHttpURLs
 This header defines several categories which provide methods which return
 http URLs for related web pages.
 */

#import <Foundation/Foundation.h>

#import "LJJournal.h"
#import "LJEntryRoot.h"
#import "LJGroup.h"
#import "LJUserEntity.h"
#import "LJFriend.h"


@class LJJournal, LJEntryRoot, LJGroup, LJUserEntity, LJFriend;

/*!
 @category LJJournal(LJHttpURLs)
 */
@interface LJJournal (LJHttpURLs)
/*!
 @method recentEntriesHttpURL
 @abstract Returns the URL of the receiver's recent entries view.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *recentEntriesHttpURL;
/*!
 @method friendsEntriesHttpURL
 @abstract Returns the URL of the receiver's friends entries view.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *friendsEntriesHttpURL;
/*!
 @method calendarHttpURL
 @abstract Returns the URL of the receiver's calendar view.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *calendarHttpURL;
/*!
 @method calendarHttpURLForDay:
 @abstract Returns the URL of the receiver's calendar view for a given day.
 */
- (NSURL *)calendarHttpURLForDay:(NSDate *)date;
@end


/*!
 @category LJEntryRoot(LJHttpURLs)
 */
@interface LJEntryRoot (LJHttpURLs)
/*!
 @method readCommentsHttpURL
 @abstract Returns the URL of the receiver's read comments view.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *readCommentsHttpURL;
/*!
 @method postCommentsHttpURL
 @abstract Returns the URL of the receiver's post comments view.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *postCommentHttpURL;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *addToMemoriesHttpURL;
@property (NS_NONATOMIC_IOSONLY, readonly) int webItemID;

@end


/*!
 @category LJGroup(LJHttpURLs)
*/
@interface LJGroup (LJHttpURLs)
/*!
 @method membersEntriesHttpURL
 @abstract Returns the URL of the receiver's members' entries.
 @discussion
 LiveJournal allows the friends view to be filtered by group.
 This method returns an URL of the friends view showing entries
 only by members of this group.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *membersEntriesHttpURL;
@end


/*!
 @category LJUserEntity(LJHttpURLs)
 */
@interface LJUserEntity (LJHttpURLs)
/*!
 @method userProfileHttpURL
 @abstract Returns the URL of the receiver's user profile page.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *userProfileHttpURL;
/*!
 @method memoriesHttpURL
 @abstract Returns the URL of the receiver's memories page.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *memoriesHttpURL;
/*!
 @method toDoListHttpURL
 @abstract Returns the URL of the receiver's to do list page.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *toDoListHttpURL;
/*!
 @method rssFeedURL
 @abstract Returns the URL of the receiver's RSS feed.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *rssFeedURL;
/*!
 @method atomFeedURL
 @abstract Returns the URL of the receiver's Atom feed.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *atomFeedURL;
/*!
 @method foafURL
 @abstract Returns the URL of the receiver's FOAF information.
 @discussion
 If the user has set an external FOAF URL this method will NOT reflect that 
 preference.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *foafURL;
/*!
 @method recentEntriesHttpURL
 @abstract Returns the URL of the receiver's recent entries view.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *recentEntriesHttpURL;
@end


/*!
 @category LJFriend(LJHttpURLs)
 */
@interface LJFriend (LJHttpURLs)
/*!
 @method joinCommunityHttpURL
 @abstract Returns the URL of the receiver's join community page.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *joinCommunityHttpURL;
/*!
 @method leaveCommunityHttpURL
 @abstract Returns the URL of the receiver's leave community page.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSURL *leaveCommunityHttpURL;
@end