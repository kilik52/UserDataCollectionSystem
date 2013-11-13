//
//  UDCSystem.m
//  UserDataCollection
//
//  Created by 朱 曦炽 on 13-9-6.
//  Copyright (c) 2013年 Mirroon. All rights reserved.
//

#import "UDCSystem.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import <AdSupport/AdSupport.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "Reachability/UDCReachability.h"
#import "UDCDataUploader.h"

@interface UDCSystem ()
@property (nonatomic, strong) NSMutableDictionary *dataDic;
@property (nonatomic, strong) NSString *serverUrlString;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic) BOOL systemFirstStartup;
@end

@implementation UDCSystem
static UDCSystem *sharedInstance = nil;

#pragma mark - Life Cycle
// init function
- (id)initWithServerUrl:(NSString*)serverUrl secret:(NSString*)secret
{
    self = [super init];
    if (self) {
        self.systemFirstStartup = YES;
        self.serverUrlString = serverUrl;
        self.secret = secret;
        
        _dataDic = [[NSMutableDictionary alloc] init];
        
        [self.dataDic setObject:UDCSYSTEM_DATA_VERSION forKey:@"UDCSystemVersion"];
        [self.dataDic setObject:[UDCSystem UUID] forKey:@"UUID"];
        [self.dataDic setObject:[NSString stringWithFormat:@"%@", [UDCSystem OSVersion]] forKey:@"OSVersion"];
        [self.dataDic setObject:@"iOS" forKey:@"OS"];
        [self.dataDic setObject:[NSString stringWithFormat:@"%@", [UDCSystem deviceModel]] forKey:@"Device"];
        [self.dataDic setObject:[UDCSystem localTimeZone] forKey:@"LocalTimeZone"];
        [self.dataDic setObject:[UDCSystem appVersion] forKey:@"AppVersion"];
        [self.dataDic setObject:[UDCSystem carrier] forKey:@"Carrier"];
#ifdef DEBUG
        [self.dataDic setObject:@"true" forKey:@"DEBUG"];
#endif
        
        [self registerNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Singleton Function
+ (UDCSystem *)sharedInstance
{
    // must call registerWithServerUrl to init the singleton instance, so if we call this function first, just return nil
    return sharedInstance;
}

#pragma mark - Public methods
+ (void)registerWithServerUrl:(NSString*)urlString secret:(NSString*)secretString
{
    sharedInstance = [[UDCSystem alloc] initWithServerUrl:urlString secret:secretString];
}

+ (NSString*)UUID
{
    NSString *uuidString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return uuidString;
}

+ (NSString*)currentDateAdjustByTimeZone
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    // set time format
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    
    // set time zone
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    
    NSString *formattedDate = [formatter stringFromDate:[NSDate date]];
    
    return formattedDate;
}

+ (NSString*)OSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString*)deviceModel
{
    NSString *platform = [UDCSystem platform];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4 (Verizon)";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (CDMA)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}

+ (NSString*)localTimeZone
{
    return [[NSTimeZone localTimeZone] name];
}

+ (NSString*)appVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString*)carrier
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    if ([carrier carrierName] == NULL) {
        return @"None";
    }
    
    return [carrier carrierName];
}

+ (void)event:(NSString*)name
{
    [[UDCSystem sharedInstance] recordEvent:name eventType:UDC_EVENT_TYPE_USER];
}

+ (void)pageAppear:(NSString*)pageName
{
    // add a 'A' prefix to indicate it's a appear event
    [[UDCSystem sharedInstance] recordEvent:[NSString stringWithFormat:@"A%@",pageName] eventType:UDC_EVENT_TYPE_PAGE];
}

+ (void)pageDisappear:(NSString*)pageName
{
    // add a 'D' prefix to indicate it's a disappear event
    [[UDCSystem sharedInstance] recordEvent:[NSString stringWithFormat:@"D%@",pageName] eventType:UDC_EVENT_TYPE_PAGE];
}

+ (void)printCollectedData
{
    UDCSystem *system = [UDCSystem sharedInstance];
    NSLog(@"Start print collected data....");
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:system.dataDic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",jsonString);
    }
    
    NSLog(@"End print collected data....");
}

#pragma mark - Notifications
- (void) DidBecomeActiveNotification:(NSNotification *) notification
{
    if (!self.systemFirstStartup) {
        [self recordEvent:@"DidBecomeActiveNotification" eventType:UDC_EVENT_TYPE_SYSTEM];
    }
    else {
        // send app startup event
        [self recordEvent:@"DidFinishLaunching" eventType:UDC_EVENT_TYPE_SYSTEM];
    }
    self.systemFirstStartup = NO;
}

- (void) DidEnterBackgroundNotification:(NSNotification *) notification
{
    [self recordEvent:@"DidEnterBackgroundNotification" eventType:UDC_EVENT_TYPE_SYSTEM];
}

- (void) WillTerminateNotification:(NSNotification *) notification
{
    [self recordEvent:@"WillTerminateNotification" eventType:UDC_EVENT_TYPE_SYSTEM];
}

#pragma mark - helper function
- (void)recordEvent:(NSString*)name eventType:(UDC_EVENT_TYPE)eventType
{
    if ([name length] == 0) {
        NSLog(@"ERROR: event name is empty!");
        return;
    }
    
    // 'S' stands for system data, 'U' stands for user data, 'P' stands for paging data
    NSString *recordName;
    switch (eventType) {
        case UDC_EVENT_TYPE_USER:
            recordName = [@"U" stringByAppendingString:name];
            break;
            
        case UDC_EVENT_TYPE_SYSTEM:
            recordName = [@"S" stringByAppendingString:name];
            break;
            
        case UDC_EVENT_TYPE_PAGE:
            recordName = [@"P" stringByAppendingString:name];
            break;
        default:
            break;
    }
    
    @synchronized(self.dataDic)
    {
        [self.dataDic setObject:recordName forKey:@"EventName"];
        [self.dataDic setObject:[UDCSystem currentDateAdjustByTimeZone] forKey:@"EventFireTimeLocal"];
        [self.dataDic setObject:self.secret forKey:@"Secret"];
        
        //[UDCSystem printCollectedData];
        
        [self uploadData];
        
        [self.dataDic removeObjectsForKeys:@[@"EventName",@"EventFireTimeLocal"]];
    }
}

+ (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (void)uploadData
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.dataDic
                                                       options:0
                                                         error:&error];
    UDCDataUploader *uploader = [[UDCDataUploader alloc] init];
    [uploader startUpload:self.serverUrlString content:jsonData];
}

- (void)registerNotifications
{
    // register some notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(DidBecomeActiveNotification:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(DidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(WillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    // Reachability, Add this to Events
    UDCReachability* reach = [UDCReachability reachabilityWithHostname:@"www.apple.com"];
    
    // Set the blocks
    reach.reachableBlock = ^(UDCReachability *reach)
    {
        NSString *reachString = [NSString stringWithFormat:@"Reachability:%@", reach.currentReachabilityString];
        [self recordEvent:reachString eventType:UDC_EVENT_TYPE_SYSTEM];
    };
    
    reach.unreachableBlock = ^(UDCReachability *reach)
    {
        NSString *reachString = [NSString stringWithFormat:@"Reachability:%@", reach.currentReachabilityString];
        [self recordEvent:reachString eventType:UDC_EVENT_TYPE_SYSTEM];
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}
@end
