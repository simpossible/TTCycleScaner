//
//  ViewController.m
//  Cyclescaner
//
//  Created by simp on 2018/3/12.
//  Copyright © 2018年 yiyou. All rights reserved.
//

#import "ViewController.h"
#import "TTCycleScaner.h"
#import <Masonry.h>

@interface ViewController ()<TTCycleScanerProtocol>

@property (nonatomic, strong) TTCycleScaner * currentScaner;

@property (nonatomic, strong) NSArray * datas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initialData];
    [self initialUI];
    
}

- (void)initialData{
    self.datas =  @[
                                              @"http://g.hiphotos.baidu.com/zhidao/wh%3D450%2C600/sign=bbd33f6200087bf47db95fedc7e37b1a/38dbb6fd5266d016af629e01952bd40735fa359b.jpg",
                                              @"http://p2.qhmsg.com/dr/270_500_/t0162bcd037ca81acdb.jpg?size=512x512",
                                              @"http://imagecdn.lecake.com/postsystem/docroot/images/goods/201212/10865/display_10865_2.jpg?v=20170914"/*,
                                              @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1515584537861&di=f0a1020899e142557138405e73d5a9a3&imgtype=0&src=http%3A%2F%2Fimgsrc.baidu.com%2Fimgad%2Fpic%2Fitem%2F43a7d933c895d143da3cb80b78f082025aaf074b.jpg",
                                             */ ];;
    
    
    CGFloat totoal = 0;
    for (int i = 0; i < 60; i ++) {
        CGFloat angel =  M_PI/60;
        angel = angel * i;
        CGFloat sangel = sin(angel);
        totoal +=sangel;
    }
    NSLog(@"the totoalAngel is %f",totoal);
    
}

- (void)initialUI {
    self.currentScaner = [[TTCycleScaner alloc] initWithDirection:TTCycleScanerDirectionHorizontal];
    [self.view addSubview:self.currentScaner];
    
    [self.currentScaner mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view.mas_centerY);
        make.centerX.equalTo(self.view.mas_centerX);
        make.width.equalTo(self.view.mas_width);
        make.height.mas_equalTo(100);
    }];
    self.currentScaner.speed = 2;
    
    self.currentScaner.delegate = self;
    

    
}

- (NSInteger)numberOfItemForCyCleScaner {
    return self.datas.count;
}

- (TTCycleScanItem *)cycleScaner:(TTCycleScaner *)scaner itemForIndex:(NSInteger)index {
    NSInteger count = self.datas.count;
    
    NSInteger i = (index % count + count)%count;
    TTCycleScanItem *item = [scaner deqeenItemForReuseIdentifire:@"hehe"];
    if (!item) {
        item = [[TTCycleScanItem alloc] initWithReuseIdentifire:@"hehe"];
    }
    NSString *url = [self.datas objectAtIndex:i];
    item.url = url;
    
    return item;
}

- (void)viewDidLayoutSubviews{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.currentScaner startAutoScroll];
//    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)cycleScaner:(TTCycleScaner *)scaner didSelectItem:(TTCycleScanItem *)item {
    NSLog(@"haha");
}

- (NSUInteger)numberOfPageForCycleScaner:(TTCycleScaner *)scaner {
    return 5;
}

@end
