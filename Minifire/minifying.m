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
}

-(void)saveSettings
{
    [[NSUserDefaults standardUserDefaults] setObject:[fileEnding stringValue] forKey:@"fileEnding"];
    [[NSUserDefaults standardUserDefaults] setObject:[outputDir titleOfSelectedItem] forKey:@"outputDir"];
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


-(void)minifyFiles:(NSArray *)arr
{
    [spinner setHidden:NO];
    [spinner startAnimation:self];
    
    [self saveSettings];
        
	for (int i=0;i<[arr count];i++)
	{
		if ([[[arr objectAtIndex:i] pathExtension] caseInsensitiveCompare:@"js"] == NSOrderedSame ||
            [[[arr objectAtIndex:i] pathExtension] caseInsensitiveCompare:@"css"] == NSOrderedSame)
		{
			YUICompressor = [[NSTask alloc] init];
			[YUICompressor setLaunchPath: @"/usr/bin/java"];
            [YUICompressor setArguments:[NSArray arrayWithObjects:@"-jar",[[NSBundle mainBundle] pathForResource:@"yuicompressor" ofType:@"jar"],[arr objectAtIndex:i],@"-o",[self getOutputFilename:[arr objectAtIndex:i]],nil]];
			[YUICompressor launch];
			[YUICompressor release];
		}
	}
    
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




- (BOOL)application:(NSApplication *)sender openFiles:(NSArray *)path
{
	[self minifyFiles:path];
	return YES;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	
	NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	
	if ([[[draggedFilenames objectAtIndex:0] pathExtension] caseInsensitiveCompare:@"js"] == NSOrderedSame ||
        [[[draggedFilenames objectAtIndex:0] pathExtension] caseInsensitiveCompare:@"css"] == NSOrderedSame){
		[self minifyFiles:draggedFilenames];
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
