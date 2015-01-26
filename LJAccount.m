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
 2004-01-10 [BPR]	Changed exception handling (gets strings from main bundle,
                    not the LJKit bundle).
 2004-02-23 [BPR]   Updated initWithUsername: to call LJServer's designated initializer.
                    (The account field wasn't being set.)
                    Added method: description
 2004-03-13 [BPR]   Added default account methods.
 */

#import "LJAccount_EditFriends.h"
#import "LJUserEntity_Private.h"
#import "LJAccount_Private.h"
#import "LJJournal_Private.h"
#import "LJMenu.h"
#import "LJMoods_Private.h"
#import "LJServer_Private.h"
#import "Miscellaneous.h"

// The .strings resource file to look for error messages in.  "nil" means use "Localizable".
#define LJKitStringsTable nil

NSString * const LJAccountWillConnectNotification = @"LJAccountWillConnect";
NSString * const LJAccountDidConnectNotification =  @"LJAccountDidConnect";
NSString * const LJAccountWillLoginNotification =   @"LJAccountWillLogin";
NSString * const LJAccountDidLoginNotification =    @"LJAccountDidLogin";
NSString * const LJAccountDidNotLoginNotification = @"LJAccountDidNotLogin";
NSString * const LJAccountDidLogoutNotification =   @"LJAccountDidLogout";

// [FS] These are handy if we're doing asynchronous login and download
NSString * const LJAccountWillDownloadFriendsNotification = @"LJAccountWillDownloadFriends";
NSString * const LJAccountDidDownloadFriendsNotification = @"LJAccountDidDownloadFriends";

static NSString *gClientVersion = nil;

/*
 * Internally a linked list of LJAccount objects is maintained,
 * so that other objects can find the LJAccount.
 */
static LJAccount *gAccountListHead = nil;

@interface LJAccount ()
+ (NSString *)_clientVersionForBundle:(NSBundle *)bundle;

@property (NS_NONATOMIC_IOSONLY, getter=isLoggedIn, readwrite) BOOL loggedIn;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSArray *journalArray;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSDictionary *userPicturesDictionary;
@end

@implementation LJAccount
@synthesize loggedIn = _isLoggedIn;
@synthesize userPicturesDictionary = _userPicturesDictionary;

/*
 This method sets the client name and version to be sent to the server.
 By default it uses the main bundle's name and version given by its
 infoDictionary.  If you wish to override these values, you can use
 the keys LJClientName and LJClientVersion.  If none of these are
 specified, the client name is LJKit and the version is the version
 of the LJKit in use.
 */

+ (NSString *)_clientVersionForBundle:(NSBundle *)bundle
{
    NSString *key = @"CFBundleShortVersionString";
    NSString *shortVerStr = [bundle objectForInfoDictionaryKey:key];
    return [[shortVerStr componentsSeparatedByString:@" "] lastObject];
}

+(NSSet*)keyPathsForValuesAffectingUserPictureKeywords
{
	return [NSSet setWithObject:@"userPicturesDictionary"];
}

+ (void)initialize
{
    if (gClientVersion == nil) {
        NSBundle *mainBundle, *ljKitBundle;
        NSString *name, *version;

        mainBundle = [NSBundle mainBundle];
        ljKitBundle = LJKitBundle;
        // Get name and version defined in main bundle.
        name = [mainBundle objectForInfoDictionaryKey:@"LJClientName"];
        version = [mainBundle objectForInfoDictionaryKey:@"LJClientVersion"];
        // If that didn't work, use main bundle's name.
        if (name == nil) {
            name = [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
            version = [self _clientVersionForBundle:mainBundle];
        }
        // If that didn't work, use the name from the LJKit bundle.
        if (name == nil) {
            name = [ljKitBundle objectForInfoDictionaryKey:@"CFBundleName"];
            version = [self _clientVersionForBundle:ljKitBundle];
        }
        gClientVersion = [[NSString alloc] initWithFormat:@"MacOSX-%@/%@", name, version];
        NSLog(@"LJKit Client Version: %@", gClientVersion);
    }
}


+ (NSArray *)allAccounts
{
    NSMutableArray *array = [NSMutableArray array];
    LJAccount *account = gAccountListHead;

    while (account) {
        [array addObject:account];
        account = account->_nextAccount;
    }
    return array;
}


/* In Objective-C, [nil anyMessage] == nil, which makes traversing list links a breeze! */
- (LJAccount *)_accountWithIdentifier:(NSString *)identifier
{
    if ([[self identifier] isEqualToString:identifier]) {
        return self;
    } else {
        return [_nextAccount _accountWithIdentifier:identifier];
    }
}


+ (LJAccount *)accountWithIdentifier:(NSString *)identifier
{
    return [gAccountListHead _accountWithIdentifier:identifier];
}


+ (LJAccount *)defaultAccount
{
    return gAccountListHead;
}


+ (void)setDefaultAccount:(LJAccount *)newDefault
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Must save here in case newDefault is already the list head
    [defaults setObject:[newDefault identifier] forKey:@"LJDefaultAccountIdentifier"];
    if (newDefault != gAccountListHead) {
        LJAccount *previous = gAccountListHead;
        LJAccount *current = gAccountListHead->_nextAccount;
    
        while (current) {
            if (current == newDefault) {
                [gAccountListHead setDefault:NO];
                // remove newDefault from the list
                previous->_nextAccount = newDefault->_nextAccount;
                // put newDefault at the front
                newDefault->_nextAccount = gAccountListHead;
                gAccountListHead = newDefault;
                return;
            }
            previous = current;
            current = current->_nextAccount;
        }
        [NSException raise:NSInternalInconsistencyException
                    format:@"New proposed default account not in the list."];
    }
}


- (BOOL)isDefault
{
    return (gAccountListHead == self);
}


- (void)setDefault:(BOOL)flag
{
    if (flag) {
        [LJAccount setDefaultAccount:self];
    }
}
    

- (instancetype)init
{
    self = [super init];
    if (self) {
        // add self to global linked list of accounts.
        // can't overwrite the head because it is the default now
        if (nil == gAccountListHead) {
            gAccountListHead = self;
        } else {
            _nextAccount = gAccountListHead->_nextAccount;
            gAccountListHead->_nextAccount = self;
        }
    }
	
    return self;
}

- (void)_setUsername:(NSString *)newUsername
{
    LJJournal *journal;

    [super _setUsername:newUsername];
    if ([self username]) {
        journal = [LJJournal _journalWithName:[self username] account:self];
        _journalArray = [[NSArray alloc] initWithObjects:&journal count:1];
    }
}

- (instancetype)initWithUsername:(NSString *)username
{
    NSURL *defaultURL;
    
    if (self = [self init]) {
        NSParameterAssert(username);
        [self _setUsername:username];
        [self _setFullname:username];
        defaultURL = [NSURL URLWithString:@"http://www.livejournal.com"];
        _server = [[LJServer alloc] initWithURL:defaultURL account:self];
    }
    return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)path
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if (self = [self init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *theIdentifier;
        
        _username = [decoder decodeObjectForKey:@"LJAccountUsername"];
        _fullname = [decoder decodeObjectForKey:@"LJAccountFullname"];
        _server = [decoder decodeObjectForKey:@"LJAccountServer"];
        _moods = [decoder decodeObjectForKey:@"LJAccountMoods"];
        _userPicturesDictionary = [decoder decodeObjectForKey:@"LJAccountUserpics"];
        _defaultUserPictureURL = [decoder decodeObjectForKey:@"LJAccountDefaultUserpicURL"];
        _journalArray = [decoder decodeObjectForKey:@"LJAccountJournals"];
        // editfriends fields
        _friendSet = [decoder decodeObjectForKey:@"LJAccountFriends"];
        _removedFriendSet = [decoder decodeObjectForKey:@"LJAccountExFriends"];
        _friendOfSet = [decoder decodeObjectForKey:@"LJAccountFriendOfs"];
        _groupSet = [decoder decodeObjectForKey:@"LJAccountGroups"];
        _removedGroupSet = [decoder decodeObjectForKey:@"LJAccountExGroups"];
        // custom info
        _customInfo = [decoder decodeObjectForKey:@"LJAccountCustomInfo"];
        // check defaults to see if this is supposed to be the default account
        theIdentifier = [defaults stringForKey:@"LJDefaultAccountIdentifier"];
        if ([theIdentifier isEqualToString:[self identifier]]) {
            [LJAccount setDefaultAccount:self];
        }
    }
    return self;
}

- (void)dealloc
{
    // remove self from global linked list of accounts
    if (gAccountListHead == self) {
        gAccountListHead = _nextAccount;
    } else {
        LJAccount *accountList = gAccountListHead;

        while (accountList) {
            if (accountList->_nextAccount == self) {
                accountList->_nextAccount = self->_nextAccount;
                break;
            }
            accountList = accountList->_nextAccount;
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:nil name:nil
                                                  object:self];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSString *version = [LJKitBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    [encoder encodeObject:version forKey:@"LJKitVersion"];
    [encoder encodeObject:_username forKey:@"LJAccountUsername"];
    [encoder encodeObject:_fullname forKey:@"LJAccountFullname"];
    [encoder encodeObject:_server forKey:@"LJAccountServer"];
    [encoder encodeObject:_moods forKey:@"LJAccountMoods"];
    [encoder encodeObject:_userPicturesDictionary
                   forKey:@"LJAccountUserpics"];
    [encoder encodeObject:_defaultUserPictureURL
                   forKey:@"LJAccountDefaultUserpicURL"];
    [encoder encodeObject:_journalArray forKey:@"LJAccountJournals"];
    // editfriends fields
    [encoder encodeObject:_friendSet forKey:@"LJAccountFriends"];
    [encoder encodeObject:_removedFriendSet forKey:@"LJAccountExFriends"];
    [encoder encodeObject:_friendOfSet forKey:@"LJAcountFriendOfs"];
    [encoder encodeObject:_groupSet forKey:@"LJAccountGroups"];
    [encoder encodeObject:_removedGroupSet forKey:@"LJAccountExGroups"];
    // custom info
    if ([_customInfo count] > 0) {
        [encoder encodeObject:_customInfo forKey:@"LJAccountCustomInfo"];
    }
}

- (BOOL)writeToFile:(NSString *)path
{
    return [NSKeyedArchiver archiveRootObject:self toFile:path];
}

- (LJAccount *)account
{
    return self;
}

- (LJServer *)server
{
    return _server;
}

- (NSException *)_exceptionWithName:(NSString *)name reason:(NSString *)reason
{
    NSDictionary *userInfo;

    userInfo = @{@"LJAccount": self};
    return [NSException exceptionWithName:name reason:reason userInfo:userInfo];
}

- (NSException *)_exceptionWithName:(NSString *)name
{
    NSString *reason;
    
    reason = [[NSBundle mainBundle] localizedStringForKey:name value:nil 
                                                    table:LJKitStringsTable];
    return [self _exceptionWithName:name reason:reason];
}

/*
 For example,
 [_account _exceptionWithFormat:@"LJStreamError_%d_%d", 1, 5];
 will first look for a string for the key "LJStreamError_1_5" and use it.
 If no such key is found, it will look for a string for the key
 "LJStreamError_%d_%d" and substitute 1 and 5 for %d in the string itself.
 */
- (NSException *)_exceptionWithFormat:(NSString *)format, ...
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *name, *reason;
    va_list args;
    NSException *exception;
    
    va_start(args, format);
    name = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    reason = [bundle localizedStringForKey:name value:@"?" table:LJKitStringsTable];
    if ([reason isEqualToString:@"?"]) {
        reason = [bundle localizedStringForKey:format value:nil table:LJKitStringsTable];
        va_start(args, format);
        reason = [[NSString alloc] initWithFormat:reason arguments:args];
        va_end(args);
    }
    exception = [self _exceptionWithName:name reason:reason];
    return exception;
}

- (NSDictionary *)getReplyForMode:(NSString *)mode parameters:(NSDictionary *)parameters
{
    static int connectionID = 1; // to be mostly unique across invocations
    NSDictionary *reply = nil;
    NSString *success, *errmsg;
    NSException *exception = nil;
    NSNotificationCenter *noticeCenter = [NSNotificationCenter defaultCenter];
    NSMutableDictionary *info;

    if ([_delegate respondsToSelector:@selector(accountShouldConnect:)] &&
        ( ! [_delegate accountShouldConnect:self] )) {
        [[self _exceptionWithName:@"LJAccountDelegateDidVetoConnection"] raise];
    }
    if ( ! (_isLoggedIn || [mode isEqualToString:@"login"]) ) {
        [[self _exceptionWithName:@"LJNotLoggedInError"] raise];
    }
    // Post LJAccountWillConnectNotification
    info = [[NSMutableDictionary alloc] init];
    info[@"LJMode"] = mode;
    if (parameters) info[@"LJParameters"] = parameters;
    info[@"LJConnection"] = @(connectionID++);
	
	// [FS] Fire notification with -performSelectorOnMainThread:
	NSNotification *willLoginNote = [NSNotification notificationWithName: LJAccountWillConnectNotification object: self userInfo: info];
    RunOnMainThreadSync(^{
        [noticeCenter postNotification:willLoginNote];
    });
	// End change.
	
    // Do the dirty deed.
    @try {
        reply = [_server getReplyForMode:mode parameters:parameters];
        success = reply[@"success"];
        if (success == nil) {
            exception = [self _exceptionWithName:@"LJNoSuccessKeyError"];
        } else if ( ! [success isEqualToString:@"OK"] ) {
            errmsg = reply[@"errmsg"];
            if (errmsg) {
                exception = [self _exceptionWithName:@"LJServerError" reason:errmsg];
            } else {
                exception = [self _exceptionWithName:@"LJNoErrMsgKeyError"];
            }
        };
    } @catch (NSException *localException) {
        // Attach a userInfo dictionary to any LJKit exceptions.
        if ([[localException name] hasPrefix:@"LJ"]) {
            exception = [self _exceptionWithName:[localException name]
                                          reason:[localException reason]];
        } else {
            exception = localException;
        };
    }
    // Post LJAccountDidConnectNotification
    if (reply) info[@"LJReply"] = reply;
    if (exception) info[@"LJException"] = exception;

    // [FS] Change to fire notification onMainThread.
	NSNotification *didLoginNote = [NSNotification notificationWithName: LJAccountDidConnectNotification
																 object: self
															   userInfo: info];
    RunOnMainThreadSync(^{
        [noticeCenter postNotification:didLoginNote];
    });
	// end
	
    [exception raise]; // will do nothing if no exception was set
    return reply;
}

- (void)createUserPicturesDictionary:(NSDictionary *)reply
{
    NSMutableDictionary *userPics;
    NSInteger count, i;
    NSString *key, *keyword;
    NSURL *url;
	
    count = [reply[@"pickw_count"] integerValue];
    userPics = [[NSMutableDictionary alloc] initWithCapacity:count];
    for (i = 1; i <= count; i++) {
        key = [NSString stringWithFormat:@"pickw_%ld", (long)i];
        keyword = reply[key];
        key = [NSString stringWithFormat:@"pickwurl_%ld", (long)i];
        url = [NSURL URLWithString:reply[key]];
        userPics[keyword] = url;
    }
    key = reply[@"defaultpicurl"];
    url = (key != nil ? [NSURL URLWithString:key] : nil);
	_defaultUserPictureURL = url;
	
	// [FS] Added use of accessor here
	[self setUserPicturesDictionary: [userPics copy]];
}

- (void)loginWithPassword:(NSString *)password flags:(LJLoginFlag)loginFlags
{
    NSDictionary *loginInfo, *reply = nil, *info;
    NSMutableDictionary *parameters;
    NSNotificationCenter *noticeCenter = [NSNotificationCenter defaultCenter];
    NSArray *journals;	

    NSAssert(password != nil, @"Password must not be nil.");
    NSAssert((loginFlags & LJReservedLoginFlags) == 0, @"A reserved login flag was set."); 

    // [FS] Convert to fire notification onMainThread
	NSNotification *loginNote = [NSNotification notificationWithName: LJAccountWillLoginNotification
															  object: self
															userInfo: nil];
    RunOnMainThreadSync(^{
        [noticeCenter postNotification:loginNote];
    });
	
	// [FS] end change.
	
    [self willChangeValueForKey:@"loggedIn"];
    // Configure server object with login information.
    _isLoggedIn = NO;
    loginInfo = @{@"hpassword": MD5HexDigest(password),
        @"user": [self username], @"ver": @"1"};
    [_server setLoginInfo:loginInfo];
    // Set up parameters
    parameters = [[NSMutableDictionary alloc] init];
    parameters[@"clientversion"] = gClientVersion;
    if (loginFlags & LJGetMoodsLoginFlag) {
        if (_moods == nil) { _moods = [[LJMoods alloc] init]; }
        parameters[@"getmoods"] = [_moods highestMoodIDString];
    }
    if (loginFlags & LJGetMenuLoginFlag) {
        parameters[@"getmenus"] = @"1";
    }
    if (loginFlags & LJGetUserPicturesLoginFlag) {
        parameters[@"getpickws"] = @"1";
        parameters[@"getpickwurls"] = @"1";
    }
    @try {
        reply = [self getReplyForMode:@"login" parameters:parameters];
    } @catch (NSException *localException) {
        info = @{@"LJException": localException};

		// [FS] onMainThread conversion
		NSNotification *failureNote = [NSNotification notificationWithName: LJAccountDidNotLoginNotification
																	object: self
																  userInfo: info];
        RunOnMainThreadSync(^{
            [noticeCenter postNotification:failureNote];
        });
		// [FS] end.
		
        [localException raise];
    }
    // get the full name of the account
    [self _setFullname:reply[@"name"]];
    // get the login message, if present
    _loginMessage = reply[@"message"];
    // inform server object if we are allow to use the fast servers
    if (!(loginFlags & LJDoNotUseFastServersLoginFlag) &&
        [reply[@"fastserver"] boolValue])
    {
        [_server setUseFastServers:YES];
    }
    journals = [LJJournal _journalArrayFromLoginReply:reply account:self];
	// [FS] Changed this from direct ivar access for KVO reasons
	[self setJournalArray: journals];
    if (loginFlags & LJGetMoodsLoginFlag) {
        [_moods updateMoodsWithLoginReply:reply];
    }
    if (loginFlags & LJGetMenuLoginFlag) {
        _menu = [[LJMenu alloc] initWithTitle:@"Web" loginReply:reply];
    }
    if (loginFlags & LJGetUserPicturesLoginFlag) {
        [self createUserPicturesDictionary:reply];
    }
    [self updateGroupSetWithReply:reply];
    _isLoggedIn = YES;
    [self didChangeValueForKey:@"loggedIn"];
	// Get tag lists for main journal
	LJJournal *j = [self defaultJournal];
	NSDictionary *tagsReply = [j getTagsReplyForThisJournal];
	[j createJournalTagsArray: tagsReply];
	
	// [FS] onMainThread conversion
	NSNotification *successNote = [NSNotification notificationWithName: LJAccountDidLoginNotification
																object: self
															  userInfo: nil];
    RunOnMainThreadSync(^{
        [noticeCenter postNotification:successNote];
    });
	// [FS] end change.
}

- (void)loginWithPassword:(NSString *)password
{
    [self loginWithPassword:password flags:LJDefaultLoginFlags];
}

- (void)logout
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [self willChangeValueForKey:@"loggedIn"];
    self.loggedIn = NO;
    [[self server] setLoginInfo:nil];
    [self didChangeValueForKey:@"loggedIn"];
    [center postNotificationName:LJAccountDidLogoutNotification
                          object:self userInfo:nil];
}

- (NSArray *)userPictureKeywords {
	// [FS] This is potenitally a performance hot spot, but let's be guided by profiling.
	return [[_userPicturesDictionary allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSDictionary *)userPicturesDictionary
{
    return _userPicturesDictionary;
}

// [FS] For key value observing
- (void) setUserPicturesDictionary: (NSDictionary *)aDict {
	NSLog(@"Setting user pictures dictionary");
	_userPicturesDictionary = [aDict mutableCopy];
}

- (NSURL *)defaultUserPictureURL
{
    return _defaultUserPictureURL;
}

- (NSString *)defaultUserPictureKeyword {
	// This may potentially be expensive
	NSEnumerator *en = [[_userPicturesDictionary allKeys] objectEnumerator];
	NSURL *defaultURL = [self defaultUserPictureURL];
	NSString *key;
	while(key = [en nextObject]) {
		if([_userPicturesDictionary[key] isEqualTo: defaultURL])
			return key;
	}
	return nil;
}

- (NSMenu *)userPicturesMenu
{
    NSMenu *pMenu = [[NSMenu alloc] initWithTitle:@"User Pictures"];
    NSEnumerator *keywordEnumerator;
    NSString *keyword;
    NSMenuItem *pItem;
    NSURL *url;
    
    [pMenu setAutoenablesItems:NO];
    // Add "Default Picture"
    pItem = [[NSMenuItem alloc] initWithTitle:@"Default Picture" action:nil
                                keyEquivalent:@""];
    [pItem setRepresentedObject:_defaultUserPictureURL];
    [pMenu addItem:pItem];
    if ([_userPicturesDictionary count] > 0) {
        // Add separator
        [pMenu addItem:[NSMenuItem separatorItem]];
        // Add the keywords
		
		// FS: Changed this line to give a menu sorted by keyword
		//     Now that users get 100*10^6 userpics, this seems to be important.
        keywordEnumerator = [[[_userPicturesDictionary allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)] objectEnumerator];
        while (keyword = [keywordEnumerator nextObject]) {
            pItem = [[NSMenuItem alloc] initWithTitle:keyword action:nil
                                        keyEquivalent:@""];
            url = _userPicturesDictionary[keyword];
            [pItem setRepresentedObject:url];
            [pMenu addItem:pItem];
        }
    }
    return pMenu;
}

- (LJJournal *)defaultJournal
{
    return _journalArray[0];
}

- (LJJournal *)journalNamed:(NSString *)name
{
    for (LJJournal *journal in _journalArray) {
        if ([name isEqualToString:[journal name]])
            return journal;
    }
    return nil;
}

- (NSMenu *)journalMenu
{
    NSMenu *jMenu = [[NSMenu alloc] initWithTitle:@"Journals"];

    [jMenu setAutoenablesItems:NO];
    for (LJJournal *j in _journalArray) {
        NSMenuItem *jItem = [[NSMenuItem alloc] initWithTitle:[j name]
                                                       action:NULL
                                                keyEquivalent:@""];
        [jItem setRepresentedObject:j];
        [jMenu addItem:jItem];
    }
    return jMenu;
}

- (NSMutableDictionary *)customInfo
{
    if (_customInfo == nil) _customInfo = [[NSMutableDictionary alloc] init];
    return _customInfo;
}

- (NSString *)identifier
{
    NSURL *serverURL = [_server URL];
    int p = [[serverURL port] intValue];
    return [NSString stringWithFormat:@"%@@%@:%u",
        [self username], [serverURL host], (p != 0 ? p : 80)];
}

- (void)_registerDelegateForNotification:(NSString *)n selector:(SEL)s
{
    static NSNotificationCenter *defaultCenter = nil;

    if (defaultCenter == nil) {
        defaultCenter = [NSNotificationCenter defaultCenter];
    }
    if ([_delegate respondsToSelector:s]) {
        [defaultCenter addObserver:_delegate selector:s name:n object:self];
    }
}

- (void)setDelegate:(id<LJAccountDelegate>)delegate
{
    if (_delegate) {
        [[NSNotificationCenter defaultCenter] removeObserver:_delegate];
    }
    _delegate = delegate;
    [self _registerDelegateForNotification:LJAccountWillConnectNotification
                                  selector:@selector(accountWillConnect:)];
    [self _registerDelegateForNotification:LJAccountDidConnectNotification
                                  selector:@selector(accountDidConnect:)];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[LJAccount class]]) {
        NSString *otherIdentifier = [(LJAccount *)object identifier];
        return [[self identifier] isEqualToString:otherIdentifier];
    }
    return NO;
}

- (NSComparisonResult)compare:(LJAccount *)account
{
    return [[self identifier] compare:[account identifier]];
}

- (NSString *)description
{
    return [self identifier];
}

// [FS] KVO - there may be simplifcations to be made here.
 + (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
	BOOL automatic;
    if ([theKey isEqualToString:@"friendArray"]) {
        automatic=NO;
    } 
	else if ([theKey isEqualToString:@"groupArray"]) {
        automatic=NO;
    }
	else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}
@end
