//
//  ISHCommandLineController.m
//  TargetCompare
//
//  Created by Felix Schneider on 04.12.12.
//  Copyright (c) 2012 iosphere GmbH. All rights reserved.
//

#import "ISHCommandLineController.h"
#import "ISHTargetsComparisonController.h"
#import <XcodeEditor/XCProject.h>
#import <XcodeEditor/XCTarget.h>

@implementation ISHCommandLineController

- (int)startComparsion {
    XCTarget *firstTarget = nil;
    XCTarget *secondTarget = nil;

    XCProject *project = [self getCurrentProject];

    if (!project) {
        ISHSimpleLog(@"Cannot init project with %@", self.projectPath);
        return 1;
    }

    for (XCTarget *aTarget in project.targets) {
        if ([aTarget.name isEqualToString:self.firstTargetPath]) {
            firstTarget = aTarget;
        } else if ([aTarget.name isEqualToString:self.secondTargetPath]) {
            secondTarget = aTarget;
        }
    }

    if (!firstTarget) {
        ISHSimpleLog(@"first target is missing (%@)", self.firstTargetPath);
        return 1;
    }

    if (!secondTarget) {
        ISHSimpleLog(@"first target is missing (%@)", self.secondTargetPath);
        return 1;
    }

    NSArray *absolutePaths = [ISHTargetsComparisonController arrayWithAbolutePathsInProject:project];
    if (absolutePaths.count) {
        for (NSString *aString in absolutePaths) {
            ISHSimpleLog(@"Absolute Path: %@", aString);
        }
    }

    ISHTargetsComparisonController *controller = [[ISHTargetsComparisonController alloc] initWithLeftTarget:firstTarget rightTarget:secondTarget];
    [controller startComparsion];

    ISHSimpleLog(@"%@", controller.membersMissingInTargetLeft);
    ISHSimpleLog(@"%@", controller.membersMissingInTargetRight);
    
    return 0;
}

- (int)echoTargetList {
    XCProject *project = [self getCurrentProject];

    if (!project) {
        ISHSimpleLog(@"Cannot init project with %@", self.projectPath);
        return 1;
    }

    for (XCTarget *aTarget in project.targets) {
        ISHSimpleLog(@"%@", aTarget.name);
    }

    return 0;
}

- (int)writePlistWithAllResultsToPath:(NSString *)path {
    XCProject *project = [self getCurrentProject];

    if (!project) {
        ISHSimpleLog(@"Cannot init project with %@", self.projectPath);
        return 1;
    }

    NSMutableArray *targets = [NSMutableArray new];
    for (XCTarget *aTarget in project.targets) {
        [targets addObject:aTarget.name];
    }

    NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(compare:)]];
    [targets sortUsingDescriptors:sortDescriptors];
    
    NSMutableArray *helper = [targets mutableCopy];

    NSMutableArray *targetsA = [NSMutableArray new];
    NSMutableArray *targetsB = [NSMutableArray new];

    for (NSString *aTarget in targets) {
        NSString *currentTargetInHelper = nil;
        for (NSString *aString in helper) {
            if ([aString isEqualToString:aTarget]) {
                currentTargetInHelper = aString;
                break;
            }
        }
        [helper removeObject:currentTargetInHelper];

        for (NSString *aString in helper) {
            [targetsA addObject:aTarget];
            [targetsB addObject:aString];
        }
    }
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];

    int i = 0;
    NSMutableString *sortedDiff = [NSMutableString new];
    NSString *delim = @"#################\n";

    for (NSString *targetLeft in targetsA) {
        NSString *targetRight = [targetsB objectAtIndex:i];
        if ([targetLeft isEqualToString:targetRight]) {
            continue;
        }
        [sortedDiff appendFormat:@"%@# targets: %@ - %@\n%@", delim, targetLeft, targetRight, delim];

        ISHTargetsComparisonController *controller = [[ISHTargetsComparisonController alloc] initWithLeftTarget:[project targetWithName:targetLeft] rightTarget:[project targetWithName:targetRight]];
        [controller startComparsion];

        NSArray *missingLeft = [controller.membersMissingInTargetLeft sortedArrayUsingDescriptors:sortDescriptors]?:@[];
        NSArray *missingRight = [controller.membersMissingInTargetRight sortedArrayUsingDescriptors:sortDescriptors]?:@[];
        
        [results setObject:@{
                             targetLeft : missingLeft,
                             targetRight: missingRight,
                             }
                    forKey:[NSString stringWithFormat:@"%@, %@", targetLeft, targetRight]];
        
        [sortedDiff appendFormat:@"%@# not in target: %@\n%@", delim, targetLeft, delim];
        [sortedDiff appendString:[missingLeft componentsJoinedByString:@"\n"]];
        [sortedDiff appendString:@"\n"];
        [sortedDiff appendFormat:@"%@# not in target: %@\n%@", delim, targetRight, delim];
        [sortedDiff appendString:[missingRight componentsJoinedByString:@"\n"]];
        [sortedDiff appendString:@"\n"];

        i++;
    }

    [results writeToFile:path atomically:YES];
    [sortedDiff writeToFile:[[path stringByDeletingPathExtension] stringByAppendingString:@"_sorted.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    return 0;
}

- (XCProject *)getCurrentProject {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.projectPath]) {
        ISHSimpleLog(@"No project at %@", self.projectPath);
        return nil;
    }

    XCProject *project = [XCProject projectWithFilePath:self.projectPath];
    return project;
}

void ISHSimpleLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat: format
                                                       arguments: args];
    va_end(args);
    
    [((NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput]) writeData:[[formattedString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
