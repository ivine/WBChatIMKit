//
//  AVIMTypedMessage+WBExtension.h
//  WBChat

#import <LeanCloudObjc/Realtime.h>
#import "WBMessageModel.h"
@interface LCIMTypedMessage (WBExtension)

- (void)wb_setAttributesObject:(id)object forKey:(NSString *)key;

- (WBChatMessageType)messageType_wb;

@end
