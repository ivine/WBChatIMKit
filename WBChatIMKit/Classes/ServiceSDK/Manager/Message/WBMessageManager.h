//
//  WBMessageManager.h
//  WBChat
//
//  Created by RedRain on 2018/1/27.
//  Copyright © 2018年 RedRain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBCoreConfiguration.h"
#import <LeanCloudObjc/Foundation.h>
#import <LeanCloudObjc/Realtime.h>

#define WBMessageConversationKey @"conversation"
#define WBMessageMessageKey @"message"


#define WBMessageNewReceiveNotification @"WBMessageNewReceiveNotification"


NS_ASSUME_NONNULL_BEGIN

@interface WBMessageManager : NSObject
WB_SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(WBMessageManager)


/**
 收到新的消息
 */
- (void)conversation:(LCIMConversation *)conversation didReceiveTypedMessage:(LCIMTypedMessage *)message;

@end
NS_ASSUME_NONNULL_END
