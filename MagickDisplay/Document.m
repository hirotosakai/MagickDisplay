#import "Document.h"
#import "MagickImageView.h"
#import "MagickImageHelper.h"
#import "AppDelegate.h"

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return NO;
}

- (BOOL)isDocumentEdited {
    return NO;
}

- (NSString *)displayName {
    if (self.navigationFolderURL) {
        return [NSString stringWithFormat:@"%@ | %@",
                self.fileURL.lastPathComponent,
                self.navigationFolderURL.lastPathComponent];
    }
    return [super displayName];
}

- (NSString *)windowNibName {
    return @"Document";
}

- (void)setNavigationFolderURLAndCacheFiles:(NSURL *)url {
    // get navigation folder URL from AppDelegate context map
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSURL *contextFolderURL = nil;
    @synchronized(appDelegate.folderContextMap) {
        contextFolderURL = appDelegate.folderContextMap[url];
    }
    self.navigationFolderURL = contextFolderURL;

    // cache files in the same directory
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *navFolderURL = self.navigationFolderURL;
    NSURL *navFolderStdURL = navFolderURL.standardizedURL;
    NSURL *directoryURL = url.URLByDeletingLastPathComponent;
    NSURL *directoryStdURL = directoryURL.standardizedURL;
    NSError *dirError = nil;

    NSArray<NSURL *> *files = [manager contentsOfDirectoryAtURL:directoryURL
                                     includingPropertiesForKeys:nil
                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                          error:&dirError];
    // Fallback: try to use the navigation folder URL from AppDelegate
    if (!files) {
        if (navFolderURL && [directoryStdURL isEqual:navFolderStdURL]) {
            files = [manager contentsOfDirectoryAtURL:navFolderURL
                           includingPropertiesForKeys:nil
                                              options:NSDirectoryEnumerationSkipsHiddenFiles
                                                error:&dirError];
        }
    }

    if (files) {
        NSArray *sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
            return [url1.lastPathComponent compare:url2.lastPathComponent];
        }];
        self.cachedFiles = sortedFiles;
        NSUInteger index = [sortedFiles indexOfObject:url];
        if (index != NSNotFound) {
            self.currentFileIndex = index;
        }
    } else {
        NSLog(@"%ld %@ %@", dirError.code, dirError.localizedFailureReason, directoryStdURL.path);
    }
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    // Get main display maximum dimension for optimization
    NSScreen *mainScreen = [NSScreen mainScreen];
    CGFloat maxScreenDim = 0;
    if (mainScreen) {
        maxScreenDim = MAX(mainScreen.frame.size.width, mainScreen.frame.size.height);
    }

    NSBitmapImageRep *rep = [MagickImageHelper bitmapImageRepWithContentsOfURL:url
                                                                  maxDimension:(NSUInteger)maxScreenDim
                                                                         error:outError];
    if (!rep) {
        return NO;
    }

    self.originalWidth = (CGFloat)rep.pixelsWide;
    self.originalHeight = (CGFloat)rep.pixelsHigh;

    // create NSImage from NSBitmapImageRep
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(rep.pixelsWide, rep.pixelsHigh)];
    [image addRepresentation:rep];
    self.image = image;

    if (!self.image) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickDisplay" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Failed to create NSImage from RGBA pixels."}];
        }
        return NO;
    }

    [self setNavigationFolderURLAndCacheFiles:url];

    return YES;
}

- (void)windowControllerDidLoadNib:(id)sender {
    NSWindowController *wc = (NSWindowController *)sender;
    NSWindow *window = wc.window;
    
    window.backgroundColor = [NSColor systemGrayColor];
    
    NSView *contentView = window.contentView;
    
    if (self.imageView) {
        self.imageView.image = self.image;
        self.imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
        self.imageView.frame = contentView.bounds;
        self.imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    }
    
    if (self.image) {
        [self resizeWindowToFitImage];
    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return nil;
}

- (NSImage *)rotateImage:(NSImage *)image byDegrees:(CGFloat)degrees {
    if (!image) return nil;
    
    NSSize size = image.size;
    CGFloat absDegrees = fabs(degrees);
    BOOL is90or270 = (fabs(fmod(absDegrees, 180.0) - 90.0) < 0.001);
    NSSize newSize = is90or270 ? NSMakeSize(size.height, size.width) : NSMakeSize(size.width, size.height);
    
    NSImage *rotatedImage = [NSImage imageWithSize:newSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        NSGraphicsContext *context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:newSize.width / 2.0 yBy:newSize.height / 2.0];
        [transform rotateByDegrees:degrees];
        [transform translateXBy:-size.width / 2.0 yBy:-size.height / 2.0];
        [transform concat];
        
        [image drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, size.width, size.height) operation:NSCompositingOperationCopy fraction:1.0];
        
        [context restoreGraphicsState];
        return YES;
    }];
    
    return rotatedImage;
}

