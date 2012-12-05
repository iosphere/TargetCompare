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

- (int)start {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.projectPath]) {
        ISHSimpleLog(@"No project at %@", self.projectPath);
        return 1;
    }

    XCProject *project = [XCProject projectWithFilePath:self.projectPath];
    if (!project) {
        ISHSimpleLog(@"Cannot init project with %@", self.projectPath);
        return 1;
    }

    XCTarget *firstTarget = nil;
    XCTarget *secondTarget = nil;

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

void ISHSimpleLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat: format
                                                       arguments: args];
    va_end(args);
    
    [((NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput]) writeData:[[formattedString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
