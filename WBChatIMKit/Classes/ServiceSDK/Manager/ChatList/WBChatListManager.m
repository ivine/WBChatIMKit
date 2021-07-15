//
//  WBChatListManager.m
//  WBChat
//
//  Created by RedRain on 2018/1/16.
//  Copyright © 2018年 RedRain. All rights reserved.
//

#import "WBChatListManager.h"
#import "WBChatListDao.h"
#import "WBChatInfoDao.h"

@implementation WBChatListManager
WB_SYNTHESIZE_SINGLETON_FOR_CLASS(WBChatListManager)

- (BOOL)createDBTable{
    return [[WBChatListDao sharedInstance] createDBTable];
}

#pragma mark - 拉取服务器端的所有对话
- (void)fetchAllConversationsFromServer:(void(^_Nullable)(NSArray<WBChatListModel *> * _Nullable conersations,
                                                          NSError * _Nullable error))block {
    
    [self fetchConversationsWithCachePolicy:kLCIMCachePolicyIgnoreCache block:block];

}
- (void)fetchAllConversationsFromLocal:(void(^_Nullable)(NSArray<WBChatListModel *> * _Nullable conersations,
                                                          NSError * _Nullable error))block {
    
    
    [[WBChatListDao sharedInstance] loadChatListWithClient:self.client
                                                    result:^(NSArray<WBChatListModel *> * _Nonnull modelArray)
    {
        block(modelArray,nil);
    }];
}

- (void)fetchConversationsWithCachePolicy:(LCIMCachePolicy)chachePolicy block:(id)block{
    LCIMConversationQuery *orConversationQuery = [self.client conversationQuery];
    
    orConversationQuery.cachePolicy = chachePolicy;
    orConversationQuery.option = LCIMConversationQueryOptionWithMessage;
    [orConversationQuery findConversationsWithCallback:^(NSArray<LCIMConversation *> * _Nullable conversations, NSError * _Nullable error) {
        
        [self fetchAllConversationsFromLocal:^(NSArray<WBChatListModel *> * _Nullable localConversations, NSError * _Nullable error) {
            NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:conversations.count];

            
            // 1.把远端的信息保存成字典模式
            NSMutableDictionary *mDic = [NSMutableDictionary new];
            for (LCIMConversation *conver in conversations) {
                mDic[conver.conversationId] = conver;
            }
            
            
            
            // 2.以本地的最近联系人列表为准, 更新信息
            for (WBChatListModel *localListModel in localConversations) {
                LCIMConversation *conver = mDic[localListModel.conversationID];
                if (conver) {
                    WBChatListModel *listModel = [WBChatListModel createWithConversation:conver];
                    // 2.1.从服务器获取的信息, 使用本地的未读消息数量
                    listModel.unreadCount = [localListModel unreadCount];
                    [tempArray addObject:listModel];
                }
            }

            
            // 3.存储到本地
            if (tempArray.count) {
                [[WBChatListDao sharedInstance] insertChatListModelArray:tempArray];
            }
            
            // PS: 远端的最近联系人列表和本地是有区别的, 本地列表的新增是通过收到消息插入的.
            
            !block ?: ((LCIMArrayResultBlock)block)(tempArray, error);
        }];
        
        
    }];
}

#pragma mark - 根据 conversationId 获取对话
/**
 *  根据 conversationId 获取对话
 *  @param conversationId   对话的 id
 */
