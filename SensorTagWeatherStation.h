//
//  SensorTagWeatherStation.h
//  TisNobler
//
//  Created by Peter Merchant on 6/3/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "WeatherStation.h"

#import "TISensorTagDevice/TISensorTagDevice.h"

@interface SensorTagWeatherStation : WeatherStation
{
@protected
	TISensorTag*	_sensorTag;
}

@property (readwrite, strong)	TISensorTag*	sensorTag;

- (id) initWithSensorTag: (TISensorTag*) tag;

- (void) loadData;
- (void) pause;
- (void) resume;

@end
