//
//  UIViewSpeechBubble.h
//  TisNobler
//
//  Created by Peter Merchant on 12/31/15.
//  Copyright © 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewSpeechBubble : UIView
{
}

@property (nonatomic, readwrite, assign,setter=setTriangleVertexOffset:) CGFloat triangleVertexOffset;

- (void) drawRect: (CGRect) rect;

@end
