//
//  LJUserEntity.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Foundation

public class LJUserEntity: NSObject {
    /*!
    @property username
    @abstract The username of the receiver.
    */
    public private(set) var username: String;
    
    /*!
    @property fullname
    @abstract The full name of the receiver.
    @discussion
    Returns the receiver's full name, as reported by the server.  If not
    available, this method returns the receiver's username.
    */
    public private(set) var fullname: String

    public override init() {
        username = ""
        fullname = ""
        
        super.init()
    }
}
