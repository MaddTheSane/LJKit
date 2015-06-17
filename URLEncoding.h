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

#ifndef __private_extern
#define __private_extern __attribute__((visibility("hidden")))
#endif

/**
 *  URL encodes the string argument and appends the result to data.
 */
__private_extern void LJAppendURLEncodingOfStringToData(NSString *string, NSMutableData *data);

/**
 *  Decodes an URL encoded string and returns the result as a string.
 */
__private_extern NSString *LJURLDecodeString(NSString *es);

/**
 * Creates an NSData object with the key-value pairs URL encoded,
 * suitable for sending to a HTTP server.  Note: &, the pair separator,
 * is prepended to ALL pairs, including the first one.  This is peculiar
 * to the LJKit, since the mode key and value will always be prepended
 * to the result.
 */
__private_extern NSData *LJCreateURLEncodedFormData(NSDictionary *dict);

/**
 *  Parses a LiveJournal server response and returns the key/value pairs as
 *  an NSDictionary.
 */
__private_extern NSDictionary *ParseLJReplyData(NSData *data);
