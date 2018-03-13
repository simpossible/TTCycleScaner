//
//  TTCycleScanItem.m
//  TT
//
//  Created by simp on 2017/11/25.
//  Copyright © 2017年 yiyou. All rights reserved.
//

#import "TTCycleScanItem.h"
#import <Masonry.h>
#import <UIImageView+WebCache.h>

@interface TTCycleScanItem ()

/**加载中*/
@property (nonatomic, strong) UIActivityIndicatorView * indicator;
@property (nonatomic, strong) UIImageView * imageView;

@property (nonatomic, assign) BOOL complete;

@property (nonatomic, copy) NSString * identifire;
@end

@implementation TTCycleScanItem

- (instancetype)initWithReuseIdentifire:(NSString *)identifire {
    if (self = [super init]) {
        [self initialUI];
        self.identifire = identifire;
        self.backgroundColor = [UIColor blueColor];
        [self initialEvent];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialUI];
        self.complete = NO;
    }
    return self;
}

- (void)initialUI {
    self.imageView = [[UIImageView alloc] init];
    [self addSubview:self.imageView];
    
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self initialIndicatorView];
}

- (void)initialEvent {
    [self addTarget:self action:@selector(clicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)clicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(itemClicked:)]) {
        [self.delegate itemClicked:self];
    }
}

- (void)initialIndicatorView {
//    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    [self addSubview:self.indicator];
//    [self.indicator mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerX.equalTo(self.mas_centerX);
//        make.centerY.equalTo(self.mas_centerY);
////        make.width.mas_equalTo(50);
////        make.height.mas_equalTo(50);
//    }];
//    [self.indicator startAnimating];
    
}
- (void)setUrl:(NSString *)url {
    _url = url;
    __weak typeof(self)wself = self;;
//    if (!self.complete) {
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:url]];
        
//        wself.complete = YES;
//    }

}

- (NSString *)description {
    return [NSString stringWithFormat:@"%ld--",self.dataIndex];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(itemTouchBegin:)]) {
        [self.delegate itemTouchBegin:self];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(itemTouchEnd:)]) {
        [self.delegate itemTouchEnd:self];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if ([self.delegate respondsToSelector:@selector(itemTouchEnd:)]) {
        [self.delegate itemTouchEnd:self];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
