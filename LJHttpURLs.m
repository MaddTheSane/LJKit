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

#import "LJHttpURLs.h"

@implementation LJAccount (LJHttpURLs)

- (NSURL *)userProfileHttpURL
{
    NSString *s;
    s = [NSString stringWithFormat:@"/userinfo.bml?user=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[_server URL]] absoluteURL];
}

- (NSURL *)memoriesHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/tools/memories.bml?user=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[_server URL]] absoluteURL];
}

- (NSURL *)toDoListHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/todo/?user=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[_server URL]] absoluteURL];
}

@end

@implementation LJJournal (LJHttpURLs)

- (NSURL *)recentEntriesHttpURL
{
    NSString *s;
    s = [NSString stringWithFormat:@"/users/%@/", _name];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
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
    NSString *s;
    // New URL Code: remove "day" from URL
    s = [date descriptionWithCalendarFormat:@"day/%Y/%m/%d/" timeZone:nil locale:nil];
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
    NSURL *baseURL = [[_account defaultJournal] friendsEntriesHttpURL];
    return [[NSURL URLWithString:_name relativeToURL:baseURL] absoluteURL];
}

@end

@implementation LJFriend (LJHttpURLs)

- (NSURL *)userProfileHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/userinfo.bml?user=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
}

- (NSURL *)memoriesHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/tools/memories.bml?user=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
}

- (NSURL *)toDoListHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/todo/?user=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
}

- (NSURL *)rssFeedURL
{
    NSString *s = [NSString stringWithFormat:@"/users/%@/data/rss", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];	
}

- (NSURL *)atomFeedURL
{
    NSString *s = [NSString stringWithFormat:@"/users/%@/data/atom", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];		
}

- (NSURL *)foafURL 
{
    NSString *s = [NSString stringWithFormat:@"/users/%@/data/foaf", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];		
}

- (NSURL *)recentEntriesHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/users/%@/", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
}

- (NSURL *)joinCommunityHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/community/join.bml?comm=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
}

- (NSURL *)leaveCommunityHttpURL
{
    NSString *s = [NSString stringWithFormat:@"/community/leave.bml?comm=%@", _username];
    return [[NSURL URLWithString:s relativeToURL:[[_account server] URL]] absoluteURL];
}

@end
