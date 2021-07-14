//
//  WBChatKitDelegateObj.m
//  WBChatIMKit_Example
//
//  Created by RedRain on 2018/3/14.
//  Copyright © 2018年 Ding RedRain. All rights reserved.
//

#import "WBChatKitDelegateObj.h"

@implementation WBChatKitDelegateObj
+ (instancetype)sharedManager {
    static WBChatKitDelegateObj *_shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [WBChatKitDelegateObj new];
    });
    
    return _shared;
}


#pragma mark - WBChatKitProtocol
- (NSString *)memberNameWithClientID:(NSString *)clientId{
    LCUser *user = [LCUser objectWithObjectId:clientId];
    [user fetchIfNeeded];
    return user.username;
}

@end
