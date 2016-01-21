//
//  WxStationSetupViewController.h
//  TisNobler
//
//  Created by Peter Merchant on 6/15/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "WxStationSetupViewController.h"

#import "WxStationSetupTableViewCell.h"

#import "TISensorTagDevice/TISensorTag.h"

@implementation WxStationSetupViewController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Weather Station Setup";
}

- (void) setWeatherStations: (NSMutableArray*) wxStations
{
	_weatherStations = wxStations;
}

- (IBAction) checkBoxHit: (id) sender
{
	NSInteger	row = ((UISwitch*) sender).tag;
	BOOL		value = ((UISwitch*) sender).isOn;
	
	NSMutableDictionary* wxStation = self.weatherStations[row];
	
	[wxStation setObject: [NSNumber numberWithBool: value] forKey: @"show"];
}

#pragma - TableView Datasource

- (UITableViewCell*) tableView: (UITableView*) tableView cellForRowAtIndexPath: (NSIndexPath*) indexPath
{
	WxStationSetupTableViewCell*	theCell = [tableView dequeueReusableCellWithIdentifier: @"wxStation"];
	
	NSAssert(theCell != NULL, @"Reusable cell not found!");
	
	UISwitch*				showWxStationSwitch = (UISwitch*) theCell.accessoryView;
	NSMutableDictionary*	wxStation = self.weatherStations[indexPath.row];
	
	theCell.textField.text = [wxStation objectForKey: @"name"];
	theCell.textField.delegate = self;
	theCell.textField.tag = indexPath.row;
	
	theCell.detailTextLabel.text = [wxStation objectForKey: @"identifier"];
	theCell.detailTextLabel.adjustsFontSizeToFitWidth = YES;

	NSNumber*	showWxStation = [wxStation objectForKey: @"show"];
	
	showWxStationSwitch.tag = indexPath.row;
	
	if (showWxStation && showWxStation.boolValue)
		showWxStationSwitch.on = YES;
	else
		showWxStationSwitch.on = NO;
	
	return theCell;
}

- (NSInteger) tableView: (UITableView*) tableView numberOfRowsInSection: (NSInteger) section
{
	return [self.weatherStations count];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

#pragma - Text Field Delegate

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
	[textField setSelectedTextRange: [textField textRangeFromPosition: textField.beginningOfDocument toPosition: textField.endOfDocument]];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	
	return YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
	NSInteger				row = textField.tag;
	NSString*				value = textField.text;
	NSMutableDictionary*	wxStation = self.weatherStations[row];
	
	[wxStation setObject: value forKey: @"name"];
}

@end
