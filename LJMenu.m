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

#import "LJMenu.h"

@implementation LJMenu

- (id)initWithTitle:(NSString *)title loginReply:(NSDictionary *)reply
{
    self = [super initWithTitle:title];
    if (self) {
        [self setAutoenablesItems:NO];
        [self populateMenu:self number:@"0" loginReply:reply];
    }
    return self;
}

// These macros make the following code easier to read.
#define LJ_MENU_COUNT(m) [NSString stringWithFormat:@"menu_%@_count", m]
#define LJ_MENU_TEXT(m,i) [NSString stringWithFormat:@"menu_%@_%d_text", m, i]
#define LJ_MENU_URL(m,i) [NSString stringWithFormat:@"menu_%@_%d_url", m, i]
#define LJ_MENU_SUB(m,i) [NSString stringWithFormat:@"menu_%@_%d_sub", m, i]

- (void)populateMenu:(NSMenu *)menu
              number:(NSString *)number
          loginReply:(NSDictionary *)reply
{
    int itemCount, i;
    NSString *itemText, *itemSub, *itemUrl;
    NSMenuItem *item;
    NSMenu *submenu;

    itemCount = [[reply objectForKey:LJ_MENU_COUNT(number)] intValue];
    for (i = 1; i <= itemCount; i++) {
        itemText = [reply objectForKey:LJ_MENU_TEXT(number, i)];
        itemUrl = [reply objectForKey:LJ_MENU_URL(number, i)];
        itemSub = [reply objectForKey:LJ_MENU_SUB(number, i)];
        if ([itemText isEqualToString:@"-"]) {
            item = [NSMenuItem separatorItem];
        } else {
            item = [[NSMenuItem alloc] initWithTitle:itemText
                                              action:@selector(launchMenuItemUrl:)
                                       keyEquivalent:@""];
            if (itemUrl) {
                [item setTarget:self];
                [item setRepresentedObject:[NSURL URLWithString:itemUrl]];
            } else if (itemSub) {
                submenu = [[NSMenu alloc] initWithTitle:itemText];
                [self populateMenu:submenu number:itemSub loginReply:reply];
                [item setSubmenu:submenu];
            }
        }
        [menu addItem:item];
    }
}

- (IBAction)launchMenuItemUrl:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[sender representedObject]];
}

@end
