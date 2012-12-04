//
//  ISHTargetsTableViewController.m
//  TargetCompare
//
//  Created by Felix Lamouroux on 09.08.12.
//  Copyright (c) 2012 iosphere GmbH. All rights reserved.
//

#import "ISHTargetsTableViewController.h"
#import <XcodeEditor/XCProject.h>
#import <XcodeEditor/XCSourceFile.h>

NSString const *kUserDefaultsPathKey = @"ISHUserDefaultsPathKey";

@interface ISHTargetsTableViewController ()
@property (strong) NSString * projectFilePath;
@property (strong) XCProject *project;
@end

@implementation ISHTargetsTableViewController

-(void)awakeFromNib {
    // reset project file path from defaults
    [self setProjectFilePath:[[NSUserDefaults standardUserDefaults] stringForKey:(NSString *)kUserDefaultsPathKey]];
    
    [self updateButtonsStates];
    
    if (self.projectFilePath) {        
        // if project is not empty set the path text field
        [self.filePathTextField setStringValue:self.projectFilePath];
        // read project
        [self readProject:self.readProjectButton];
    }
}

- (void)updateButtonsStates {
    // read button is enabled if project file path has length
    [self.readProjectButton setEnabled:[[self projectFilePath] length]];
    
    // comparison button should only be enabled if two different targets are selected
    NSInteger selectedIndexLeft = [self.targetsTableViewLeft selectedRow];
    NSInteger selectedIndexRight = [self.targetsTableViewRight selectedRow];
    
    BOOL comparisonPossible = (selectedIndexLeft >= 0 && selectedIndexRight >= 0 && selectedIndexLeft != selectedIndexRight);
    
    [self.startComparisonButton setEnabled:comparisonPossible];
}

- (IBAction)selectFilePath:(id)sender {
    NSInteger result = 0;
    NSArray *fileTypes = [NSArray arrayWithObject:@"xcodeproj"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setAllowedFileTypes:fileTypes];
    result = [oPanel runModal];
    
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel URLs];
        NSUInteger count = [filesToOpen count];
        
        for (int i = 0; i < count; i++) {
            NSURL *selectedUrl = [filesToOpen objectAtIndex:i];
            NSString *aFile = [selectedUrl relativePath];
            
            // set file path of project
            [self setProjectFilePath:aFile];
            // show in text field
            [self.filePathTextField setStringValue:aFile];
            // make it persistent via userdefaults
            [[NSUserDefaults standardUserDefaults] setObject:aFile forKey:(NSString *)kUserDefaultsPathKey];
        }
    }
    
    [self readProject:self.readProjectButton];
    
    [self updateButtonsStates];
}

- (IBAction)readProject:(id)sender {
    if (!self.projectFilePath) {
        return;
    }
    
    // get project from path
    XCProject *project = [XCProject projectWithFilePath:self.projectFilePath];
    
    [self setProject:project];
    
    // reload target table view (will fetch targets from project)
    [self.targetsTableViewLeft reloadData];
    [self.targetsTableViewRight reloadData];
    [self updateButtonsStates];
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.project.targets.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString *name = [[self.project.targets objectAtIndex:rowIndex] name];
    
    return name;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self updateButtonsStates];
}

- (IBAction)startComparison:(id)sender {

    NSInteger selectedIndexLeft = [self.targetsTableViewLeft selectedRow];
    NSInteger selectedIndexRight = [self.targetsTableViewRight selectedRow];

    XCTarget *targetLeft = [self targetAtIndex:selectedIndexLeft];
    XCTarget *targetRight = [self targetAtIndex:selectedIndexRight];


    [self setTargetComparisonController:[[ISHTargetsComparisonController alloc] initWithLeftTarget:targetLeft rightTarget:targetRight]];
    [self.targetComparisonController showResults];
}

- (IBAction)startSanityCheck:(id)sender {
    [sender setEnabled:NO];
    [self checkSanityForProject:self.project];
    [sender setEnabled:YES];
}

- (void)checkSanityForProject:(XCProject *)aProject {
    NSArray *filesWithAbsolutePath = [aProject.files filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary * bindings) {
        return [[(XCSourceFile *) evaluatedObject pathRelativeToProjectRoot] isAbsolutePath];
    }]];

    NSArray *fileNames = nil;

    if ([XCSourceFile instancesRespondToSelector:@selector(name)]) {
        fileNames = [filesWithAbsolutePath valueForKey:@"name"];
    }

    NSAlert *myAlert = nil;

    if (filesWithAbsolutePath.count) {
        myAlert = [NSAlert alertWithMessageText:@"Absolute paths in project" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There are %lu files with absolute paths:\n%@", fileNames.count, [fileNames componentsJoinedByString:@"\n"]];
    } else {
        myAlert = [NSAlert alertWithMessageText:@"no absolute paths!" defaultButton:@"Cool" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Yeehaa, looks good!"];
    }

    [myAlert runModal];
}

- (XCTarget*)targetAtIndex:(NSUInteger)index {
    if (index >= self.project.targets.count) {
        return nil;
    }
    
    return [self.project.targets objectAtIndex:index];
}

- (XCTarget *)selectedLeftTarget {
    NSInteger selectedIndexLeft = [self.targetsTableViewLeft selectedRow];

    return [self targetAtIndex:selectedIndexLeft];
}

@end
