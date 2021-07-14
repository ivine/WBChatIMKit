//
//  WBMessageModel.m
//  WBChat
//
//  Created by RedRain on 2018/1/26.
//  Copyright © 2018年 RedRain. All rights reserved.
//

#import "WBMessageModel.h"
#import "WBNamedTool.h"
#import "WBPathManager.h"
#import "WBFileManager.h"
#import "UIImage+WBScaleExtension.h"


#define kMessageThumbImageKey @"thumbImg"
#define kMessageLocalImgNameKey @"LocalImgName"


@implementation WBMessageModel


+ (instancetype)createWithTypedMessage:(LCIMTypedMessage *)message{
    WBMessageModel *messageModel = [WBMessageModel new];
    messageModel.status = message.status;
    messageModel.content = message;
    
//    kLCIMMessageMediaTypeNone = 0,
//    kLCIMMessageMediaTypeText = -1,
//    kLCIMMessageMediaTypeImage = -2,
//    kLCIMMessageMediaTypeAudio = -3,
//    kLCIMMessageMediaTypeVideo = -4,
//    kLCIMMessageMediaTypeLocation = -5,
//    kLCIMMessageMediaTypeFile = -6,
//    kLCIMMessageMediaTypeRecalled = -127
    
    switch (message.mediaType) {
        case kLCIMMessageMediaTypeImage:{
            NSDictionary *info = message.attributes;
            NSString *encodedImgString = info[kMessageThumbImageKey];
            messageModel.thumbImage = [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:encodedImgString options:0]];
            
            NSString *imageName = info[kMessageLocalImgNameKey];
            NSString *imageFilePath = [[WBPathManager imagePath] stringByAppendingPathComponent:imageName];

            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *imagePath;
            if ([fileManager fileExistsAtPath:imageFilePath]){
                imagePath = imageFilePath;
            }else{
                LCIMImageMessage *imageMsg = (LCIMImageMessage*)message;
                imagePath = imageMsg.file.url;
            }
            
            messageModel.imagePath = imagePath;
            
        }
            break;
        case kLCIMMessageMediaTypeAudio:{
            LCIMAudioMessage *audioMsg = (LCIMAudioMessage*)message;
            messageModel.voiceDuration = @(audioMsg.duration).stringValue;
            
            
            NSString *pathForFile = audioMsg.file.url;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *aPath;
            if ([fileManager fileExistsAtPath:pathForFile]){
                aPath = audioMsg.file.url;
            }else{
                aPath = audioMsg.file.url;
            }
            messageModel.audioPath = aPath;
        }break;
            
        default:
            break;
    }
    return messageModel;
}


+ (instancetype)createWithText:(NSString *)text{
    
    LCIMTextMessage *messageText = [LCIMTextMessage messageWithText:text attributes:nil];
    WBMessageModel *message = [WBMessageModel new];
    message.status = LCIMMessageStatusSending;
    message.content = messageText;
    return message;
}

+ (instancetype)createWithImage:(UIImage *)image{
    // 1.得到路径
    
    
    // 2.处理图片,让体积小一些, 节省流量
    NSString *imageName = [WBNamedTool namedWithType:(WBResNamedTypeImage)];
    NSString *imageFilePath = [[WBPathManager imagePath] stringByAppendingPathComponent:imageName];
    UIImage *normalImage = [image wb_imageByScalingAspectFill];
    NSData *normalData = UIImageJPEGRepresentation(normalImage, 1);
    [WBFileManager saveImageData:normalData toImagePath:imageFilePath];
    
    // 3.压缩图
    NSData *thumbData = [normalImage wb_compressWithMaxKBytes:3];
    
    WBMessageModel *messageModel = [WBMessageModel new];
    messageModel.status = LCIMMessageStatusSending;
    messageModel.thumbImage = [UIImage imageWithData:thumbData];
    messageModel.imagePath = imageFilePath;
    
    LCIMImageMessage *imgMsg = [LCIMImageMessage messageWithText:nil
                                                attachedFilePath:imageFilePath
                                                      attributes:@{kMessageThumbImageKey:[thumbData base64EncodedStringWithOptions:0],
                                                                   kMessageLocalImgNameKey:imageName}];
    messageModel.content = imgMsg;
    
    return messageModel;

}

+ (instancetype)createWithAudioPath:(NSString *)audioPath duration:(NSNumber *)duration{
    LCIMAudioMessage *audioMsg = [LCIMAudioMessage messageWithText:nil attachedFilePath:audioPath attributes:nil];

    WBMessageModel *messageModel = [WBMessageModel new];
    messageModel.status = LCIMMessageStatusSending;
    messageModel.content = audioMsg;
    messageModel.voiceDuration = duration.stringValue;
    messageModel.audioPath = audioPath;
    return messageModel;

}
- (WBChatMessageType)messageType{
    return self.content.messageType_wb;
}

@end
