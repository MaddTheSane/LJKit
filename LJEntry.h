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
 2004-03-13 [BPR] Added setAccount:
 */

#import <Foundation/Foundation.h>
#import <LJKit/LJEntryRoot.h>

@class LJAccount, LJJournal, LJGroup;

NS_ASSUME_NONNULL_BEGIN

/*!
 @const LJEntryWillSaveToJournalNotification
 Posted before an entry is saved to the server.  The notification object
 is the instance of LJEntry or LJEntrySummary that is being saved.
 */
FOUNDATION_EXPORT NSString * const LJEntryWillSaveToJournalNotification;

/*!
 @const LJEntryDidSaveToJournalNotification
 Posted after an entry is successfully saved to the server.  The
 notification object is the instance of LJEntry or LJEntrySummary that was
 saved.
 */
FOUNDATION_EXPORT NSString * const LJEntryDidSaveToJournalNotification;

/*!
 @const LJEntryDidNotSaveToJournalNotification
 Posted after an attempt to save an entry to the server fails.  The
 notification object is the instance of LJEntry or LJEntrySummary, and the
 userInfo key @"LJException" is the exception that was raised while the
 attempt was made.
 */
FOUNDATION_EXPORT NSString * const LJEntryDidNotSaveToJournalNotification;

/*!
 @class LJEntry
 @abstract Represents a LiveJournal entry.
 @discussion
 The LJEntry class represents a LiveJournal entry.  An entry is either unassociated,
 associated with a journal, or posted to a journal.  When entries are created using
 init they are unassociated.  You can associate them with a journal by calling the
 setJournal: method.  The entry is finally posted by calling saveToJournal.  Entries
 that are obtained from LJJournal's getEntries... methods are posted entries.

 <TABLE BORDER=1>
 <TR><TH> unassociated </TH> <TD> journal == nil </TD></TR>
 <TR><TH> associated </TH>   <TD> journal != nil, itemID == 0 </TD></TR>
 <TR><TH> posted </TH>       <TD> journal != nil, itemID != 0 </TD></TR>
 </TABLE>
 */
@interface LJEntry : LJEntryRoot <NSCoding>
{
@protected
    NSString *_subject;
    NSMutableDictionary *_properties;
    NSMutableDictionary *_customInfo;
}

/*!
 @method init
 @abstract Initializes a new journal entry.
 @discussion
 Initializes a new journal entry.  The date is set to the current date and time.
 All other fields are left blank.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
 @property journal
 @abstract The journal associated with the receiver.
 @discussion
 Sets the journal this entry is associated with.  To cause the receiver to become
 unassociated, set journal to nil.  An exception is raised if you attempt to
 change the journal of a posted entry.

 If through this method you cause the receiver to become associated with an
 different account than before, and the security mode is LJGroupModeSecurity,
 the set of allowed groups will be cleared, as groups have no meaning outside
 of the account they exist in.
 */
@property (NS_NONATOMIC_IOSONLY, readwrite, strong, nullable) LJJournal *journal;

/*!
 @property account
 @abstract The account associated with the receiver.
 @discussion
 Sets the account this entry is associated with.  To cause the receiver to become
 unassociated, set the account to nil.  An exception is raised if you attempt to
 change the account of a posted entry.

 If through this method you cause the receiver to become associated with an
 different account than before, and the security mode is LJGroupModeSecurity,
 the set of allowed groups will be cleared, as groups have no meaning outside
 of the account they exist in.
 */
@property (NS_NONATOMIC_IOSONLY, readwrite, strong) LJAccount *account;

/*!
 @property date
 @abstract The date of the receiver.
 @discussion
 Sets the date of the receiver.  Note that if you want to post an entry with a date
 earlier than the latest entry already in the journal the server will return an error
 asking you to set the backdate option on this entry.  See  setOptionBackdated:.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSDate *date;

/*!
 @property subject
 @abstract The subject of the receiver.
 */
@property (nonatomic, copy) NSString *subject;

/*!
 @property content
 @abstract The content of the receiver.
 */
@property (NS_NONATOMIC_IOSONLY, copy) NSString *content;

/*!
 @property edited
 @abstract The edited status of this entry.
 @discussion
 Returns YES if this entry has changed since it was last downloaded or saved, NO
 otherwise.  The edited flag is set whenever any of the set... methods are
 called, and reset when saveToJournal completes successfully.
 You can call this method to mark this entry as edited or unedited as you see
 fit.
 */
@property (NS_NONATOMIC_IOSONLY, getter=isEdited) BOOL edited;

/*!
 @property securityMode
 @abstract Set the security mode of the receiver.
 @discussion
 The security modes are explained in the LJEntry Security Modes enumeration.

 You cannot set the security mode to LJSecurityModeGroup unless the receiver
 has been associated with a journal.  This is because groups only have meaning
 in the context of a particular account, and an unassociated entry has no
 connection to an account object.
 */
@property (NS_NONATOMIC_IOSONLY) LJSecurityMode securityMode;

/*!
 @method setAccessAllowed:forGroup:
 @abstract Allow or deny access for a specific group.
 @discussion
 Set whether a group is allowed to access this journal if the security mode is
 set to LJSecurityModeGroup.  If the security mode is something else, an
 exception is raised.

 You cannot use this and other group security related methods on unassociated
 entries.  If you try, an exception will be raised.  This is because groups
 have no meaning outside of their account, and unassociated entries are not
 attached to an account.
 */
- (void)setAccessAllowed:(BOOL)allowed forGroup:(LJGroup *)group;

/*!
 @method setGroupsAllowedAccessMask:
 @discussion
 Set the bitmask which defines the groups allowed to access this entry.
 This value is ignored if not in LJSecurityModeGroup.
 */
- (void)setGroupsAllowedAccessMask:(unsigned int)mask;

/*!
 @method saveToJournal
 @abstract Saves the receiver's data on the server.
 @discussion
 If the receiver is unassociated, raises an exception.
 If the receiver is associated with a journal, sends a postevent message to the
 server and sets the itemID of the receiver, making is a posted entry.
 If the receiver is posted, sends an editevent message to the server.
 */
- (void)saveToJournal;

/*!
 @property customInfo
 @abstract The custom info dictionary for this entry.
 @discussion
 Returns a mutable dictionary object you can use to store whatever
 information you would like to attach to this entry.  All keys and
 values must support the NSCoding protocol.

 This property is preserved during archiving.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSMutableDictionary *customInfo;

@end

NS_ASSUME_NONNULL_END
