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
#import "LJServer.h"
#import "LJAccount.h"
#import "LJJournal.h"
#import "LJEntry.h"
#import "LJEntrySummary.h"
#import "LJGroup.h"
#import "LJFriend.h"

/*!
 @category LJAccount(LJHttpURLs)
 */
@interface LJAccount (LJHttpURLs)
/*!
 @method userProfileHttpURL
 @abstract Returns the URL of the receiver's user profile webpage.
 */
- (NSURL *)userProfileHttpURL;
- (NSURL *)memoriesHttpURL;
- (NSURL *)toDoListHttpURL;
@end

/*!
 @category LJJournal(LJHttpURLs)
 */
@interface LJJournal (LJHttpURLs)
/*!
 @method recentEntriesHttpURL
 @abstract Returns the URL of the receiver's recent entries view.
 */
- (NSURL *)recentEntriesHttpURL;
/*!
 @method friendsEntriesHttpURL
 @abstract Returns the URL of the receiver's friends entries view.
 */
- (NSURL *)friendsEntriesHttpURL;
/*!
 @method calendarHttpURL
 @abstract Returns the URL of the receiver's calendar view.
 */
- (NSURL *)calendarHttpURL;
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
- (NSURL *)readCommentsHttpURL;
/*!
 @method postCommentsHttpURL
 @abstract Returns the URL of the receiver's post comments view.
 */
- (NSURL *)postCommentHttpURL;
- (NSURL *)addToMemoriesHttpURL;
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
- (NSURL *)membersEntriesHttpURL;
@end

/*!
@category LJFriend(LJHttpURLs)
 */
@interface LJFriend (LJHttpURLs)
/*!
@method userProfileHttpURL
 @abstract Returns the URL of the receiver's user profile page.
 */
- (NSURL *)userProfileHttpURL;
- (NSURL *)memoriesHttpURL;
- (NSURL *)toDoListHttpURL;
- (NSURL *)rssFeedURL;
- (NSURL *)atomFeedURL;
- (NSURL *)foafURL;
/*!
 @method recentEntriesHttpURL
 @abstract Returns the URL of the receiver's recent entries view.
 */
- (NSURL *)recentEntriesHttpURL;
- (NSURL *)joinCommunityHttpURL;
- (NSURL *)leaveCommunityHttpURL;
@end
