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

//7612 - transit mall southbound
//2626 - hawthorne & chavez westbound
//4316 - Tyler work eastbound
//13329 - Nick work
//2641 - hawthorne bridge eastbound
NSString* stopId = @"4316";

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
    [NSTimer scheduledTimerWithTimeInterval:30.0
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
    NSArray *arrivals = [[response objectForKey:@"resultSet"] objectForKey:@"arrival"];
    NSArray *location = [[response objectForKey:@"resultSet"] objectForKey:@"location"];
    
    // Loop through existing menu items and delete anything
    // up to our first separator.
    for (NSMenuItem *item in [statusMenu itemArray]){
        if(item.tag == kEndMinuteSeparator){
            break;
        } else {
            [statusMenu removeItem:item];
        }
    }
    
    NSString* title = @"";
    for (NSInteger i = [arrivals count] -  1; i >= 0; i--) {
        NSDictionary* arrival = arrivals[i];
        if ([arrival objectForKey:@"estimated"]) {
            double estimatedTime = [[arrival objectForKey:@"estimated"] doubleValue]/1000;
            NSDate* arrivalDate = [NSDate dateWithTimeIntervalSince1970:estimatedTime];
            double minutes = [arrivalDate timeIntervalSinceNow] / 60;
            if (minutes < 0) minutes = 0;
            
            NSMenuItem *item = [NSMenuItem alloc];
            //NSString *line = [NSString stringWithFormat:@"Bus %@", [arrival valueForKey:@"route"]];
            //NSString *eta = [NSString stringWithFormat:@"%.0lfm", minutes];

            
            if (minutes < 1) {
                [item setTitle:[NSString stringWithFormat:@"Bus %@ - due", [arrival valueForKey:@"route"]]];
            }
            else {
                [item setTitle:[NSString stringWithFormat:@"Bus %@ - %.0lfm", [arrival valueForKey:@"route"], minutes]];
                
                //trying to get alignment to work
                //[item setTitle:[[line stringByPaddingToLength: 16-[eta length] withString:@"-" startingAtIndex: 0] stringByAppendingString:eta]];
            }
            [statusMenu insertItem:item atIndex:0];
            
            title = item.title;
            [statusItem setTitle:title];
        }
    }
    
    NSMenuItem *stopIDMenuItem = [NSMenuItem alloc];//stop id in main menu with arrow and stop id label
    NSMenu *stopSubMenu = [NSMenu alloc];//submenu that opens when user clicks stopIDMenuItem
    NSMenuItem *stopDescriptionItem = [NSMenuItem alloc];//first item in stopSubMenu
    //NSString *scratch = [NSString stringWithFormat:@"%@",[location valueForKey:@"desc"]];
    
    [stopIDMenuItem setTitle:[NSString stringWithFormat:@"Stop ID: %@", stopId]];
    //trim parenths, newlines ,whitespaces and quotes from stop desc like: ( \n "stop desc" \n )
    [stopDescriptionItem setTitle:[
                                   [[[NSString stringWithFormat:@"%@",[location valueForKey:@"desc"]]
                                     stringByTrimmingCharactersInSet: [NSCharacterSet punctuationCharacterSet]            ]
                                    stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]   ]
                                   stringByTrimmingCharactersInSet: [NSCharacterSet punctuationCharacterSet]            ]
     ];
    
    [stopIDMenuItem setSubmenu:stopSubMenu];
    
    [stopSubMenu insertItemWithTitle:@"Watch list here" action:nil keyEquivalent:@"" atIndex:0];//dynamically generate this later
    [stopSubMenu insertItem:[NSMenuItem separatorItem] atIndex:0];//separator
    [stopSubMenu insertItem:stopDescriptionItem atIndex:0];//put in item with desc string as title
    
    //finish up writing to the main menu
    [statusMenu insertItem:[NSMenuItem separatorItem] atIndex:0];
    [statusMenu insertItem:stopIDMenuItem atIndex:0];//attach submenu item to main menu
}

- (IBAction)openPreferences:(id)sender {
    
}


@end