- (void)fetchConversationWithConversationId:(NSString *)conversationId callback:(void (^)(LCIMConversation *conversation, NSError *error))callback {
    NSAssert(conversationId.length > 0, @"Conversation id is nil");
    LCIMConversation *conversation = [self.client conversationForId:conversationId];
    if (conversation) {
        !callback ?: callback(conversation, nil);
        return;
    }
    
    NSSet *conversationSet = [NSSet setWithObject:conversationId];
    [self fetchConversationsWithConversationIds:conversationSet callback:^(NSArray *objects, NSError *error) {
        if (error) {
            !callback ?: callback(nil, error);
        } else {
            if (objects.count == 0) {
                NSString *errorReasonText = [NSString stringWithFormat:@"conversation of %@ are not exists", conversationId];
                NSInteger code = 0;
                NSDictionary *errorInfo = @{
                                            @"code" : @(code),
                                            NSLocalizedDescriptionKey : errorReasonText,
                                            };
                NSError *error = [NSError errorWithDomain:WBIMConversationFindErrorDomain
                                                     code:code
                                                 userInfo:errorInfo];
                !callback ?: callback(nil, error);
            } else {
                !callback ?: callback(objects[0], error);
            }
        }
    }];
}

#pragma mark - 根据 conversationId集合 获取对话
/**
 *  根据 conversationId数组 获取多个指定的会话信息
 */
- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds
                                     callback:(void (^_Nullable)(NSArray<LCIMConversation *> * _Nullable conersations,
                                                                 NSError * _Nullable error))callback {
    LCIMConversationQuery *query = [self.client conversationQuery];
    [query whereKey:@"objectId" containedIn:[conversationIds allObjects]];
    query.limit = conversationIds.count;
    query.option = LCIMConversationQueryOptionWithMessage;
    query.cacheMaxAge = kLCIMCachePolicyIgnoreCache;
    [query findConversationsWithCallback: ^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [objects makeObjectsPerformSelector:@selector(lastMessage)];
            dispatch_async(dispatch_get_main_queue(),^{
                !callback ?: callback(objects, error);
            });
        });
    }];
}
#pragma mark - 更新最近一条消息记录到List
static LCIMConversation * staticLastConversation = nil;
- (void)insertConversationToList:(LCIMConversation *)conversation{
    
    if (conversation == nil) {
        return;
    }
    
    // 把最新的信息保存到库中
    WBChatListModel *listModel = [WBChatListModel createWithConversation:conversation];
    
    [[WBChatListDao sharedInstance] insertChatListModel:listModel];
    
    [self pushChatListUpdateAction:conversation];
    
}
- (void)pushChatListUpdateAction:(LCIMConversation *)conversation{
    NSMutableDictionary *mDic = [NSMutableDictionary new];
    if (conversation) {
        mDic[WBMessageConversationKey] = conversation;
    }
    if (conversation.lastMessage) {
        mDic[WBMessageMessageKey] = conversation.lastMessage;
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:WBChatListUpdateNotification object:nil
     userInfo:mDic];
}


/**
 根据conversationId, 判断本地有没有对应的会话信息
 
 @param conversationId conversationId
 @return 是否已经存在
 */
- (BOOL)isExistWithConversationId:(NSString *)conversationId{
    return [[WBChatListDao sharedInstance] isExistWithConversationId:conversationId];
}


#pragma mark - 删除一个会话
- (void)deleteConversation:(NSString *)conversationId{
    
    WBChatListModel *listModel = [[WBChatListDao sharedInstance] chatListModelWithConversationId:conversationId client:self.client];
    
    /**
     * 暂时注释这一段代码
     * 备注： readInBackground 会触发
     * delegate: `- (void)conversation:(LCIMConversation *)conversation didUpdateForKey:(NSString *)key`
     * delgate ---> insertConversationToList ---> re-add this converation to local DB
     * 从而导致该聊天无法被删除
    if (listModel) {
        // 清除之前的未读数, 以及聊天记录
        [listModel.conversation readInBackground];
    }
    */
    
    // 列表
    [[WBChatListDao sharedInstance] deleteConversation:conversationId];
}

#pragma mark - 改变某个会话的会话状态
/**
 阅读了某个会话
 
 @param conversation 被阅读的会话
 */
- (void)readConversation:(LCIMConversation *)conversation{
    // 设置某个会话为已读
    [conversation readInBackground];
    
    // 更新本地数据库
    [self insertConversationToList:conversation];
}

#pragma mark - Private Methods
- (LCIMClient *)client{
    return [WBChatKit sharedInstance].usingClient;
}
@end
