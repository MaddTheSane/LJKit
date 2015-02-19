//
//  LJAccount.swift
//  LJKit
//
//  Created by C.W. Betts on 2/19/15.
//
//

import Cocoa

/// Methods implemented by the delegate
@objc public protocol LJAccountDelegate {
	/// The account object delegate can veto connections to the server by implementing
	/// this method and returning NO.  If a connection is vetoed, an exception is
	/// raised.
	optional func accountShouldConnect(sender: LJAccount)
	
	/// Called before an account will connect to the server.
	/// What is [notification object]???
	optional func accountWillConnect(notification: NSNotification)
	
	/// Called immediately after a connection to the server is completed.
	/// Is it called if an error occurs???
	/// What is [notification object]???
	optional func accountDidConnect(notification: NSNotification)
}


/*!
@class LJAccount

@abstract Represents an account on a LiveJournal server.

@discussion
An LJAccount object represents a user's account on a LiveJournal server.
This is the primary class used to communicate over the network with the
server.

LJAccount implements the NSCoding protocol, meaning account objects may
be archived to disk and loaded at a later time.  This functionality can
be used by clients to provide offline capabilities.  Properties which are
preserved during archiving are indicated in the documentation for their
accessor methods.  The an account's customInfo dictionary can be used
to store client specific information with the account.
*/
public class LJAccount: LJUserEntity, NSSecureCoding {
	///  These flags are used with the loginWithPassword:flags: method to
	/// determine what features of the LJKit you wish to enable or disable.
	/// They can be combined with the bitwise OR operator (|).
	public struct LoginFlags : RawOptionSetType {
		typealias RawValue = UInt32
		private var value: UInt32 = 0
		init(_ value: UInt32) { self.value = value }
		public init(rawValue value: UInt32) { self.value = value }
		public init(nilLiteral: ()) { self.value = 0 }
		public static var allZeros: LoginFlags { return self(0) }
		public static func fromMask(raw: UInt32) -> LoginFlags { return self(raw) }
		public var rawValue: UInt32 { return self.value }
		
		/// Don't download any extra information.
		public static var None: LoginFlags { return self(0) }
		
		/// Download mood information.  Updates the current mood object if it has
		/// already been set using the setMoods: method.  Otherwise, creates a new
		/// moods object.
		public static var GetMoods: LoginFlags { return LoginFlags(1 << 0) }
		
		/// Creates a web menu.  After login it can be retrieved with the menu
		/// method.
		public static var GetMenu: LoginFlags { return LoginFlags(1 << 1) }
		
		
		/// Download keywords and URLs for account pictures.  After login they can
		/// be retrieved with the userPicturesDictionary method.
		public static var GetUserPictures: LoginFlags { return LoginFlags(1 << 2) }
		
		/// Don't enable fast server access, even if the server offers it.
		/// Has no effect if fast server access is not offered.
		public static var DoNotUseFastServers: LoginFlags { return LoginFlags(1 << 3) }
		
		/// Downloads all available information and enabled fast server access if
		/// offered.
		public static var DefaultFlags: LoginFlags { return .GetMoods | .GetMenu | .GetUserPictures }
		
		/// These bits are reserved and must be set to zero.
		public static var Reserved: LoginFlags { return LoginFlags(0xfffffff0) }
	}

	/// The delegate is automatically registered to
	/// receive notifications if it implements the methods below.
	public weak var delegate: LJAccountDelegate? {
		willSet {
			
		}
		
		didSet {
			
		}
	}
	
	/// @abstract Obtain an array containing all active account objects.
	/// @discussion
	/// The LJAccount class keeps track of all active account objects.
	/// This method returns the list in the form of an NSArray.
	public class var allAcounts: [LJAccount] {
		return []
	}
	
	/// @abstract Find the account with the given identifier.
	/// @param identifier The identifier for the desired account object.
	/// @result An account reference if found, nil otherwise.
	/// @discussion
	/// The LJAccount class keeps track of all active account objects.
	/// Using this method, you can obtain a reference to the account
	/// object with the given identifier.  If no matching account is
	/// found, returns nil.
	public class func accountWithIdentifier(identifier: String) -> LJAccount? {
		return nil
	}
	
