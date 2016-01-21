//
//  WxStationInfoViewController.m
//  TisNobler
//
//  Created by Peter Merchant on 12/23/15.
//  Copyright © 2015 Peter Merchant. All rights reserved.
//

#import "WxStationInfoViewController.h"

#import "NWSWeatherStation.h"

@implementation WxStationInfoViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	if (self.wxStation)
	{
		stationMapView.delegate = self;
		[stationMapView addAnnotation: self];
	
		[stationMapView.userLocation addObserver: self forKeyPath: @"location" options: NSKeyValueObservingOptionNew context: NULL];
		NSString*	titleFormatString = [navBarTitle.title copy];
		navBarTitle.title = [NSString stringWithFormat: titleFormatString, self.wxStation.locationDescription];
		navBarTitle.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone target: self action:@selector(backButtonHit:)];
		navBarTitle.hidesBackButton = NO;
	}
}

- (void) setWxStation: (WeatherStation*) newWxStation
{
	if ([newWxStation isKindOfClass: [NWSWeatherStation class]])
	{
		_wxStation = newWxStation;
	}
}

- (IBAction) backButtonHit: (id) sender
{	
	[self dismissViewControllerAnimated: YES completion: NULL];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context
{
	if ([keyPath isEqualToString: @"location"])
	{
		[stationMapView.userLocation removeObserver: self forKeyPath: @"location"];
		
		CLLocationCoordinate2D stationCoordinate = ((NWSWeatherStation*) self.wxStation).location.coordinate;
		
		CLLocation*	myLocation = change[NSKeyValueChangeNewKey];
		
		//		CLLocationCoordinate2D myLocation = mapView.userLocation.location.coordinate;
		
		MKCoordinateSpan span = MKCoordinateSpanMake(fabs(stationCoordinate.latitude - myLocation.coordinate.latitude) * 2.15, fabs(stationCoordinate.longitude - myLocation.coordinate.longitude) * 2.15);
		
		[stationMapView setRegion: [stationMapView regionThatFits: MKCoordinateRegionMake(stationCoordinate, span)] animated: YES];
	}
}

#pragma mark - MKAnnotation Protocol methods

- (CLLocationCoordinate2D) coordinate
{
	return ((NWSWeatherStation*)self.wxStation).location.coordinate;
}

- (NSString*) title
{
	return ((NWSWeatherStation*)self.wxStation).locationDescription;
}

- (NSString*) subtitle
{
	return ((NWSWeatherStation*)self.wxStation).networkName;
}

#pragma mark - MKMapViewDelegate protocol methods

- (MKAnnotationView*) mapView: (MKMapView*) mapView viewForAnnotation: (id<MKAnnotation>) annotation
{
	if ([annotation isKindOfClass: [MKUserLocation class]])	// Use default view for the user's location
		return NULL;
	
	MKPinAnnotationView*	pinView = [[MKPinAnnotationView alloc] initWithAnnotation: self reuseIdentifier: NULL];

	pinView.pinColor = MKPinAnnotationColorPurple;
	pinView.canShowCallout = NO;
	
	return pinView;
}

- (void) mapView:(MKMapView*) mapView didSelectAnnotationView: (MKAnnotationView*) view
{
	if ([view isKindOfClass: [MKPinAnnotationView class]])
	{
		double_t	metersDistant = [((NWSWeatherStation*)self.wxStation).location distanceFromLocation: mapView.userLocation.location];
		double_t	distance = metersDistant * 3.2808399;	// Convert to feet
		NSString*	distanceUnits;
		
		if (distance >= 528)	// More than a tenth of a mile?
		{
			distance /= 5280;
			distanceUnits = @"miles";
		}
		else
			distanceUnits = @"feet";
		
		CGRect	infoFrame = annotationInfoView.frame;

		infoFrame.origin.x = (mapView.frame.origin.x - view.frame.origin.x) + 10;
		infoFrame.origin.y = view.bounds.origin.y - annotationInfoView.bounds.size.height;
		infoFrame.size.width = mapView.bounds.size.width - 20;
		
		annotationInfoView.frame = infoFrame;
		annotationInfoView.triangleVertexOffset = (view.frame.origin.x + (view.bounds.size.width / 4)) - 10;
		annotationInfoView.alpha = 0.0;
		
		annotationInfoStationName.text = ((NWSWeatherStation*)self.wxStation).locationDescription;
		annotationInfoStationNetwork.text = ((NWSWeatherStation*)self.wxStation).networkName;
		annotationInfoStationDistance.text = [NSString stringWithFormat: @"%.1f %@", distance, distanceUnits];
		[annotationInfoStationName sizeToFit];
		[annotationInfoStationNetwork sizeToFit];
		
		[view addSubview: annotationInfoView];
		[UIView animateWithDuration: 0.1 animations: ^{ annotationInfoView.alpha = 1.0; }];
	}
}

- (void) mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
	CGFloat	tempAlpha = annotationInfoView.alpha;
	
	[UIView animateWithDuration: 0.1 animations: ^{ annotationInfoView.alpha = 0; } completion: ^(BOOL finished){ [annotationInfoView removeFromSuperview]; annotationInfoView.alpha = tempAlpha; }];
}

@end
