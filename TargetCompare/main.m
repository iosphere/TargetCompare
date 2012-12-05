//
//  main.m
//  TargetCompare
//
//  Created by Felix Lamouroux on 09.08.12.
//  Copyright (c) 2012 iosphere GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <getopt.h>
#import "ISHCommandLineController.h"

void printUsage(void);

int main(int argc, char *argv[])
{
    @autoreleasepool {
        BOOL cli = NO;
        int c;
        NSMutableArray *additionalArgs = [NSMutableArray array];
        NSString *firstTarget;
        NSString *secondTarget;
        
        const struct option longopts[] = {
            { "cli",        no_argument,            NULL,           'c' },
            { "target1",    required_argument,      NULL,           'a' },
            { "target2",    required_argument,      NULL,           'b' },
            { NULL,         0,                      NULL,           0 }
        };

        BOOL error = NO;
        while (((c = getopt_long(argc, argv, "a:b:h", longopts, NULL)) != -1) && !error) {
            switch(c) {
                case 'c':
                    cli = YES;
                    break;
                case 'h':
                    printUsage();
                    break;
                case 'a':
                    firstTarget = [NSString stringWithUTF8String:optarg];
                    break;
                case 'b':
                    secondTarget = [NSString stringWithUTF8String:optarg];
                    break;
                default:
                    NSLog(@"unknown cmdline option. falling back to GUI");
                    printUsage();
                    error = YES;
            }

        }

        if (argc > optind) {
            for (int i = optind; i < argc; i++) {
                [additionalArgs addObject:[NSString stringWithUTF8String:argv[i]]];
            }
        }
        
        if (cli) {
            ISHCommandLineController *controller = [ISHCommandLineController new];
            [controller setFirstTargetPath:firstTarget];
            [controller setSecondTargetPath:secondTarget];
            [controller setProjectPath:[additionalArgs objectAtIndex:0]];
            return [controller start];
        }
    }

    return NSApplicationMain(argc, (const char **)argv);

}

void printUsage() {
    fprintf(stderr, "usage: targetCompare -c [options] project-path\n");
    fprintf(stderr, "example: waxsim -c -t1 testTarget -2 anotherTarget /path/to/proj.xcodeproj\n");
    fprintf(stderr, "Available options are:\n");
    fprintf(stderr, "\t-c  cli      Version number of sdk to use (-s 3.1)\n");
    fprintf(stderr, "\t-a target1   Base target\n");
    fprintf(stderr, "\t-b target2   Target to compare with\n");
    fprintf(stderr, "\t-h           Prints out this wonderful documentation!\n");
}
