//
//  NWSWeatherStation.m
//  TisNobler
//
//  Created by Peter Merchant on 6/2/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "NWSWeatherStation.h"

#import <UIKit/UIKit.h>

#include <time.h>

@implementation NWSWeatherStation

@synthesize location;
@synthesize stationName = _stationName;
@synthesize networkName;

#define kONE_HOUR_IN_SEC	3600
#define kONE_DAY_IN_SEC (kONE_HOUR_IN_SEC * 24)

static NSCache*	sNetworkCache = NULL;

- (id) init
{
	if ((self = [super init]))
	{
		_network = NULL;
		_mesoToken = [[NSUserDefaults standardUserDefaults] stringForKey: @"MesoToken"];
	}
	
	return  self;
}

- (id) initNearLocation: (CLLocation*) loc
{
	if ((self = [self init]))
	{
		location = loc;
	}
	
	return self;
}

- (void) dealloc
{
	if (_locationManager && [CLLocationManager significantLocationChangeMonitoringAvailable])
		[_locationManager stopMonitoringSignificantLocationChanges];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self name: @"NSApplicationDidBecomeActive" object: NULL];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: @"NSApplicationWillResignActive" object: NULL];
}

- (NSString*) networkName
{
	if (_network)
		return _network;
	else
		return @"Unknown";
}

- (void) loadData
{
	CLAuthorizationStatus	authStatus = [CLLocationManager authorizationStatus];
	
	if (authStatus == kCLAuthorizationStatusDenied)
	{
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self.error = [NSError errorWithDomain: kCLErrorDomain code: kCLErrorDenied userInfo: @{ NSLocalizedDescriptionKey : @"Location Services must be enabled to determine the conditions at your location." }];
		});
		
		return;
	}
	
	if (! _locationManager)
	{
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
		_locationManager.delegate = self;

		if (authStatus == kCLAuthorizationStatusNotDetermined)
			[_locationManager requestWhenInUseAuthorization];
	}
	else
	{
		[_locationManager requestLocation];
		
		if ([CLLocationManager significantLocationChangeMonitoringAvailable])
			[_locationManager startMonitoringSignificantLocationChanges];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pauseResumeNotification:) name: @"NSApplicationDidBecomeActive" object: NULL];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(pauseResumeNotification:) name: @"NSApplicationWillResignActive" object: NULL];
}

- (void) pause
{
	if (_nwsUpdateTimer && _nwsUpdateTimer.valid)
		dispatch_async(dispatch_get_main_queue(), ^{ [_nwsUpdateTimer invalidate]; });
}

- (void) resume
{
	if (_nwsUpdateTimer && ! _nwsUpdateTimer.valid)
	{
		NSTimeInterval	secondsFromNow = (_nwsTimerFireDate == NULL ? kONE_HOUR_IN_SEC : [_nwsTimerFireDate timeIntervalSinceNow]);
		
		if (secondsFromNow < 0)
			secondsFromNow = 0;
		
		[self setUpdateTimerSeconds: secondsFromNow];
	}
}

- (void) loadDataNearLocation: (CLLocation*) loc
{
	NSURL*          wxAddress;
	
	NSAssert(loc != NULL, @"NULL Location sent to loadDataNearLocation.");
	
	if (_mesoToken == NULL)
	{
		self.error = [NSError errorWithDomain: @"MESOWEST" code: -2 userInfo: @{ NSLocalizedDescriptionKey : @"You must specify a MesoWest API token in the settings.  For more information on API keys and tokens, visit http://www.mesowest.org." }];
		return;
	}
	
	wxAddress = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.mesowest.net/v2/stations/nearesttime?radius=%.4f,%.4f,25&within=60&token=%@&vars=air_temp,pressure,relative_humidity", loc.coordinate.latitude, loc.coordinate.longitude, _mesoToken]];
	
	NSURLRequest*		dataRequest = [NSURLRequest requestWithURL: wxAddress cachePolicy: NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval: 30];
	NSURLSessionDataTask* dataTask = [[NSURLSession sharedSession] dataTaskWithRequest: dataRequest completionHandler: ^(NSData* data, NSURLResponse* response, NSError* sessionError) {
		if (sessionError)
		{
			self.error = sessionError;
		}
		else
		{
			if (! [self parseJSONWeatherData: data])
			{
				self.error = [NSError errorWithDomain: @"MESOWEST" code: -1 userInfo: @{ NSLocalizedDescriptionKey : @"Weather stations in this area have not reported information in the last hour." }];
			}
		}
	}];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[dataTask resume];
}

