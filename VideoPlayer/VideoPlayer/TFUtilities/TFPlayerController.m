//
//  PlayerController.m
//  Vitamio-Demo
//
//  Created by erlz nuo(nuoerlz@gmail.com) on 7/8/13.
//  Copyright (c) 2013 yixia. All rights reserved.
//

#import "TFPlayerController.h"
//#import "Utilities.h"
//#import "VSegmentSlider.h"
#import "TFUtilities.h"
#import "TFVSegmentSlider.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ForwardBackView.h"
#import "UIAlertView+Blocks.h"
#define KTFPlayer_Btn_Play [UIImage imageNamed:@"VKVideoPlayer_play.png"]
#define KTFPlayer_Btn_pause [UIImage imageNamed:@"VKVideoPlayer_pause.png"]


//是否是iOS8
#define IsIOS8 ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0)

typedef NS_ENUM(NSInteger,SwipeStyle) {
    PlayerSwipeUnKnown = -1,
    PlayerSwipePlaySpeed =  0,
    PlayerSwipePlayVoice =  1,
    PlayerSwipePlayLight =  2,
};

@interface TFPlayerController ()
{
    VMediaPlayer       *mMPayer;
    long               mDuration;
    long               mCurPostion;
    NSTimer            *mSyncSeekTimer;
    
    BOOL isEndFast;//快进结束
    NSNumber * fastNum;
}
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *singleGesture;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *doubleGesture;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;

/** 播放暂定按钮 */
@property (nonatomic, weak) IBOutlet UIButton *startPause;
@property (nonatomic, weak) IBOutlet UIButton *prevBtn;
@property (nonatomic, weak) IBOutlet UIButton *nextBtn;
@property (nonatomic, weak) IBOutlet UIButton *modeBtn;
@property (nonatomic, weak) IBOutlet UIButton *reset;
@property (nonatomic, weak) IBOutlet TFVSegmentSlider *progressSld;
@property (nonatomic, weak) IBOutlet UILabel  *curPosLbl;
@property (nonatomic, weak) IBOutlet UILabel  *durationLbl;
@property (nonatomic, weak) IBOutlet UILabel  *bubbleMsgLbl;
@property (nonatomic, weak) IBOutlet UILabel  *downloadRate;
@property (nonatomic, weak) IBOutlet UIView  	*activityCarrier;
@property (nonatomic, weak) IBOutlet UIView  	*backView;
@property (nonatomic, weak) IBOutlet UIView  	*carrier;

@property (nonatomic, copy)   NSURL *videoURL;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@property (nonatomic, assign) BOOL progressDragging;

@property (weak, nonatomic) IBOutlet UIView *topControl;
@property (weak, nonatomic) IBOutlet UIView *bottomControl;
@property (weak, nonatomic) IBOutlet UIButton *trackBtn;

-(IBAction)goBackButtonAction:(id)sender;

#pragma mark - 切换音轨
- (IBAction)changeTrack:(UIButton *)sender;

#pragma mark - 开始 暂停
-(IBAction)startPauseButtonAction:(id)sender;

-(IBAction)prevButtonAction:(id)sender;

-(IBAction)nextButtonAction:(id)sender;

#pragma mark - 切换Model
-(IBAction)switchVideoViewModeButtonAction:(id)sender;
#pragma mark - reset
-(IBAction)resetButtonAction:(id)sender;

#pragma mark - 进度条相关
-(IBAction)progressSliderDownAction:(id)sender;
-(IBAction)progressSliderUpAction:(id)sender;
-(IBAction)dragProgressSliderAction:(id)sender;

#pragma mark - 单击手势
- (IBAction)handleSingleTap:(id)sender;

- (IBAction)handleTwoTap:(id)sender;
- (IBAction)lockButtonClick:(UIButton *)sender;

/**NSTimer对象 */
@property (nonatomic,strong)NSTimer * timer;


#pragma mark - 自定义播放器需要的一些参数
/** 时间栏是否隐藏 */
@property (nonatomic,assign)BOOL isStatusBarHidden;

@property (nonatomic, assign) CGPoint curTickleStart;

@property (nonatomic,assign)SwipeStyle swipeType;

//*快进view*/
@property (nonatomic,weak)ForwardBackView * forwardView;

//音轨的数组
@property (nonatomic,strong)NSMutableArray * trackArray;



//

@property (nonatomic,strong)NSURL *PrevMediaUrl;
@end


@implementation TFPlayerController


