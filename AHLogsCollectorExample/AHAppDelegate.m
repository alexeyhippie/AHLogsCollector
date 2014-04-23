//
//  AHAppDelegate.m
//  AHLogsCollectorExample
//
//  Created by Alexey Hippie on 23/04/14.
//  Copyright (c) 2014 AlexeyHippie. All rights reserved.
//

#import "AHAppDelegate.h"
#import "AHLogsCollector/AHLogsCollector.h"

@implementation AHAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [logger setCrashHandlers];
    [logger setShowInConsole:YES];
    [logger setLogsFileCapacity:10];
    [logger setInMemoryLogsCapacity:5];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    [logger saveLogs];
}

@end
