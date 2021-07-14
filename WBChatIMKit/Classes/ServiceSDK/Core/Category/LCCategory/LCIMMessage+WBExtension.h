//
//  AVIMMessage+WBExtension.h


#import <LeanCloudObjc/Realtime.h>

@interface LCIMMessage (WBExtension)

- (LCIMTypedMessage *)wb_getValidTypedMessage;
- (BOOL)wb_isValidMessage;

@end
