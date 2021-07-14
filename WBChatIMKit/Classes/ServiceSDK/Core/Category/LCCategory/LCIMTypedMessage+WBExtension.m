//
//  AVIMTypedMessage+WBExtension.m

#import "LCIMTypedMessage+WBExtension.h"

@implementation LCIMTypedMessage (WBExtension)
- (void)wb_setAttributesObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:object forKey:key];
    if (self.attributes == nil) {
        self.attributes = attributes;
    } else {
        [attributes addEntriesFromDictionary:self.attributes];
        self.attributes = attributes;
    }
    self.attributes = attributes;
}

- (WBChatMessageType)messageType_wb{
    return self.mediaType;
}
@end
