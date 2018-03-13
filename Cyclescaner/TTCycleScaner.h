//
//  TTCycleScaner.h
//  TT
//
//  Created by simp on 2017/11/25.
//  Copyright © 2017年 yiyou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTCycleScanItem.h"

typedef NS_ENUM(NSUInteger,TTCycleScanerDirection) {
    TTCycleScanerDirectionHorizontal,
    TTCycleScanerDirectionVerticle,
};

@class TTCycleScanItem;
@class TTCycleScaner;

@protocol TTCycleScanerProtocol <NSObject>

- (TTCycleScanItem *)cycleScaner:(TTCycleScaner *)scaner itemForIndex:(NSInteger)index;

- (void)cycleScaner:(TTCycleScaner *)scaner didSelectItem:(TTCycleScanItem *)item;

@end



@interface TTCycleScaner : UIView

- (instancetype)initWithDirection:(TTCycleScanerDirection)direction;

/**滚动的时间间隔*/
@property (nonatomic, assign) CGFloat scrllTimeSpace;

@property (nonatomic, weak) id<TTCycleScanerProtocol> delegate;

/**滚动方向*/
@property (nonatomic, assign) TTCycleScanerDirection  scrollDirection;

/**是否可以手动滑动*/
@property (nonatomic, assign) BOOL canScrollManual;

/**是否支持翻页*/
@property (nonatomic, assign) BOOL pageEnable;

/**
 开始自动轮播-需要调用stopToScroll 保证释放
 */
- (void)startAutoScroll;

/**停止释放*/
- (void)stopScroll;

- (TTCycleScanItem *)deqeenItemForReuseIdentifire:(NSString *)identifire;
@end
