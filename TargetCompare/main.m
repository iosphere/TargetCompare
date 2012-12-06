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
        BOOL list = NO;
        int c;
        NSMutableArray *additionalArgs = [NSMutableArray array];
        NSString *firstTarget;
        NSString *secondTarget;
        NSString *plistPath;
        
        const struct option longopts[] = {
            { "cli",        no_argument,            NULL,           'c' },
            { "list",       no_argument,            NULL,           'l' },
            { "write",      required_argument,      NULL,           'w' },
            { "target1",    required_argument,      NULL,           'a' },
            { "target2",    required_argument,      NULL,           'b' },
            { NULL,         0,                      NULL,           0 }
        };

        BOOL error = NO;
        while (((c = getopt_long(argc, argv, "a:b:w:hl", longopts, NULL)) != -1) && !error) {
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
                case 'l':
                    list = YES;
                    break;
                case 'w':
                    plistPath = [NSString stringWithUTF8String:optarg];
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
            if (list) {
                return [controller echoTargetList];
            }
            if (plistPath) {
                return [controller writePlistWithAllResultsToPath:plistPath];
            }
            return [controller startComparsion];
        }
    }

    return NSApplicationMain(argc, (const char **)argv);

}

void printUsage() {
    fprintf(stderr, "usage: targetCompare -c [options] project-path\n");
    fprintf(stderr, "example: targetCompare -c -t1 testTarget -2 anotherTarget /path/to/proj.xcodeproj\n");
    fprintf(stderr, "example: targetCompare -c -w test.plist /path/to/proj.xcodeproj\n");
    fprintf(stderr, "Available options are:\n");
    fprintf(stderr, "\t-c  cli       Version number of sdk to use (-s 3.1)\n");
    fprintf(stderr, "\t-a  target1   Base target\n");
    fprintf(stderr, "\t-b  target2   Target to compare with\n");
    fprintf(stderr, "\t-l  list      \n");
    fprintf(stderr, "\t-w  write     Filename\n");
    fprintf(stderr, "\t-h            Prints out this wonderful documentation!\n");
}
