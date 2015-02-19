//
//  LJMoods.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Foundation

private let moodsDictionary = "LJMoodsDictionary"

public class LJMoods: NSObject, NSSecureCoding {
	private var moods = [String: String]()
	
	private var moodNames: [String] {
		var moodArray = moods.keys.array
		
		moodArray.sort { (lhs, rhs) -> Bool in
			var aRet = lhs.localizedStandardCompare(rhs)
			
			return aRet == .OrderedAscending
		}
		return moodArray
	}
	
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
			moods[moodName] = moodID
			if moodID.toInt()! > highestMoodID {
				highestMoodID = moodID.toInt()!
			}
		}
	}
	
	public override init() {


		super.init()
	}


	/// @property highestMoodID
	/// @abstract The highest value mood ID.
	public private(set) var highestMoodID: Int = 0
	
	
	/// @property highestMoodIDString
	/// @abstract The highest value mood ID as a string.
	public var highestMoodIDString: String {
		return "\(highestMoodID)"
	}

	internal func updateMoodsWithLoginReply(reply: NSDictionary) {
		let count = reply["mood_count"] as Int
		
		for (var i = 1; i <= count; i++) {
			let moodNameKey = "mood_\(i)_name"
			let moodIDKey = "mood_\(i)_id"

		}
	}
	/*
- (void)updateMoodsWithLoginReply:(NSDictionary *)reply
{
NSInteger count = [reply[@"mood_count"] integerValue];
for (NSInteger i = 1; i <= count; i++) {
NSString *moodNameKey = [NSString stringWithFormat:@"mood_%ld_name", (long)i];
NSString *moodIDKey = [NSString stringWithFormat:@"mood_%ld_id", (long)i];
[self _addMoodID:reply[moodIDKey]
forName:reply[moodNameKey]];
}
}
*/

	// MARK: - NSCoding
	public func encodeWithCoder(aCoder: NSCoder) {
		let moodmap = NSDictionary(objects: moods.keys.array, forKeys: moods.values.array)
		aCoder.encodeObject(moodmap, forKey: moodsDictionary)
	}
	
	
	public required init(coder aDecoder: NSCoder) {
		let moodmap = aDecoder.decodeObjectForKey(moodsDictionary) as NSDictionary as [String: String]
		let ohai = NSDictionary(objects: moodmap.keys.array, forKeys: moodmap.values.array)
		
		
		
		super.init()
		
		for (key, value) in moodmap {
			
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
