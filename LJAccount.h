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
 2004-03-13 [BPR] Added default account methods.
 */

#import <Cocoa/Cocoa.h>
#import <LJKit/LJUserEntity.h>

@class LJServer, LJMoods, LJJournal;

#define LJKitBundle [NSBundle bundleForClass:[LJAccount class]]

/*!
 @enum Login Flags

 @discussion
 These flags are used with the loginWithPassword:flags: method to
 determine what features of the LJKit you wish to enable or disable.
 They can be combined with the bitwise OR operator (|).
 
 @constant LJNoLoginFlags
 Don't download any extra information.
 
 @constant LJGetMoodsLoginFlag
 Download mood information.  Updates the current mood object if it has
 already been set using the setMoods: method.  Otherwise, creates a new
 moods object.
 
 @constant LJGetMenuLoginFlag
 Creates a web menu.  After login it can be retrieved with the menu
 method.
 
 @constant LJGetUserPicturesLoginFlag
 Download keywords and URLs for account pictures.  After login they can
 be retrieved with the userPicturesDictionary method.
  
 @constant LJDoNotUseFastServersLoginFlag
 Don't enable fast server access, even if the server offers it.
 Has no effect if fast server access is not offered.
 
 @constant LJDefaultLoginFlags
 Downloads all available information and enabled fast server access if
 offered.
 
 @constant LJReservedLoginFlags
 These bits are reserved and must be set to zero.
 */
enum {
    LJNoLoginFlags                 = 0,
    LJGetMoodsLoginFlag            = 0x00000001,
    LJGetMenuLoginFlag             = 0x00000002,
    LJGetUserPicturesLoginFlag     = 0x00000004,
    LJDoNotUseFastServersLoginFlag = 0x00000008,
    LJDefaultLoginFlags            = 0x00000007,
    LJReservedLoginFlags           = 0xFFFFFFF0,
};

/*!
 @const LJAccountWillConnectNotification
 Posted before the LJAccount initiates a connection to the server.
 The notification object is the LJAccount instance, and the userInfo
 dictionary contains:
	LJMode => the protocol mode
	LJParameters => the key-value pairs sent to the server
	LJConnection => a connection ID (an NSNumber)
 */
FOUNDATION_EXPORT NSString * const LJAccountWillConnectNotification;

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
FOUNDATION_EXPORT NSString * const LJAccountDidConnectNotification;

/*!
 @const LJAccountWillLoginNotification
 @discussion
 Posted before an account object attempts to login.
 The notification object is the account instance.
 */
FOUNDATION_EXPORT NSString * const LJAccountWillLoginNotification;

/*!
 @const LJAccountDidLoginNotification
 @discussion
 Posted after an account object performs a successful login.
 The notification object is the account instance.
 */
FOUNDATION_EXPORT NSString * const LJAccountDidLoginNotification;

/*!
 @const LJAccountDidNotLoginNotification
 @discussion
 Posted after an account object fails to log in.
 The notification object is the account instance.
 The userInfo object for key LJException is the exception raised during login.
 */
FOUNDATION_EXPORT NSString * const LJAccountDidNotLoginNotification;

/*!
 @const LJAccountDidLogoutNotification
 @discussion
 Posted after an account object logs out.
 The notification object is the account instance.
 */
FOUNDATION_EXPORT NSString * const LJAccountDidNotLoginNotification;

/*!
 @const LJAccountWillDownloadFriendsNotification
 @discussion
 Posted before an account object downloads friend/group info.
 The notification object is the account instance.
 */
FOUNDATION_EXPORT NSString * const LJAccountWillDownloadFriendsNotification;

/*!
@const LJAccountDidDownloadFriendsNotification
 @discussion
 Posted after an account object downloads friend/group info.
 The notification object is the account instance.
 */
FOUNDATION_EXPORT NSString * const LJAccountDidDownloadFriendsNotification;

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
@interface LJAccount : LJUserEntity <NSCoding>
{
    NSMenu *_menu;
    NSArray *_journalArray;
    LJServer *_server;
    LJMoods *_moods;
    NSDictionary *_userPicturesDictionary;
    NSURL *_defaultUserPictureURL;
    NSString *_loginMessage;
    NSMutableDictionary *_customInfo;
    BOOL _isLoggedIn;
    id _delegate;
    // for friends editing
    NSMutableSet *_friendSet;
    NSMutableSet *_removedFriendSet;
    NSMutableSet *_groupSet;
    NSMutableSet *_removedGroupSet;
    NSMutableSet *_friendOfSet;
    NSDate *_groupsSyncDate;
    NSDate *_friendsSyncDate;
    
