//
//  minifying.m
//  Minifire
//
//  Created by @vanyamikhailov on 3/15/11.
//  

#import "minifying.h"


@implementation minifying

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
					hasVisibleWindows:(BOOL)flag
{
	if( !flag )
		[window makeKeyAndOrderFront:nil];
	
	return YES;
}

-(void)awakeFromNib
{
   [self loadSettings];
}

// Settings

-(IBAction)showSettings:(id)sender
{
    [settingsPanel setIsVisible:YES];
}

-(void)loadSettings
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"fileEnding"]){
        [fileEnding setStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"fileEnding"]];  
    }
    else
    {
        [fileEnding setStringValue:@".min"];
        [self saveSettings];
    }
    
    NSString *outputDirSett = [[NSUserDefaults standardUserDefaults] objectForKey:@"outputDir"];
	if (outputDirSett) {
		[outputDir selectItemWithTitle:outputDirSett];
	}
	else {
		[outputDir selectItemWithTitle:@"same folder as source"];
        [self saveSettings];
	}

	bool combineFilesCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"combineFiles"];
	
	if (combineFilesCheck) {
		[combineFiles setState:combineFilesCheck];
	}
	else {
		[combineFiles setState:0];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"combineFiles"];
	}
}

-(void)saveSettings
{
    [[NSUserDefaults standardUserDefaults] setObject:[fileEnding stringValue] forKey:@"fileEnding"];
    [[NSUserDefaults standardUserDefaults] setObject:[outputDir titleOfSelectedItem] forKey:@"outputDir"];
    [[NSUserDefaults standardUserDefaults] setBool:[combineFiles state] forKey:@"combineFiles"];

}

//-------------

-(NSString *)getOutputFilename:(NSString *)origin
{
    
    NSString *ext = [origin pathExtension];
    NSString *filename = [[origin lastPathComponent] stringByDeletingPathExtension];
    NSString *newFilename = [filename stringByAppendingString:[fileEnding stringValue]];
    newFilename = [newFilename stringByAppendingPathExtension:ext];
    
    NSString *outputDirSett = [outputDir titleOfSelectedItem];
    
    if ([outputDirSett isEqualToString:@"Desktop"]) {
        NSString *desktopPath = [NSString stringWithFormat:@"/Users/%@/Desktop/",NSUserName()];
        return [desktopPath stringByAppendingPathComponent:newFilename];
    }
    else
    {
        return [[origin stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFilename];
    }
}

-(void)combineFilesAndMinify:(NSArray *)arr{
    
    NSMutableArray *cssArray = [NSMutableArray new];
    NSMutableArray *jsArray = [NSMutableArray new];
    
    for (int i=0;i<[arr count];i++){
        if ([[[arr objectAtIndex:i] pathExtension] caseInsensitiveCompare:@"js"] == NSOrderedSame) {
            [jsArray addObject:[arr objectAtIndex:i]];
        }
        else if([[[arr objectAtIndex:i] pathExtension] caseInsensitiveCompare:@"css"] == NSOrderedSame){
            [cssArray addObject:[arr objectAtIndex:i]];
        }
        
    }
    
    NSMutableArray *filesArray = [NSMutableArray arrayWithObjects:cssArray, jsArray, nil];
    
    for (int i=0; i < [filesArray count]; i++){
        if (![[filesArray objectAtIndex:i] count]){
            [filesArray removeObjectAtIndex:i];
        }
    }
    
    for (int i=0; i < [filesArray count]; i++){
    
        bool show;
        
        if (i == [filesArray count]-1) {
            show = YES;
        }else{
            show = NO;
        }
        
        if ([[filesArray objectAtIndex:i] count]) {

            if ([[filesArray objectAtIndex:i] count] > 1) {
                
                NSString *outputFolder = [[[filesArray objectAtIndex:i] objectAtIndex:0] stringByDeletingLastPathComponent];
                
                NSString *tempFileName = [NSString stringWithFormat:@"%@%@", @"combined.output.", [[[filesArray objectAtIndex:i] objectAtIndex:0] pathExtension]];
                
                NSString *tempFile = [outputFolder stringByAppendingPathComponent:tempFileName];

                NSFileManager *FileManager = [[NSFileManager alloc] init];
                
                for (int y=0; y < [[filesArray objectAtIndex:i] count]; y++) {
                    
                    if(![FileManager fileExistsAtPath:tempFile]){
                        [FileManager createFileAtPath:tempFile contents:NULL attributes:NULL];
                    }
                    
                    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:tempFile];
                    [handle seekToEndOfFile];
                    [handle writeData:[NSData dataWithContentsOfFile:[[[filesArray objectAtIndex:i] objectAtIndex:y] stringByStandardizingPath]]];
                    [handle closeFile];
                }

                [self minifyFiles:[NSArray arrayWithObject:tempFile] showSuccess:show];
        
                
                [FileManager removeItemAtPath:tempFile error:NULL];
                [FileManager release];
                
            }
            else if ([[filesArray objectAtIndex:i] count] == 1){
                [self minifyFiles:[filesArray objectAtIndex:i] showSuccess:show];
            }
        }
    }
}


