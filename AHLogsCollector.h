//
//  AHLogsCollector.h
//
//  Created by Alexey Hippie on 23/04/14.
//  Copyright (c) 2014 AlexeyHippie. All rights reserved.
//

#import <Foundation/Foundation.h>

#define logger [AHLogsCollector logsCollector]

#define AALog(__FORMAT__, ...) [logger logString:([NSString stringWithFormat:@"%s [Line %d] %@\n", __PRETTY_FUNCTION__, __LINE__,[NSString stringWithFormat:__FORMAT__, ##__VA_ARGS__]])];

#define AALog_c(aLogString, aShowInConsole) [logger logString:(aLogString) showInConsole:(aShowInConsole)];

#define AALogError(errorName, parameters) [logger logErrorWithName:(errorName) andInfoDict:(parameters)];

#define AALogError_c(errorName, parameters, aShowInConsole) [logger logErrorWithName:(errorName) andInfoDict:(parameters) showInConsole:(aShowInConsole)];

#define AALogNSError(error) [logger logError:(error)];

@interface AHLogsCollector : NSObject

+ (AHLogsCollector *)logsCollector;

#pragma mark - Configurations

/*
 Paths to files setters
 **/
- (void)setLogsFileName:(NSString *)logsFilePath;
- (void)setErrorsFileName:(NSString *)errorsFilePath;
- (void)setCrashesFileName:(NSString *)crashesFilePath;

/*
 Set maximum amount of records in logs file;
 Default is 10000 records;
 **/
- (void)setLogsFileCapacity:(NSInteger)capacity;

/*
 Set maximum amount of in-memory logs array;
 Default value is 1000 records; 
 When logs exceeds this limit logger will store it to file and reset in-memory array;
 **/
- (void)setInMemoryLogsCapacity:(NSInteger)capacity;

/*
 Set crash handlers to logger handlers; 
 Allow to store information about crash in logs
 and detect app crashing on next app running;
 **/
- (void)setCrashHandlers;

/*
 Duplicate log string in console; 
 NO by default;
 **/
- (void)setShowInConsole:(BOOL)showInConsole;

/* 
 Add to log string method name where logString was called;
 YES by default;
 **/
- (void)setAddMethodName:(BOOL)addMethodName;

/*
 Add to log string code line number and file name where logString was called;
 YES by default;
 **/
- (void)setAddCodeLine:(BOOL)addCodeLine;

- (NSString *)logsFilePath;
- (NSURL *)logsFileURL;
- (NSString *)errorsFilePath;
- (NSURL *)errorsFileURL;
- (NSString *)crashesFilePath;
- (NSURL *)crashesFileURL;

// functions
- (void)logString:(NSString *)logString;
- (void)logString:(NSString *)logString showInConsole:(BOOL)showInConsole;
- (void)logError:(NSError *)error;
- (void)logError:(NSError *)error showInConsole:(BOOL)showInConsole;
- (void)logErrorWithName:(NSString *)error andInfoDict:(NSDictionary *)errorInfo;
- (void)logErrorWithName:(NSString *)error
             andInfoDict:(NSDictionary *)errorInfo
           showInConsole:(BOOL)showInConsole;

/*
 Returns YES if crashes file not empty
 **/
- (BOOL)appCrashedLastTime;

// data getters
- (NSArray *)logs;
- (NSArray *)extractFirst:(NSInteger)firstRecordsCount;
- (NSArray *)extractLast:(NSInteger)lastRecordsCount;


/*
 Saves logs to default logs file
 **/
- (BOOL)saveLogs;
- (BOOL)saveLogsToFile:(NSString *)filePath;
- (BOOL)saveLogsToFileWithURL:(NSURL *)fileURL;

- (BOOL)removeLogs;
- (BOOL)removeLogsFromFile:(NSString *)filePath;
- (BOOL)removeLogsFromURL:(NSURL *)fileURL;

- (BOOL)removeErrors;
- (BOOL)removeCrashes;

@end
