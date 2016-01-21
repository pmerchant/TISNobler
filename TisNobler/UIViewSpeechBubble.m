//
//  UIViewSpeechBubble.m
//  TisNobler
//
//  Created by Peter Merchant on 12/31/15.
//  Copyright © 2015 Peter Merchant. All rights reserved.
//

#import "UIViewSpeechBubble.h"

@implementation UIViewSpeechBubble

@synthesize triangleVertexOffset;

- (void) setTriangleVertexOffset: (CGFloat) newOffset
{
	triangleVertexOffset = newOffset;
	[self setNeedsDisplay];
}

- (void) drawRect: (CGRect) rect
{	
	UIBezierPath*	trianglePath = [UIBezierPath bezierPath];
	
	[trianglePath moveToPoint: CGPointMake(0, 0)];
	[trianglePath addLineToPoint: CGPointMake(triangleVertexOffset, self.bounds.size.height)];
	[trianglePath addLineToPoint: CGPointMake(self.bounds.size.width, 0)];
	[trianglePath addLineToPoint: CGPointMake(0, 0)];
	
	UIView*	firstSubView = self.subviews[0];
	CGRect	bottomRect = CGRectMake(0, self.bounds.origin.y + firstSubView.bounds.size.height, self.bounds.size.width, self.bounds.size.height - firstSubView.bounds.size.height);
	
	CGContextSaveGState(UIGraphicsGetCurrentContext());
	CGContextClipToRect(UIGraphicsGetCurrentContext(), bottomRect);
	
	UIColor*	fillColor = [UIColor colorWithWhite: 1.0 alpha:	1.0];
	
	[fillColor set];
	[trianglePath fill];
	CGContextRestoreGState(UIGraphicsGetCurrentContext());
}

@end
