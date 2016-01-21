//
//  WXStationSetupTableViewCell.h
//  TisNobler
//
//  Created by Peter Merchant on 6/19/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WxStationSetupTableViewCell : UITableViewCell
{
@protected
	IBOutlet UITextField*	_textField;
	IBOutlet UILabel*		_detailTextLabel;
}

@property (readonly, weak, nonatomic, getter=textField) UITextField* textField;
@property (readonly, weak, nonatomic, getter=detailTextLabel) UILabel* detailTextLabel;
@property (readonly, weak, nonatomic, getter=checkmarkButton) UIButton* checkmarkButton;
@property (readwrite, strong) NSMutableDictionary*	wxStation;

@end