   	// For efficiency, keep an ordered cache of friends, 
	// which we only update when _friendSet changes
	NSArray *_orderedFriendArrayCache;
	NSArray *_orderedGroupArrayCache;
	
    // for internal linked list
    LJAccount *_nextAccount;
}

/*!
 @method allAccounts
 @abstract Obtain an array containing all active account objects.
 @discussion
 The LJAccount class keeps track of all active account objects.
 This method returns the list in the form of an NSArray.
 */
+ (NSArray *)allAccounts;

/*!
 @method accountWithIdentifier:
 @abstract Find the account with the given identifier.
 @param identifier The identifier for the desired account object.
 @result An account reference if found, nil otherwise.
 @discussion
 The LJAccount class keeps track of all active account objects.
 Using this method, you can obtain a reference to the account
 object with the given identifier.  If no matching account is
 found, returns nil.
 */
+ (LJAccount *)accountWithIdentifier:(NSString *)identifier;


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
+ (LJAccount *)defaultAccount;

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
+ (void)setDefaultAccount:(LJAccount *)newDefault;

/*!
 @method setDefault:
 @abstract Makes the receiver the default.
 @param flag YES to make the receiver the default.
 @discussion
 Use this method to designate the receiver to be the object returned by
 defaultAccount.  If flag is NO, no action is taken.
 */
- (void)setDefault:(BOOL)flag;

/*!
 @method isDefault
 @abstract Determines if the receiver is the default account.
 @returns YES if the receiver is the default account, NO otherwise.
 @discussion
 Use this method to determine if the receiver is the object returned by
 defaultAccount.
 */
- (BOOL)isDefault;


/*!
 @method initWithUsername:
 @abstract Initializes an LJAccount object.
 @param username The user's login name.
 @discussion
 Initializes a newly allocated LJAccount.  To start communicating
 with the LiveJournal server you must call the loginWithPassword:
 method.  This is the designated initializer for the class.
 */
- (id)initWithUsername:(NSString *)username;

- (id)initWithCoder:(NSCoder *)decoder;

/*!
 @method initWithContentsOfFile:
 @abstract Initializes an LJAccount object from a file.
 @param path The path to the previously archived account object.
 @discussion
 Initializes an account object using information previously saved
 to a file.  This method uses NSKeyedUnarchiver to read the file.
 */
- (id)initWithContentsOfFile:(NSString *)path;

- (void)encodeWithCoder:(NSCoder *)encoder;

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
- (BOOL)writeToFile:(NSString *)path;

/*!
 @method server
 @abstract Returns the LJServer object used by the receiver.
 @discussion
 This property is preserved during archiving.
 */
- (LJServer *)server;

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
- (void)loginWithPassword:(NSString *)password flags:(int)loginFlags;

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
 @method loginMessage
 @abstract Obtain the server's login message.
 @result The login message, or nil if none was available.
 @discussion
 The server may send a message for the user after login.  Your client
 should call this method after loginWithPassword: and if it returns
 a string, display the string to the user.
 */
- (NSString *)loginMessage;

/*!
 @method isLoggedIn
 @abstract Returns YES if the account has been logged in.
 @result YES if the account has successfully logged in, NO otherwise.
 @discussion
 */
- (BOOL)isLoggedIn;

/*!
 @method menu
 @abstract Returns the web menu provided by the server.
 @discussion
 If you provided the LJGetMenuLoginFlag to the loginWithPassword:flags:
 method, this method will return an NSMenu object you can display in your
 application.  Otherwise, returns nil.
 The menu is configured so that selection of any items
 will direct the system default web browser to the correct web site.
 Thus, all you need to do is display the menu in your interface.
 */
- (NSMenu *)menu;

