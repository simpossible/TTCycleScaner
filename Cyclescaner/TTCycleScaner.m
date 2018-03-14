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

@property (nonatomic, assign) NSInteger currentPage;

/**纪录一个虚拟的偏移值-即使从头滑动这个偏移值也不重置*/
@property (nonatomic, assign) CGFloat allOffset;

/**这个决定速度 一秒是60帧 如果值为60 那就是1s 跑完一个宽度 如果为120 就是2s 跑完一个宽度*/
@property (nonatomic, assign) NSUInteger totoalPart;

@end

@implementation TTCycleScaner
- (instancetype)initWithDirection:(TTCycleScanerDirection)direction {
    if (self = [super init]) {
        self.reuseItemQueue = [NSMutableDictionary dictionary];
        self.allItems = [NSMutableArray array];
        [self initialUI];
        self.scrllTimeSpace = 1;
        self.currentPage = 0;
        self.allOffset = 0;
        _speed = 2;
        [self initialData];
    }
    return self;
}

- (void)initialData {
    self.totoalPart = 60 * _speed;
    self.angelPerFrame = M_PI/_totoalPart;
    _offCache = malloc(sizeof(typeof(float))*_totoalPart);//初始化60个
    CGFloat totoal = 0;
    for (int i = 0; i < _totoalPart; i ++) {
        CGFloat angel = sin(_angelPerFrame*i);
        totoal += angel;
    }
    
    CGFloat alredyLen = 0;
    for (int i = 0; i < _totoalPart; i ++) {
        CGFloat angel = sin(_angelPerFrame*i);
        CGFloat currentLen = angel / totoal;
        alredyLen += currentLen;
        _offCache[i]= alredyLen;
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
            
            NSInteger count = [self.delegate numberOfPageForCycleScaner:self];
            self.pageControl.numberOfPages = count;
            self.pageControl.currentPage = 0;
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



#pragma mark - 滑动

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGPoint offset = scrollView.contentOffset;
    if (self.scrollDirection == TTCycleScanerDirectionHorizontal) {
        CGFloat velocyty = offset.x - self.lastOffset;
        self.allOffset += velocyty;
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
    
    [self dealOffsetForPageControl];
}

- (void)leftScrollCheck {
    TTCycleScanItem *firstItem = self.allItems.firstObject;
    if (!firstItem) {
        return;
    }
    [self enQueenItem:firstItem];
    [self.allItems removeObject:firstItem];
    
    NSUInteger count = [self.delegate numberOfPageForCycleScaner:self];
    
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
        
        self.currentPage ++;
        self.currentPage = self.currentPage>=count?0:self.currentPage;
        self.pageControl.currentPage = self.currentPage;
        NSLog(@"________currentpage is %ld",self.currentPage);
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
        
        NSUInteger count = [self.delegate numberOfPageForCycleScaner:self];
        self.currentPage --;
        self.currentPage = self.currentPage<0?count-1:self.currentPage;
        self.pageControl.currentPage = self.currentPage;
    }
}


#pragma mark - 自动播放

- (void)startAutoScroll {
    if (!self.autoScrollTimer) {
        self.pageControl.hidden = NO;
        self.autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollToNext:)];
        [self.autoScrollTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
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
    NSLog(@"divipart is %f ",divitinPart);
    
    //判断当前的偏移值是否是正确的-连续的 如果连续那么 _lastRecordIndex 增加1 进入下一个偏移值的选取
    if ([self isfloat:lastOff issameTofloat:currentOff]) {
        _lastRecordIndex = ++_lastRecordIndex;
        if (_lastRecordIndex >= _totoalPart) {
            _lastRecordIndex = 0;
//            divitinPart += width;
        }
        newoff = _offCache[_lastRecordIndex] * width;
         NSLog(@"newoff is %f ",newoff);
    }else if ( [self isfloat:lastOff-width issameTofloat:currentOff]){//因为赋值给offset.x 会丢失精度 所以这里要对这种情况进行处理 如果在 _totoalPart -1 或者 _totoalPart -2 就已经是 一个宽度了 那就要从新计数了
        _lastRecordIndex = 0;
         newoff = _offCache[_lastRecordIndex] * width;
    }else {
        //如果不连续 则通过2分查找-找到当前最接近的那个偏移值 并更新 _lastRecordIndex 到这个接近的值
        CGFloat currentPer = currentOff/ width;
        //当前最接近的一个偏移值
        UInt16 currentCloseIndex = [self findF:currentPer atBegin:0 toEnd:_totoalPart];
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

#pragma mark 页码
- (void)dealOffsetForPageControl {
    CGFloat width = CGRectGetWidth(self.scrollView.bounds);
    NSUInteger count = [self.delegate numberOfPageForCycleScaner:self];
    NSInteger numberOffPage = self.allOffset / width;
     NSInteger i = (numberOffPage % count + count)%count;
    self.pageControl.currentPage = i;
}

- (void)dealloc {
    free(_offCache);
}

@end
