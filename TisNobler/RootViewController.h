//
//  RootViewController.h
//  TisNobler
//
//  Created by Peter Merchant on 5/29/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TISensorTagDevice/TISensorTagManager.h"

#import "WxStationSetupViewController.h"

@interface RootViewController : UINavigationController <UINavigationControllerDelegate>
{
@protected
	NSMutableArray*	weatherStations;
}

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) WxStationSetupViewController* setupViewController;
@property (strong, nonatomic) TISensorTagManager*	sensorTagManager;
@end

