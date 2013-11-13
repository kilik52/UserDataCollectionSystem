//
//  UDCDataUploader.h
//  UserDataCollection
//
//  Created by 朱 曦炽 on 13-9-10.
//  Copyright (c) 2013年 Mirroon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UDCDataUploader : NSObject
- (void)startUpload:(NSString*)urlString content:(NSData*)contentData;
@end
