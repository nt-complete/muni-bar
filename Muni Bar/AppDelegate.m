//
//  AppDelegate.m
//  Muni Bar
//
//  Created by Andre Torrez on 2/26/13.
//  Copyright (c) 2013 Simpleform. All rights reserved.
//

#import "AppDelegate.h"
#define kEndMinuteSeparator 9

@implementation AppDelegate

NSString* stopId = @"13329";

- (void)awakeFromNib {
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setTitle:@"Loading…"];
    [statusItem setHighlightMode:YES];
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    minuteArray = [[NSMutableArray alloc] init];

    //Refresh data every 60 seconds.
    [NSTimer scheduledTimerWithTimeInterval:60.0
                                     target:self
                                   selector:@selector(loadPredictions:)
                                   userInfo:nil
                                    repeats:YES];

    //Do the first prediction loading.
    [self loadPredictions:nil];
}

-(IBAction)loadPredictions:(id)sender {
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"appkey" ofType:@"plist"];
    NSDictionary *configuration = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    NSString *appId = configuration[@"appkey"];
    
    
    NSURL *theURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://developer.trimet.org/ws/V2/arrivals?appID=%@&locIDs=%@", appId, stopId]];
    NSData *data = [NSData dataWithContentsOfURL:theURL];
    NSError *error = nil;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSLog(@"Loading predictions");
    NSArray     *arrivals = [[response objectForKey:@"resultSet"] objectForKey:@"arrival"];
    
    
    // Loop through existing menu items and delete anything
    // up to our first separator.
    for (NSMenuItem *item in [statusMenu itemArray]){
        if(item.tag == kEndMinuteSeparator){
            break;
        } else {
            [statusMenu removeItem:item];
        }
    }
    
    for (NSInteger i = 0; i < [arrivals count]; i++) {
        NSDictionary* arrival = arrivals[i];
        if ([arrival objectForKey:@"estimated"]) {
        double estimatedTime = [[arrival objectForKey:@"estimated"] doubleValue]/1000;
        NSDate* arrivalDate = [NSDate dateWithTimeIntervalSince1970:estimatedTime];
        double minutes = [arrivalDate timeIntervalSinceNow] / 60;
        
        NSMenuItem *item = [statusMenu insertItemWithTitle:[NSString stringWithFormat:@"Bus: %@ - %.0lfm", [arrival valueForKey:@"route"], minutes] action:nil keyEquivalent:@"" atIndex:i];
        
        //A sort-of hack to not receive a warning about the unused item variable.
        if(i == 0){
            [statusItem setTitle:item.title];
        }
        }
    }
}


@end
