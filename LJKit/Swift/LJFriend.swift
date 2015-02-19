//
//  LJFriend.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Cocoa

public class LJFriend: LJUserEntity {
    public struct LJFriendship : RawOptionSetType {
        typealias RawValue = UInt
        private var value: UInt = 0
        init(_ value: UInt) { self.value = value }
        public init(rawValue value: UInt) { self.value = value }
        public init(nilLiteral: ()) { self.value = 0 }
        public static var allZeros: LJFriendship { return self(0) }
        public static func fromMask(raw: UInt) -> LJFriendship { return self(raw) }
        public var rawValue: UInt { return self.value }
        
        public static var Outgoing: LJFriendship { return LJFriendship(1) }
        public static var Incoming: LJFriendship { return LJFriendship(2) }
        public static var Mutual: LJFriendship { return LJFriendship(3) }
    }

}