-(void)minifyFiles:(NSArray *)arr showSuccess:(bool)showSheet
{
    [spinner setHidden:NO];
    [spinner startAnimation:self];
    
	for (int i=0;i<[arr count];i++)
	{
		if ([[[arr objectAtIndex:i] pathExtension] caseInsensitiveCompare:@"js"] == NSOrderedSame ||
            [[[arr objectAtIndex:i] pathExtension] caseInsensitiveCompare:@"css"] == NSOrderedSame)
		{
            YUICompressor = [[NSTask alloc] init];
            [YUICompressor setLaunchPath: @"/usr/bin/java"];
            [YUICompressor setArguments:[NSArray arrayWithObjects:@"-jar",[[NSBundle mainBundle] pathForResource:@"yuicompressor" ofType:@"jar"],[arr objectAtIndex:i],@"-o",[self getOutputFilename:[arr objectAtIndex:i]],nil]];
			[YUICompressor launch];
            [YUICompressor waitUntilExit];
            [YUICompressor release];
		}
	}
    
    if (showSheet) {
        [spinner stopAnimation:self];
        [spinner setHidden:YES];

        NSBeginAlertSheet(
                          @"Success!",
                          // sheet message
                          @"OK",              // default button label
                          nil,                // no third button
                          nil,                // other button label
                          window,         // window sheet is attached to
                          self,               // we’ll be our own delegate
                          nil,
                          // did-end selector
                          NULL,               // no need for did-dismiss selector
                          window,         // context info
                          @"Honey, i shrunk the files.");

    }
	
}




- (BOOL)application:(NSApplication *)sender openFiles:(NSArray *)path
{
    [self saveSettings];

    bool combineFilesCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"combineFiles"];
    if (combineFilesCheck) {
        [self combineFilesAndMinify:path];
    }
    else{
        [self minifyFiles:path showSuccess:YES];
    }
	return YES;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    [self saveSettings];
    
	NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	if ([[[draggedFilenames objectAtIndex:0] pathExtension] caseInsensitiveCompare:@"js"] == NSOrderedSame ||
        [[[draggedFilenames objectAtIndex:0] pathExtension] caseInsensitiveCompare:@"css"] == NSOrderedSame){
        
        bool combineFilesCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"combineFiles"];
        if (combineFilesCheck) {
            [self combineFilesAndMinify:draggedFilenames];
        }
        else{
            [self minifyFiles:draggedFilenames showSuccess:YES];
        }
	}
    
	
	
	[status setTextColor:[NSColor colorWithCalibratedRed:(205.0/255.0) 
												   green:(205.0/255.0) 
													blue:(205.0/255.0) 
												   alpha:1]];
	
	return YES;
	
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSTIFFPboardType, 
								   NSFilenamesPboardType, nil]];
    if (self) {
		
	}
    return self;
}


- (void)drawRect:(NSRect)bounds {
    bounds = [self bounds];
	
    NSBezierPath*    clipShape = [NSBezierPath bezierPath];
	[clipShape appendBezierPathWithRect:bounds];
    
	
	
    NSGradient* aGradient = [[[NSGradient alloc]
							  initWithColorsAndLocations:[NSColor whiteColor], (CGFloat)0.0,
							  [NSColor colorWithCalibratedRed:224 green:224 blue:224 alpha:0], (CGFloat)1,
							  nil] autorelease];
	
    [aGradient drawInBezierPath:clipShape angle:-90.0];
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
		== NSDragOperationGeneric)
    {
   		
		NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		if ([[[draggedFilenames objectAtIndex:0] pathExtension] isEqual:@"js"] ||
            [[[draggedFilenames objectAtIndex:0] pathExtension] isEqual:@"css"]){
			[[NSCursor dragCopyCursor] set];
			[status setTextColor:[NSColor colorWithCalibratedRed:(115.0/255.0) 
                                                           green:(130.0/255.0) 
                                                            blue:(150.0/255.0) 
                                                           alpha:1]];
		}
		else{
			[[NSCursor arrowCursor] set];
			[status setTextColor:[NSColor colorWithCalibratedRed:(205.0/255.0) 
														   green:(205.0/255.0) 
															blue:(205.0/255.0) 
														   alpha:1]];
			
		}
		
		
		return NSDragOperationGeneric;
    }
    else
    {
        
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[status setTextColor:[NSColor colorWithCalibratedRed:(205.0/255.0) 
												   green:(205.0/255.0) 
													blue:(205.0/255.0) 
												   alpha:1]];
	[[NSCursor dragCopyCursor] set];
    
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) 
		== NSDragOperationGeneric)
    {
        
		[[NSCursor dragCopyCursor] set];
        
        return NSDragOperationGeneric;
    }
    else
    {
        
        return NSDragOperationNone;
    }
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}


- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [self setNeedsDisplay:YES];
}


- (void)applicationWillTerminate:(NSApplication *)theApplication
{
    NSLog(@"i'm tired and i quit");   // x_x
    [self saveSettings];
}


- (void)dealloc
{
    
    [super dealloc];
}

@end
