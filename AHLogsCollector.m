//
//  AHLogsCollector.m
//
//  Created by Alexey Hippie on 23/04/14.
//  Copyright (c) 2014 AlexeyHippie. All rights reserved.
//

#import "AHLogsCollector.h"

@interface AHLogsCollector ()

@property (nonatomic) NSMutableArray *logsArray;

@property (nonatomic) NSString * logsFilePath;
@property (nonatomic) NSString * errorsFilePath;
@property (nonatomic) NSString * crashesFilePath;

@property (nonatomic) NSInteger logsFileCapacity;
@property (nonatomic) NSInteger inMemoryCapacity;

@property (nonatomic) BOOL addMethodName;
@property (nonatomic) BOOL addCodeLine;
@property (nonatomic) BOOL showInConsole;

@end

@implementation AHLogsCollector

static NSInteger const kDefaultLogsFileCapacity = 10000;
static NSInteger const kDefaultInMemoryCapacity = 1000;

static NSString * const kDefaultLogsDirectory = @"LogsCollector";
static NSString * const kDefaultLogsFileName = @"logs.log";
static NSString * const kDefaultErrorsFileName = @"errors.log";
static NSString * const kDefaultCrashesFileName = @"crashes.log";

static NSString * const kAppCrashedKey = @"appCrashed";

+ (AHLogsCollector *)sharedInstance {
    static dispatch_once_t pred;
    static AHLogsCollector *logsCollector = nil;
    dispatch_once(&pred, ^{
        logsCollector = [[AHLogsCollector alloc] init];
    });
    
    return logsCollector;
}