- (BOOL) parseJSONWeatherData: (NSData*) wxData
{
	NSError*	err;
	id			jsonStations = [NSJSONSerialization JSONObjectWithData: wxData options: NSJSONReadingAllowFragments error: &err];
	BOOL		result = NO;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	if (err)
		self.error = err;
	else
	{
		NSDictionary*	summary = [jsonStations objectForKey: @"SUMMARY"];
		NSNumber*		responseCode = [summary objectForKey: @"RESPONSE_CODE"];
		
		if (! [responseCode isEqualToNumber: @1])
		{
			self.error = [NSError errorWithDomain: @"MESOWEST" code: [responseCode intValue] userInfo: @{ NSLocalizedDescriptionKey : [summary objectForKey: @"RESPONSE_MESSAGE"] }];
			result = YES;
		}
	}
	
	if (! self.error)
	{
		NSArray*		stationList = [jsonStations objectForKey: @"STATION"];
		NSDictionary*	dataUnits = [jsonStations objectForKey: @"UNITS"];
		NSDictionary*	eachStation;
		NSDictionary*	temperatureStation = NULL;
		NSDictionary*	temperatureDict = NULL;
		NSDictionary*	humidityDict = NULL;
		NSDictionary*	pressureDict = NULL;
		double_t		temperatureDistance = 200;
		double_t		humidityDistance = 200;;
		double_t		pressureDistance = 200;
		
		for (eachStation in stationList)
		{
			double_t				eachStationDistance = [[eachStation objectForKey: @"DISTANCE"] doubleValue];
			NSDictionary*	observations = [eachStation objectForKey: @"OBSERVATIONS"];
			
			if (eachStationDistance < temperatureDistance)
			{
				NSDictionary*	eachTemperatureDict = [observations objectForKey: @"air_temp_value_1"];
				
				if (eachTemperatureDict)
				{
					temperatureDict = eachTemperatureDict;
					temperatureStation = eachStation;
					temperatureDistance = eachStationDistance;
				}
			}
			
			if (eachStationDistance < humidityDistance)
			{
				NSDictionary*	eachHumidityDict = [observations objectForKey: @"relative_humidity_value_1"];
				
				if (eachHumidityDict)
				{
					humidityDict = eachHumidityDict;
					humidityDistance = eachStationDistance;
				}
			}
			
			if (eachStationDistance < pressureDistance)
			{
				NSDictionary*	eachPressureDict = [observations objectForKey: @"pressure_value_1"];
			
				if (eachPressureDict)
				{
					pressureDict = eachPressureDict;
					pressureDistance = eachStationDistance;
				}
			}
		}
		
		if (temperatureStation)
		{
			NSString*	latString = [temperatureStation objectForKey: @"LATITUDE"];
			NSString*	lonString = [temperatureStation objectForKey: @"LONGITUDE"];
			
			self.location = [[CLLocation alloc] initWithLatitude: [latString doubleValue] longitude: [lonString doubleValue]];
			
			[self loadLocationDescription];
			[self loadNetworkNameFromNetworkID: temperatureStation[@"MNET_ID"]];
			
			if (temperatureDict)
			{
				NSNumber*	temp = [temperatureDict objectForKey: @"value"];
				
				if ([dataUnits[@"air_temp"] isEqualToString: @"Fahrenheit"])
					temp = [NSNumber numberWithFloat: ([temp floatValue] - 32) / 1.8];
				
				self.temperature = [temp intValue];
				
				_stationName = [temperatureStation objectForKey: @"NAME"];
				
				NSDateFormatter*	dateFormat = [[NSDateFormatter alloc] init];
				
				[dateFormat setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
				dateFormat.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
				
				self.lastUpdateDate = [dateFormat dateFromString: [temperatureDict objectForKey: @"date_time"]];
				
				// Get Latency information to calculate when the best time to ask again is.
				
				NSDate*	dayOldDate = [self.lastUpdateDate dateByAddingTimeInterval: -(kONE_DAY_IN_SEC)];
				NSDateFormatter*	latencyQueryDateFormat = [[NSDateFormatter alloc] init];
				latencyQueryDateFormat.dateFormat = @"yyyyMMddHHmm";
				latencyQueryDateFormat.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
				
				NSURL*	wxLatencyAddress = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.mesowest.net/v2/stations/latency?stid=%@&start=%@&end=%@&token=%@", temperatureStation[@"STID"], [latencyQueryDateFormat stringFromDate: dayOldDate], [latencyQueryDateFormat stringFromDate: self.lastUpdateDate], _mesoToken]];
				
				NSURLSessionDataTask* latencyDataTask = [[NSURLSession sharedSession] dataTaskWithURL: wxLatencyAddress completionHandler: ^(NSData* data, NSURLResponse* response, NSError* sessionError) {
					if (sessionError == NULL)
					{
						[self setUpdateTimerSeconds: [self calculateUpdateIntervalWithLatencyJSONData: data]];
					}
				}];
				[latencyDataTask resume];

			}
			if (humidityDict)
			{
				NSNumber*	humidity = [humidityDict objectForKey: @"value"];
				
				self.humidity = [humidity intValue];
			}
			if (pressureDict)
			{
				NSNumber*	pressure = [pressureDict objectForKey: @"value"];
				
				self.barometricPressure = ([((NSNumber*) pressure) doubleValue] / 1000) * 0.29529980164712;
			}
			
			result = YES;
		}
	}
	
	return result;
}


- (NSTimeInterval) calculateUpdateIntervalWithLatencyJSONData: (NSData*) latencyData
{
	NSDictionary*		jsonResponse = [NSJSONSerialization JSONObjectWithData: latencyData options: NSJSONReadingAllowFragments error: NULL];
	NSDictionary*		station = jsonResponse[@"STATION"][0];
	NSDictionary*		latencyInfo = station[@"LATENCY"];
	NSArray*			recentReportDates = latencyInfo[@"date_time"];
	NSDateFormatter*	dateFormat = [[NSDateFormatter alloc] init];
	
	[dateFormat setDateFormat: @"yyyy-MM-dd'T'HH:mm:ssZ"];
	dateFormat.timeZone = [NSTimeZone timeZoneForSecondsFromGMT: 0];
	
	NSDate*	lastDate = NULL;
	NSTimeInterval	maxInterval = 0;
	
	for (NSString* eachDateString in recentReportDates)
	{
		if (lastDate == NULL)
			lastDate = [dateFormat dateFromString: eachDateString];
		else
		{
			NSDate* eachDate = [dateFormat dateFromString: eachDateString];
			NSTimeInterval	eachDifference = [eachDate timeIntervalSinceDate: lastDate];
			
			if (eachDifference > maxInterval)
				maxInterval = eachDifference;
			
			lastDate = eachDate;
		}
	}
	
	return maxInterval;
}

- (void) setUpdateTimerSeconds: (NSTimeInterval) secondsToWait;
{
	if (_nwsUpdateTimer && _nwsUpdateTimer.valid)
		[_nwsUpdateTimer invalidate];
	
	_nwsTimerFireDate = [NSDate dateWithTimeIntervalSinceNow: secondsToWait];
	
	_nwsUpdateTimer = [[NSTimer alloc] initWithFireDate: _nwsTimerFireDate interval: 0 target: self selector: @selector(updateTimerFired:) userInfo: NULL repeats: NO];
	
	dispatch_async(dispatch_get_main_queue(), ^{ [[NSRunLoop mainRunLoop] addTimer: _nwsUpdateTimer forMode:NSRunLoopCommonModes]; });
}

- (void) updateTimerFired: (NSTimer*) timer
{
	// Generate an update to our location, which should cause the data to be reloaded.
	
	[_locationManager requestLocation];
}

- (void) pauseResumeNotification: (NSNotification*) note
{
	if ([note.name isEqualToString: @"NSApplicationWillResignActive"])
		[self pause];
	else if ([note.name isEqualToString: @"NSApplicationDidBecomeActive"])
		[self resume];
}

- (void) loadNetworkNameFromNetworkID: (NSString*) networkID
{
	BOOL	downloadNetworkInfo = NO;
	
	if (sNetworkCache)
	{
		NSDictionary*	networkInfo = [sNetworkCache objectForKey: networkID];
		
		if (networkInfo)
			_network = networkInfo[@"LONGNAME"];
		else
			downloadNetworkInfo = YES;
	}
	else
	{
		sNetworkCache = [[NSCache alloc] init];
		downloadNetworkInfo = YES;
	}
	
	if (downloadNetworkInfo)
	{
		NSURL*	wxNetAddress = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.mesowest.net/v2/networks?id=%@&token=%@", networkID, _mesoToken]];
		
		NSURLSessionDataTask* netDataTask = [[NSURLSession sharedSession] dataTaskWithURL: wxNetAddress completionHandler: ^(NSData* data, NSURLResponse* response, NSError* sessionError) {
			if (sessionError == NULL)
			{
				NSDictionary*	jsonResponse = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingAllowFragments error: NULL];
				NSArray*		networkList = jsonResponse[@"MNET"];
				
				if (networkList.count > 0)
				{
					[sNetworkCache setObject: networkList[0] forKey: networkID];
					_network = [networkList[0] objectForKey: @"LONGNAME"];
				}
			}
		}];
		[netDataTask resume];
	}
}