/*!
 @method moods
 @abstract Returns an LJMoods object for this account.
 @discussion
 If you provided the LJGetMoodsLoginFlag to the loginWithPassword:flags:
 method, this method returns an LJMoods object, which represents all the
 moods known to the system and maps them to IDs.
 Otherwise, returns nil.

 This property is preserved during archiving.
*/
- (LJMoods *)moods;

/*!
 @method setMoods:
 @abstract Set the LJMoods object for this account.
 @discussion
 You can set the moods object before logging in, so that the
 mood list can be saved between sessions.  If so, only new moods will be
 downloaded from the server, to save on bandwidth.
 */
- (void)setMoods:(LJMoods *)moods;

/*!
 @method userPictureKeywords
 @abstract Returns an NSArray of account picture keywords in NSStrings.
 @discussion
	 If you provided the LJGetPicturesLoginFlag to the loginWithPassword:flags:
	 method, this method will return an NSArray of NSStrings. Otherwise, returns nil.
	 
	 This property is preserved during archiving.
	 */
- (NSArray *)userPictureKeywords;


/*!
 @method userPicturesDictionary
 @abstract Returns a dictionary of account picture keywords and URLs.
 @discussion
 If you provided the LJGetPicturesLoginFlag to the loginWithPassword:flags:
 method, this method will return an NSDictionary mapping userpic keywords
 to NSURL objects.  Otherwise, returns nil.

 This property is preserved during archiving.
*/
- (NSDictionary *)userPicturesDictionary;

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
 @method userPicturesMenu
 @abstract Returns an NSMenu of all picture keywords for the receiver.
 @discussion
 Creates an NSMenu representing the user's picture keywords.  Each menu item
 has the picture's URL as a its represented object, so you can retrieve the
 NSURL object by calling [menuItem representedObject].
 */
- (NSMenu *)userPicturesMenu;

/*!
 @method journalArray
 @abstract Obtain an array of LJJournal objects for this account.
 @discussion
 This method returns an array of LJJournal objects, representing the
 journals this account has access to post into (e.g., communities).
 It will always return an array with at least one element, the default
 journal for this account.  The default journal is always at index 0.

 This property is preserved during archiving.
*/
- (NSArray *)journalArray;

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
 @method journalMenu
 @abstract Returns an NSMenu of all journals for this account.
 @discussion
 Creates an NSMenu of all journals for the receivers account.  Each
 menu item is set to represent the appropriate LJJournal object, so
 you may retrieve a journal by sending the representedObject message
 to any of the menu items.
 */
- (NSMenu *)journalMenu;

/*!
 @method customInfo
 @abstract Returns a custom info dictionary for this account.
 @discussion
 Returns a mutable dictionary object you can use to store whatever
 information you would like to attach to this account.  All keys and
 values must support the NSCoding protocol.

 This property is preserved during archiving.
*/
- (NSMutableDictionary *)customInfo;

/*!
 @method identifier
 @abstract Returns a unique identifier for this account.
 @discussion
 Returns a unique identifier for the receiver.  It is of the form
 "username&#64;hostname:port".
 */
- (NSString *)identifier;

/*!
 @method delegate
 @abstract Returns the receiver's delegate.
 */
- (id)delegate;

/*!
 @method setDelegate:
 @abstract Sets the receiver's delegate.
 @discussion
 Sets the delegate of the receiver.  The delegate is automatically registered to
 receive notifications if it implements the methods below.
 */
- (void)setDelegate:(id)delegate;

@end


/*!
 @category NSObject(LJAccountDelegate)
 @abstract Methods implemented by the delegate
 */
@interface NSObject(LJAccountDelegate)

/*!
 @method accountShouldConnect:
 @discussion
 The account object delegate can veto connections to the server by implementing
 this method and returning NO.  If a connection is vetoed, an exception is
 raised.
 */
- (BOOL)accountShouldConnect:(LJAccount *)sender;

/*!
 @method accountWillConnect:
 @param notification 
 @discussion
 Called before an account will connect to the server.
 What is [notification object]???
 */
- (void)accountWillConnect:(NSNotification *)notification;

/*!
 @method accountDidConnect:
 @discussion
 Called immediately after a connection to the server is completed.
 Is it called if an error occurs???
 What is [notification object]???
 */
- (void)accountDidConnect:(NSNotification *)notification;

@end
