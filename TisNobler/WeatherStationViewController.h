//
//  WeatherStationViewController.h
//  TisNobler
//
//  Created by Peter Merchant on 6/8/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIHeightAdjustLabel.h"

#import "WeatherStation.h"
#import "WxStationInfoViewController.h"

@interface WeatherStationViewController : UIViewController
{
	WeatherStation*	_wxStation;
	IBOutlet UIActivityIndicatorView* activity;
	IBOutlet WxStationInfoViewController*	infoViewController;
}

@property (nonatomic, strong, readwrite, setter=setWxStation:) WeatherStation*	wxStation;
@property (strong, readwrite) NSString*	dataIdentifier;

@property (strong, readwrite) IBOutlet UIHeightAdjustLabel*	temperature;
@property (strong, readwrite) IBOutlet UILabel*	humidity;
@property (strong, readwrite) IBOutlet UILabel*	barometricPressure;
@property (strong, readwrite) IBOutlet UIButton* locationDescription;

- (IBAction) showStationInfo: (id) sender;

@end