- (void) loadLocationDescription
{
	// Go to nominatim and get the name of the city where the weather station is located.
	
	NSAssert(self.location != NULL, @"No location defined.");
	
	NSURL*	reverseGeocodeAddress = [NSURL URLWithString: [NSString stringWithFormat: @"http://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=%.7f&lon=%.7f", self.location.coordinate.latitude, self.location.coordinate.longitude]];
	
	NSURLSessionDataTask* netDataTask = [[NSURLSession sharedSession] dataTaskWithURL: reverseGeocodeAddress
																	completionHandler: ^(NSData* data, NSURLResponse* response, NSError* sessionError) {
		if (sessionError == NULL)
		{
			NSDictionary*	jsonResponse = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingAllowFragments error: NULL];
			NSDictionary*	addressInfo = jsonResponse[@"address"];
			
			if (addressInfo == NULL)	// No address info in response?
				self.locationDescription = self.stationName;	// Use the station name
			else if (addressInfo[@"village"])
				self.locationDescription = addressInfo[@"village"];
			else if (addressInfo[@"town"])
				self.locationDescription = addressInfo[@"town"];
			else if (addressInfo[@"suburb"])
				self.locationDescription = addressInfo[@"suburb"];
			else if (addressInfo[@"city"])
				self.locationDescription = addressInfo[@"city"];
			else
				self.locationDescription = self.stationName;
		}
		else
			self.locationDescription = self.stationName;
	}];
	[netDataTask resume];
}
#pragma mark - Location Manager Delegate Methods

- (void) locationManager: (CLLocationManager*) manager didUpdateLocations: (NSArray*) locations
{
	CLLocation*	currentLocation = [locations lastObject];
	
	if (currentLocation)
		[self loadDataNearLocation: currentLocation];
}

- (void) locationManager: (CLLocationManager*) manager didChangeAuthorizationStatus: (CLAuthorizationStatus) status
{
	if (status == kCLAuthorizationStatusAuthorizedWhenInUse)
	{
		[self loadData];
	}
}

- (void) locationManager: (CLLocationManager*) manager didFailWithError: (NSError*) error
{
	self.error = error;
}

@end
