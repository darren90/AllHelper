//
//  ViewController.m
//  VideoPlayer
//
//  Created by Tengfei on 16/5/30.
//  Copyright © 2016年 tengfei. All rights reserved.
//

#import "ViewController.h"
#import "Vitamio.h"

#import "PlayerController.h"
#import "PlayerControllerDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>
#import "TFPlayerController.h"

@interface ViewController () <PlayerControllerDelegate>
@property (nonatomic, assign)          int          isPlay2;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    NSLog(@"NAL 1UIO &&&&&&& Vitamio version: %@", [Vitamio version]);

}
- (IBAction)play:(UIButton *)sender {
    self.isPlay2 = NO;
    [self pplayer];
}

- (IBAction)play2:(id)sender {
    self.isPlay2 = YES;
    [self pplayer];
}

-(void)pplayer
{
//    TFPlayerController2 *playerCtrl = [[TFPlayerController2 alloc] init];
    TFPlayerController *playerCtrl = [[TFPlayerController alloc] init];
//    playerCtrl.delegate = self;
//    [self presentModalViewController:playerCtrl animated:YES];
    playerCtrl.vTitleStr = @"大话西游 在终端中进入到你的项目的文件夹，也即是你要提交的项目";
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask , YES) firstObject];
    NSString *urlStr = [path stringByAppendingPathComponent:@"22.mp4"];
    playerCtrl.playUrl = @"22.mp4";
    [self presentViewController:playerCtrl animated:YES completion:nil];
}


#pragma mark - PlayerControllerDelegate

- (NSURL *)playCtrlGetCurrMediaTitle:(NSString **)title lastPlayPos:(long *)lastPlayPos
{
    NSString *uurl = @"http://ws.acgvideo.com/6/0e/3856792-1hd.mp4?wsTime=1464629496&wsSecret2=5ca5abea9949762d303179bbcfde8cd9&oi=2043096855&player=1&or=3078717850";
//    uurl = @"http://www.renren66.com/play/getty.php?id=8Ct8fA1H2lBZlfUdduMH5ly@h95wYSc";
    uurl = @"http://ws.acgvideo.com/2/6e/4128842-1.mp4?wsTime=1465031180&wsSecret2=7c01920b28074dfabd49aacaab0c8883&oi=2043096855&player=1&or=2061576138";
    
    NSURL *url ;
    
    if (self.isPlay2) {
        url = [NSURL URLWithString:uurl];
    }else{
        //    NSURL *url = [[NSBundle mainBundle] URLForResource:@"minion_06.mkv" withExtension:nil];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask , YES) firstObject];
        NSString *urlStr = [path stringByAppendingPathComponent:@"22.mp4"];
//        urlStr = [path stringByAppendingPathComponent:@"33.mov"];
//        urlStr = [path stringByAppendingPathComponent:@"11.rmvb"];
//        urlStr = [path stringByAppendingPathComponent:@"666.mkv"];
//        urlStr = [path stringByAppendingPathComponent:@"22.mp4"];
//         urlStr = [path stringByAppendingPathComponent:@"2018.mkv"];
        urlStr = [path stringByAppendingPathComponent:@"passenger_nginx.mov"];

        
        url = [NSURL fileURLWithPath:urlStr];
    }
    
#pragma mark - 获取视频文件的长度
    //    AVURLAsset *avUrl = [AVURLAsset assetWithURL:url];
    //    CMTime time = [avUrl duration];
    //    double seconds = ceil(time.value/time.timescale);
    //    NSLog(@"duration:%f,%lld,%d",seconds,time.value,time.timescale);
    
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
//    CMTime duration = playerItem.duration;
//    float seconds = CMTimeGetSeconds(duration);
//    NSLog(@"duration: %.2f", seconds);
    
    //    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:audioFileURL options:nil];
    //    CMTime audioDuration = audioAsset.duration;
    //    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    
    
//    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url
//                                                options:[NSDictionary dictionaryWithObjectsAndKeys:
//                                                         [NSNumber numberWithBool:YES],
//                                                         AVURLAssetPreferPreciseDurationAndTimingKey,
//                                                         nil]];
//    NSTimeInterval durationInSeconds = 0.0;
//    if (asset)
//        durationInSeconds = CMTimeGetSeconds(asset.duration) ;
//    NSLog(@"videoDuration: %.2f", durationInSeconds);
    
//    AVPlayer *avPlayer = [[AVPlayer alloc]initWithURL:url];
//    [avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time){
//        double seconds = ceil(time.value/time.timescale);
//        NSLog(@"duration:%f,%lld,%d",seconds,time.value,time.timescale);
//    }];

    
    AVAsset *movie = [AVAsset assetWithURL:url];
    CMTime time = movie.duration;
    double seconds = ceil(time.value/time.timescale);
    NSLog(@"duration:%f,%lld,%d",seconds,time.value,time.timescale);
    
    return url;
    
}

- (NSURL *)playCtrlGetNextMediaTitle:(NSString **)title lastPlayPos:(long *)lastPlayPos
{
//    int num = sizeof(sMediaURLs) / sizeof(sMediaURLs[0]);
//    sCurrPlayIdx = (sCurrPlayIdx + num + 1) % num;
//    NSString *v = sMediaURLs[sCurrPlayIdx];
    NSString *uurl = @"http://data.vod.itc.cn/?new=/159/153/BLTbszdeSESKAORdntDxeB.mp4&vid=2369390&plat=17&mkey=filtjNDkZUYXjVnIMpwWi0UdTyx5u_eO&ch=tv&uid=1464595069948338&SOHUSVP=lApD3A56a0CT_mWoMjobOn6Lf_Q57FGagSolxETsgIQ&pt=5&prod=h5&pg=1&eye=0&cv=1.0.0&qd=68000&src=11050001&ca=4&cateCode=101&_c=1&appid=tv&oth=&cd=";

    return [NSURL URLWithString:uurl];
}

- (NSURL *)playCtrlGetPrevMediaTitle:(NSString **)title lastPlayPos:(long *)lastPlayPos
{
//    int num = sizeof(sMediaURLs) / sizeof(sMediaURLs[0]);
//    sCurrPlayIdx = (sCurrPlayIdx + num - 1) % num;
//    NSString *v = sMediaURLs[sCurrPlayIdx];
    NSString *uurl = @"http://data.vod.itc.cn/?new=/159/153/BLTbszdeSESKAORdntDxeB.mp4&vid=2369390&plat=17&mkey=filtjNDkZUYXjVnIMpwWi0UdTyx5u_eO&ch=tv&uid=1464595069948338&SOHUSVP=lApD3A56a0CT_mWoMjobOn6Lf_Q57FGagSolxETsgIQ&pt=5&prod=h5&pg=1&eye=0&cv=1.0.0&qd=68000&src=11050001&ca=4&cateCode=101&_c=1&appid=tv&oth=&cd=";

    return [NSURL URLWithString:uurl];
}

@end
