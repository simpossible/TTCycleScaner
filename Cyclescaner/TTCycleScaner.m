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

@property (nonatomic, assign) BOOL initialed;

@property (nonatomic, assign) CGFloat lastOffset;

@property (nonatomic, strong) CADisplayLink * autoScrollTimer;

/**每一帧增加的timergoing。- 这里使用sin函数进行*/
@property (nonatomic, assign) CGFloat angelPerFrame;

/**上一个偏移值所在的纪录*/
@property (nonatomic, assign) NSUInteger lastRecordIndex;

@property (nonatomic, assign) float * offCache;
@end

@implementation TTCycleScaner
- (instancetype)initWithDirection:(TTCycleScanerDirection)direction {
    if (self = [super init]) {
        self.reuseItemQueue = [NSMutableDictionary dictionary];
        self.allItems = [NSMutableArray array];
        [self initialUI];
        self.scrllTimeSpace = 1;
        self.angelPerFrame = M_PI/60;
        [self initialData];
    }
    return self;
}

- (void)initialData {
    _offCache = malloc(sizeof(typeof(float))*60);//初始化60个
    CGFloat totoal = 0;
    for (int i = 0; i < 60; i ++) {
        CGFloat angel = sin(_angelPerFrame*i);
        totoal += angel;
    }
    
    CGFloat alredyLen = 0;
    for (int i = 0; i < 60; i ++) {
        CGFloat angel = sin(_angelPerFrame*i);
        CGFloat currentLen = angel / totoal;
        alredyLen += currentLen;
        _offCache[i]= alredyLen;
        NSLog(@"the already len is %f",alredyLen);
    }
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
            if (!rItem) {
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
            if (!rItem) {
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
    if (!self.autoScrollTimer) {
        self.pageControl.hidden = NO;
        self.autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollToNext:)];
        [self.autoScrollTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopScroll {
    [self.autoScrollTimer invalidate];
    self.autoScrollTimer = nil;
}

- (void)scrollToNext:(id)sender {

    CGFloat width = CGRectGetWidth(self.bounds);

    //找到当前在整数倍之外偏移了多少
    CGFloat currentOff = self.scrollView.contentOffset.x;
    currentOff = fmodf(currentOff, width);
    
    //留下的整除部分
    CGFloat divitinPart = self.scrollView.contentOffset.x - currentOff;
    
    //计算出这一个如果没有手动拖动的情况下应该偏移多少，并计算出新的偏移值
    CGFloat lastOffPer = _offCache[_lastRecordIndex];
    CGFloat lastOff = lastOffPer * width;
    CGFloat newoff = 0;
    
    //判断当前的偏移值是否是正确的-连续的 如果连续那么 _lastRecordIndex 增加1 进入下一个偏移值的选取
    if ([self isfloat:lastOff issameTofloat:currentOff] || [self isfloat:lastOff-width issameTofloat:currentOff]) {
        _lastRecordIndex = ++_lastRecordIndex;
        if (_lastRecordIndex >= 60) {
            _lastRecordIndex = 0;
        }
        newoff = _offCache[_lastRecordIndex] * width;
    }else {
        //如果不连续 则通过2分查找-找到当前最接近的那个偏移值 并更新 _lastRecordIndex 到这个接近的值
        CGFloat currentPer = currentOff/ width;
        //当前最接近的一个偏移值
        UInt16 currentCloseIndex = [self findF:currentPer atBegin:0 toEnd:60];
        _lastRecordIndex = currentCloseIndex;
         newoff = _offCache[currentCloseIndex] * width;
    }

    self.scrollView.contentOffset = CGPointMake(divitinPart + newoff, 0);
    
}

//偏移量的最小为一个小数
- (BOOL)isfloat:(float)a issameTofloat:(float)b {

    CGFloat c = a - b;
    c = fabs(c);
    return c < 0.5;;
    
}

//2分查找
- (UInt16)findF:(CGFloat)f atBegin:(UInt16)start toEnd:(UInt16)end{
    
    if (start == end) {
        return start;
    }
    
    if (abs(start - end) == 1) {
        float startF = _offCache[start] - f;
        float endf = _offCache[end] - f;
        startF = fabsf(startF);
        endf = fabsf(endf);
        return  startF <endf?start:end;
    }
    
    int center = (start + end)/2;
    
    float centerValue = _offCache[center];
    if (centerValue == f) {
        return center;
    }
    
    if (centerValue >f) {
        return [self findF:f atBegin:start toEnd:center];
    }else {
        return [self findF:f atBegin:center toEnd:end];
    }
    
}


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

- (void)itemClicked:(TTCycleScanItem *)item {
    if ([self.delegate respondsToSelector:@selector(cycleScaner:didSelectItem:)]) {
        [self.delegate cycleScaner:self didSelectItem:item];
    }
}

- (void)dealloc {
    free(_offCache);
}

@end
