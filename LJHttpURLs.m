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

#import "LJAccount.h"
#import "LJServer.h"
#import "LJHttpURLs.h"
#import "LJUserEntity_Private.h"
#import "LJGroup_Private.h"

@implementation LJJournal (LJHttpURLs)

- (NSURL *)recentEntriesHttpURL
{
    NSString *s;
    s = [NSString stringWithFormat:@"/users/%@/", self.name];
    return [[NSURL URLWithString:s relativeToURL:[[self.account server] URL]] absoluteURL];
}

- (NSURL *)friendsEntriesHttpURL
{
    NSURL *url = [NSURL URLWithString:@"friends/" relativeToURL:[self recentEntriesHttpURL]];
    return [url absoluteURL];
}

- (NSURL *)calendarHttpURL
{
    NSURL *url = [NSURL URLWithString:@"calendar/" relativeToURL:[self recentEntriesHttpURL]];
    return [url absoluteURL];
}

- (NSURL *)calendarHttpURLForDay:(NSDate *)date
{
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"%Y/%m/%d/";
    
    NSString *s = [df stringFromDate:date];

    return [[NSURL URLWithString:s relativeToURL:[self recentEntriesHttpURL]] absoluteURL];
}

@end


@implementation LJEntryRoot (LJHttpURLs)

- (int)webItemID
{
    return ((_itemID << 8) + _aNum);
}

- (NSURL *)readCommentsHttpURL
{
    if (_itemID) {
        NSURL *baseURL = [_journal recentEntriesHttpURL];
        NSString *s = [NSString stringWithFormat:@"%u.html", [self webItemID]];
        return [[NSURL URLWithString:s relativeToURL:baseURL] absoluteURL];
    }
    return nil;
}

- (NSURL *)postCommentHttpURL
{
    if (_itemID) {
        return [[NSURL URLWithString:@"?mode=reply"
                       relativeToURL:[self readCommentsHttpURL]] absoluteURL];
    }
    return nil;
}

- (NSURL *)addToMemoriesHttpURL
{
    if (_itemID) {
        NSURL *baseURL = [[[_journal account] server] URL];
        NSString *s = [NSString stringWithFormat:@"tools/memadd.bml?journal=%@&itemid=%u",
            [_journal name], [self webItemID]];
        return [[NSURL URLWithString:s relativeToURL:baseURL] absoluteURL];
    }
    return nil;
}

@end


@implementation LJGroup (LJHttpURLs)

- (NSURL *)membersEntriesHttpURL
{
    NSURL *baseURL = [[self.account defaultJournal] friendsEntriesHttpURL];
    return [[NSURL URLWithString:self.name relativeToURL:baseURL] absoluteURL];
}

@end


@interface LJUserEntity (PrivateLJHttpURLs)

- (NSURL *)_URLWithUsernameFormat:(NSString *)format;

@end


@implementation LJUserEntity (LJHttpURLs)

- (NSURL *)_URLWithUsernameFormat:(NSString *)format
{
    NSString *string = [NSString stringWithFormat:format, [self username]];
    NSURL *serverURL = [[[self account] server] URL];
    return [[NSURL URLWithString:string relativeToURL:serverURL] absoluteURL];
}

- (NSURL *)userProfileHttpURL
{
    return [self _URLWithUsernameFormat:@"/userinfo.bml?user=%@"];
}

- (NSURL *)memoriesHttpURL
{
    return [self _URLWithUsernameFormat:@"/tools/memories.bml?user=%@"];
}

- (NSURL *)toDoListHttpURL
{
    return [self _URLWithUsernameFormat:@"/todo/?user=%@"];
}

- (NSURL *)rssFeedURL
{
    return [self _URLWithUsernameFormat:@"/users/%@/data/rss"];
}

- (NSURL *)atomFeedURL
{
    return [self _URLWithUsernameFormat:@"/users/%@/data/atom"];
}

- (NSURL *)foafURL 
{
    return [self _URLWithUsernameFormat:@"/users/%@/data/foaf"];
}

- (NSURL *)recentEntriesHttpURL
{
    return [self _URLWithUsernameFormat:@"/users/%@/"];
}

@end


@implementation LJFriend (LJHttpURLs)

- (NSURL *)joinCommunityHttpURL
{
    return [self _URLWithUsernameFormat:@"/community/join.bml?comm=%@"];
}

- (NSURL *)leaveCommunityHttpURL
{
    return [self _URLWithUsernameFormat:@"/community/leave.bml?comm=%@"];
}

@end
