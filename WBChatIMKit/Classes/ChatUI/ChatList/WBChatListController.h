//
//  WBChatListController.h
//  WBChat
//
//  Created by RedRain on 2017/11/17.
//  Copyright © 2017年 RedRain. All rights reserved.
//

static NSString *NotificationKey_WBChatList_Fetching = @"NotificationKey_WBChatList_Fetching";
static NSString *NotificationKey_WBChatList_FetchCompleted = @"NotificationKey_WBChatList_FetchCompleted";

#import "WBBaseController.h"
@class WBChatListCellModel;
@interface WBChatListController : WBBaseController
@property (nonatomic, strong) NSMutableArray<WBChatListCellModel *> *dataArray;

@end
