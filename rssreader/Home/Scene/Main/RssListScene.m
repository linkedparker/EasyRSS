//
//  RssListScene.m
//  rssreader
//
//  Created by 朱潮 on 14-8-19.
//  Copyright (c) 2014年 zhuchao. All rights reserved.
//

#import "RssListScene.h"
#import "RssCell.h"
#import "RssDetailScene.h"
#import "FeedSceneModel.h"
#import "RssListSceneModel.h"
#import "WebDetailScene.h"
#import "ActionSceneModel.h"
#import "AddFeedRequest.h"

@interface RssListScene ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong)RssListSceneModel *rssSceneModel;
@property (strong, nonatomic) SceneTableView *tableView;
@property (strong,nonatomic)FeedEntity *feed;
@end

@implementation RssListScene

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.params[@"title"];
    UIButton *leftbutton = [IconFont buttonWithIcon:[IconFont icon:@"fa_chevron_left" fromFont:fontAwesome] fontName:fontAwesome size:24.0f color:[UIColor whiteColor]];
    [self showBarButton:NAV_LEFT button:leftbutton];
    

    self.tableView = [[SceneTableView alloc]init];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 210.0f;
    [self addSubView:self.tableView extend:EXTEND_TOP];
    [self.tableView registerClass:[RssCell class] forCellReuseIdentifier:@"RssCell"];
    
    _rssSceneModel = [RssListSceneModel SceneModel];
    _rssSceneModel.request.feedId = self.params[@"id"];
    @weakify(self);
    [self.tableView addPullToRefreshWithActionHandler:^{
        @strongify(self);
        self.rssSceneModel.request.page = @1;
        self.rssSceneModel.request.requestNeedActive = YES;
    }];
    
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        @strongify(self);
        self.rssSceneModel.request.page = [self.rssSceneModel.request.page increase:@1];
        self.rssSceneModel.request.requestNeedActive = YES;
    }];

    [[RACObserve(self.rssSceneModel, rssList)
      filter:^BOOL(RssList* value) {
          return value !=nil;
      }]
     subscribeNext:^(RssList *value) {
         @strongify(self);
         self.rssSceneModel.dataArray = [value.pagination
                                          success:self.rssSceneModel.dataArray
                                          newArray:value.list];
         self.rssSceneModel.request.page = value.pagination.page;
         [self.tableView reloadData];
         [self.tableView endAllRefreshingWithIntEnd:value.pagination.isEnd.integerValue];
     }];
    
    [[RACObserve(self.rssSceneModel.request, state)
      filter:^BOOL(NSNumber *state) {
          @strongify(self);
          return self.rssSceneModel.request.failed;
      }]
     subscribeNext:^(id x) {
         @strongify(self);
         self.rssSceneModel.request.page = self.rssSceneModel.rssList.pagination.page?:@1;
         [self.tableView endAllRefreshingWithIntEnd:self.rssSceneModel.rssList.pagination.isEnd.integerValue];
     }];
    
    [self.tableView triggerPullToRefresh];
    [self loadHud:self.view];
}

-(void)rightButtonTouch{
    AddFeedRequest *req = [AddFeedRequest Request];
    req.feedUrl = _feed.link;
    req.feedType = _feed.feedType;
    
    [self showHudIndeterminate:@"正在加载"];
    [[ActionSceneModel sharedInstance] sendRequest:req success:^{
        [self hideHudSuccess:@"订阅成功"];
    } error:^{
         [self hideHudFailed:@"订阅失败"];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rssSceneModel.dataArray.count;
}

- (UITableViewCell *)tableView:(SceneTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RssCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RssCell" forIndexPath:indexPath];
    FeedRssEntity *feedRss = [self.rssSceneModel.dataArray objectAtIndex:indexPath.row];
    if(!_feed.isNotEmpty && feedRss.feed.isNotEmpty){
        _feed = feedRss.feed;
        [self showBarButton:NAV_RIGHT title:@"订阅" fontColor:[UIColor whiteColor]];
    }
    [cell reloadRss:feedRss];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FeedRssEntity *feedRss = [self.rssSceneModel.dataArray objectAtIndex:indexPath.row];
    
    if(feedRss.feed.feedType.integerValue == 0){
        RssDetailScene* scene =  [[RssDetailScene alloc]init];
        scene.feedRss = feedRss;
        [self.navigationController pushViewController:scene animated:YES];
    }else{
        WebDetailScene* scene =  [[WebDetailScene alloc]init];
        scene.feedRss = feedRss;
        [self.navigationController pushViewController:scene animated:YES];
    }
}
@end
