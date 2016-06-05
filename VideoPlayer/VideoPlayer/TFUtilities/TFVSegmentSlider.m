//
//  VSegmentSlider.m
//  VPlayer
//
//  Created by erlz nuo on 6/26/13.
//
//

#import "TFVSegmentSlider.h"


@implementation TFVSegmentSlider

@dynamic segments;


- (NSArray *)segments
{
	return _segments;
}

- (void)setSegments:(NSArray *)segs
{
	@synchronized(self) {
//		[_segments release];
//		_segments = [segs retain];
        _segments = segs;
		[self setNeedsDisplay];
	}
}

- (void)drawRect:(CGRect)rect
{
	@synchronized(self) {
		float rw = rect.size.width;
		float ycrop = 2.0;
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSaveGState(context); {
//			CGContextSetRGBFillColor(context, 0.3794, 0.7968, 0.7911, 1.0);
            //缓冲条的颜色
            CGContextSetRGBFillColor(context,91/255.0, 138/255.0, 219/255.0, 1.0);
			for (int i = 0; i < self.segments.count / 2; i++) {
				CGRect cur = CGRectZero;
				cur.origin.x    = rw * [self.segments[2*i] floatValue];
				cur.origin.y    = rect.origin.y + ycrop;
				cur.size.width  = rw * [self.segments[2*i+1] floatValue] - cur.origin.x;
				cur.size.height = rect.size.height - ycrop * 2.0;
				CGContextFillRect(context, cur);
			}
			if (self.segments == nil) {
				CGContextFillRect(context, CGRectZero);
			}
			CGContextStrokePath(context);
		} CGContextRestoreGState(context);
	}
}

 
@end
