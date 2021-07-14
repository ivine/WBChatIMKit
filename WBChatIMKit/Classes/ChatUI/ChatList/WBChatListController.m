//
//  WBChatListController.m
//  WBChat
//
//  Created by RedRain on 2017/11/17.
//  Copyright © 2017年 RedRain. All rights reserved.
//

#import "WBChatListController.h"
#import "WBChatListCell.h"
#import "WBChatViewController.h"
#import "WBServiceSDKHeaders.h"
#import "WBIMDefine.h"

@interface WBChatListController ()
@property (nonatomic, strong) NSTimer *dalayTimer;
@end

@implementation WBChatListController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [self setupObserver];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadListData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -  Life Cycle
#pragma mark -  UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WBChatListCell *cell = [WBChatListCell cellWithTableView:tableView];
    cell.cellModel = self.dataArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    WBChatListCellModel *cellModle = self.dataArray[indexPath.row];
    
    WBChatViewController *vc = [WBChatViewController createWithConversation:cellModle.dataModel.conversation];
    vc.title = cellModle.title;
    [self.navigationController pushViewController:vc animated:YES];
}


- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {

    WBChatListCellModel *cellModel = nil;
    if ((NSUInteger)indexPath.row < self.dataArray.count) {
        cellModel = self.dataArray[indexPath.row];
    }
    else {
        return nil;
    }
    UITableViewRowAction *actionItemDelete = [UITableViewRowAction
                                              rowActionWithStyle:UITableViewRowActionStyleNormal
                                              title:@"删除"
                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                  LCIMConversation *conversation = cellModel.dataModel.conversation;
                                                  [[WBChatKit sharedInstance] deleteConversation:conversation.conversationId];
                                                  [self reloadListData];
                                              }];
    actionItemDelete.backgroundColor = [UIColor redColor];
    return @[ actionItemDelete ];
}


#pragma mark -  CustomDelegate
#pragma mark -  Event Response
#pragma mark -  Notification Callback
- (void)connectivityUpdated:(NSNotification *)notifi{
    do_dispatch_async_mainQueue(^{
        WBLog(@"%@",@([WBChatKit sharedInstance].connectStatus));
        switch ([WBChatKit sharedInstance].connectStatus) {
            case LCIMClientStatusOpening:
            case LCIMClientStatusResuming:{
                WBLog(@"链接中...");
            }
                break;
            case LCIMClientStatusClosed:{
                WBLog(@"未连接");
            }
                break;
            case LCIMClientStatusOpened:
                WBLog(@"连接正常");
                [self reloadListData];
                break;
            default:
                WBLog(@"连接...");
                break;
        }
    });
}


- (void)receiveListUpdateAction:(NSNotification *)notifi{
    [self reloadListData];
}
#pragma mark -  GestureRecognizer Action
#pragma mark -  Btn Click
#pragma mark -  Private Methods
- (void)setupUI{
    // 导航栏透明
    CGFloat navHeight = 0;
    if(self.navigationController.navigationBar.translucent == YES){
        navHeight = WB_NavHeight;
    }
    self.tableView.top_wb = navHeight;
    self.tableView.height_wb -= navHeight;

    [self.view addSubview:self.tableView];
    self.tableView.rowHeight = [WBChatListCell cellHeight];
}
- (void)setupObserver{

    [self notificationName:WBIMNotificationConnectivityUpdated action:@selector(connectivityUpdated:)];
    [self notificationName:WBChatListUpdateNotification action:@selector(receiveListUpdateAction:)];
}

- (void)notificationName:(NSString *)name action:(SEL)action{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:action name:name object:nil];
}


- (void)reloadListData {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController != nil) {
            if (self.parentViewController != nil &&
                self.navigationController.topViewController != self.parentViewController) {
                return;
            } else if (self.parentViewController == nil && self.navigationController.topViewController != self) {
                return;
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKey_WBChatList_Fetching object:nil];
        [[WBChatKit sharedInstance] fetchAllConversationsFromLocal:^(NSArray<WBChatListModel *> * _Nullable conersations,
                                                                     NSError * _Nullable error) {
            
            NSMutableArray *tempA = [NSMutableArray arrayWithCapacity:conersations.count];
            for (WBChatListModel *obj in conersations) {
                WBChatListCellModel *cellModel = [WBChatListCellModel new];
                
                // 在set方法中,进行了frame计算, 时间戳整理等操作
                cellModel.dataModel = obj;
                
                [tempA addObject:cellModel];
            }
            self.dataArray = tempA;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.tableView reloadData];
            });
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationKey_WBChatList_FetchCompleted object:nil];
        }];
    });
}


#pragma mark -  Public Methods
#pragma mark -  Getters and Setters
-(NSMutableArray *)dataArray{
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc]init];
    }
    return _dataArray;
}
@end

