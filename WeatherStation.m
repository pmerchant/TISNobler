//
//  Weather.m
//  
//
//  Created by Peter Merchant on 5/29/15.
//
//

#import "WeatherStation.h"

@implementation WeatherStation

@synthesize locationDescription;
@synthesize error;
@synthesize temperature;
@synthesize humidity;
@synthesize barometricPressure;

- (id) init
{
	if ((self = [super init]))
	{
		error = NULL;
	}
	
	return self;
}

- (void) loadData
{
	NSAssert(NO, @"[WeatherStation loadData]: base class should not be called.");
	return;
}

- (void) pause
{
	NSAssert(NO, @"[WeatherStation pause]: base class should not be called.");
	return;
}

- (void) resume
{
	NSAssert(NO, @"[WeatherStation resume]: base class should not be called.");
	return;
}

@end
