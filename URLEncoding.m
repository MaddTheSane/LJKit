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
 2004-01-06 [BPR] Functions renamed to include LJ prefix.
 */

#import "URLEncoding.h"
#import "Miscellaneous.h"

/*
 URL encodes the string argument and appends the result to data.
 */
void LJAppendURLEncodingOfStringToData(NSString *string, NSMutableData *data)
{
    const char *bytes;
    unsigned char c, digit;
    char hex[3];
    int i;

    hex[0] = '%';
    bytes = [string UTF8String];
    for ( i = 0; (c = bytes[i]); i++ ) {
        if (c == ' ') {
            [data appendBytes:"+" length:1];
        } else if (((c >= 'a') && (c <= 'z')) ||
                   ((c >= 'A') && (c <= 'Z')) ||
                   ((c >= '0') && (c <= '9'))) {
            [data appendBytes:&c length:1];
        } else {
            digit = c >> 4;
            hex[1] = (digit < 10) ? ('0' + digit) : ('A' + (digit - 10));
            digit = c & 0x0F;
            hex[2] = (digit < 10) ? ('0' + digit) : ('A' + (digit - 10));
            [data appendBytes:hex length:3];
        }
    }
}

/*
 Decodes an URL encoded string and returns the result as a string.
 */
NSString *LJURLDecodeString(NSString *string)
{
    const char *encodedBytes;
    char *decodedBytes;
    int si, di;
    char c, hexValue;
    NSMutableData *decodedData;
    NSString *decodedString;

    if ([string length] == 0) return nil;
    // The decoded string will be AT MOST as long as the encoded string.
    decodedData = [[NSMutableData alloc] initWithLength:[string length]];
    decodedBytes = (char *)[decodedData mutableBytes];
    encodedBytes = [string UTF8String];
    di = 0;
    for ( si = 0; (c = encodedBytes[si]); si++ ) {
        if (c == '+') {
            decodedBytes[di++] = ' ';
        } else if (c == '%') {
            hexValue = ((ValueForHexDigit(encodedBytes[si+1]) << 4) +
                        (ValueForHexDigit(encodedBytes[si+2])));
            si += 2;
            decodedBytes[di++] = hexValue;
        } else {
            decodedBytes[di++] = c;
        }
    }
    [decodedData setLength:di];
    decodedString = [[NSString alloc] initWithData:decodedData
                                          encoding:NSUTF8StringEncoding];
    return decodedString;
}

/*
 * Creates an NSData object with the key-value pairs URL encoded,
 * suitable for sending to a HTTP server.  Note: &, the pair separator,
 * is prepended to ALL pairs, including the first one.  This is peculiar
 * to the LJKit, since the mode key and value will always be prepended
 * to the result.
 */
NSData *LJCreateURLEncodedFormData(NSDictionary *dict)
{
    NSMutableData *data = [NSMutableData dataWithCapacity:[dict count]*16];
    
    for (NSString *key in dict) {
        [data appendBytes:"&" length:1];
        LJAppendURLEncodingOfStringToData(key, data);
        [data appendBytes:"=" length:1];
        LJAppendURLEncodingOfStringToData(dict[key], data);
    }
    return [data copy];
}

/*
 Parses a LiveJournal server response and returns the key/value pairs as
 an NSDictionary.
 */
NSDictionary *ParseLJReplyData(NSData *data)
{
    NSCParameterAssert(data);
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (string == nil) {
        [NSException raise:@"LJParseError"
                    format:(@"Unable convert the response data into a UTF8 "
                            @"encoded string.")];
    }
    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    NSInteger count = [lines count];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:(count / 2)];
    for (NSInteger i = 1; i < count; i += 2 ) {
        dict[lines[(i - 1)]] = lines[(i)];
    }
    return [dict copy];
}
