//
//  UDCDataUploader.m
//  UserDataCollection
//
//  Created by 朱 曦炽 on 13-9-10.
//  Copyright (c) 2013年 Mirroon. All rights reserved.
//

#import "UDCDataUploader.h"

@interface UDCDataUploader ()
@property (nonatomic, strong) NSURLConnection *dataConnection;
@end

@implementation UDCDataUploader
- (void)startUpload:(NSString*)urlString content:(NSData*)contentData
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:
                                    [NSURL URLWithString:urlString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString* postDataLengthString = [[NSString alloc] initWithFormat:@"%d", [contentData length]];
    [request setValue:postDataLengthString forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:contentData];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request
                                                            delegate:nil];
    
    self.dataConnection = conn;
}
@end