#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    

	self.view.bounds = [[UIScreen mainScreen] bounds];
	self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
						  UIActivityIndicatorViewStyleWhiteLarge];
	[self.activityCarrier addSubview:self.activityView];

	UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc]
								   initWithTarget:self 
								   action:@selector(progressSliderTapped:)];
    [self.progressSld addGestureRecognizer:gr];
    //当前点点的位置
    [self.progressSld setThumbImage:[UIImage imageNamed:@"pb-seek-bar-btn@2x.png"] forState:UIControlStateNormal];
    //已播放的条的颜色
    [self.progressSld setMinimumTrackImage:[UIImage imageNamed:@"pb-seek-bar-fr@2x.png"] forState:UIControlStateNormal];
    //未播放的条的颜色
    [self.progressSld setMaximumTrackImage:[UIImage imageNamed:@"pb-seek-bar-bg@2x.png"] forState:UIControlStateNormal];
 
    //这句话的意思时，只有当doubleTapGesture识别失败的时候(即识别出这不是双击操作)，singleTapGesture才能开始识别，同我们一开始讲的是同一个问题。
    [self.singleGesture requireGestureRecognizerToFail:self.doubleGesture];
    
    [self initialize];


	if (!mMPayer) {
		mMPayer = [VMediaPlayer sharedInstance];
		[mMPayer setupPlayerWithCarrierView:self.carrier withDelegate:self];
		[self setupObservers];
	}
    
    [self addTimer];
    self.PrevMediaUrl = [NSURL URLWithString:@""];
}
-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(BOOL)prefersStatusBarHidden
{
    return self.isStatusBarHidden;
}

