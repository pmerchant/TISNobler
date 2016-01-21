//
//  Weather.h
//  
//
//  Created by Peter Merchant on 5/29/15.
//
//

#import <Foundation/Foundation.h>

@interface WeatherStation : NSObject

@property (readwrite, strong)	NSString*	locationDescription;
@property (readwrite, strong)	NSDate* lastUpdateDate;
@property (readwrite, assign)   int temperature;
@property (readwrite, assign)   unsigned int humidity;
@property (readwrite, assign)   double barometricPressure;
@property (readwrite, strong)	NSError* error;
- (id) init;

- (void) loadData;

@end
