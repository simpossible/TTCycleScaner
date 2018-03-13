//
//  TTCycleScanItem.h
//  TT
//
//  Created by simp on 2017/11/25.
//  Copyright © 2017年 yiyou. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TTCycleScanItem;
@protocol TTCycleScanItemProtocol<NSObject>

- (void)itemClicked:(TTCycleScanItem *)item;

- (void)itemTouchBegin:(TTCycleScanItem *)item;

- (void)itemTouchEnd:(TTCycleScanItem *)item;

@end

@interface TTCycleScanItem : UIControl

@property (nonatomic, copy) NSString * url;

@property (nonatomic, assign) NSInteger page;

@property (nonatomic, assign) NSInteger dataIndex;

@property (nonatomic, copy, readonly) NSString * identifire;

@property (nonatomic, weak) id<TTCycleScanItemProtocol> delegate;

- (instancetype)init __unavailable;

- (instancetype)initWithReuseIdentifire:(NSString *)identifire;


@end