-(void)initialize
{
    [self.progressSld addObserver:self forKeyPath:@"maximumValue" options:0 context:nil];
    
    //2－快进
//    [self.view addSubview:self.forwardView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.titleLabel.text = self.vTitleStr;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
//	[[UIApplication sharedApplication] setStatusBarHidden:YES];
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	[self becomeFirstResponder];

	[self currButtonAction:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
//	[[UIApplication sharedApplication] setStatusBarHidden:NO];
	[[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)to duration:(NSTimeInterval)duration
{
	if (UIInterfaceOrientationIsLandscape(to)) {
		self.backView.frame = self.view.bounds;
	} else {
        self.backView.frame = self.view.bounds;//kBackviewDefaultRect;
	}
	NSLog(@"NAL 1HUI &&&&&&&&& frame=%@", NSStringFromCGRect(self.carrier.frame));
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	NSLog(@"NAL 2HUI &&&&&&&&& frame=%@", NSStringFromCGRect(self.carrier.frame));
}


#pragma mark - Respond to the Remote Control Events

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	switch (event.subtype) {
		case UIEventSubtypeRemoteControlTogglePlayPause:
			if ([mMPayer isPlaying]) {
				[mMPayer pause];
			} else {
				[mMPayer start];
			}
			break;
		case UIEventSubtypeRemoteControlPlay:
			[mMPayer start];
			break;
		case UIEventSubtypeRemoteControlPause:
			[mMPayer pause];
			break;
		case UIEventSubtypeRemoteControlPreviousTrack:
			[self prevButtonAction:nil];
			break;
		case UIEventSubtypeRemoteControlNextTrack:
			[self nextButtonAction:nil];
			break;
		default:
			break;
	}
}

- (void)applicationDidEnterForeground:(NSNotification *)notification
{
	[mMPayer setVideoShown:YES];
    if (![mMPayer isPlaying]) {
		[mMPayer start];
//		[self.startPause setTitle:@"Pause" forState:UIControlStateNormal];
        [self.startPause setImage:KTFPlayer_Btn_pause forState:UIControlStateNormal];
	}
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    if ([mMPayer isPlaying]) {
		[mMPayer pause];
		[mMPayer setVideoShown:NO];
    }
}


#pragma mark - VMediaPlayerDelegate Implement

#pragma mark VMediaPlayerDelegate Implement / Required

- (void)mediaPlayer:(VMediaPlayer *)player didPrepared:(id)arg
{
//	[player setVideoFillMode:VMVideoFillMode100];
    [player setVideoFillMode:VMVideoFillModeFit];//可以撑满屏幕 VMVideoFillModeCrop

	mDuration = [player getDuration];
    NSLog(@"------- mDuration：%ld",mDuration);
    [player start];

	[self setBtnEnableStatus:YES];
	[self stopActivity];
    mSyncSeekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/3
                                                      target:self
                                                    selector:@selector(syncUIStatus)
                                                    userInfo:nil
                                                     repeats:YES];
    
    NSArray * arr = [mMPayer getAudioTracksArray];
    self.trackBtn.hidden = YES;
    if (arr.count <= 1) return;
    
    self.trackBtn.hidden = NO;
    self.trackArray = [NSMutableArray array];
//    {
//        VMMediaTrackId = 1;
//        VMMediaTrackLocationType = 0;
//        VMMediaTrackTitle = "1. und. SoundHandler";
//    }
    for (NSDictionary *dic in arr) {
        [self.trackArray addObject:dic[@"VMMediaTrackTitle"]];
    }
//    [mMPayer setAudioTrackWithArrayIndex:1];
//    int index  = [mMPayer getAudioTrackCurrentArrayIndex];
//    NSLog(@"index:%d-:%lu-%@",index,(unsigned long)arr.count,arr);
    //    NSLog(@"VMMediaTrackTitle:%@,",arr[1][@"VMMediaTrackTitle"]);
}

- (void)mediaPlayer:(VMediaPlayer *)player playbackComplete:(id)arg
{
	[self goBackButtonAction:nil];
}

- (void)mediaPlayer:(VMediaPlayer *)player error:(id)arg
{
	NSLog(@"NAL 1RRE &&&& VMediaPlayer Error: %@", arg);
	[self stopActivity];
//	[self showVideoLoadingError];
	[self setBtnEnableStatus:YES];
}

#pragma mark VMediaPlayerDelegate Implement / Optional

- (void)mediaPlayer:(VMediaPlayer *)player setupManagerPreference:(id)arg
{
	player.decodingSchemeHint = VMDecodingSchemeSoftware;
	player.autoSwitchDecodingScheme = NO;
}

- (void)mediaPlayer:(VMediaPlayer *)player setupPlayerPreference:(id)arg
{
	// Set buffer size, default is 1024KB(1*1024*1024).
//	[player setBufferSize:256*1024];
	[player setBufferSize:512*1024];
//	[player setAdaptiveStream:YES];

	[player setVideoQuality:VMVideoQualityHigh];

	player.useCache = YES;
	[player setCacheDirectory:[self getCacheRootDirectory]];
}

- (void)mediaPlayer:(VMediaPlayer *)player seekComplete:(id)arg
{
}

- (void)mediaPlayer:(VMediaPlayer *)player notSeekable:(id)arg
{
	self.progressDragging = NO;
	NSLog(@"NAL 1HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingStart:(id)arg
{
	self.progressDragging = YES;
	NSLog(@"NAL 2HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
	if (![TFUtilities isLocalMedia:self.videoURL]) {
		[player pause];
//		[self.startPause setTitle:@"Start" forState:UIControlStateNormal];
        [self.startPause setImage:KTFPlayer_Btn_Play forState:UIControlStateNormal];
		[self startActivityWithMsg:@"Buffering... 0%"];
	}
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingUpdate:(id)arg
{
	if (!self.bubbleMsgLbl.hidden) {
		self.bubbleMsgLbl.text = [NSString stringWithFormat:@"Buffering... %d%%",
								  [((NSNumber *)arg) intValue]];
	}
}

- (void)mediaPlayer:(VMediaPlayer *)player bufferingEnd:(id)arg
{
	if (![TFUtilities isLocalMedia:self.videoURL]) {
		[player start];
//		[self.startPause setTitle:@"Pause" forState:UIControlStateNormal];
        [self.startPause setImage:KTFPlayer_Btn_pause forState:UIControlStateNormal];
		[self stopActivity];
	}
	self.progressDragging = NO;
	NSLog(@"NAL 3HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
}

- (void)mediaPlayer:(VMediaPlayer *)player downloadRate:(id)arg
{
	if (![TFUtilities isLocalMedia:self.videoURL]) {
		self.downloadRate.text = [NSString stringWithFormat:@"%dKB/s", [arg intValue]];
	} else {
		self.downloadRate.text = nil;
	}
}

- (void)mediaPlayer:(VMediaPlayer *)player videoTrackLagging:(id)arg
{
//	NSLog(@"NAL 1BGR video lagging....");
}

#pragma mark VMediaPlayerDelegate Implement / Cache

- (void)mediaPlayer:(VMediaPlayer *)player cacheNotAvailable:(id)arg
{
	NSLog(@"NAL .... media can't cache.");
	self.progressSld.segments = nil;
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheStart:(id)arg
{
	NSLog(@"NAL 1GFC .... media caches index : %@", arg);
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheUpdate:(id)arg
{
	NSArray *segs = (NSArray *)arg;
//	NSLog(@"NAL .... media cacheUpdate, %d, %@", segs.count, segs);
	if (mDuration > 0) {
		NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
		for (int i = 0; i < segs.count; i++) {
			float val = (float)[segs[i] longLongValue] / mDuration;
			[arr addObject:[NSNumber numberWithFloat:val]];
		}
		self.progressSld.segments = arr;
	}
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheSpeed:(id)arg
{
//	NSLog(@"NAL .... media cacheSpeed: %dKB/s", [(NSNumber *)arg intValue]);
}

- (void)mediaPlayer:(VMediaPlayer *)player cacheComplete:(id)arg
{
	NSLog(@"NAL .... media cacheComplete");
	self.progressSld.segments = @[@(0.0), @(1.0)];
}


#pragma mark - Convention Methods

#define TEST_Common					1
#define TEST_setOptionsWithKeys		0
#define TEST_setDataSegmentsSource	0

-(void)quicklyPlayMovie:(NSURL*)fileURL title:(NSString*)title seekToPos:(long)pos
{
	[UIApplication sharedApplication].idleTimerDisabled = YES;
//	[self setBtnEnableStatus:NO];

	NSString *docDir = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
	NSLog(@"NAL &&& Doc: %@", docDir);


//	fileURL = [NSURL URLWithString:@"http://v.17173.com/api/5981245-4.m3u8"];



#if TEST_Common // Test Common
	NSString *abs = [fileURL absoluteString];
	if ([abs rangeOfString:@"://"].length == 0) {
		NSString *docDir = [NSString stringWithFormat:@"%@/Documents", NSHomeDirectory()];
		NSString *videoUrl = [NSString stringWithFormat:@"%@/%@", docDir, abs];
		self.videoURL = [NSURL fileURLWithPath:videoUrl];
	} else {
		self.videoURL = fileURL;
	}
//    [mMPayer setDataSource:self.videoURL header:nil];
    [mMPayer setDataSource:self.videoURL];
#elif TEST_setOptionsWithKeys // Test setOptionsWithKeys:withValues:
	self.videoURL = [NSURL URLWithString:@"rtmp://videodownls.9xiu.com/9xiu/552"]; // This is a live stream.
	NSMutableArray *keys = [NSMutableArray arrayWithCapacity:0];
	NSMutableArray *vals = [NSMutableArray arrayWithCapacity:0];
	keys[0] = @"-rtmp_live";
	vals[0] = @"-1";
    [mMPayer setDataSource:self.videoURL header:nil];
	[mMPayer setOptionsWithKeys:keys withValues:vals];
#elif TEST_setDataSegmentsSource // Test setDataSegmentsSource:fileList:
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:0];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.1.mp4?vkey=E3D97333E93EDF36E56CB85CE0B02018E1001BA5C023DFFD298C0204CD81610CFCE546C79DE6C3E2"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.2.mp4?vkey=5E82F44940C19CCF26610E7E4088438E868AB2CAB5255E5FDE6763484B9B7E967EF9A97D7E54A324"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.3.mp4?vkey=0A1EA30BCB057BAE8746C2D7B07FE4ABF3BD839FF011224F31F7544BFFB647F06A6D5245C57277BC"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.4.mp4?vkey=DF36DC29AD2C2F0BA5A688223AFCD0008BDD681D8B060C9F4739E1A365495CD165E28DFD80E8E41C"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.5.mp4?vkey=76172D18B89A91CDB803889B4C5127741EF4BBD9B90CC54269B89CEEF558B9B286DDE6083ADB8195"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.6.mp4?vkey=27718B68A396DCFBC483321827604179D35F31C41EC57908C0F78D9416690F6986B0766872C2AF60"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.7.mp4?vkey=B56628DD31A60E975CC9EE321DCE2FC9554AF2CE5BC2BFCEFCEEA633F27CDF16CADA9915338AB2E5"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.8.mp4?vkey=40F45871CE7827699FACE57A95CA1FDA58B16A8A2523C738C422ADCBF015F50254C356614EFAFDE0"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.9.mp4?vkey=553157FD5A7607CC1E255D0E26B503FAD842DC509F15D766C31446E8607E60A621F7B9FABC5B8C7D"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.10.mp4?vkey=2968D15E93D1C1A295FC810DA561789487330F8BEA5B408533BF396648400A89924611724FD5BE67"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.11.mp4?vkey=495CDFCAD30945947CE1E43CBD88DE32E505B4D02BD4AAB2F4B17F98EFF702485C270558951A3109"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.12.mp4?vkey=01B5580A0A6F3597D66440C060885AFC7AA03CD7272D36472FBC9C261D72D2E964D254775C574CA3"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.13.mp4?vkey=2256FFE5FABC971F6A0D6889A1EA1CE8E837D17929708C6ACC6F903939076BB926442DBF6F3AD309"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.14.mp4?vkey=77BB2C40B9383BF048206EC357FE5F061A0A16B9242CAD207CBEA3C3C53E50B24056D93E578A400F"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.15.mp4?vkey=1366F026BB6B987C82C58CF707269C091EA086BB1A09430611A6E124A419E04774FE793E11EB64C1"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.16.mp4?vkey=E0F358E64365C5B12614EA74B25C4F87C7E8CD4003DCB2C792850180CF3CD7645BB22E5E57B40CC5"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.17.mp4?vkey=E95EC62FAE0D92BE8A2FE85842B875F2E9B9B07616B8892D1EF18A0C645994E885D65BDAC24EF0FD"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.18.mp4?vkey=48B021C886CFC23E22FA56C71C7C204E300E7D58CBB97867F23CC8F30EB4D1B53ABE41627F7D6610"];
	[list addObject:@"http://112.65.235.140/vlive.qqvideo.tc.qq.com/95V8NuxWX2J.p202.19.mp4?vkey=0D51F428BB12C2C5C015E41997371FC80338924F804D9D688C7B9560C7336A48870873F34189C58D"];
    [mMPayer setDataSegmentsSource:nil fileList:list];
#endif

    [mMPayer prepareAsync];
	[self startActivityWithMsg:@"Loading..."];
}

-(void)quicklyReplayMovie:(NSURL*)fileURL title:(NSString*)title seekToPos:(long)pos
{
    [self quicklyStopMovie];
    [self quicklyPlayMovie:fileURL title:title seekToPos:pos];
}

-(void)quicklyStopMovie
{
	[mMPayer reset];
	[mSyncSeekTimer invalidate];
	mSyncSeekTimer = nil;
	self.progressSld.value = 0.0;
	self.progressSld.segments = nil;
	self.curPosLbl.text = @"00:00:00";
	self.durationLbl.text = @"00:00:00";
	self.downloadRate.text = nil;
	mDuration = 0;
	mCurPostion = 0;
	[self stopActivity];
	[self setBtnEnableStatus:YES];
	[UIApplication sharedApplication].idleTimerDisabled = NO;
}


#pragma mark - UI Actions

#define DELEGATE_IS_READY(x) (self.delegate && [self.delegate respondsToSelector:@selector(x)])

-(IBAction)goBackButtonAction:(id)sender
{
	[self quicklyStopMovie];
    
    [self unSetupObservers];
    [mMPayer unSetupPlayer];
    
//	[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 切换音轨
- (IBAction)changeTrack:(UIButton *)sender {
//    [mMPayer setAudioTrackWithArrayIndex:1];
//    int index  = [mMPayer getAudioTrackCurrentArrayIndex];
 
    UIAlertView *alertView = [UIAlertView
                              showWithTitle:@"Audio Trackers Picker"
                              message:nil
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:self.trackArray
                              tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                  NSInteger firstOBIndex = [alertView firstOtherButtonIndex];
                                  NSInteger lastOBIndex = firstOBIndex + [self.trackArray count];
                                  if (buttonIndex >= firstOBIndex && buttonIndex < lastOBIndex) {
                                      [mMPayer setAudioTrackWithArrayIndex:(int)(buttonIndex - firstOBIndex)];
                                  }
                              }];
    [alertView show];
}

-(IBAction)startPauseButtonAction:(id)sender
{
    NSLog(@"--pasuse-start-startPauseButtonAction--slide-value:%f,seek = %ld,t:%@",self.progressSld.value,(long)(self.progressSld.value * mDuration),[TFUtilities timeToHumanString:(long)(self.progressSld.value * mDuration)]);

	BOOL isPlaying = [mMPayer isPlaying];
	if (isPlaying) {
		[mMPayer pause];
//		[self.startPause setTitle:@"Start" forState:UIControlStateNormal];
        [self.startPause setImage:KTFPlayer_Btn_Play forState:UIControlStateNormal];
	} else {
		[mMPayer start];
//		[self.startPause setTitle:@"Pause" forState:UIControlStateNormal];
        [self.startPause setImage:KTFPlayer_Btn_pause forState:UIControlStateNormal];
	}
}

-(void)startPlay
{
    [mMPayer start];
    [self.startPause setImage:KTFPlayer_Btn_pause forState:UIControlStateNormal];
}

-(void)currButtonAction:(id)sender
{
	NSURL *url = nil;
	NSString *title = nil;
	long lastPos = 0;
 
    url = [NSURL URLWithString:self.playUrl];
    if (self.PrevMediaUrl) {
//	if (DELEGATE_IS_READY(playCtrlGetPrevMediaTitle:lastPlayPos:)) {
//		url = [self.delegate playCtrlGetCurrMediaTitle:&title lastPlayPos:&lastPos];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask , YES) firstObject];
        NSString *urlStr = [path stringByAppendingPathComponent:self.playUrl];
        url = [NSURL fileURLWithPath:urlStr];
	}
	if (url) {
		[self quicklyPlayMovie:url title:title seekToPos:lastPos];
	} else {
		NSLog(@"WARN: No previous media url found!");
	}
}

-(IBAction)prevButtonAction:(id)sender
{
	NSURL *url = nil;
	NSString *title = nil;
	long lastPos = 0;
    if (self.PrevMediaUrl) {
//	if (DELEGATE_IS_READY(playCtrlGetPrevMediaTitle:lastPlayPos:)) {
        url = self.PrevMediaUrl;//[self.delegate playCtrlGetPrevMediaTitle:&title lastPlayPos:&lastPos];
    }
	if (url) {
		[self quicklyReplayMovie:url title:title seekToPos:lastPos];
	} else {
		NSLog(@"WARN: No previous media url found!");
	}
}

-(IBAction)nextButtonAction:(id)sender
{
	NSURL *url = nil;
	NSString *title = nil;
	long lastPos = 0;
    if (self.PrevMediaUrl) {
//	if (DELEGATE_IS_READY(playCtrlGetPrevMediaTitle:lastPlayPos:)) {
		url = [self.delegate playCtrlGetNextMediaTitle:&title lastPlayPos:&lastPos];
	}
	if (url) {
		[self quicklyReplayMovie:url title:title seekToPos:lastPos];
	} else {
		NSLog(@"WARN: No previous media url found!");
	}
}

#pragma mark - 切换播放Model
-(IBAction)switchVideoViewModeButtonAction:(id)sender
{
	static emVMVideoFillMode modes[] = {
		VMVideoFillModeFit,
		VMVideoFillMode100,
		VMVideoFillModeCrop,
		VMVideoFillModeStretch,
	};
	static int curModeIdx = 0;

	curModeIdx = (curModeIdx + 1) % (int)(sizeof(modes)/sizeof(modes[0]));
	[mMPayer setVideoFillMode:modes[curModeIdx]];
}

#pragma mark - reset
-(IBAction)resetButtonAction:(id)sender
{
	static int bigView = 0;

	[UIView animateWithDuration:0.3 animations:^{
		if (bigView) {
			self.backView.frame = kBackviewDefaultRect;
			bigView = 0;
		} else {
			self.backView.frame = self.view.bounds;
			bigView = 1;
		}
		NSLog(@"NAL 1NBV &&&& backview.frame=%@", NSStringFromCGRect(self.backView.frame));
	}];


//	[self quicklyStopMovie];
}

#pragma mark - 进度条相关

-(IBAction)progressSliderDownAction:(id)sender
{
	self.progressDragging = YES;
//	NSLog(@"NAL 4HBT &&&&&&&&&&&&&&&&.......&&&&&&&&&&&&&&&&&");
//	NSLog(@"NAL 1DOW &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& Touch Down");
}

-(IBAction)progressSliderUpAction:(id)sender
{
	UISlider *sld = (UISlider *)sender;
//	NSLog(@"NAL 1BVC &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& seek = %ld", (long)(sld.value * mDuration));
    NSLog(@"-progressSliderUpAction--slide-value:%f,seek = %ld,t:%@",sld.value,(long)(sld.value * mDuration),[TFUtilities timeToHumanString:(long)(sld.value * mDuration)]);
	[self startActivityWithMsg:@"Buffering"];
	[mMPayer seekTo:(long)(sld.value * mDuration)];
}

-(IBAction)dragProgressSliderAction:(id)sender
{
	UISlider *sld = (UISlider *)sender;
    NSLog(@"-dragProgressSliderAction--slide-value:%f",sld.value);
	self.curPosLbl.text = [TFUtilities timeToHumanString:(long)(sld.value * mDuration)];
}

-(void)progressSliderTapped:(UIGestureRecognizer *)g
{
    UISlider* s = (UISlider*)g.view;
    if (s.highlighted)
        return;
    CGPoint pt = [g locationInView:s];
    CGFloat percentage = pt.x / s.bounds.size.width;
    CGFloat delta = percentage * (s.maximumValue - s.minimumValue);
    CGFloat value = s.minimumValue + delta;
    [s setValue:value animated:YES];
    long seek = percentage * mDuration;
	self.curPosLbl.text = [TFUtilities timeToHumanString:seek];
	NSLog(@"NAL 2BVC &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& seek = %ld", seek);
	[self startActivityWithMsg:@"Buffering"];
    [mMPayer seekTo:seek];
}


#pragma mark - Sync UI Status

-(void)syncUIStatus
{
	if (!self.progressDragging) {
		mCurPostion  = [mMPayer getCurrentPosition];
		[self.progressSld setValue:(float)mCurPostion/mDuration];
		self.curPosLbl.text = [TFUtilities timeToHumanString:mCurPostion];
//        NSLog(@"---syncUIStatus---:%@",[TFUtilities timeToHumanString:mCurPostion]);
		self.durationLbl.text = [TFUtilities timeToHumanString:mDuration];
	}
}


#pragma mark Others

-(void)startActivityWithMsg:(NSString *)msg
{
	self.bubbleMsgLbl.hidden = NO;
	self.bubbleMsgLbl.text = msg;
	[self.activityView startAnimating];
}

-(void)stopActivity
{
	self.bubbleMsgLbl.hidden = YES;
	self.bubbleMsgLbl.text = nil;
	[self.activityView stopAnimating];
}

-(void)setBtnEnableStatus:(BOOL)enable
{
	self.startPause.enabled = enable;
	self.prevBtn.enabled = enable;
	self.nextBtn.enabled = enable;
	self.modeBtn.enabled = enable;
}

- (void)setupObservers
{
	NSNotificationCenter *def = [NSNotificationCenter defaultCenter];
    [def addObserver:self
			selector:@selector(applicationDidEnterForeground:)
				name:UIApplicationDidBecomeActiveNotification
			  object:[UIApplication sharedApplication]];
    [def addObserver:self
			selector:@selector(applicationDidEnterBackground:)
				name:UIApplicationWillResignActiveNotification
			  object:[UIApplication sharedApplication]];
}

- (void)unSetupObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)showVideoLoadingError
{
	NSString *sError = NSLocalizedString(@"Video cannot be played", @"description");
	NSString *sReason = NSLocalizedString(@"Video cannot be loaded.", @"reason");
	NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   sError, NSLocalizedDescriptionKey,
							   sReason, NSLocalizedFailureReasonErrorKey,
							   nil];
	NSError *error = [NSError errorWithDomain:@"Vitamio" code:0 userInfo:errorDict];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}

- (NSString *)getCacheRootDirectory
{
	NSString *cache = [NSString stringWithFormat:@"%@/Library/Caches/MediasCaches", NSHomeDirectory()];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cache]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache
								  withIntermediateDirectories:YES
												   attributes:nil
														error:NULL];
    }
	return cache;
}

//static 
#pragma mark - 处理手势 - 单击 : 隐藏子控件
- (IBAction)handleSingleTap:(id)sender {
    [self destroyTimer];
    //    if (self.isSmallPlayShow) {//小屏幕播放器，直接返回不再隐藏
    //        self.screenLockButton.hidden = YES;
    //        return;
    //    }
//    if (self.isLockBtnEnable) {
//        return;
//    }
//    [self setControlsHidden:!self.isControlsHidden];
//    if (!self.isControlsHidden) {
//        self.controlHideCountdown = [self.playerControlsAutoHideTime integerValue];
//    }
//    [self.delegate playerViewSingleTapped];
    if (self.isLockBtnEnable) {
        [self hiddenLockBtn];
    }else{
        [self hiddenControl];
    }
    
    //隐藏状态栏
    self.isStatusBarHidden = self.topControl.hidden;
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self addTimer];
}

-(void)hiddenControl
{
    self.topControl.hidden = !self.topControl.hidden;
    self.bottomControl.hidden = !self.bottomControl.hidden;
}

-(void)hiddenLockBtn
{
    self.lockButton.hidden = !self.lockButton.hidden;
}


#pragma mark - 双击手势的处理
- (IBAction)handleTwoTap:(id)sender {
    
    if (self.isLockBtnEnable) {
        return;
    }
 
    [self startPauseButtonAction:nil];
}

#pragma mark - 点击锁屏按钮
- (IBAction)lockButtonClick:(UIButton *)sender {
    self.isLockBtnEnable = !self.isLockBtnEnable;
    if (!self.isLockBtnEnable) {
        //开
        [sender setImage:[UIImage imageNamed:@"icon_kai_n.png"] forState:UIControlStateNormal];
        self.topControl.hidden = NO;
        self.bottomControl.hidden = NO;
    }else{
        //锁
        [sender setImage:[UIImage imageNamed:@"icon_suo_h.png"] forState:UIControlStateNormal];
        self.topControl.hidden = YES;
        self.bottomControl.hidden = YES;
        self.lockButton.hidden = YES;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"---kvo1:%@",@"syncUIStatus");

    if (object == self.progressSld) {
        if ([keyPath isEqualToString:@"maximumValue"]) {
//            DDLogVerbose(@"scrubber Value change: %f", self.scrubber.value);
//            RUN_ON_UI_THREAD(^{
            NSLog(@"---kvo:%@",@"syncUIStatus");
                [self syncUIStatus];
//            });
        }
    }
    
//    if ([object isKindOfClass:[UIButton class]]) {
//        UIButton* button = object;
//        if ([button isDescendantOfView:self.topControlOverlay]) {
//            [self layoutTopControls];
//        }
//    }
}


#pragma mark - 手势快进，快退
# if 0

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch * touch = [touches anyObject];
    self.curTickleStart = [touch locationInView:self.view];
}

