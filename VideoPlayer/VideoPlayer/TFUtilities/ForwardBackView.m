//
//  ForwardBackView.m
//  VideoPlayer
//
//  Created by Tengfei on 16/6/4.
//  Copyright © 2016年 tengfei. All rights reserved.
//

#import "ForwardBackView.h"

@implementation ForwardBackView
{
    UIImageView * forwardImage;
    UILabel * seconds;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.layer.cornerRadius = 2;
        self.backgroundColor = [UIColor blackColor];
        
        forwardImage = [[UIImageView alloc]initWithFrame:CGRectMake((frame.size.width - 52)/2, 20, 52, 30)];
        [self addSubview:forwardImage];
        
        seconds = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(forwardImage.frame) + 10, frame.size.width - 20, 16)];
        seconds.font = [UIFont boldSystemFontOfSize:14];
        seconds.textColor = [UIColor whiteColor];
        seconds.textAlignment = NSTextAlignmentCenter;
        [self addSubview:seconds];
    }
    return self;
}

- (void)setDirection:(ForwardDirection)direction
{
    if (direction) {
        forwardImage.image = [UIImage imageNamed:@"left"];
    }else{
        forwardImage.image = [UIImage imageNamed:@"right"];
    }
}

- (void)setTime:(NSString *)time
{
    if (time) {
        
        
        seconds.text = time;
    }
}

@end


