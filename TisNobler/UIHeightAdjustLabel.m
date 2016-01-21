//
//  UIHeightAdjustLabel.m
//  TisNobler
//
//  Created by Peter Merchant on 7/6/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "UIHeightAdjustLabel.h"

@implementation UIHeightAdjustLabel

- (CGFloat) fontSizeToFitLabelHeight
{
	CGFloat				tooSmallPointSize = 0;
	CGFloat				tooBigPointSize = self.frame.size.height;
	CGFloat				newFontPointSize;

	do
	{
		newFontPointSize = (tooSmallPointSize + tooBigPointSize) / 2;
		
		@autoreleasepool
		{
			UIFont*			labelFont = [UIFont fontWithName: self.font.fontName size: newFontPointSize];
			NSDictionary*	attributes = [NSDictionary dictionaryWithObjectsAndKeys: labelFont, NSFontAttributeName, nil];
			CGSize			newSize = [self.text sizeWithAttributes: attributes];
			
			if (newSize.height > self.bounds.size.height || newSize.width > self.bounds.size.width)
				tooBigPointSize = newFontPointSize;
			else if (newSize.height < self.bounds.size.height || newSize.width < self.bounds.size.width)
				tooSmallPointSize = newFontPointSize;
		}
	}
	while (fabs(tooSmallPointSize - tooBigPointSize) > 1);
	
	return tooSmallPointSize;
}

- (void) layoutSubviews
{
	[super layoutSubviews];

	CGFloat	newSize = [self fontSizeToFitLabelHeight];
	
	if ((int) newSize != (int) self.font.pointSize)
		self.font = [UIFont fontWithName: self.font.fontName size: newSize];
}

@end
