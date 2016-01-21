//
//  NWSWeatherStation.h
//  TisNobler
//
//  Created by Peter Merchant on 6/2/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "WeatherStation.h"

#import <CoreLocation/CoreLocation.h>

@interface NWSWeatherStation : WeatherStation <NSXMLParserDelegate, CLLocationManagerDelegate>
{
@protected
	CLLocationManager*			_locationManager;

	NSMutableDictionary*		_locationData;
	NSMutableDictionary*		_timeData;
	NSMutableDictionary*		_tempData;
	NSMutableDictionary*		_humidityData;
	NSMutableDictionary*		_barometerData;
	__weak NSMutableDictionary*	_currentElementData;
	__weak NSString*			_currentElementName;
	NSTimer*					_nwsUpdateTimer;
	NSDate*						_nwsTimerFireDate;
	NSString*					_mesoToken;
	NSString*					_network;
}

@property (readwrite, strong)	CLLocation* location;
@property (readonly, strong,getter=networkName)	NSString*	networkName;

- (id) initNearLocation: (CLLocation*) loc;

@end

