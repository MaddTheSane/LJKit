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

#import "LJAccount.h"
#import "LJAccount_EditFriends.h"
#import "LJServer.h"
#import "Miscellaneous.h"
#import "LJMenu.h"
#import "LJMoods.h"
#import "LJJournal.h"

NSString * const LJAccountWillConnectNotification =
@"LJAccountWillConnect";
NSString * const LJAccountDidConnectNotification =
@"LJAccountDidConnect";
NSString * const LJAccountWillLoginNotification =
@"LJAccountWillLogin";
NSString * const LJAccountDidLoginNotification =
@"LJAccountDidLogin";
NSString * const LJAccountDidNotLoginNotification =
@"LJAccountDidNotLogin";

static NSString *clientVersion = nil;

/*
 * Internally a linked list of LJAccount objects is maintained,
 * so that other objects can find the LJAccount.
 */
static LJAccount *accountListHead = nil;

@implementation LJAccount

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

+ (void)initialize
{
    NSBundle *bundle;
    NSString *msg, *name, *version;

    if (clientVersion == nil) {
        bundle = [NSBundle mainBundle];
        name = [bundle objectForInfoDictionaryKey:@"LJClientName"];
        version = [bundle objectForInfoDictionaryKey:@"LJClientVersion"];
        if (name == nil) {
            name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
            version = [self _clientVersionForBundle:bundle];
        }
        bundle = LJKitBundle;
        if (name == nil) {
            name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
            version = [self _clientVersionForBundle:bundle];
        }
        msg = [bundle localizedStringForKey:name value:nil table:nil];
        clientVersion = [[NSString alloc] initWithFormat:
            @"MacOSX-%@/%@", name, version];
        NSLog(msg, clientVersion);
    }
}

+ (NSArray *)allAccounts
{
    NSMutableArray *array = [NSMutableArray array];
    LJAccount *account = accountListHead;

    while (account) {
        [array addObject:account];
        account = account->_nextAccount;
    }
    return array;
}

+ (LJAccount *)accountWithIdentifier:(NSString *)identifier
{
    LJAccount *account = accountListHead;

    while (account) {
        if ([[account identifier] isEqualToString:identifier])
            return account;
        account = account->_nextAccount;
    }
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        // add self to global linked list of accounts
        _nextAccount = accountListHead;
        accountListHead = self;
    }
    return self;
}