	public class var defaultAccount: LJAccount {
/*!
@method defaultAccount
@abstract Returns the default account.
@result An account reference if any exists.
@discussion
The LJAccount keeps an internal list of all known account objects.
This method will return the one designated as default.  If you have
never set a default account, and arbitrary account will be returned.
This method is guaranteed not to return nil unless there are no
LJAccount objects in memory.
*/
		get {
			return LJAccount()
		}
/*!
@method setDefaultAccount:
@abstract Sets the default account.
@param newDefault The account to be set as the new default.
@discussion
Use this method to designate the account object to be returned by
defaultAccount.
The identifier of the selected account will be stored in the user defaults
database.  As account objects are unarchived, they check their identifiers
against the defaults database.  If a match is found, the unarchived object
will be registered as the default account.  Thus, default account status
is maintained across executions of your application if you archive account
object instances.  If you modify the defaults key directly default account
status will not be synchronized and the results are undefined.
*/
		set {
			
		}
	}
	
	@objc public var defaultAccount: Bool {
		
		/*!
		@method isDefault
		@abstract Determines if the receiver is the default account.
		@returns YES if the receiver is the default account, NO otherwise.
		@discussion
		Use this method to determine if the receiver is the object returned by
		defaultAccount.
		*/
		@objc(isDefault) get {
			return false
		}
		
		/*!
		@method setDefault:
		@abstract Makes the receiver the default.
		@param flag YES to make the receiver the default.
		@discussion
		Use this method to designate the receiver to be the object returned by
		defaultAccount.  If flag is NO, no action is taken.
		*/
		@objc(setDefault:) set {
			
		}
	}
	
	
	override convenience public init() {
		self.init(username: "")
	}
	
	/*!
	@method initWithUsername:
	@abstract Initializes an LJAccount object.
	@param username The user's login name.
	@discussion
	Initializes a newly allocated LJAccount.  To start communicating
	with the LiveJournal server you must call the loginWithPassword:
	method.  This is the designated initializer for the class.
	*/
	public init(username: String) {
		
		
		super.init()
	}
	
	/*!
	@method initWithContentsOfFile:
	@abstract Initializes an LJAccount object from a file.
	@param path The path to the previously archived account object.
	@discussion
	Initializes an account object using information previously saved
	to a file.  This method uses NSKeyedUnarchiver to read the file.
	*/
	public init?(contentsOfFile path: String) {
		if let unencoded = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? LJAccount {
			
		}
		
		super.init()
		
		return nil
	}
	
	/*!
	@method writeToFile:
	@abstract Archives the receiver to a file.
	@param path The path to save the object to.
	@discussion
	Archives the receiver to a file.  This is a convenience
	method; it uses NSKeyedArchiver to write the file to disk.
	This can be used by offline clients to save account info.
	@result YES on success; NO otherwise.
	*/
	public func writeToFile(path: String) -> Bool {
		return NSKeyedArchiver.archiveRootObject(self, toFile: path)
	}
	
