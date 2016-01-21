//
//  SensorTagWeatherStation.m
//  TisNobler
//
//  Created by Peter Merchant on 6/3/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "SensorTagWeatherStation.h"

@implementation SensorTagWeatherStation

- (id) initWithSensorTag: (TISensorTag*) tag
{
	if ((self = [self init]))
	{
		_sensorTag = tag;
	}
	
	return self;
}

- (void) dealloc
{		
	[_sensorTag removeObserver: self forKeyPath: @"hygrometer"];
	[_sensorTag removeObserver: self forKeyPath: @"hygrometer.temperature"];
	[_sensorTag removeObserver: self forKeyPath: @"hygrometer.humidity"];

	[_sensorTag removeObserver: self forKeyPath: @"barometer"];
	[_sensorTag removeObserver: self forKeyPath: @"barometer.pressure"];
	
	[_sensorTag removeObserver: self forKeyPath: @"buttons.button1Down"];
	[_sensorTag removeObserver: self forKeyPath: @"deviceError"];
}

- (void) loadData
{
	[_sensorTag addObserver: self forKeyPath: @"hygrometer" options: NSKeyValueObservingOptionNew context:NULL];
	[_sensorTag addObserver: self forKeyPath: @"barometer" options: NSKeyValueObservingOptionNew context:NULL];
	[_sensorTag addObserver: self forKeyPath: @"buttons.button1Down" options: NSKeyValueObservingOptionNew context: NULL];
	[_sensorTag addObserver: self forKeyPath: @"deviceError" options: NSKeyValueObservingOptionNew context: NULL];
	
	NSArray*	stationList = [[NSUserDefaults standardUserDefaults] arrayForKey: @"stations"];
	
	if (stationList)
	{
		NSDictionary*	eachStation;
		
		for (eachStation in stationList)
		{
			if ([_sensorTag.identifier isEqualToString: [[eachStation[@"identifier"] componentsSeparatedByString: @"@"] objectAtIndex: 0]])
			{
				self.locationDescription = [eachStation valueForKey: @"name"];
				break;
			}
		}
	}
	
	[self resume];
}

- (void) pause
{
	_sensorTag.hygrometerActive = NO;
	_sensorTag.barometerActive = NO;
	_sensorTag.buttonsActive = NO;
}

- (void) resume
{
	_sensorTag.hygrometerActive = YES;
	_sensorTag.barometerActive = YES;
	_sensorTag.buttonsActive = YES;
}

#pragma mark - KVO/KVC Support

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*)context
{
	id	newValue = [change objectForKey: NSKeyValueChangeNewKey];

	if ([keyPath isEqualToString: @"barometer.pressure"])
	{
		// Convert Pascals to Inches of Mercury
		self.barometricPressure = ([((NSNumber*) newValue) doubleValue] / 1000) * 0.29529980164712;
		self.lastUpdateDate = [NSDate date];
	}
	else if ([keyPath isEqualToString: @"hygrometer.humidity"])
	{
		self.humidity = [((NSNumber*) newValue) unsignedIntValue];
		self.lastUpdateDate = [NSDate date];
	}
	else if ([keyPath isEqualToString: @"hygrometer.temperature"])
	{
		self.temperature = [newValue intValue];
		self.lastUpdateDate = [NSDate date];
	}
	else if ([keyPath isEqualToString: @"buttons.button1Down"])
	{
		if ([((NSNumber*) newValue) boolValue])
		{
			// Post a message to anyone who is interested to let them know that the button was pressed.
			// (Where "anyone interested" is the WeatherStationViewController)
			
			NSNotification*	buttonNotification = [NSNotification notificationWithName: @"buttonPress" object:self];
			
			[[NSNotificationCenter defaultCenter] postNotification: buttonNotification];
		}
	}
	else if ([keyPath isEqualToString: @"hygrometer"])
	{
		if (! [newValue isEqual: [NSNull null]])
		{
			_sensorTag.hygrometer.period = 2.55;
			[_sensorTag addObserver: self forKeyPath: @"hygrometer.temperature" options: NSKeyValueObservingOptionNew context: NULL];
			[_sensorTag addObserver: self forKeyPath: @"hygrometer.humidity" options: NSKeyValueObservingOptionNew context: NULL];
		}
		else
		{
			[_sensorTag removeObserver: self forKeyPath: @"hygrometer.temperature"];
			[_sensorTag removeObserver: self forKeyPath: @"hygrometer.humidity"];
		}
	}
	else if ([keyPath isEqualToString: @"barometer"])
	{
		if (! [newValue isEqual: [NSNull null]])
		{
			_sensorTag.barometer.period = 2.55;
			[_sensorTag addObserver: self forKeyPath: @"barometer.pressure" options: NSKeyValueObservingOptionNew context: NULL];
		}
		else
			[_sensorTag removeObserver: self forKeyPath: @"barometer.pressure"];
	}
	else if ([keyPath isEqualToString: @"deviceError"])
		self.error = newValue;
}

@end
