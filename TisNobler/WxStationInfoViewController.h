//
//  WxStationInfoViewController.h
//  TisNobler
//
//  Created by Peter Merchant on 12/23/15.
//  Copyright © 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MapKit/MapKit.h>

#import "WeatherStation.h"
#import "UIViewSpeechBubble.h"

@interface WxStationInfoViewController : UIViewController <MKAnnotation, MKMapViewDelegate>
{
	IBOutlet UINavigationItem*		navBarTitle;
	IBOutlet MKMapView*				stationMapView;
	IBOutlet UIViewSpeechBubble*	annotationInfoView;
	IBOutlet UILabel*				annotationInfoStationName;
	IBOutlet UILabel*				annotationInfoStationNetwork;
	IBOutlet UILabel*				annotationInfoStationDistance;
}

@property (strong, readwrite, nonatomic, setter=setWxStation:) WeatherStation* wxStation;

- (IBAction) backButtonHit: (id) sender;

@end
