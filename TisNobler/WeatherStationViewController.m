//
//  WeatherStationViewController.m
//  TisNobler
//
//  Created by Peter Merchant on 6/8/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "WeatherStationViewController.h"

#import "NWSWeatherStation.h"

@implementation WeatherStationViewController

- (void) setWxStation: (WeatherStation*) wxStation
{
	if (_wxStation)
	{
		[_wxStation removeObserver: self forKeyPath: @"temperature"];
		[_wxStation removeObserver: self forKeyPath: @"humidity"];
		[_wxStation removeObserver: self forKeyPath: @"barometricPressure"];
		[_wxStation removeObserver: self forKeyPath: @"locationDescription"];
		[_wxStation removeObserver: self forKeyPath: @"lastUpdateDate"];
		[_wxStation removeObserver: self forKeyPath: @"error"];
	}
	
	_wxStation = wxStation;
	
	if (_wxStation)
	{
		[_wxStation addObserver: self forKeyPath: @"temperature" options: NSKeyValueObservingOptionNew context: NULL];
		[_wxStation addObserver: self forKeyPath: @"humidity" options: NSKeyValueObservingOptionNew context: NULL];
		[_wxStation addObserver: self forKeyPath: @"barometricPressure" options: NSKeyValueObservingOptionNew context: NULL];
		[_wxStation addObserver: self forKeyPath: @"locationDescription" options: NSKeyValueObservingOptionNew context: NULL];
		[_wxStation addObserver: self forKeyPath: @"lastUpdateDate" options: NSKeyValueObservingOptionNew context: NULL];
		[_wxStation addObserver: self forKeyPath: @"error" options: NSKeyValueObservingOptionNew context: NULL];

		[_wxStation loadData];
	}
}

- (void) dealloc
{
	if (_wxStation)
	{
		[self setWxStation: NULL];
	}
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	activity.hidden = NO;
	[activity startAnimating];
	self.temperature.adjustsFontSizeToFitWidth = YES;
	[self.locationDescription setTitleColor: [UIColor blackColor] forState: UIControlStateDisabled];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController isKindOfClass: [WxStationInfoViewController class]])
	{
		((WxStationInfoViewController*) segue.destinationViewController).wxStation = self.wxStation;
	}
}

- (IBAction) showStationInfo: (id) sender
{
	if (infoViewController == NULL)
		[self.storyboard instantiateViewControllerWithIdentifier: @"WxStationInfoViewController"];
	
	infoViewController.wxStation = self.wxStation;
	
	[self transitionFromViewController: self toViewController: infoViewController duration: 0 options: UIViewAnimationOptionLayoutSubviews animations: NULL completion: NULL];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change:(NSDictionary*) change context: (void*) context
{
	NSNumber*	newValue = [change valueForKey: NSKeyValueChangeNewKey];
	NSString*	newString = ([newValue respondsToSelector: @selector(stringValue)]) ? [newValue stringValue] : (NSString*)newValue;
	
	if (activity.isAnimating)
	{
		dispatch_async(dispatch_get_main_queue(), ^{ [activity stopAnimating]; activity.hidden = YES; });
	}
	
	if ([keyPath isEqualToString: @"temperature"])
	{
		char	temperatureChar = 'C';
		
		if (! [[[NSLocale autoupdatingCurrentLocale] objectForKey: NSLocaleUsesMetricSystem] boolValue])
		{
			// They don't use metric, so convert to Fahrenheit.
			
			newString = [NSString stringWithFormat: @"%.f", ([newValue intValue] * 1.8) + 32];
			temperatureChar = 'F';
		}
		
		NSString*	formattedTemperature = [NSString stringWithFormat: @"%@°%c", newString, temperatureChar];
		
		if (! [self.temperature.text isEqualToString: formattedTemperature])
			dispatch_async(dispatch_get_main_queue(), ^{ self.temperature.text = formattedTemperature; });
	}
	else if ([keyPath isEqualToString: @"humidity"])
	{
		NSString*	formattedHumidity = [NSString stringWithFormat: @"%@%%", newString];
		
		if (![self.humidity.text isEqualToString: formattedHumidity])
			dispatch_async(dispatch_get_main_queue(), ^{ self.humidity.text = formattedHumidity; });

	}
	else if ([keyPath isEqualToString: @"barometricPressure"])
	{
		NSString*	formattedBarometer = [NSString stringWithFormat: @"%.2f\"", [newValue doubleValue]];
		
		if (! [self.barometricPressure.text isEqualToString: formattedBarometer])
			dispatch_async(dispatch_get_main_queue(), ^{ self.barometricPressure.text = formattedBarometer; });
	}
	else if ([keyPath isEqualToString: @"locationDescription"] ||
			 [keyPath isEqualToString: @"lastUpdateDate"])
	{
		if (((WeatherStation*) object).lastUpdateDate && ((WeatherStation*) object).locationDescription)
		{
			NSDateFormatter*	dateFormat = [[NSDateFormatter alloc] init];
			NSString*			lastUpdate;
			NSString*			locationAndUpdate;
			BOOL				canShowInfo = NO;
			NSInteger			seconds = [[NSCalendar calendarWithIdentifier: NSCalendarIdentifierGregorian] component: NSCalendarUnitSecond fromDate: ((WeatherStation*)object).lastUpdateDate];
			
			dateFormat.doesRelativeDateFormatting = YES;
			dateFormat.dateStyle = NSDateFormatterShortStyle;
			
			if (seconds != 0)
				dateFormat.timeStyle = NSDateFormatterMediumStyle;
			else
				dateFormat.timeStyle = NSDateFormatterShortStyle;
			
			lastUpdate = [dateFormat stringFromDate: ((WeatherStation*)object).lastUpdateDate];
			locationAndUpdate = [NSString stringWithFormat: @"%@ (%@)", ((WeatherStation*) object).locationDescription, lastUpdate];
			
			if ([self.wxStation isKindOfClass: [NWSWeatherStation class]])
				canShowInfo = YES;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.locationDescription setTitle: locationAndUpdate forState: canShowInfo ? UIControlStateNormal : UIControlStateDisabled];
				[self.locationDescription setEnabled: canShowInfo];
			});
		}
	}
	else if ([keyPath isEqualToString: @"error"])
	{
		if ([newValue isKindOfClass: [NSError class]])
		{
			NSError*	err = [change valueForKey: NSKeyValueChangeNewKey];
			NSString*	alertTitle = @"An Error Occurred.";
			
			if ([[err domain] isEqualToString: kCLErrorDomain])
				alertTitle = @"An Error Occurred Retrieving Your Location.";
			else if ([[err domain] isEqualToString: @"MESOWEST"])
				alertTitle = @"An Error Occurred Retrieving Weather Information.";
			UIAlertController*	alert = [UIAlertController alertControllerWithTitle: alertTitle message: [err localizedDescription] preferredStyle: UIAlertControllerStyleAlert];
			UIAlertAction*		dismissAction = [UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self dismissViewControllerAnimated: YES completion: NULL];
			}];
			
			[alert addAction: dismissAction];

			dispatch_async(dispatch_get_main_queue(), ^{ [self presentViewController: alert animated: YES completion: NULL]; });
		}
	}
}

@end
