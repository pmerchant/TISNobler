//
//  NWSWeatherStation.h
//  TisNobler
//
//  Created by Peter Merchant on 6/2/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "WeatherStation.h"

#import <CoreLocation/CoreLocation.h>

@interface NWSWeatherStation : WeatherStation <CLLocationManagerDelegate>
{
@protected
	CLLocationManager*			_locationManager;

	NSTimer*					_nwsUpdateTimer;
	NSDate*						_nwsTimerFireDate;
	NSString*					_mesoToken;
	NSString*					_stationName;
	NSString*					_network;
}

@property (readwrite, strong) CLLocation* location;
@property (readwrite, strong) NSString*	stationName;
@property (readonly, strong,getter=networkName)	NSString*	networkName;

- (id) initNearLocation: (CLLocation*) loc;

@end

