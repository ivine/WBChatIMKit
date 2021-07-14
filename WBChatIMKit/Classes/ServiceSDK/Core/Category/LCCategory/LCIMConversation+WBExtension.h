//
//  AVIMConversation+WBExtension.h
//  AVOSCloud
//
//  Created by RedRain on 2018/3/14.
//

#import <LeanCloudObjc/Realtime.h>
#import "WBIMDefine.h"
@interface LCIMConversation (WBExtension)

/**
 得到会话的类型

 @return 会话类型
 */
- (WBConversationType)wb_conversationType;
@end
