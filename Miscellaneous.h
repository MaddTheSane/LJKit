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
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "LJColor.h"

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

/*!
 * Returns the MD5 digest of the given NSString object as a hex
 * encoded string.  Uses the crypto library distributed with OS X.
 */
__private_extern NSString *MD5HexDigest(NSString *string);

/*!
 * Converts a hexadecimal digit character to its value.
 * This function is case insensitive and returns 0x10 if the hex
 * digit is invalid.
 */
__private_extern char ValueForHexDigit(char digit);

/*!
 * Creates an NSColor object represented by a given HTML color code.
 * (e.g., "#FFCC00")
 */
__private_extern LJColorRef ColorForHTMLCode(NSString *code);

/*!
 * Returns the HTML color code which represents the given NSColor object.
 * Assumes the NSColor is an RGB color.
 */
__private_extern NSString *HTMLCodeForColor(LJColorRef color);
