#import "Document.h"
#import "MagickImageView.h"
#import "MagickWrapper.h"

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

- (NSString *)windowNibName {
    return @"Document";
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    NSError *dataError = nil;
    
    // open file and read contents
    NSData *fileData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&dataError];
    if (!fileData) {
        NSLog(@"Failed to read file into NSData: %@", dataError);
        if (outError) {
            *outError = dataError;
        }
        return NO;
    }
    
    // Get main display maximum dimension for optimization
    NSScreen *mainScreen = [NSScreen mainScreen];
    CGFloat maxScreenDim = 0;
    if (mainScreen) {
        maxScreenDim = MAX(mainScreen.frame.size.width, mainScreen.frame.size.height);
    }
    
    // put contents into ImageMagick and convert to RGBA raw pixels
    size_t w, h;
    unsigned char *pixels = magick_read_image_rgba(url.lastPathComponent.UTF8String, fileData.bytes, fileData.length, (size_t)maxScreenDim, &w, &h);
    if (pixels == NULL) {
        NSLog(@"ImageMagick failed to read image RGBA pixels");
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickDisplay" code:2 userInfo:@{NSLocalizedDescriptionKey:@"ImageMagick could not extract RGBA pixels from the image."}];
        }
        return NO;
    }
    
#ifdef DEBUG
    NSLog(@"readFromURL successfully read image RGBA. Size: %zu x %zu", w, h);
#endif
    
    self.originalWidth = (CGFloat)w;
    self.originalHeight = (CGFloat)h;
    
    // create NSBitmapImageRep from RGBA raw pixels
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:w
                                                                    pixelsHigh:h
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bytesPerRow:w * 4
                                                                  bitsPerPixel:32];
    if (!rep) {
        NSLog(@"Failed to create NSBitmapImageRep from RGBA pixels");
        free(pixels);
        return NO;
    }
    
    memcpy([rep bitmapData], pixels, w * h * 4);
    free(pixels);
    
    // create NSImage from NSBitmapImageRep
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
    [image addRepresentation:rep];
    self.image = image;
    
    if (!self.image) {
        NSLog(@"Failed to create NSImage from RGBA pixels");
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickDisplay" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Failed to create NSImage from RGBA pixels."}];
        }
        return NO;
    }
    
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
    NSSize newSize = is90or270 ? NSMakeSize(size.height, size.width) : size;
    
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
    
    // Use the paper's imageable bounds (printable area) to size the temporary image view.
    // This allows the image view's proportional scaling logic to lay out the image inside the printable area.
    NSRect pageBounds = [printInfo imageablePageBounds];
    NSImageView *printImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, pageBounds.size.width, pageBounds.size.height)];
    printImageView.image = self.image;
    printImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printImageView printInfo:printInfo];
    [printOp setShowsPrintPanel:YES];

    return printOp;
}

@end
