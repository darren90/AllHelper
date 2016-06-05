//
//  TFMoviePlayerViewController.h
//  VideoPlayer
//
//  Created by Tengfei on 16/6/5.
//  Copyright © 2016年 tengfei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TFMoviePlayerViewController : UIViewController

@property (nonatomic,copy)NSString * vTitleStr;
/**
 *  播放地址本地已下载的文件，只针对mp4文件(没有后缀的文件名)
 */
@property (nonatomic,copy)NSString * playUrl;

@end
