//
//  Miscellaneous.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Foundation
import CommonCrypto

internal func MD5HexDigest(string: String) -> String {
	var digest = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
	var hexString = ""
	
	CC_MD5(string, UInt32(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)), &digest)
	
	for aVal in digest {
		hexString += String(format: "%02x", aVal)
	}
	
	return hexString
}