- (void)resizeWindowToFitImage {
    NSArray *windowControllers = self.windowControllers;
    if (windowControllers.count == 0) return;
    NSWindowController *wc = windowControllers.firstObject;
    NSWindow *window = wc.window;
    if (!window) return;
    if (!self.image) return;
    
    NSSize imageSize = self.image.size;
    if (imageSize.width <= 0 || imageSize.height <= 0) return;
    
    NSScreen *screen = window.screen ?: [NSScreen mainScreen];
    NSRect screenFrame = screen.visibleFrame;
    
    NSRect currentFrame = window.frame;
    NSRect contentRect = [window contentRectForFrameRect:currentFrame];
    CGFloat decorationW = currentFrame.size.width - contentRect.size.width;
    CGFloat decorationH = currentFrame.size.height - contentRect.size.height;
    
    CGFloat targetWinW = imageSize.width + decorationW;
    CGFloat targetWinH = imageSize.height + decorationH;
    
    CGFloat maxContentW = screenFrame.size.width - decorationW;
    CGFloat maxContentH = screenFrame.size.height - decorationH;
    
    if (imageSize.width > maxContentW || imageSize.height > maxContentH) {
        CGFloat wRatio = maxContentW / imageSize.width;
        CGFloat hRatio = maxContentH / imageSize.height;
        CGFloat ratio = MIN(wRatio, hRatio);
        
        targetWinW = (imageSize.width * ratio) + decorationW;
        targetWinH = (imageSize.height * ratio) + decorationH;
    }
    
    CGFloat newX = currentFrame.origin.x + (currentFrame.size.width - targetWinW) / 2.0;
    CGFloat newY = (currentFrame.origin.y + currentFrame.size.height) - targetWinH;
    
    NSRect newFrame = NSMakeRect(newX, newY, targetWinW, targetWinH);
    
    if (newFrame.origin.x < screenFrame.origin.x) {
        newFrame.origin.x = screenFrame.origin.x;
    }
    if (newFrame.origin.y < screenFrame.origin.y) {
        newFrame.origin.y = screenFrame.origin.y;
    }
    if (NSMaxX(newFrame) > NSMaxX(screenFrame)) {
        newFrame.origin.x = NSMaxX(screenFrame) - newFrame.size.width;
    }
    if (NSMaxY(newFrame) > NSMaxY(screenFrame)) {
        newFrame.origin.y = NSMaxY(screenFrame) - newFrame.size.height;
    }
    
    [window setFrame:newFrame display:YES animate:YES];
}

- (void)updateImageViewAndWindow {
    NSArray *windowControllers = self.windowControllers;
    if (windowControllers.count == 0) return;
    NSWindowController *wc = windowControllers.firstObject;
    NSWindow *window = wc.window;
    if (!window) return;
    
    if (self.imageView) {
        self.imageView.image = self.image;
    }
    
    [self resizeWindowToFitImage];
}

- (IBAction)rotateLeft:(id)sender {
    if (!self.image) return;
    
    NSImage *rotatedImage = [self rotateImage:self.image byDegrees:90.0];
    if (rotatedImage) {
        self.image = rotatedImage;
        CGFloat origWidth = self.originalWidth;
        self.originalWidth = self.originalHeight;
        self.originalHeight = origWidth;
        
        [self updateImageViewAndWindow];
    }
}

- (IBAction)rotateRight:(id)sender {
    if (!self.image) return;
    
    NSImage *rotatedImage = [self rotateImage:self.image byDegrees:-90.0];
    if (rotatedImage) {
        self.image = rotatedImage;
        CGFloat origWidth = self.originalWidth;
        self.originalWidth = self.originalHeight;
        self.originalHeight = origWidth;
        
        [self updateImageViewAndWindow];
    }
}

