//
//  TTCycleScaner.m
//  TT
//
//  Created by simp on 2017/11/25.
//  Copyright © 2017年 yiyou. All rights reserved.
//

#import "TTCycleScaner.h"
#import "TTCycleScanItem.h"
#import <Masonry.h>

#define ttcyclescanercount 5

//M_PI 分为60分 的sin值的总和
#define TTSCANSIXTYSIN 38.188459297025602

@interface TTCycleScaner ()<UIScrollViewDelegate,TTCycleScanItemProtocol>

@property (nonatomic, strong) UIScrollView * scrollView;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, strong) NSMutableDictionary * reuseItemQueue;

@property (nonatomic, strong) NSMutableArray * allItems;

@property (nonatomic, assign) NSInteger cuurentIndex;

@property (nonatomic, strong) NSTimer * scrollTimer;

@property (nonatomic, assign) BOOL initialed;

@property (nonatomic, assign) CGFloat lastOffset;

/**纪录timer的值 38.188459297025602*/
@property (nonatomic, assign) CGFloat timerGoing;

@property (nonatomic, assign) BOOL isAutoScrollAnimating;

@property (nonatomic, strong) CADisplayLink * autoScrollTimer;

@property (nonatomic, assign) BOOL isItemTouched;

/**每一帧增加的timergoing。- 这里使用sin函数进行*/
@property (nonatomic, assign) CGFloat angelPerFrame;

@end

@implementation TTCycleScaner
- (instancetype)initWithDirection:(TTCycleScanerDirection)direction {
    if (self = [super init]) {
        self.reuseItemQueue = [NSMutableDictionary dictionary];
        self.allItems = [NSMutableArray array];
        [self initialUI];
        self.scrllTimeSpace = 1;
        self.angelPerFrame = M_PI/60;
        self.timerGoing = 0;
    }
    return self;
}


- (void)initialUI {
    [self initialScrollView];
    [self initialPageControl];
}

- (void)initialScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    [self addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
//    self.scrollView.showsVerticalScrollIndicator = NO;
//    self.scrollView.showsHorizontalScrollIndicator =NO;
    
    self.scrollView.backgroundColor = [UIColor redColor];;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.panGestureRecognizer.delaysTouchesBegan = YES;
    
}

- (void)initialPageControl {
    self.pageControl = [[UIPageControl alloc] init];
    [self addSubview:self.pageControl];
    
    [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_bottom).offset(-6);
    }];
    self.pageControl.currentPage = 0;
    self.pageControl.hidden = YES;
}


#pragma mark - 布局

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!self.initialed) {
        self.initialed = YES;
        if (self.scrollDirection == TTCycleScanerDirectionHorizontal) {
            [self initialItemForHorizontal];
        }else {
            [self initialItemsForVerticle];
        }
    }
    
}

- (void)initialItemsForVerticle {
    
}

- (void)initialItemForHorizontal {
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    
    CGSize contentSize = CGSizeMake(width * ttcyclescanercount * 4,height);
    self.scrollView.contentSize = contentSize;
    
    //初始化4份 中间两个段有值 后来的就一直重用
    for (int i = -2; i <= 2; i ++) {
        TTCycleScanItem *item = [self.delegate cycleScaner:self itemForIndex:i];
        if (!item) {
            continue;
        }
        item.delegate = self;
        [self.allItems addObject:item];
        item.dataIndex = i;
        CGPoint center = CGPointMake(width * ttcyclescanercount*2 + width /2 + width * i, height/2);
        item.frame = self.bounds;
        item.center = center;
        [self.scrollView addSubview:item];
    }
    self.cuurentIndex = 0;
    [self.scrollView setContentOffset:CGPointMake(width *ttcyclescanercount*2, 0)];
    
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{

}


- (void)pageScrollCheck:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    if (self.scrollDirection == TTCycleScanerDirectionHorizontal) {
        
        CGFloat velocyty = offset.x - self.lastOffset;
        if (velocyty <0) {
           
        }else {
            [self pageScroolLeftCheck:scrollView];
        }
        self.lastOffset = scrollView.contentOffset.x;
    }else {
        
    }
}

