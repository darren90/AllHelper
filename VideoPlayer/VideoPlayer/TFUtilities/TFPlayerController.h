//
//  PlayerController.h
//  Vitamio-Demo
//
//  Created by erlz nuo on 7/8/13.
//  Copyright (c) 2013 yixia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Vitamio.h"
#import "PlayerControllerDelegate.h"


#define kBackviewDefaultRect		CGRectMake(20, 47, 280, 180)
#define  KHeight    [UIScreen mainScreen].bounds.size.height
#define  KWidth     [UIScreen mainScreen].bounds.size.width

@interface TFPlayerController : UIViewController <VMediaPlayerDelegate>

@property (nonatomic, weak) id<PlayerControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isLockBtnEnable;//屏幕锁


@property (nonatomic,copy)NSString * vTitleStr;

/**
 *  播放地址本地已下载的文件，只针对mp4文件(没有后缀的文件名)
 */
@property (nonatomic,copy)NSString * playUrl;

@end