- (id)init {
    self = [super init];
    if (self) {
        _logsArray = [NSMutableArray array];
        
        _logsFileCapacity = kDefaultLogsFileCapacity;
        _inMemoryCapacity = kDefaultInMemoryCapacity;
        
        // store in cache directory
        NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *logsDir = [[pathList objectAtIndex:0] stringByAppendingPathComponent:kDefaultLogsDirectory];
        if (![[NSFileManager defaultManager] fileExistsAtPath:logsDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:logsDir
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
        }
        
        _logsFilePath = [logsDir stringByAppendingPathComponent:kDefaultLogsFileName];
        _errorsFilePath = [logsDir stringByAppendingPathComponent:kDefaultErrorsFileName];
        _crashesFilePath = [logsDir stringByAppendingPathComponent:kDefaultCrashesFileName];
        
        _addMethodName = YES;
        _addCodeLine = YES;
        _showInConsole = NO;
    }
    
    return self;
}


#pragma mark - Configurations


- (void)setLogsFileName:(NSString *)logsFilePath {
    logsFilePath = [self trim:logsFilePath];
    if (logsFilePath && [logsFilePath isEqualToString:@""]) {
        _logsFilePath = logsFilePath;
    }
}

- (void)setErrorsFileName:(NSString *)errorsFilePath {
    errorsFilePath = [self trim:errorsFilePath];
    if (errorsFilePath && [errorsFilePath isEqualToString:@""]) {
        _errorsFilePath = errorsFilePath;
    }
}

- (void)setCrashesFileName:(NSString *)crashesFilePath {
    crashesFilePath = [self trim:crashesFilePath];
    if (crashesFilePath && [crashesFilePath isEqualToString:@""]) {
        _crashesFilePath = crashesFilePath;
    }
}

- (void)setLogsFileCapacity:(NSInteger)capacity {
    if (capacity > 0) {
        _logsFileCapacity = capacity;
    }
}

- (void)setInMemoryLogsCapacity:(NSInteger)capacity {
    if (capacity > 0) {
        _inMemoryCapacity = capacity;
    }
}

- (void)setCrashHandlers {
    NSSetUncaughtExceptionHandler(&HandleException);
    
    signal(SIGABRT, HandleSignal);
    signal(SIGILL, HandleSignal);
    signal(SIGSEGV, HandleSignal);
    signal(SIGFPE, HandleSignal);
    signal(SIGBUS, HandleSignal);
    signal(SIGPIPE, HandleSignal);
}

- (void)setShowInConsole:(BOOL)showInConsole {
    _showInConsole = showInConsole;
}

- (void)setAddMethodName:(BOOL)addMethodName {
    _addMethodName = addMethodName;
}

- (void)setAddCodeLine:(BOOL)addCodeLine {
    _addCodeLine = addCodeLine;
}

- (NSString *)logsFilePath {
    return _logsFilePath;
}

- (NSURL *)logsFileURL {
    return [NSURL URLWithString:_logsFilePath];
}

- (NSString *)errorsFilePath {
    return _errorsFilePath;
}

- (NSURL *)errorsFileURL {
    return [NSURL URLWithString:_errorsFilePath];
}

- (NSString *)crashesFilePath {
    return _crashesFilePath;
}

- (NSURL *)crashesFileURL {
    return [NSURL URLWithString:_crashesFilePath];
}

#pragma mark - Functions

- (void)logString:(NSString *)logString {
    [self logString:logString showInConsole:self.showInConsole];
}

- (void)logString:(NSString *)logString showInConsole:(BOOL)showInConsole {
    if (logString) {
        NSString *logRecord = [NSString stringWithFormat:@"%@: %@ \n", [NSDate date], logString];
        if (logString) {
            @synchronized(self) {
                [self.logsArray addObject:logRecord];
            }
        }
    }
    
    // save and clean logs every kLogsInMemoryRecordLimit records
    if ([self.logsArray count] >= self.inMemoryCapacity) {
        BOOL saved = [self saveLogs];
        if (saved) {
            [self resetLog];
        }
    }
    
    // console
    if (showInConsole) {
        NSLog(@"%@", logString);
    }
}

- (void)logError:(NSError *)error {
    [self logError:error showInConsole:self.showInConsole];
}

- (void)logError:(NSError *)error showInConsole:(BOOL)showInConsole {
    if (error) {
        [self logErrorWithName:error.localizedDescription
                   andInfoDict:error.userInfo
                 showInConsole:showInConsole];
    }
}

- (void)logErrorWithName:(NSString *)error andInfoDict:(NSDictionary *)errorInfo {
    [self logErrorWithName:error
               andInfoDict:errorInfo
             showInConsole:self.showInConsole];
}

- (void)logErrorWithName:(NSString *)error
             andInfoDict:(NSDictionary *)errorInfo
           showInConsole:(BOOL)showInConsole {
    
    // compose log string
    NSString *errorStr = @"!--!--!--!--!--!--!--!ERROR!--!--!--!--!--!--!--!";
    errorStr = [errorStr stringByAppendingFormat:@"\n%@\n%@\n\nParameters:\n", [NSDate date], error];
    
    for (NSString *key in errorInfo.allKeys) {
        errorStr = [errorStr stringByAppendingFormat:@"%@: %@\n", key, [errorInfo objectForKey:key]];
    }
    
    errorStr = [errorStr stringByAppendingFormat:@"\nBacktrace:\n%@\n", [NSThread callStackSymbols]];
    
    errorStr = [errorStr stringByAppendingFormat:@"\n!--!--!--!--!--!--!--!ERROR!--!--!--!--!--!--!--!"];
    
    [self addAppErrorToErrorFile:errorStr];
    
    if (showInConsole) {
        NSLog(@"%@", errorStr);
    }
}

- (BOOL)appCrashedLastTime {
    BOOL crashed = getAppCrashed();
    if (crashed) {
        resetAppCrashed();
    };
    
    return crashed;
}

// data getters
- (NSArray *)logs {
    return [NSArray arrayWithArray:_logsArray];
}

// TODO: implement
- (NSArray *)extractFirst:(NSInteger)firstRecordsCount {
    return @[];
}

// TODO: implement
- (NSArray *)extractLast:(NSInteger)lastRecordsCount {
    return @[];
}

- (BOOL)saveLogs {
    BOOL result = NO;
    
    result = [self saveLogsToFile:self.logsFilePath];
    
    return result;
}

- (BOOL)saveLogsToFile:(NSString *)filePath {
    BOOL result = NO;
    
    filePath = [self trim:filePath];
    if (filePath && ![filePath isEqualToString:@""]) {
        NSMutableArray *storedLogs = [NSMutableArray arrayWithContentsOfFile:filePath];
        if (!storedLogs) {
            storedLogs = [NSMutableArray arrayWithArray:@[]];
        }
        
        NSArray *logsToAdd = self.logs;
        if (logsToAdd) {
            // if logs array contain more records that logs file capacity then
            // we no need to merge it, just replace with new records
            if ([logsToAdd count] >= self.logsFileCapacity) {
                storedLogs = [NSMutableArray arrayWithArray:logsToAdd];
            } else {
                [storedLogs addObjectsFromArray:logsToAdd];
            }
        }
        
        // adjust with capacity
        if ([storedLogs count] > self.logsFileCapacity) {
            // remove strings if needed
            [storedLogs removeObjectsInRange:NSMakeRange(0, [storedLogs count] - self.logsFileCapacity)];
        }
        
        result = [storedLogs writeToFile:filePath atomically:YES];
        if (result) {
            [self resetLog];
        } else {
            NSLog(@"LogCollector error");
        }
    
    } else {
        NSLog(@"LogCollector error: wrong logs file path");
    }
    
    return result;
}

- (BOOL)saveLogsToFileWithURL:(NSURL *)fileURL {
    BOOL result = NO;
    
    NSError *error;
    NSString *filePath = [NSString stringWithContentsOfURL:fileURL
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (error) {
        NSLog(@"LogCollector error: Error with URL (%@): \n%@", fileURL, error);
    } else {
        result = [self saveLogsToFile:filePath];
    }

    return result;
}


- (BOOL)removeLogs {
    BOOL result = NO;
    
    result = [self removeLogsFromFile:self.logsFilePath];
    
    return result;
}

- (BOOL)removeLogsFromFile:(NSString *)filePath {
    BOOL result = NO;
    
    NSString *logPath = [self trim:filePath];
    if ([self fileExist:logPath]) {
        NSError *error;
        result = [self removeFileByPath:logPath error:&error];
    }
    
    return result;
}

- (BOOL)removeLogsFromURL:(NSURL *)fileURL {
    BOOL result = NO;
    
    NSError *error;
    NSString *path = [NSString stringWithContentsOfURL:fileURL
                                              encoding:NSUTF8StringEncoding
                                                 error:&error];
    if (error) {
        NSLog(@"LogCollector error: Error with URL (%@): \n%@", fileURL, error);
    } else {
        result = [self removeLogsFromFile:path];
    }
    
    return result;
}

- (BOOL)removeErrors {
    BOOL result = NO;
    
    if ([self fileExist:self.errorsFilePath]) {
        NSError *error;
        result = [self removeFileByPath:self.errorsFilePath error:&error];
        if (error) {
            NSLog(@"LogCollector error: error with error file removing :) \n%@", error);
        }
    }
    
    return result;
}

- (BOOL)removeCrashes {
    BOOL result = NO;
    
    if ([self fileExist:self.crashesFilePath]) {
        NSError *error;
        result = [self removeFileByPath:self.crashesFilePath error:&error];
        if (error) {
            NSLog(@"LogCollector error: error with crashes file removing \n%@", error);
        }
    }
    
    return result;
}

#pragma mark - Internals

- (void)resetLog {
    self.logsArray = [NSMutableArray array];
}

void saveAppCrashed() {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:@(YES) forKey:kAppCrashedKey];
    [defs synchronize];
}

void resetAppCrashed() {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:@(NO) forKey:kAppCrashedKey];
    [defs synchronize];
}

