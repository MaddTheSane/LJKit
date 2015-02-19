//
//  LJMoods.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Foundation

private let moodsDictionary = "LJMoodsDictionary"

/*!
@class LJMoods
@abstract Represents the set of moods known to a LiveJournal server.
@discussion
An LJMoods object represents a set of moods and their IDs.

This class implements the NSComboBoxDataSource protocol, including
autocompleting mood names, so it can be used as a data source for
NSComboBoxes in your human interface.
*/
@objc(LJMoods) public class LJMoods: NSObject, NSSecureCoding {
	private var moods: [(name: String, ID: String)] = []
	
	private func indexForMoodName(moodName: String, hypothetical flag: Bool) -> Int? {
		let sml = moodNames
		var min = 0
		var max = sml.count - 1
		while min <= max {
			let i = (min + max) / 2
			let name = sml[i]
			switch name.compare(moodName) {
			case .OrderedAscending:
				min = i + 1
				
			case .OrderedDescending:
				max = i - 1
				
			case .OrderedSame:
				return i
			}
		}
		// If flag is true, then we return the index that the moodname WOULD have
		// had WERE in the array.
		return flag ? min : nil
	}
	
	private func addMoodID(moodID: String, name moodName: String) {
		if !moodID.isEmpty && !moodName.isEmpty {
			var index = indexForMoodName(moodName, hypothetical: true)!
			moods.insert((moodName, moodID), atIndex: index)
			if moodID.toInt()! > highestMoodID {
				highestMoodID = moodID.toInt()!
			}
		}
	}
	
	/// Initialize an LJMoods object.
	public override init() {


		super.init()
	}


	///  The highest value mood ID.
	public private(set) var highestMoodID: Int = 0
	
	
	/// The highest value mood ID as a string.
	public var highestMoodIDString: String {
		return "\(highestMoodID)"
	}

	/// Obtain the ID number for a given mood name.
	public func IDForMoodName(moodName: String) -> Int {
		return IDStringForMoodName(moodName)?.toInt() ?? 0
	}
	
	/// Obtain the ID number for a given mood name as a string.
	public func IDStringForMoodName(moodName: String) -> String? {
		if let index = indexForMoodName(moodName, hypothetical: false) {
			return moods[index].ID
		} else {
			return nil
		}
	}
	
	/// Obtain the mood name for a given mood id.
	public func moodNameFromID(moodID: String) -> String? {
		if let index = indexForMoodID(moodID) {
			return moods[index].name
		}
		
		return nil
	}

	private func indexForMoodID(moodID: String) -> Int? {
		for (index, key) in enumerate(moods) {
			if key.ID == moodID {
				return index
			}
		}
		
		return nil
	}
	
	/// A sorted array of all known moods.
	public var moodNames: [String] {
		var moodArray = moods.map { (aMood) -> String in
			return aMood.name
		}
		
		return moodArray
	}
	
	internal func updateMoodsWithLoginReply(reply: NSDictionary) {
		let count = reply["mood_count"] as Int
		
		for (var i = 1; i <= count; i++) {
			let moodNameKey = "mood_\(i)_name"
			let moodIDKey = "mood_\(i)_id"
			
			addMoodID(reply[moodIDKey] as String, name: reply[moodNameKey] as String)
		}
	}

	// MARK: - NSCoding
	public func encodeWithCoder(aCoder: NSCoder) {
		var moodMap = [String: String]()
		moods.map { (anObj) -> Void in
			moodMap[anObj.ID] = anObj.name
		}
		
		aCoder.encodeObject(moodMap as NSDictionary, forKey: moodsDictionary)
	}
	
	public required init(coder aDecoder: NSCoder) {
		let moodmap = aDecoder.decodeObjectForKey(moodsDictionary) as NSDictionary as [String: String]
		
		super.init()
		
		for (key, value) in moodmap {
			addMoodID(key, name: value)
		}
	}
	
	public class func supportsSecureCoding() -> Bool {
		return true
	}
}


#if os(OSX)
	import Cocoa
	
	extension LJMoods: NSComboBoxDataSource {
		public func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
			return moods.count
		}
		
		public func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
			return moodNames[index]
		}
		
		public func comboBox(aComboBox: NSComboBox, completedString string: String) -> String? {
			var index = indexForMoodName(string, hypothetical: true) ?? -1
			if (index < moods.count) {
				var moodName = moodNames[index];
				if (moodName.hasPrefix(string)) {
					return moodName
				}
			}
			return nil;
			
		}
		
		public func comboBox(aComboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
			return indexForMoodName(string, hypothetical: false) ?? -1
		}
	}
	
#endif
