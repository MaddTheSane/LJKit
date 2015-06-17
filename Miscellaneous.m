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
 2004-01-06 [BPR] Replaced cString with UTF8String in MD5HexDigest().
 2004-01-06 [BPR] Removed ImmutablizeObject()
 2011-02-16 [MTS] Use CommonCrypto instead of openssl
 */

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import "Miscellaneous.h"

NSString *MD5HexDigest(NSString *string)
{
    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};
    NSMutableString *hexString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    const char *utfString = [string UTF8String];
    CC_MD5((const unsigned char*)utfString, (unsigned int)strlen(utfString), digest);
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hexString appendFormat:@"%02x", digest[i]];
    }
    return [NSString stringWithString: hexString];
}

char ValueForHexDigit(char digit)
{
    if ('0' <= digit && digit <= '9') {
        return (digit - '0');
    } else if ('a' <= digit && digit <= 'f') {
        return (digit - 'a' + 10);
    } else if ('A' <= digit && digit <= 'F') {
        return (digit - 'A' + 10);
    } else {
        [NSException raise:@"ValueForHexDigit"
                    format:@"Unable to parse: '%c' (0x%X) is not a hex digit.",
            digit, digit];
        return 0;
    }
}

LJColorRef ColorForHTMLCode(NSString *code)
{
    // Code is of the form "#RRGGBB"
    CGFloat r, g, b;

    if ([code length] < 7) {
        [NSException raise:@"ColorForHTMLCode"
                    format:@"Cannot parse: '%@' is too short.", code];
        return nil;
    }
    r = ((ValueForHexDigit([code characterAtIndex:1]) << 4) +
          ValueForHexDigit([code characterAtIndex:2])) / 255.0;
    g = ((ValueForHexDigit([code characterAtIndex:3]) << 4) +
          ValueForHexDigit([code characterAtIndex:4])) / 255.0;
    b = ((ValueForHexDigit([code characterAtIndex:5]) << 4) +
          ValueForHexDigit([code characterAtIndex:6])) / 255.0;
#if TARGET_OS_IPHONE
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
#else
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
#endif
}

NSString *HTMLCodeForColor(LJColorRef color)
{
#if TARGET_OS_IPHONE
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    return [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)(255.0 * red),
            (int)(255.0 * green),
            (int)(255.0 * blue)];
#else
    OurColor *rgbColor;
    if ([[color colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace])
        rgbColor = color;
    else
        rgbColor = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    return [NSString stringWithFormat:@"#%02X%02X%02X",
        (int)(255.0 * [rgbColor redComponent]),
        (int)(255.0 * [rgbColor greenComponent]),
        (int)(255.0 * [rgbColor blueComponent])];
#endif
}