BOOL getAppCrashed() {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:kAppCrashedKey] boolValue];
}

#pragma mark - Crash detection
// TODO: check
void HandleException(NSException *exception) {
    AALog(@"\n\n   !!!  App crashed  !!!\n");
    saveAppCrashed();
    NSString *exceptionString = [logger exceptionToString:exception];
    [logger addAppCrashToCrashesFile:exceptionString];
    AALog(@"%@", exceptionString);
    [logger saveLogs];
    if (!logger.showInConsole) {
        NSLog(@"%@", exceptionString);
    }
    exit(0);
}

// TODO: check
void HandleSignal(int signal) {
    AALog(@"\nCRASH! App crashed\n\nWe received a signal: %d\n\n", signal);
    saveAppCrashed();
    NSString *backtrace = [NSString stringWithFormat:@"%@\n%@", [NSDate date], [NSThread callStackSymbols]];
    [logger addAppCrashToCrashesFile:backtrace];
    AALog(@"%@", backtrace);
    [logger saveLogs];
    if (!logger.showInConsole) {
        NSLog(@"\n%@\n", backtrace);
    }
}

#pragma mark - Filework

- (BOOL)fileExist:(NSString *)filePath {
    BOOL isDir;
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    
    return (exist && !isDir);
}

- (BOOL)dirExist:(NSString *)filePath {
    BOOL isDir;
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
    
    return (exist && isDir);
}

