//
//  UDCSystem.h
//  UserDataCollection
//
//  Created by 朱 曦炽 on 13-9-6.
//  Copyright (c) 2013年 Mirroon. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UDCSYSTEM_DATA_VERSION @"1.0"

typedef NS_ENUM(NSInteger, UDC_EVENT_TYPE) {
    UDC_EVENT_TYPE_USER,
    UDC_EVENT_TYPE_SYSTEM,
    UDC_EVENT_TYPE_PAGE,
};

@interface UDCSystem : NSObject

// regitster function
+ (void)registerWithServerUrl:(NSString*)urlString secret:(NSString*)secretString;

// Get advertisingIdentifier
+ (NSString*)UUID;

// Get current date adjust by time zone
+ (NSString*)currentDateAdjustByTimeZone;

// Get OS Version
+ (NSString*)OSVersion;

// Get Device Info
+ (NSString*)deviceModel;

// Get local time zone
+ (NSString*)localTimeZone;

// Get App Version
+ (NSString*)appVersion;

// Get Carrier
+ (NSString*)carrier;

// Record event
+ (void)event:(NSString*)name;

// Page event
+ (void)pageAppear:(NSString*)pageName;
+ (void)pageDisappear:(NSString*)pageName;

// Print out collected data
+ (void)printCollectedData;
@end