- (IBAction)showActualSize:(id)sender {
    if (!self.image) return;
    [self resizeWindowToFitImage];
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary<NSPrintInfoAttributeKey,id> *)psSettings error:(NSError **)outError {
    if (!self.image) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickDisplay"
                                            code:4
                                        userInfo:@{NSLocalizedDescriptionKey:@"No image to print."}];
        }
        return nil;
    }
    
    NSPrintInfo *printInfo = [self printInfo];
    
    // Set pagination modes to "Fit" to scale content to fit the paper size
    [printInfo setHorizontalPagination:NSPrintingPaginationModeFit];
    [printInfo setVerticalPagination:NSPrintingPaginationModeFit];
    
    // Use the imageable bounds (printable area) to size the temporary image view.
    NSRect pageBounds = [printInfo imageablePageBounds];
    NSImageView *printImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, pageBounds.size.width, pageBounds.size.height)];
    printImageView.image = self.image;
    printImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printImageView printInfo:printInfo];
    [printOp setShowsPrintPanel:YES];

    return printOp;
}

- (IBAction)selectAll:(id)sender {
    if (!self.imageView || !self.image) return;
    [self.imageView selectAll:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    NSString *action = NSStringFromSelector(menuItem.action);

    if ([action isEqualToString:NSStringFromSelector(@selector(copy:))]) {
        return self.imageView.hasSelection;
    }

    if ([action isEqualToString:NSStringFromSelector(@selector(openPrevFile:))] ||
        [action isEqualToString:NSStringFromSelector(@selector(openPrevFileInWindow:))]) {
        return (self.cachedFiles.count > 0 && self.currentFileIndex > 0);
    }

    if ([action isEqualToString:NSStringFromSelector(@selector(openNextFile:))] ||
        [action isEqualToString:NSStringFromSelector(@selector(openNextFileInWindow:))]) {
        return (self.cachedFiles.count > 0 && self.currentFileIndex < self.cachedFiles.count - 1);
    }

    return [super validateMenuItem:menuItem];
}

- (IBAction)copy:(id)sender {
    if (!self.imageView || !self.image) return;

    NSRect imageRect = [self.imageView selectedImageRect];
    if (NSIsEmptyRect(imageRect)) return;

    NSImage *finalImage = [NSImage imageWithSize:imageRect.size
                                         flipped:NO
                                   drawingHandler:^BOOL(NSRect dstRect) {
        [self.image drawAtPoint:NSMakePoint(0, 0)
                      fromRect:imageRect
                      operation:NSCompositingOperationCopy
                       fraction:1.0];
        return YES;
    }];

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:@[finalImage]];
}

- (void)attemptToOpenFileAtIndex:(NSInteger)index direction:(NSInteger)direction withWindow:(BOOL)withWindow currentWindow:(NSWindow *)currentWindow currentFrame:(NSRect)currentFrame {
    if (index < 0 || index >= self.cachedFiles.count) {
        return;
    }

    NSURL *url = self.cachedFiles[index];
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
                                                                         display:YES
                                                              completionHandler:^(NSDocument *doc, BOOL wasAlreadyOpen, NSError *error) {
        if (doc) {
            NSWindow *newWindow = doc.windowControllers.firstObject.window;
            if (newWindow && currentWindow) {
                NSRect newFrame = newWindow.frame;
                if (!withWindow) {
                    newFrame.origin.x = currentFrame.origin.x;
                    newFrame.origin.y = currentFrame.origin.y + (currentFrame.size.height - newFrame.size.height);
                }
                [newWindow setFrame:newFrame display:YES animate:NO];
            }
            if (!withWindow) [self close];
        } else {
            [self attemptToOpenFileAtIndex:index + direction direction:direction withWindow:withWindow currentWindow:currentWindow currentFrame:currentFrame];
        }
    }];
}

- (void)openPrev:(BOOL)withWindow {
    if (self.cachedFiles.count == 0) return;

    NSWindow *currentWindow = self.windowControllers.firstObject.window;
    NSRect currentFrame = currentWindow ? currentWindow.frame : NSZeroRect;

    [self attemptToOpenFileAtIndex:self.currentFileIndex - 1 direction:-1 withWindow:withWindow currentWindow:currentWindow currentFrame:currentFrame];
}

- (void)openNext:(BOOL)withWindow {
    if (self.cachedFiles.count == 0) return;

    NSWindow *currentWindow = self.windowControllers.firstObject.window;
    NSRect currentFrame = currentWindow ? currentWindow.frame : NSZeroRect;

    [self attemptToOpenFileAtIndex:self.currentFileIndex + 1 direction:1 withWindow:withWindow currentWindow:currentWindow currentFrame:currentFrame];
}

- (IBAction)openPrevFile:(id)sender {
    [self openPrev:NO];
}

- (IBAction)openPrevFileInWindow:(id)sender {
    [self openPrev:YES];
}

- (IBAction)openNextFile:(id)sender {
    [self openNext:NO];
}

- (IBAction)openNextFileInWindow:(id)sender {
    [self openNext:YES];
}

@end
