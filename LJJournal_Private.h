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

#import "LJJournal.h"

@interface LJJournal (FrameworkPrivate)
+ (LJJournal *)_journalWithName:(NSString *)name account:(LJAccount *)account;
+ (NSArray *)_journalArrayFromLoginReply:(NSDictionary *)reply account:(LJAccount *)account;
- (id)initWithName:(NSString *)name account:(LJAccount *)account;
@end