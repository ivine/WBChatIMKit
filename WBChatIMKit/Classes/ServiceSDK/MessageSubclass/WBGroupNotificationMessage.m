//
//  WBGroupNotificationMessage.m
//  AVOSCloud
//
//  Created by RedRain on 2018/3/14.
//

#import "WBGroupNotificationMessage.h"
#import "WBMessageModel.h"


@implementation WBGroupNotificationMessage
+ (void)load{
    [self registerSubclass];
}

#pragma mark - LCIMTypedMessageSubclassing
+ (LCIMMessageMediaType)classMediaType{
    return (int8_t)(WBChatMessageTypeNotification);
}
@end
