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
 The LJKit uses of HeaderDoc.  The comments that start with a ! can be converted
 to HTML by Apple's HeaderDoc tool.  You can download HeaderDoc from
 http://www.opensource.apple.com/projects/headerdoc/.
 */

/*!
 @header LJKit

 LJKit is a Mac OS X framework written in Objective-C which encapsulates the
 workings of the LiveJournal Client-Server Protocol.  It is designed to handle
 most of the gruntwork involved in writing a LiveJournal client.

 Your feedback is essential the continued development of LJKit.  If you have any
 questions or comments, please don't hesitate to send email to me at
 benzado&#64;livejournal.com.

 LJKit is distributed under the terms of the GNU Lesser General Public License.
 A full copy of the license is available as the file License.txt in the
 Resources subdirectory of the LJKit bundle.  In short, you may use LJKit to
 write a client application, and you are free to license your client as you
 choose.  However, any changes you make to LJKit must be distributed under the
 same terms it was licensed to you.

 Methods and functions without HeaderDoc comments are not intended for use by
 client applications.  Don't use them in your client, unless you want it to
 break when LJKit is updated.  All interfaces are subject to change until LJKit
 reaches version 1.0.

 To use LJKit in a client application, you must
 <ol>
 <li> <b>Build LJKit.framework.</b>
 I recommend you configure Project Builder to put build products in a separate
 location from your project files.  This is not required, but since your
 compiler output will be separate from your source code it is easier to make
 backups and keep your disk tidy.
 <li> <b>Add LJKit.framework to your project.</b>
 You can either drag and drop the bundle from the Finder, or select
 <b>Add Frameworks...</b> from Project Builder's Project menu.
 <li> <b>Add a Copy Files phase to your target.</b>
 Edit your target, select Build Phases, then select Project -> New Build Phase ->
 New Copy Files Build Phase from the menu bar.  In the resulting panel, select
 Frameworks from the Where pop up menu and drag LJKit.framework from your
 project's Files tab to the Files to copy area.  This will place a copy of LJKit
 inside your application's bundle.  This is the recommended way to include it,
 since otherwise you must complicate your application's installation process by
 requiring users to copy the framework to another location on their hard disk.
 </ol>

 If you think you have found a bug, email all relevant information to
 benzado&#64;livejournal.com.  If you are trying to trace an exception, you can
 catch exceptions in Project Builder's debugger by setting a symbolic breakpoint
 on "-[NSException raise]".  To do so, open the Breakpoints tab, click the New
 button, and type the expression in quotes above.  Be sure NOT to put a space
 between the dash and the opening square bracket.

 Happy hacking!
 */

#import <LJKit/LJAccount.h>
#import <LJKit/LJAccount_EditFriends.h>
#import <LJKit/LJCheckFriendsSession.h>
#import <LJKit/LJServer.h>
#import <LJKit/LJMoods.h>
#import <LJKit/LJJournal.h>
#import <LJKit/LJEntry.h>
#import <LJKit/LJEntry_Metadata.h>
#import <LJKit/LJEntrySummary.h>
#import <LJKit/LJFriend.h>
#import <LJKit/LJGroup.h>
#import <LJKit/LJHttpURLs.h>
