//
//  RootViewController.m
//  TisNobler
//
//  Created by Peter Merchant on 5/29/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "RootViewController.h"
#import "ModelController.h"

#import "TISensorTagDevice/TISensorTag.h"

@interface RootViewController ()

@property (readonly, strong, nonatomic) ModelController *modelController;
@end

@implementation RootViewController

@synthesize modelController = _modelController;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self setupWeatherStations];
	
	self.title = @"Root";
	self.navigationBarHidden = YES;
	self.delegate = self;
		
	self.sensorTagManager = [[TISensorTagManager alloc] init];
	[self.sensorTagManager addObserver: self forKeyPath: @"list" options: NSKeyValueObservingOptionNew context: NULL];
	[self.sensorTagManager startLooking];
	
	self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle: UIPageViewControllerTransitionStyleScroll navigationOrientation: UIPageViewControllerNavigationOrientationHorizontal options: NULL];
	self.pageViewController.dataSource = self.modelController;
	self.pageViewController.delegate = self.modelController;
	
	[self pushViewController: self.pageViewController animated: NO];

	self.setupViewController = [self.storyboard instantiateViewControllerWithIdentifier: @"WxStationSetupViewController"];
	self.setupViewController.weatherStations = weatherStations;

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(buttonPress:) name:@"buttonPress" object: NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (ModelController *)modelController
{
    // Return the model controller object, creating it if necessary.
    // In more complex implementations, the model controller may be passed to the view controller.
    if (!_modelController)
	{
        _modelController = [[ModelController alloc] init];
		_modelController.sensorTags = self.sensorTagManager;
    }
    return _modelController;
}

- (void) setupWeatherStations
{
	NSArray*	defaultStations = [[NSUserDefaults standardUserDefaults] arrayForKey: @"stations"];
	
	if (defaultStations == NULL)	// Initialize with just the NWS station
	{
		weatherStations = [[NSMutableArray alloc] init];
		
		NSMutableDictionary*	nwsWxStationDict = [NSMutableDictionary dictionary];
		
		nwsWxStationDict[@"show"] = @YES;
		nwsWxStationDict[@"name"] = @"MesoWest";
		nwsWxStationDict[@"class"] = @"NWSWeatherStation";
		nwsWxStationDict[@"identifier"] = @"MesoNet@Current";
		
		[weatherStations addObject: nwsWxStationDict];
	}
	else
	{
		weatherStations = [NSMutableArray array];
		
		NSDictionary*	eachStation;
		for (eachStation in defaultStations)
		{
			[weatherStations addObject: [eachStation mutableCopy]];
		}
	}
}

- (void) buttonPress: (NSNotification*) note
{
	// If the user presses button 1 on the TI SensorTag, bring up the setup view sheet so the user can change
	// the names of the devices.
	
	dispatch_async(dispatch_get_main_queue(), ^{ [self pushViewController: self.setupViewController animated: YES]; });
}

#pragma mark - KVO methods

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString: @"list"])
	{
		if ([[change objectForKey: NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeInsertion ||
			[[change objectForKey: NSKeyValueChangeKindKey] integerValue] == NSKeyValueChangeRemoval)
		{
			TISensorTag*	eachSensorTag;
			BOOL			newTagFound = NO;
			
			for (eachSensorTag in [change objectForKey: NSKeyValueChangeNewKey])
			{
				NSDictionary*	eachKnownWxStation;
				BOOL			wxStationKnown = NO;
				
				for (eachKnownWxStation in weatherStations)
				{
					NSString*	identifier = [[eachKnownWxStation[@"identifier"] componentsSeparatedByString: @"@"] objectAtIndex: 1];
					
					if ([identifier isEqualToString: eachSensorTag.identifier])
					{
						wxStationKnown = YES;
						break;
					}
				}
				
				if (! wxStationKnown)
				{
					NSMutableDictionary*	sensorTagWxStation = [NSMutableDictionary dictionary];
					
					sensorTagWxStation[@"show"] = @YES;
					sensorTagWxStation[@"name"] = eachSensorTag.name;
					sensorTagWxStation[@"identifier"] = [NSString stringWithFormat: @"SensorTag@%@", eachSensorTag.identifier];
					sensorTagWxStation[@"class"] = @"SensorTagWeatherStation";
					
					if (weatherStations.count > 0)
						[weatherStations insertObject: sensorTagWxStation atIndex: weatherStations.count - 1];
					else
						[weatherStations addObject: sensorTagWxStation];
					
					newTagFound = YES;
				}
			}
			
			if (newTagFound)
			{
				dispatch_async(dispatch_get_main_queue(), ^{ [self pushViewController: self.setupViewController animated: YES]; });
			}
			else
				dispatch_async(dispatch_get_main_queue(), ^{ [self.modelController reloadControllersForPageViewController: self.pageViewController storyboard: self.storyboard]; });
		}
	}
}


#pragma mark - Navigation Controller Delegate

- (void) navigationController: (UINavigationController*) navigationController willShowViewController: (UIViewController*) viewController animated: (BOOL) animated
{
	if (viewController == self.pageViewController)
	{
		self.navigationBarHidden = YES;

		[[NSUserDefaults standardUserDefaults] setObject: weatherStations forKey: @"stations"];
		
		[self.modelController reloadControllersForPageViewController: self.pageViewController storyboard: self.storyboard];
	}
	else if (viewController == self.setupViewController)
		self.navigationBarHidden = NO;
}

@end
