//
//  SPProgressIndicatingButtonCell.m
//  spires
//
//  Created by Yuji on 3/31/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SPProgressIndicatingButtonCell.h"
#define ConvertAngle(a) (fmod((90.0-(a)), 360.0))
#define DEG2RAD  ((CGFloat)0.017453292519943295)

@implementation SPProgressIndicatingButtonCell
@synthesize isSpinning;
-(id)init;
{
    self=[super initImageCell:nil];
    [self setButtonType:NSMomentaryPushInButton];
    [self setBordered:NO];
    [self setHighlightsBy:NSContentsCellMask];
//    [self setBackgroundColor:[NSColor clearColor]];
    stopImage=[NSImage imageNamed:NSImageNameStopProgressTemplate];
    return self;
}
-(void)refresh:(id)ignored;
{
    step++;
    [[self controlView] display];
}
-(void)startAnimation:(id)sender;
{
    if(!spinTimer){
	spinTimer=[NSTimer scheduledTimerWithTimeInterval:.04 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:spinTimer forMode:NSEventTrackingRunLoopMode];
    }
    isSpinning=YES;
}
-(void)stopAnimation:(id)sender;
{
    if(spinTimer){
	[spinTimer invalidate];
	spinTimer=nil;
    }
    isSpinning=NO;
    [[self controlView] display];
}
- (void)drawSpinningInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // taken from http://www.harmless.de/cocoa-code.php
    CGFloat flipFactor = (CGFloat)([controlView isFlipped] ? 1.0 : -1.0);
    CGFloat cellSize = MIN(cellFrame.size.width, cellFrame.size.height);
    NSPoint center = cellFrame.origin;
    center.x += cellSize/(CGFloat)2.0;
    center.y += cellFrame.size.height/(CGFloat)2.0;
    CGFloat outerRadius;
    CGFloat innerRadius;
    CGFloat strokeWidth = cellSize*(CGFloat)0.08;
    if (cellSize >= 32.0) {
	outerRadius = cellSize*(CGFloat)0.38;
	innerRadius = cellSize*(CGFloat)0.23;
    } else {
	outerRadius = cellSize*(CGFloat)0.48;
	innerRadius = cellSize*(CGFloat)0.27;
    }
    outerRadius *= (CGFloat).75;
    innerRadius *= (CGFloat).75;
    CGFloat a; // angle
    NSPoint inner;
    NSPoint outer;
    // remember defaults
    NSLineCapStyle previousLineCapStyle = [NSBezierPath defaultLineCapStyle];
    CGFloat previousLineWidth = [NSBezierPath defaultLineWidth]; 
    // new defaults for our loop
    [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
    [NSBezierPath setDefaultLineWidth:strokeWidth];
    if (isSpinning) {
	a = (CGFloat)(270+(step* 30))*DEG2RAD;
    } else {
	a = (CGFloat)270*DEG2RAD;
    }
    a = flipFactor*a;
    int i;
    for (i = 0; i < 12; i++) {
	//			[[NSColor colorWithCalibratedWhite:MIN(sqrt(i)*0.25, 0.8) alpha:1.0] set];
	//			[[NSColor colorWithCalibratedWhite:0.0 alpha:1.0-sqrt(i)*0.25] set];
	CGFloat redComponent=0;
	CGFloat greenComponent=0;
	CGFloat blueComponent=0;
	CGFloat alphaComponent=(CGFloat)(1.0-sqrt(i)*0.25);
	[[NSColor colorWithCalibratedRed:redComponent green:greenComponent blue:blueComponent alpha:alphaComponent] set];
	outer = NSMakePoint(center.x+(CGFloat)cos(a)*outerRadius, center.y+(CGFloat)sin(a)*outerRadius);
	inner = NSMakePoint(center.x+(CGFloat)cos(a)*innerRadius, center.y+(CGFloat)sin(a)*innerRadius);
	[NSBezierPath strokeLineFromPoint:inner toPoint:outer];
	a -= flipFactor*30*DEG2RAD;
    }
    // restore previous defaults
    [NSBezierPath setDefaultLineCapStyle:previousLineCapStyle];
    [NSBezierPath setDefaultLineWidth:previousLineWidth];
}

/*-(void)mouseEntered:(NSEvent*)ev
{
    mouseIsIn=YES;
    [super mouseEntered:ev];
}
-(void)mouseExited:(NSEvent*)ev
{
    mouseIsIn=NO;
    [super mouseExited:ev];
}*/
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //NSLog(@"cellFrame: %f %f %f %f", cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
    NSView*v=[self controlView];
    NSPoint pt=[[v window] mouseLocationOutsideOfEventStream];
    pt=[v convertPoint:pt fromView:nil];
    BOOL mouseIsIn=[[self controlView] mouse:pt inRect:cellFrame];
    if (isSpinning && ! mouseIsIn) {
	[self drawSpinningInteriorWithFrame:cellFrame inView:controlView];
    }else if(isSpinning && mouseIsIn){
	NSImage*img=[self image];
	[self setImage:stopImage];
	[super drawInteriorWithFrame:cellFrame inView:controlView];
	[self setImage:img];
    }else{
	[super drawInteriorWithFrame:cellFrame inView:controlView];	
    }
}

@end