	/*
/*!
@property server
@abstract The LJServer object used by the receiver.
@discussion
This property is preserved during archiving.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, strong) LJServer *server;

/*!
@method getReplyForMode:parameters:
@abstract Sends a request to the LiveJournal server.
@param mode The protocol mode to use.
@param parameters A set of variables and values to send to the server.
@result A set of variables and values received from the server.
@discussion
Sends a message to the LiveJournal server and returns the reply.
This message blocks until the message is sent over the network and
a reply is received.

Most LiveJournal protocol modes are handled by other classes in the
LJKit, so client programs won't need to call this method directly.

If an error occurs, an exception is raised.
*/
- (NSDictionary *)getReplyForMode:(NSString *)mode parameters:(NSDictionary *)parameters;

/*!
@method loginWithPassword:flags:
@abstract Logs in to the LiveJournal server.
@param password The user's password.
@param loginFlags A bitwise-OR combination of the login flag constants.
@discussion
Sends a login message to the server.  Use a combination of the login
flags to determine what features you want to download (e.g., moods,
pictures, etc.).

This method causes the password to be stored in the receiver so that
it can be sent to the server on subsequent messages.  You must call
this method before any other methods that may communicate with the
server.

The password is encoded as an MD5 hex digest before it is sent to the
server, in order to make it (slightly) more difficult for packet sniffers
to guess your actual password.

This method also sends the client name and version to the server.
The name and version is determined by your main bundle's infoDictionary.
By default, it uses the values of CFBundleName and CFBundleVersion.
If you wish to override one or both of these values, use the keys
LJClientName and LJClientVersion.  Finally, if none of these are
set the client is identified as LJKit/1.0.0.

If the username/password combination is incorrect, an exception will
be raised.
*/
- (void)loginWithPassword:(NSString *)password flags:(LJLoginFlag)loginFlags;

/*!
@method loginWithPassword:
@abstract Logs in to the LiveJournal server.
@discussion
Calls loginWithPassword:flags: with LJDefaultLoginFlags.
*/
- (void)loginWithPassword:(NSString *)password;

/*!
@method logout
@abstract Logs out of the LiveJournal server.
@discussion
Since the LiveJournal Client Server Protocol is stateless, logging out does
not result in any communication with the server.  This method destroys any
stored password information and posts LJAccountDidLogoutNotification.
*/
- (void)logout;

/*!
@property loginMessage
@abstract The server's login message.
@result The login message, or nil if none was available.
@discussion
The server may send a message for the user after login.  Your client
should call this method after loginWithPassword: and if it returns
a string, display the string to the user.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *loginMessage;

/*!
@property loggedIn
@abstract Returns YES if the account has been logged in.
@result YES if the account has successfully logged in, NO otherwise.
@discussion
*/
@property (NS_NONATOMIC_IOSONLY, getter=isLoggedIn, readonly) BOOL loggedIn;

/*!
@property menu
@abstract The web menu provided by the server.
@discussion
If you provided the LJGetMenuLoginFlag to the loginWithPassword:flags:
method, this method will return an NSMenu object you can display in your
application.  Otherwise, returns nil.
The menu is configured so that selection of any items
will direct the system default web browser to the correct web site.
Thus, all you need to do is display the menu in your interface.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMenu *menu;

/*!
@property moods
@abstract An LJMoods object for this account.
@discussion
If you provided the LJGetMoodsLoginFlag to the loginWithPassword:flags:
method, this method returns an LJMoods object, which represents all the
moods known to the system and maps them to IDs.
Otherwise, returns nil.

This property is preserved during archiving.
You can set the moods object before logging in, so that the
mood list can be saved between sessions.  If so, only new moods will be
downloaded from the server, to save on bandwidth.

*/
@property (NS_NONATOMIC_IOSONLY, strong) LJMoods *moods;

/*!
@property userPictureKeywords
@abstract An NSArray of account picture keywords in NSStrings.
@discussion
If you provided the LJGetPicturesLoginFlag to the loginWithPassword:flags:
method, this method will return an NSArray of NSStrings. Otherwise, returns nil.

This property is preserved during archiving.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *userPictureKeywords;


/*!
@property userPicturesDictionary
@abstract A dictionary of account picture keywords and URLs.
@discussion
If you provided the LJGetPicturesLoginFlag to the loginWithPassword:flags:
method, this method will return an NSDictionary mapping userpic keywords
to NSURL objects.  Otherwise, returns nil.

This property is preserved during archiving.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *userPicturesDictionary;

/*!
@method defaultUserPictureURL
@abstract Returns the URL of the default user picture.
@discussion
This property is preserved during archiving.
*/
- (NSURL *)defaultUserPictureURL;

/*!
@method defaultUserPictureURL
@abstract Returns the URL of the default user picture.
@discussion
This property is preserved during archiving.
*/
- (NSString *)defaultUserPictureKeyword;

/*!
@property userPicturesMenu
@abstract An NSMenu of all picture keywords for the receiver.
@discussion
Creates an NSMenu representing the user's picture keywords.  Each menu item
has the picture's URL as a its represented object, so you can retrieve the
NSURL object by calling [menuItem representedObject].
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMenu *userPicturesMenu;

/*!
@property journalArray
@abstract An array of LJJournal objects for this account.
@discussion
This method returns an array of LJJournal objects, representing the
journals this account has access to post into (e.g., communities).
It will always return an array with at least one element, the default
journal for this account.  The default journal is always at index 0.

This property is preserved during archiving.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *journalArray;

/*!
@method defaultJournal
@abstract Obtain the user's default journal.
@discussion
A convenience method to return the user's default journal (their own).

This property is preserved during archiving.
*/
- (LJJournal *)defaultJournal;

/*!
@method journalNamed:
@abstract Obtain the journal with the given name.
@result The desired journal if found, nil otherwise.
@discussion
Searches the user's list of journals and returns one with the given name,
or nil if none match.
*/
- (LJJournal *)journalNamed:(NSString *)name;

/*!
@property journalMenu
@abstract The NSMenu of all journals for this account.
@discussion
Creates an NSMenu of all journals for the receivers account.  Each
menu item is set to represent the appropriate LJJournal object, so
you may retrieve a journal by sending the representedObject message
to any of the menu items.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMenu *journalMenu;

/*!
@property customInfo
@abstract The custom info dictionary for this account.
@discussion
Returns a mutable dictionary object you can use to store whatever
information you would like to attach to this account.  All keys and
values must support the NSCoding protocol.

This property is preserved during archiving.
*/
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSMutableDictionary *customInfo;

/*!
@property identifier
@abstract The unique identifier for this account.
@discussion
Returns a unique identifier for the receiver.  It is of the form
"username&#64;hostname:port".
*/
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *identifier;

/*!
@property delegate
@abstract The receiver's delegate.
@discussion
The delegate is automatically registered to
receive notifications if it implements the methods below.
*/
@property (nonatomic, weak) id<LJAccountDelegate> delegate;

*/
	
