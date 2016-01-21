//
//  WxStationSetupViewController.h
//  TisNobler
//
//  Created by Peter Merchant on 6/15/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TISensorTagDevice/TISensorTagDevice.h"

@interface WxStationSetupViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
@protected
	IBOutlet UITableView*	sensorTagTable;
}

@property (readwrite, strong, nonatomic) NSMutableArray*	weatherStations;

@end