- (void)pageScroolLeftCheck:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
     CGFloat width = CGRectGetWidth(self.bounds);
    TTCycleScanItem *item = self.allItems.lastObject;
    if (offset.x > width * ttcyclescanercount* 3) {//说明已经翻到最后一个
        self.lastOffset = width * ttcyclescanercount * 2;
        
        //这里移除所有的item 进queue 然后从 2 * ttcyclescanercount 开始
        for (TTCycleScanItem *item in self.allItems) {
            [self enQueenItem:item];
        }
        [self.allItems removeAllObjects];
        for (int i = -1; i <2; i ++) {
            NSInteger dataindex = item.dataIndex + i;
            TTCycleScanItem *rItem =[self.delegate cycleScaner:self itemForIndex:dataindex];
            if (!item) {
                return;
            }
            rItem.delegate = self;
            rItem.dataIndex = dataindex;
            rItem.bounds = self.bounds;
            rItem.center =  CGPointMake(width * ttcyclescanercount*2 + width /2 + width * i, item.center.y);
            [self.allItems addObject:rItem];
            if (!rItem.superview) {
                [self.scrollView addSubview:rItem];
            }
        }
        self.scrollView.contentOffset = CGPointMake(width * ttcyclescanercount * 2, 0);
        
    }else {
        NSInteger dataindex = item.dataIndex + 1;
        TTCycleScanItem *nitem = [self.delegate cycleScaner:self itemForIndex:dataindex];
        if (!nitem) {
            return;
        }
        nitem.delegate = self;
        nitem.dataIndex = dataindex;
        [self.allItems addObject:nitem];
        if (!nitem.superview) {
            [self.scrollView addSubview:nitem];
        }
        nitem.bounds = item.bounds;
        
        CGPoint newCenter = CGPointMake(item.center.x + width, item.center.y);
        nitem.center = newCenter;
    }
    
}

#pragma mark - 滑动

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.scrollTimer) {//自动滚动中
        return;
    }
    CGPoint offset = scrollView.contentOffset;
    if (self.scrollDirection == TTCycleScanerDirectionHorizontal) {
        CGFloat velocyty = offset.x - self.lastOffset;
        if (velocyty <0) {
            TTCycleScanItem *item = self.allItems.firstObject;
            if ([self isItemVisible:item]) {
                [self rightScrollCheck];
            }
        }else {
            TTCycleScanItem *item = self.allItems.lastObject;
            if ([self isItemVisible:item]) {
            [self leftScrollCheck];
            }

        }
        self.lastOffset = scrollView.contentOffset.x;
        
        
    }else {
        
    }
}

- (void)leftScrollCheck {
    TTCycleScanItem *firstItem = self.allItems.firstObject;
    if (!firstItem) {
        return;
    }
    [self enQueenItem:firstItem];
    [self.allItems removeObject:firstItem];
    
    TTCycleScanItem *item = self.allItems.lastObject;
    CGFloat width = CGRectGetWidth(self.bounds);
    
    CGPoint offset = self.scrollView.contentOffset;
    
    if (offset.x > width * ttcyclescanercount* 3) {//如果大于3
        CGFloat off = offset.x - width * ttcyclescanercount* 3;
        self.lastOffset = width * ttcyclescanercount * 2;
        
        //这里移除所有的item 进queue 然后从 2 * ttcyclescanercount 开始
        for (TTCycleScanItem *item in self.allItems) {
            [self enQueenItem:item];
        }
        [self.allItems removeAllObjects];
        
        for (int i = -1; i <2; i ++) {
             NSInteger dataindex = item.dataIndex + i-1;
            TTCycleScanItem *rItem =[self.delegate cycleScaner:self itemForIndex:dataindex];
            if (!ritem) {
                return;
            }
            rItem.delegate = self;
            rItem.dataIndex = dataindex;
            rItem.bounds = self.bounds;
            rItem.center =  CGPointMake(width * ttcyclescanercount*2 + width /2 + width * i, item.center.y);
            [self.allItems addObject:rItem];
            if (!rItem.superview) {
                [self.scrollView addSubview:rItem];
            }
        }
        self.scrollView.contentOffset = CGPointMake(width * ttcyclescanercount * 2 + off, 0);
    }else {
        NSInteger dataindex = item.dataIndex + 1;
        TTCycleScanItem *nitem = [self.delegate cycleScaner:self itemForIndex:dataindex];
        if (!nitem) {
            return;
        }
        nitem.delegate = self;
        nitem.dataIndex = dataindex;
        [self.allItems addObject:nitem];
        if (!nitem.superview) {
            [self.scrollView addSubview:nitem];
        }
        nitem.bounds = item.bounds;
      
        CGPoint newCenter = CGPointMake(item.center.x + width, item.center.y);
        nitem.center = newCenter;
    }
}

- (void)rightScrollCheck {
    
    TTCycleScanItem *last = self.allItems.lastObject;
    if (!last) {
        return;
    }
    [self enQueenItem:last];
    [self.allItems removeObject:last];
    
    TTCycleScanItem *item = self.allItems.firstObject;
    CGFloat width = CGRectGetWidth(self.bounds);
    
    CGPoint offset = self.scrollView.contentOffset;
    
    if (offset.x < width * ttcyclescanercount){
        CGFloat off = offset.x - width * ttcyclescanercount;
        self.lastOffset = width * ttcyclescanercount * 2;
        //这里移除所有的item 进queue 然后从 2 * ttcyclescanercount 开始
        for (TTCycleScanItem *item in self.allItems) {
            [self enQueenItem:item];
        }
        [self.allItems removeAllObjects];
        
        for (int i = -1; i <2; i ++) {
            NSInteger dataindex = item.dataIndex + i  + 1;
            TTCycleScanItem *rItem =[self.delegate cycleScaner:self itemForIndex:dataindex];
            if (!ritem) {
                return;
            }
              rItem.delegate = self;
            rItem.dataIndex = dataindex;
            rItem.bounds = self.bounds;
            rItem.center =  CGPointMake(width * ttcyclescanercount*2 + width /2 + width * i, item.center.y);
            [self.allItems addObject:rItem];
            if (!rItem.superview) {
                [self.scrollView addSubview:rItem];
            }
        }
        self.scrollView.contentOffset = CGPointMake(width * ttcyclescanercount * 2 + off, 0);
    }else {
        NSInteger dataindex = item.dataIndex - 1;
        
        TTCycleScanItem *nitem = [self.delegate cycleScaner:self itemForIndex:dataindex];
        if (!nitem) {
            return;
        }
        nitem.delegate= self;
        nitem.dataIndex = dataindex;
        [self.allItems insertObject:nitem atIndex:0];
        
        if (!nitem.superview) {
            [self.scrollView addSubview:nitem];
        }
        nitem.bounds = item.bounds;
        
        CGPoint newCenter = CGPointMake(item.center.x - width, item.center.y);
        nitem.center = newCenter;
    }
}