	override var account: LJAccount? {
		return self
	}
	
	// MARK - NSCoding
	
	public class func supportsSecureCoding() -> Bool {
		return true
	}
	
	public func encodeWithCoder(aCoder: NSCoder) {
		
	}
	
	public required convenience init(coder aDecoder: NSCoder) {
		
		
		self.init()
	}
	
	// MARK - string constants
	/*!
 @const LJAccountWillConnectNotification
 Posted before the LJAccount initiates a connection to the server.
 The notification object is the LJAccount instance, and the userInfo
 dictionary contains:
	LJMode => the protocol mode
	LJParameters => the key-value pairs sent to the server
	LJConnection => a connection ID (an NSNumber)
 */
	public class var WillConnectNotification: String {
	return "LJAccountWillConnect"
	}
	
	/*!
 @const LJAccountWillConnectNotification
 Posted after the LJAccount initiates a connection to the server.
 The notification object is the LJAccount instance, and the userInfo
 dictionary contains:
	LJMode => the protocol mode
	LJParameters => the key-value pairs sent to the server
	LJConnection => a connection ID (an NSNumber)
	LJReply => the key-value pairs returned from the server on success
	LJException => the exception raised during the connection
 */
	public class var DidConnectNotification: String {
		return "LJAccountDidConnect"
	}
	/*!
 @const LJAccountWillLoginNotification
 @discussion
 Posted before an account object attempts to login.
 The notification object is the account instance.
 */
	public class var WillLoginNotification: String {
		return "LJAccountWillLogin"
	}
	
	/*!
 @const LJAccountDidLoginNotification
 @discussion
 Posted after an account object performs a successful login.
 The notification object is the account instance.
 */
	public class var DidLoginNotification: String {
		return "LJAccountDidLogin"
	}
	
	/*!
 @const LJAccountDidNotLoginNotification
 @discussion
 Posted after an account object fails to log in.
 The notification object is the account instance.
 The userInfo object for key LJException is the exception raised during login.
 */
	public class var DidNotLoginNotification: String {
		return "LJAccountDidNotLogin"
	}
	
	/*!
 @const LJAccountDidLogoutNotification
 @discussion
 Posted after an account object logs out.
 The notification object is the account instance.
 */
	public class var DidLogoutNotification: String {
		return "LJAccountDidLogout"
	}
	
	/*!
 @const LJAccountWillDownloadFriendsNotification
 @discussion
 Posted before an account object downloads friend/group info.
 The notification object is the account instance.
 */
	public class var WillDownloadFriendsNotification: String {
		return "LJAccountWillDownloadFriends"
	}
	
	/*!
	@const LJAccountDidDownloadFriendsNotification
 @discussion
 Posted after an account object downloads friend/group info.
 The notification object is the account instance.
 */
	public class var DidDownloadFriendsNotification: String {
		return "LJAccountDidDownloadFriends"
	}

}