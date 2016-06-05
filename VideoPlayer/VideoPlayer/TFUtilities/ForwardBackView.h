//
//  ForwardBackView.h
//  VideoPlayer
//
//  Created by Tengfei on 16/6/4.
//  Copyright © 2016年 tengfei. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,ForwardDirection) {
    ForwardUp = 0,
    ForwardBack = 1,
};

@interface ForwardBackView : UIView

@property (nonatomic,assign)ForwardDirection  direction;

@property (nonatomic,copy)NSString * time;

@end
