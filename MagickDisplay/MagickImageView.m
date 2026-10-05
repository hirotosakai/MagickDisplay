#import "MagickImageView.h"

@interface MagickImageView ()

@property (nonatomic, assign) NSPoint startPoint;
@property (nonatomic, assign) BOOL isDragging;

@end

@implementation MagickImageView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageScaling = NSImageScaleProportionallyUpOrDown;
        self.selectionRect = NSZeroRect;
        self.originalImageSize = NSZeroSize;
        self.startPoint = NSMakePoint(0, 0);
        self.isDragging = NO;
    }
    return self;
}

- (void)setImage:(NSImage *)newImage {
    [super setImage:newImage];
    if (newImage) {
        self.originalImageSize = newImage.size;
    }
}

- (NSSize)effectiveImageSize {
    if (self.image && self.image.size.width > 0 && self.image.size.height > 0) {
        return self.image.size;
    }
    return self.originalImageSize;
}

- (CGFloat)scaleForViewSize:(NSSize)viewSize imageSize:(NSSize)imageSize {
    if (imageSize.width <= 0 || imageSize.height <= 0) return 0.0;
    if (viewSize.width <= 0 || viewSize.height <= 0) return 0.0;
    return MIN(viewSize.width / imageSize.width, viewSize.height / imageSize.height);
}

- (CGFloat)currentScale {
    return [self scaleForViewSize:self.bounds.size imageSize:[self effectiveImageSize]];
}

- (NSRect)imageDrawingFrameForViewSize:(NSSize)viewSize imageSize:(NSSize)imageSize {
    CGFloat scale = [self scaleForViewSize:viewSize imageSize:imageSize];
    if (scale <= 0.0) return NSZeroRect;

    CGFloat drawW = imageSize.width * scale;
    CGFloat drawH = imageSize.height * scale;
    CGFloat offsetX = (viewSize.width - drawW) / 2.0;
    CGFloat offsetY = (viewSize.height - drawH) / 2.0;

    return NSMakeRect(offsetX, offsetY, drawW, drawH);
}

- (NSRect)imageDrawingFrame {
    return [self imageDrawingFrameForViewSize:self.bounds.size imageSize:[self effectiveImageSize]];
}

- (BOOL)hasSelection {
    return !NSIsEmptyRect(self.selectionRect);
}

- (IBAction)selectAll:(id)sender {
    NSRect drawFrame = [self imageDrawingFrame];
    if (NSIsEmptyRect(drawFrame)) return;
    self.selectionRect = drawFrame;
    self.needsDisplay = YES;
}

- (NSRect)selectedImageRect {
    if (!self.hasSelection) return NSZeroRect;

    NSSize imageSize = [self effectiveImageSize];
    CGFloat scale = [self currentScale];
    if (scale <= 0.0 || imageSize.width <= 0 || imageSize.height <= 0) return NSZeroRect;

    NSRect drawFrame = [self imageDrawingFrame];
    if (NSIsEmptyRect(drawFrame)) return NSZeroRect;

    CGFloat imageX = (self.selectionRect.origin.x - drawFrame.origin.x) / scale;
    CGFloat imageY = (self.selectionRect.origin.y - drawFrame.origin.y) / scale;
    CGFloat imageW = self.selectionRect.size.width / scale;
    CGFloat imageH = self.selectionRect.size.height / scale;

    imageX = MAX(0, imageX);
    imageY = MAX(0, imageY);
    imageW = MIN(imageW, imageSize.width - imageX);
    imageH = MIN(imageH, imageSize.height - imageY);

    if (imageW <= 0 || imageH <= 0) return NSZeroRect;

    return NSMakeRect(imageX, imageY, imageW, imageH);
}

- (void)setFrame:(NSRect)frame {
    NSRect oldFrame = self.frame;
    [super setFrame:frame];

    // Follow the selection area when resizing
    if (self.hasSelection) {
        [self updateSelectionForResizeFromOldFrame:oldFrame];
    }
}

- (void)updateSelectionForResizeFromOldFrame:(NSRect)oldFrame {
    NSSize imageSize = [self effectiveImageSize];
    CGFloat oldScale = [self scaleForViewSize:oldFrame.size imageSize:imageSize];
    if (oldScale <= 0.0) return;

    NSRect oldDrawFrame = [self imageDrawingFrameForViewSize:oldFrame.size imageSize:imageSize];
    NSRect newDrawFrame = [self imageDrawingFrame];
    CGFloat newScale = [self currentScale];
    if (newScale <= 0.0) return;

    // Convert selection area to image-relative coordinates and recalculate for the new scale
    CGFloat relX = (self.selectionRect.origin.x - oldDrawFrame.origin.x) / oldScale;
    CGFloat relY = (self.selectionRect.origin.y - oldDrawFrame.origin.y) / oldScale;
    CGFloat relW = self.selectionRect.size.width / oldScale;
    CGFloat relH = self.selectionRect.size.height / oldScale;

    self.selectionRect = NSMakeRect(
        newDrawFrame.origin.x + relX * newScale,
        newDrawFrame.origin.y + relY * newScale,
        relW * newScale,
        relH * newScale
    );
}

- (void)updateSelectionForCurrentBounds {
    if (!self.hasSelection) return;
    self.selectionRect = [self imageDrawingFrame];
}

- (void)mouseDown:(NSEvent *)event {
    self.startPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    self.isDragging = YES;

    // Clear current selection when starting a new drag
    self.selectionRect = NSZeroRect;
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint currentPoint = [self convertPoint:[event locationInWindow] fromView:nil];

    CGFloat x = MIN(self.startPoint.x, currentPoint.x);
    CGFloat y = MIN(self.startPoint.y, currentPoint.y);
    CGFloat width = ABS(self.startPoint.x - currentPoint.x);
    CGFloat height = ABS(self.startPoint.y - currentPoint.y);

    self.selectionRect = NSMakeRect(x, y, width, height);
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event {
    self.isDragging = NO;

    // Treat extremely small rectangles as empty
    if (self.selectionRect.size.width < 2.0 || self.selectionRect.size.height < 2.0) {
        self.selectionRect = NSZeroRect;
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    if (!self.hasSelection) {
        return;
    }

    NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.selectionRect];
    CGFloat lengths[] = {4.0, 4.0};
    [path setLineDash:lengths count:2 phase:0];
    [path setLineWidth:1.0];
    [[NSColor selectedControlColor] setStroke];

    [path stroke];
}

@end