#pragma mark - 自动播放

- (void)startAutoScroll {
    if (!self.scrollTimer) {
        self.pageControl.hidden = NO;
        self.scrollTimer = [NSTimer timerWithTimeInterval:self.scrllTimeSpace target:self selector:@selector(scrollToNext:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:self.scrollTimer forMode:NSDefaultRunLoopMode];
        [self.scrollTimer fire];
    }
//    if (!self.autoScrollTimer) {
//        self.pageControl.hidden = NO;
//        self.autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollToNext:)];
//        [self.autoScrollTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//    }
}

- (void)stopScroll {
    [self.scrollTimer invalidate];
    self.scrollTimer = nil;
}

- (void)scrollToNext:(id)sender {
    
//    if (self.isItemTouched) {
//        return;
//    }
    CGFloat width = CGRectGetWidth(self.bounds);
    CGPoint offset = self.scrollView.contentOffset;
    self.isAutoScrollAnimating = YES;
//    self.scrollView setContentOffset:<#(CGPoint)#> animated:<#(BOOL)#>
//
    [UIView animateWithDuration:self.scrllTimeSpace-0.1 delay:0 options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
         self.scrollView.contentOffset = CGPointMake(offset.x + width, 0);
    } completion:^(BOOL finished) {
        self.isAutoScrollAnimating = NO;
        [self pageScroolLeftCheck:self.scrollView];
//        [self scrollViewDidScroll:self.scrollView];
    }];
    
//     CGFloat width = CGRectGetWidth(self.bounds);
//    //考虑到被手拖动的情况
//
//    CGFloat currentOff = self.scrollView.contentOffset.x;
//    currentOff = fmod(currentOff, width);
//
//    //这里使用sin 函数
//
//    CGFloat relativeWith = width / TTSCANSIXTYSIN;
//    CGFloat angel = sin(self.timerGoing);
//    CGFloat off = angel * relativeWith;
//    self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x + off, 0);
//
//    self.timerGoing += _angelPerFrame;
//    if (self.timerGoing > M_PI) {//下一个循环
//        self.timerGoing = _angelPerFrame;
//        //这里对scroolview 进行对齐 防止出现小的误差
//    }
    
}

- (void)dealloc {

}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)enQueenItem:(TTCycleScanItem *)item {
    NSMutableArray *array = [self.reuseItemQueue objectForKey:item.identifire];
    if (!array) {
        array = [NSMutableArray array];
        [self.reuseItemQueue setObject:array forKey:item.identifire];
    }
    if (![array containsObject:item]) {
        [array addObject:item];
    }
    item.hidden = YES;
}


- (TTCycleScanItem *)deqeenItemForReuseIdentifire:(NSString *)identifire {
     NSMutableArray *array = [self.reuseItemQueue objectForKey:identifire];
    if (array.count > 0) {
        TTCycleScanItem *item = [array firstObject];
        [array removeObject:item];
        item.hidden = NO;
        return item;
    }
    return nil;
}

- (BOOL)isItemVisible:(TTCycleScanItem *)item {
    CGRect itemFrame = [item convertRect:item.bounds toView:self];
    CGRect myframe = self.bounds;
    BOOL isVisible = CGRectIntersectsRect(myframe, itemFrame);
    
    return isVisible;
}

#pragma mark 翻页

- (void)setPageEnable:(BOOL)pageEnable {
    _pageEnable = pageEnable;
    self.scrollView.pagingEnabled = pageEnable;
}

- (void)itemTouchBegin:(TTCycleScanItem *)item {
    self.isItemTouched = YES;
}

- (void)itemTouchEnd:(TTCycleScanItem *)item {
    self.isItemTouched = NO;
}

- (void)itemClicked:(TTCycleScanItem *)item {
    if ([self.delegate respondsToSelector:@selector(cycleScaner:didSelectItem:)]) {
        [self.delegate cycleScaner:self didSelectItem:item];
    }
}

@end
