//
//  Miscellaneous.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Foundation
import CommonCrypto

/*
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
*/

internal func MD5HexDigest(string: String) -> String {
	var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
	var hexString = ""
	
	CC_MD5(string, UInt32(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), &digest)
	
	for aVal in digest {
		hexString += String(format: "%02x", aVal)
	}
	
	return hexString
}