//手势控制音量和亮度
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch = [touches anyObject];
    //当前触摸点
    CGPoint current = [touch locationInView:self.view];
    //上一个触摸点
    CGPoint previous = [touch previousLocationInView:self.view];
    
    CGRect leftF;//左半边的
    CGRect reightF;//右半边
    if (!IsIOS8) {
        leftF = CGRectMake(0, 0, KHeight/2, KWidth);//左半边的
        reightF = CGRectMake( KHeight/2 , 0, KHeight/2, KWidth);//右半边
    }else{
        leftF = CGRectMake(0, 0, KWidth/2, KHeight);//左半边的
        reightF = CGRectMake( KWidth/2 , 0, KWidth/2, KHeight);//右半边
    }
    
    CGFloat moveAmtx = current.x - self.curTickleStart.x;
    CGFloat moveAmty = current.y - self.curTickleStart.y;
    
    CGFloat ratio = moveAmty/10000;
    isEndFast = YES;
    
    if (self.isLockBtnEnable) {
        return;
    }
    
    if (CGRectContainsPoint(leftF, previous) && CGRectContainsPoint(leftF, current)&&(fabs(moveAmtx)<fabs(moveAmty))) {//调整左边 亮度
        self.swipeType = PlayerSwipePlayLight;
        //获取屏幕亮度
        CGFloat lightness = [UIScreen mainScreen].brightness;
        lightness = lightness - ratio;
        if (lightness>=1) {
            lightness=1;
        }
        if (lightness <= 0) {
            lightness = 0;
        }
        [[UIScreen mainScreen] setBrightness:lightness];
        
    }else if(CGRectContainsPoint(reightF, previous) && CGRectContainsPoint(reightF, current)&&(fabs(moveAmtx) < fabs(moveAmty))){//调整右边 音量
        self.swipeType = PlayerSwipePlayVoice;
        CGFloat volumness = [MPMusicPlayerController applicationMusicPlayer].volume;
        volumness = volumness - ratio;
        [[MPMusicPlayerController applicationMusicPlayer] setVolume:volumness];
        
    }else if(fabs(moveAmtx) > 30 &&(fabs(moveAmtx) > fabs(moveAmty))){
        
        self.swipeType = PlayerSwipePlaySpeed;
        self.forwardView.hidden = NO;
        if (!isEndFast) {
//            [self.player begainFast];
            isEndFast = YES;
        }
        int seconds = fabs(moveAmtx)/10;
        int currentTotal;
        if (moveAmtx > 0) {//快进
            fastNum = [NSNumber numberWithInt:seconds];
            self.forwardView.direction = ForwardUp;
            
            currentTotal = mMPayer.getCurrentPosition + seconds;
        }else{//后退
            fastNum = [NSNumber numberWithInt:-seconds];
            self.forwardView.direction = ForwardBack;
            currentTotal = mMPayer.getCurrentPosition - seconds;
        }
//        NSString * currentTime = [VKSharedUtility timeStringFromSecondsValue:currentTotal];
//        NSString * total = [VKSharedUtility timeStringFromSecondsValue:(int)self.player.view.scrubber.maximumValue];
//        self.forwardView.time = [NSString stringWithFormat:@"%@/%@",currentTime,total];
    }else{
        
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.curTickleStart = CGPointZero;
    
    if (self.swipeType == PlayerSwipePlaySpeed) {
        
//        [self.player endFastWithTime:self.player.currentTime +[fastNum floatValue]];
    }
    isEndFast = NO;
    self.forwardView.hidden = YES;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.curTickleStart = CGPointZero;
    isEndFast = NO;
    self.forwardView.hidden = YES;
    self.swipeType = PlayerSwipeUnKnown;
}

