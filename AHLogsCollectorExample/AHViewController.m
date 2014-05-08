//
//  AHViewController.m
//  AHLogsCollectorExample
//
//  Created by Alexey Hippie on 23/04/14.
//  Copyright (c) 2014 AlexeyHippie. All rights reserved.
//

#import "AHViewController.h"
#import "AHLogsCollector.h"

@interface AHViewController ()

@end

@implementation AHViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL isAppCrashed = [logger appCrashedLastTime];
    if (isAppCrashed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                        message:@"App crashed last time"
                                                       delegate:nil
                                              cancelButtonTitle:@"Got it"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)duplicateLogsSwitchChanged:(id)sender {
    UISwitch *aswitch = (UISwitch *)sender;
    BOOL on = aswitch.on;
    NSString *status = @"off";
    if (on) {
        status = @"on";
    }
    
    [logger setShowInConsole:aswitch.on];
    
    AALog(@"Duplicate logs is %@", status);
}

- (IBAction)addLogStringButtonTapped:(id)sender {
    AALog(@"Simple log string");
}

- (IBAction)addLogStringInConsoleButtonTapped:(id)sender {
    AALog_c(@"This log string will appear in console anyway", YES);
}

- (IBAction)addErrorButtonTapped:(id)sender {
    NSDictionary *info = @{NSLocalizedFailureReasonErrorKey:@"no one knows",
                           NSLocalizedRecoveryOptionsErrorKey: @"restart your computer"};
    AALogError(@"Simple error", info);
}

- (IBAction)saveLogsButtonTapped:(id)sender {
    [logger saveLogs];
    
    NSLog(@"Saved!");
}

- (IBAction)crashAppButtonTapped:(id)sender {
    NSArray *a = @[];
    NSLog(@"crash me %@", a[666]);
}

- (IBAction)removeLogsButtonTapped:(id)sender {
    [logger removeLogs];
    [logger removeErrors];
    [logger removeCrashes];
    
    NSLog(@"Removed!");
}

- (IBAction)showLogsButtonTapped:(id)sender {
    NSString *storedLogs = [NSString stringWithContentsOfFile:logger.logsFilePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    NSLog(@"LOGS:\n%@\n\n", storedLogs);
    
    NSString *storedErrors = [NSString stringWithContentsOfFile:logger.errorsFilePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    NSLog(@"ERRORS:\n%@\n\n", storedErrors);
    
    NSString *storedCrashes = [NSString stringWithContentsOfFile:logger.crashesFilePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    NSLog(@"CRASHES:\n%@\n\n", storedCrashes);
}

@end
