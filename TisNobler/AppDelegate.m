//
//  AppDelegate.m
//  TisNobler
//
//  Created by Peter Merchant on 5/29/15.
//  Copyright (c) 2015 Peter Merchant. All rights reserved.
//

#import "AppDelegate.h"

#import "WeatherStation.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{        
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"NSApplicationWillResignActive" object:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"NSApplicationDidBecomeActive" object:application];
}

@end