- (id)initWithUsername:(NSString *)username
{
    if ([self init]) {
        NSParameterAssert(username);
        _username = [[username lowercaseString] retain];
        _fullname = [_username copy];
        _server = [[LJServer alloc] init];
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    [self dealloc];
    return [[NSKeyedUnarchiver unarchiveObjectWithFile:path] retain];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ([self init]) {
        _username = [[decoder decodeObjectForKey:@"LJAccountUsername"] retain];
        _fullname = [[decoder decodeObjectForKey:@"LJAccountFullname"] retain];
        _server = [[decoder decodeObjectForKey:@"LJAccountServer"] retain];
        _moods = [[decoder decodeObjectForKey:@"LJAccountMoods"] retain];
        _userPicturesDictionary = [[decoder decodeObjectForKey:@"LJAccountUserpics"] retain];
        _defaultUserPictureURL = [[decoder decodeObjectForKey:@"LJAccountDefaultUserpicURL"] retain];
        _journalArray = [[decoder decodeObjectForKey:@"LJAccountJournals"] retain];
        // editfriends fields
        _friendSet = [[decoder decodeObjectForKey:@"LJAccountFriends"] retain];
        _removedFriendSet = [[decoder decodeObjectForKey:@"LJAccountExFriends"] retain];
        _friendOfSet = [[decoder decodeObjectForKey:@"LJAccountFriendOfs"] retain];
        _groupSet = [[decoder decodeObjectForKey:@"LJAccountGroups"] retain];
        _removedGroupSet = [[decoder decodeObjectForKey:@"LJAccountExGroups"] retain];
        // custom info
        _customInfo = [[decoder decodeObjectForKey:@"LJAccountCustomInfo"] retain];
    }
    return self;
}

- (void)dealloc
{
    // remove self from global linked list of accounts
    if (accountListHead == self) {
        accountListHead = _nextAccount;
    } else {
        LJAccount *accountList = accountListHead;

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
    // General account variables:
    [_username release];
    [_fullname release];
    [_server release];
    [_menu release];
    [_journalArray release];
    [_userPicturesDictionary release];
    [_moods release];
    [_loginMessage release];
    [_customInfo release];
    // Variables for friends editing:
    [_friendSet release];
    [_removedFriendSet release];
    [_groupSet release];
    [_removedGroupSet release];
    [_friendOfSet release];
    [super dealloc];
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

- (NSString *)username
{
    return _username;
}

- (NSString *)fullname
{
    return _fullname;
}

- (LJServer *)server
{
    return _server;
}

- (NSException *)_exceptionWithName:(NSString *)name reason:(NSString *)reason
{
    NSDictionary *userInfo;

    userInfo = [NSDictionary dictionaryWithObject:self forKey:@"LJAccount"];
    return [NSException exceptionWithName:name reason:reason userInfo:userInfo];
}

- (NSException *)_exceptionWithName:(NSString *)name
{
    NSString *r = [LJKitBundle localizedStringForKey:name value:nil table:nil];
    return [self _exceptionWithName:name reason:r];
}

- (void)_raiseExceptionWithName:(NSString *)name
{
    [[self _exceptionWithName:name reason:nil] raise];
}

- (void)_raiseExceptionWithName:(NSString *)name reason:(NSString *)reason
{
    [[self _exceptionWithName:name reason:reason] raise];
}

- (NSDictionary *)getReplyForMode:(NSString *)mode
                       parameters:(NSDictionary *)parameters
{
    static int connectionID = 1; // to be mostly unique across invocations
    NSDictionary *reply = nil;
    NSString *success, *errmsg;
    NSException *exception = nil;
    NSNotificationCenter *noticeCenter = [NSNotificationCenter defaultCenter];
    NSMutableDictionary *info;

    if ([_delegate respondsToSelector:@selector(accountShouldConnect:)] &&
        ( ! [_delegate accountShouldConnect:self] )) {
        [self _raiseExceptionWithName:@"LJAccountDelegateDidVetoConnection"];
    }
    if ( ! (_isLoggedIn || [mode isEqualToString:@"login"]) ) {
        [self _raiseExceptionWithName:@"LJNotLoggedInError"];
    }
    // Post LJAccountWillConnectNotification
    info = [[NSMutableDictionary alloc] init];
    [info setObject:mode forKey:@"LJMode"];
    if (parameters) [info setObject:parameters forKey:@"LJParameters"];
    [info setObject:[NSNumber numberWithInt:(connectionID++)]
             forKey:@"LJConnection"];
    [noticeCenter postNotificationName:LJAccountWillConnectNotification
                                object:self userInfo:info];
    // Do the dirty deed.
    NS_DURING
        reply = [_server getReplyForMode:mode parameters:parameters];
        success = [reply objectForKey:@"success"];
        if (success == nil) {
            exception = [self _exceptionWithName:@"LJNoSuccessKeyError"];
        } else if ( ! [success isEqualToString:@"OK"] ) {
            errmsg = [reply objectForKey:@"errmsg"];
            if (errmsg) {
                exception = [self _exceptionWithName:@"LJServerError"
                                              reason:errmsg];
            } else {
                exception = [self _exceptionWithName:@"LJNoErrMsgKeyError"];
            }
        };
    NS_HANDLER
        // Attach a userInfo dictionary to any LJKit exceptions.
        if ([[localException name] hasPrefix:@"LJ"]) {
            exception = [self _exceptionWithName:[localException name]
                                          reason:[localException reason]];
        } else {
            exception = localException;
        };
    NS_ENDHANDLER
    // Post LJAccountDidConnectNotification
    if (reply) [info setObject:reply forKey:@"LJReply"];
    if (exception) [info setObject:exception forKey:@"LJException"];
    [noticeCenter postNotificationName:LJAccountDidConnectNotification
                                object:self userInfo:info];
    [info release];
    [exception raise]; // will do nothing if no exception was set
    return reply;
}

- (void)createUserPicturesDictionary:(NSDictionary *)reply
{
    NSMutableDictionary *userPics;
    int count, i;
    NSString *key, *keyword;
    NSURL *url;

    count = [[reply objectForKey:@"pickw_count"] intValue];
    userPics = [[NSMutableDictionary alloc] initWithCapacity:count];
    for (i = 1; i <= count; i++) {
        key = [NSString stringWithFormat:@"pickw_%d", i];
        keyword = [reply objectForKey:key];
        key = [NSString stringWithFormat:@"pickwurl_%d", i];
        url = [NSURL URLWithString:[reply objectForKey:key]];
        [userPics setObject:url forKey:keyword];
    }
    key = [reply objectForKey:@"defaultpicurl"];
    url = (key != nil ? [NSURL URLWithString:key] : nil);
    SafeSetObject(&_defaultUserPictureURL, url);
    [_userPicturesDictionary release];
    _userPicturesDictionary = [userPics copy];
    [userPics release];
}

- (void)loginWithPassword:(NSString *)password flags:(int)loginFlags
{
    NSDictionary *loginInfo, *reply, *info;
    NSMutableDictionary *parameters;
    NSNotificationCenter *noticeCenter = [NSNotificationCenter defaultCenter];

    if (loginFlags & LJReservedLoginFlags) {
        [self _raiseExceptionWithName:@"LJReservedLoginFlagSetError"];
    }
    [noticeCenter postNotificationName:LJAccountWillLoginNotification
                                object:self userInfo:nil];
    // Configure server object with login information.
    _isLoggedIn = NO;
    loginInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
        MD5HexDigest(password), @"hpassword",
        _username, @"user", @"1", @"ver", nil];
    [_server setLoginInfo:loginInfo];
    [loginInfo release];
    // Set up parameters
    parameters = [NSMutableDictionary dictionary];
    [parameters setObject:clientVersion forKey:@"clientversion"];
    if (loginFlags & LJGetMoodsLoginFlag) {
        if (_moods == nil) { _moods = [[LJMoods alloc] init]; }
        [parameters setObject:[_moods highestMoodIDString] forKey:@"getmoods"];
    }
    if (loginFlags & LJGetMenuLoginFlag) {
        [parameters setObject:@"1" forKey:@"getmenus"];
    }
    if (loginFlags & LJGetUserPicturesLoginFlag) {
        [parameters setObject:@"1" forKey:@"getpickws"];
        [parameters setObject:@"1" forKey:@"getpickwurls"];
    }
    NS_DURING
        reply = [self getReplyForMode:@"login" parameters:parameters];
    NS_HANDLER
        info = [NSDictionary dictionaryWithObject:localException
                                           forKey:@"LJException"];
        [noticeCenter postNotificationName:LJAccountDidNotLoginNotification
                                    object:self userInfo:info];
        [localException raise];
    NS_ENDHANDLER
    // get the full name of the account
    _fullname = [[reply objectForKey:@"name"] retain];
    // get the login message, if present
    _loginMessage = [[reply objectForKey:@"message"] retain];
    // inform server object if we are allow to use the fast servers
    if (!(loginFlags & LJDoNotUseFastServersLoginFlag) &&
        [[reply objectForKey:@"fastserver"] isEqualToString:@"1"])
    {
        [_server setUseFastServers:YES];
    }
    _journalArray = [LJJournal _journalArrayFromLoginReply:reply account:self];
    [_journalArray retain];
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
    [noticeCenter postNotificationName:LJAccountDidLoginNotification
                                object:self userInfo:nil];
}

- (void)loginWithPassword:(NSString *)password
{
    return [self loginWithPassword:password flags:LJDefaultLoginFlags];
}

- (NSString *)loginMessage
{
    return _loginMessage;
}

- (BOOL)isLoggedIn
{
    return _isLoggedIn;
}

- (NSMenu *)menu
{
    return _menu;
}

- (NSDictionary *)userPicturesDictionary
{
    return _userPicturesDictionary;
}

- (NSURL *)defaultUserPictureURL
{
    return _defaultUserPictureURL;
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
    [pItem release];
    if ([_userPicturesDictionary count] > 0) {
        // Add separator
        [pMenu addItem:[NSMenuItem separatorItem]];
        // Add the keywords
        keywordEnumerator = [_userPicturesDictionary keyEnumerator];
        while (keyword = [keywordEnumerator nextObject]) {
            pItem = [[NSMenuItem alloc] initWithTitle:keyword action:nil
                                        keyEquivalent:@""];
            url = [_userPicturesDictionary objectForKey:keyword];
            [pItem setRepresentedObject:url];
            [pMenu addItem:pItem];
            [pItem release];
        }
    }
    return [pMenu autorelease];
}

- (LJMoods *)moods
{
    return _moods;
}

- (void)setMoods:(LJMoods *)moods
{
    SafeSetObject(&_moods, moods);
}

- (NSArray *)journalArray
{
    return _journalArray;
}

- (LJJournal *)defaultJournal
{
    return [_journalArray objectAtIndex:0];
}

- (LJJournal *)journalNamed:(NSString *)name
{
    unsigned int i;

    for (i = 0; i < [_journalArray count]; i++) {
        LJJournal *journal = [_journalArray objectAtIndex:i];
        if ([name isEqualToString:[journal name]])
            return journal;
    }
    return nil;
}

- (NSMenu *)journalMenu
{
    NSMenu *jMenu = [[NSMenu alloc] initWithTitle:@"Journals"];
    int i;

    [jMenu setAutoenablesItems:NO];
    for (i = 0; i < [_journalArray count]; i++) {
        LJJournal *j = [_journalArray objectAtIndex:i];
        NSMenuItem *jItem = [[NSMenuItem alloc] initWithTitle:[j name]
                                                       action:NULL
                                                keyEquivalent:@""];
        [jItem setRepresentedObject:j];
        [jMenu addItem:jItem];
        [jItem release];
    }
    return [jMenu autorelease];
}

- (NSMutableDictionary *)customInfo
{
    if (_customInfo == nil) _customInfo = [[NSMutableDictionary alloc] init];
    return _customInfo;
}

- (NSString *)identifier
{
    NSURL *serverURL = [_server url];
    int p = [[serverURL port] intValue];
    return [NSString stringWithFormat:@"%@@%@:%u",
        _username, [serverURL host], (p != 0 ? p : 80)];
}

- (id)delegate
{
    return _delegate;
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

- (void)setDelegate:(id)delegate
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

@end
