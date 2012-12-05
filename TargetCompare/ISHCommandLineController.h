//
//  ISHCommandLineController.h
//  TargetCompare
//
//  Created by Felix Schneider on 04.12.12.
//  Copyright (c) 2012 iosphere GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISHCommandLineController : NSObject

@property (strong) NSString *projectPath;
@property (strong) NSString *firstTargetPath;
@property (strong) NSString *secondTargetPath;

- (int)start;

@end
