//
//  ModelController.m
//  TisNobler
//
//  Created by Peter Merchant on 5/29/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "ModelController.h"
#import "WeatherStationViewController.h"

#import "NWSWeatherStation.h"
#import "SensorTagWeatherStation.h"

@interface ModelController ()

@end

@implementation ModelController

- (instancetype)init
{
    self = [super init];
    if (self)
	{
		_wxControllers = NULL;
    }
    return self;
}

- (void) reloadControllersForPageViewController: (UIPageViewController*) pageViewController storyboard: (UIStoryboard*) storyboard
{
	WeatherStationViewController*	currentViewController = NULL;
	
	if (_wxControllers == NULL)
		_wxControllers = [[NSMutableArray alloc] init];
	
	if (currentControllerIndex < _wxControllers.count)
		currentViewController = _wxControllers[currentControllerIndex];
	
	NSMutableArray*			allWeatherStations = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"stations"] mutableCopy];
	NSMutableIndexSet*		deleteStations = [NSMutableIndexSet indexSet];
	NSMutableDictionary*	eachWeatherStationData;
	NSUInteger				index = 0;
	
	// Remove any weather stations which are not supposed to be shown or we don't have a sensor tag for them.
	
	for (eachWeatherStationData in allWeatherStations)
	{
		NSString*		className = [eachWeatherStationData objectForKey: @"class"];
		NSNumber*		show = [eachWeatherStationData objectForKey: @"show"];
		
		if (! (show && [show boolValue]))	// Should we show this?
			[deleteStations addIndex: index];
		else if ([className isEqualToString: @"SensorTagWeatherStation"])
		{
			TISensorTag*	sensorTag = [_sensorTags sensorTagWithIdentifier: [[eachWeatherStationData[@"identifier"] componentsSeparatedByString: @"@"] objectAtIndex: 1]];

			if (! sensorTag)
				[deleteStations addIndex: index];
		}
		index++;
	}

	[allWeatherStations removeObjectsAtIndexes: deleteStations];
	
	wxStationData = allWeatherStations;
	
	// Insert empty weather stations into controller array
	
	NSMutableArray*	newWxControllers = [NSMutableArray arrayWithCapacity: wxStationData.count];
	
	for (NSUInteger newWxControllerIndex = 0; newWxControllerIndex < wxStationData.count; newWxControllerIndex++)
	{
		// Look in the old view controllers array for a view controller.
		WeatherStationViewController*	oldViewController = (WeatherStationViewController*) [NSNull null];
		
		for (NSUInteger oldWxControllerIndex = 0; oldWxControllerIndex < _wxControllers.count; oldWxControllerIndex++)
		{
			if (_wxControllers[oldWxControllerIndex] == [NSNull null])
				continue;
			if ([((WeatherStationViewController*)_wxControllers[oldWxControllerIndex]).dataIdentifier isEqualToString: wxStationData[newWxControllerIndex][@"identifier"]])
			{
				oldViewController = _wxControllers[oldWxControllerIndex];
				break;
			}
		}
		
		if (oldViewController == currentViewController)
			currentControllerIndex = newWxControllerIndex;
		
		newWxControllers[newWxControllerIndex] = oldViewController;
	}
	
	_wxControllers = newWxControllers;
	
	// Tell pageViewController to reload
	
	if (currentViewController == NULL || (currentViewController != NULL && [self indexOfViewController: currentViewController] == NSNotFound))
		currentViewController = [self viewControllerAtIndex: currentControllerIndex storyboard: storyboard];
	
	[pageViewController setViewControllers: @[currentViewController] direction: UIPageViewControllerNavigationDirectionForward animated: YES completion: NULL];
}

- (WeatherStationViewController*) viewControllerAtIndex: (NSUInteger) index storyboard: (UIStoryboard*) storyboard
{
	WeatherStationViewController*	viewController = NULL;
	
	if (index >= _wxControllers.count)
		return NULL;
	
	viewController = _wxControllers[index];
	
	if (viewController == (WeatherStationViewController*) [NSNull null])
	{
		WeatherStation*	wxStation = NULL;
		
		if (index < wxStationData.count)
		{
			NSDictionary*	theStation = wxStationData[index];
			NSString*		name = theStation[@"name"];
			NSString*		className = theStation[@"class"];
			NSString*		identifier = theStation[@"identifier"];
			
			if ([className isEqualToString: @"NWSWeatherStation"])
				wxStation = [[NWSWeatherStation alloc] init];
			else if ([className isEqualToString: @"SensorTagWeatherStation"])
			{
				NSString*		sensorTagIdentifier = [[identifier componentsSeparatedByString: @"@"] objectAtIndex: 1];
				TISensorTag*	sensorTag = [_sensorTags sensorTagWithIdentifier: sensorTagIdentifier];
				
				if (sensorTag)
				{
					wxStation = [[SensorTagWeatherStation alloc] initWithSensorTag: sensorTag];
					wxStation.locationDescription = name;
				}
			}
			
			if (wxStation)
			{
				viewController = [storyboard instantiateViewControllerWithIdentifier: @"WeatherStationViewController"];
				
				viewController.wxStation = wxStation;
				viewController.dataIdentifier = identifier;
				
				_wxControllers[index] = viewController;
			}
			else
			{
				index++;
			}
		}

	}
		
	return viewController;
}

- (NSUInteger) indexOfViewController: (WeatherStationViewController*) viewController
{
    return [_wxControllers indexOfObject: viewController];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(WeatherStationViewController*)viewController];
    if ((index == 0) || (index == NSNotFound))
	{
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(WeatherStationViewController*)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
	
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (NSInteger) presentationCountForPageViewController: (UIPageViewController*) pageViewController
{
	return wxStationData.count;
}

- (NSInteger) presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
	// This must be here to get the UIPageControl to appear, but I don't believe it matters what it returns as the UIPageViewController is
	// tracking which view is being shown.
	
	return currentControllerIndex;
}

- (void) pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
{
	nextControllerIndex = [self indexOfViewController: (WeatherStationViewController*) [pendingViewControllers firstObject]];
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
	if (completed)
		currentControllerIndex = nextControllerIndex;
}

@end