- (BOOL)removeFileByPath:(NSString *)path error:(NSError **)error {
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    return [fileMgr removeItemAtPath:path error:error];
}

- (void)addAppCrashExceptionToExceptionSummary:(NSException *)exception {
    NSString *exceptionLog = [self exceptionToString:exception];
    [self addAppCrashToCrashesFile:exceptionLog];
}

- (void)addAppCrashToCrashesFile:(NSString *)crashString {
    NSError *error = nil;
    NSMutableString *summary = [NSMutableString string];
    if ([self fileExist:self.crashesFilePath]) {
        [summary appendString:[NSString stringWithContentsOfFile:self.crashesFilePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:&error]];
        
        if (error) {
            NSLog(@"LogCollector error: fail read from file:\nfile path: %@", self.crashesFilePath);
        }
    }
    
    if (!error) {
        [summary appendFormat:@"\n\n ----------------------------------\n\n%@", crashString];
        [summary writeToFile:self.crashesFilePath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
        
        if (error) {
            NSLog(@"LogCollector error: fail write to file:\nfile path: %@\nString: %@", self.crashesFilePath, summary);
        }
    }
}

- (void)addAppErrorToErrorFile:(NSString *)errorString {
    NSError *error = nil;
    NSMutableString *summary = [NSMutableString string];
    if ([self fileExist:self.errorsFilePath]) {
        [summary appendString:[NSString stringWithContentsOfFile:self.errorsFilePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:&error]];
        
        if (error) {
            NSLog(@"LogCollector error: fail read from file:\nfile path: %@", self.errorsFilePath);
        }
    }
    
    if (!error) {
        [summary appendFormat:@"\n\n ----------------------------------\n\n%@", errorString];
        [summary writeToFile:self.errorsFilePath
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];
        
        if (error) {
            NSLog(@"LogCollector error: fail write to file:\nfile path: %@\nString: %@", self.crashesFilePath, summary);
        }
    }
}

#pragma mark - Utils

- (NSString *)exceptionToString:(NSException *)exception {
    NSMutableString *exceptionLog = [NSMutableString string];
    [exceptionLog appendFormat:@"Exception date: %@\n", [NSDate date]];
    [exceptionLog appendFormat:@"Infos\nName: %@\n", exception.name];
    [exceptionLog appendFormat:@"Reason: %@\n", exception.reason];
    [exceptionLog appendFormat:@"UserInfo: %@\n", exception.userInfo];
    [exceptionLog appendFormat:@"Backtrace: %@\n", [exception callStackReturnAddresses]];
    [exceptionLog appendFormat:@"Stack symbols: %@\n", [exception callStackSymbols]];
    [exceptionLog appendFormat:@"other: %@\n", exception];
    
    return exceptionLog;
}

- (NSString *)trim:(NSString *)astring {
    return [astring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
