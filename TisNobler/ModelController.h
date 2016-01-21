//
//  ModelController.h
//  TisNobler
//
//  Created by Peter Merchant on 5/29/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WeatherStationViewController.h"
#import "TISensorTagDevice/TISensorTagManager.h"

@interface ModelController : NSObject <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
{
@protected
	NSMutableArray*	wxStationData;
	NSUInteger		currentControllerIndex;
	NSUInteger		nextControllerIndex;
}

@property (readonly, strong, nonatomic) NSMutableArray*			wxControllers;
@property (readwrite, strong, nonatomic) TISensorTagManager*	sensorTags;

- (void) reloadControllersForPageViewController: (UIPageViewController*) pageViewController storyboard: (UIStoryboard*) storyboard;

- (WeatherStationViewController*) viewControllerAtIndex: (NSUInteger) index storyboard: (UIStoryboard*) storyboard;
- (NSUInteger)indexOfViewController: (WeatherStationViewController*) viewController;

@end