#pragma mark - 快进
- (ForwardBackView*)forwardView{
    if (!_forwardView) {
        ForwardBackView * forwardView = [[ForwardBackView alloc]initWithFrame:CGRectMake(0, 0, 170, 84)];
        if (IsIOS8) {
            forwardView.center = CGPointMake(self.view.center.y, self.view.center.x);
        }else{
            forwardView.center = CGPointMake(self.view.center.x, self.view.center.y);
        }
        forwardView.hidden = YES;
        [self.view addSubview:forwardView];
        self.forwardView = forwardView;
    }
    return _forwardView;
}

#endif

#pragma mark - 增加定时器
-(void)addTimer
{
    //     NSLog(@"---addTimer");
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(hiddenTopBottom) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        //消息循环，添加到主线程
        //extern NSString* const NSDefaultRunLoopMode;  //默认没有优先级
        //extern NSString* const NSRunLoopCommonModes;  //提高优先级
    }
}
#pragma mark - 销毁定时器
-(void)destroyTimer
{
    //    NSLog(@"---destroyTimer");
    [self.timer invalidate];
    self.timer = nil;
    NSLog(@"");
}

-(void)hiddenTopBottom
{
    if (!self.topControl.hidden) {
        self.topControl.hidden = YES;
        self.bottomControl.hidden = YES;
    }
    if (self.isLockBtnEnable) {
        self.lockButton.hidden = !self.lockButton.hidden;
    }
}

#pragma mark - 自动转屏的逻辑
- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
//    if (self.player.view.isLockBtnEnable) {
//        if (self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
//            return  UIInterfaceOrientationMaskLandscapeRight;
//        }else if(self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
//            return UIInterfaceOrientationMaskLandscapeLeft;
//        }
//        return UIInterfaceOrientationMaskLandscape;
//    }else{
//        return UIInterfaceOrientationMaskLandscape;
//    }
    return UIInterfaceOrientationMaskLandscape;
}


- (void)dealloc {
    [self unSetupObservers];
    [mMPayer unSetupPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.progressSld removeObserver:self forKeyPath:@"maximumValue"];
//    [self.rewindButton removeObserver:self forKeyPath:@"hidden"];
//    [self.nextButton removeObserver:self forKeyPath:@"hidden"];
}

@end





