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

- (void)setFrame:(NSRect)frame {
    NSRect oldFrame = self.frame;
    [super setFrame:frame];

    // Follow the selection area when resizing
    if (!NSIsEmptyRect(self.selectionRect)) {
        [self updateSelectionForResizeFromOldFrame:oldFrame];
    }
}

- (void)updateSelectionForResizeFromOldFrame:(NSRect)oldFrame {
    if (self.originalImageSize.width <= 0 || self.originalImageSize.height <= 0) return;

    // Calculate image drawing area in the old view
    NSSize oldViewSize = oldFrame.size;
    if (oldViewSize.width <= 0 || oldViewSize.height <= 0) return;
    CGFloat oldScale = MIN(oldViewSize.width / self.originalImageSize.width, oldViewSize.height / self.originalImageSize.height);
    if (oldScale <= 0) return;
    CGFloat oldDrawW = self.originalImageSize.width * oldScale;
    CGFloat oldDrawH = self.originalImageSize.height * oldScale;
    CGFloat oldOffsetX = (oldViewSize.width - oldDrawW) / 2.0;
    CGFloat oldOffsetY = (oldViewSize.height - oldDrawH) / 2.0;

    // Calculate image drawing area in the new view
    NSSize newViewSize = self.bounds.size;
    if (newViewSize.width <= 0 || newViewSize.height <= 0) return;
    CGFloat newScale = MIN(newViewSize.width / self.originalImageSize.width, newViewSize.height / self.originalImageSize.height);
    CGFloat newDrawW = self.originalImageSize.width * newScale;
    CGFloat newDrawH = self.originalImageSize.height * newScale;
    CGFloat newOffsetX = (newViewSize.width - newDrawW) / 2.0;
    CGFloat newOffsetY = (newViewSize.height - newDrawH) / 2.0;

    // Convert selection area to image-relative coordinates and recalculate for the new scale
    CGFloat relX = (self.selectionRect.origin.x - oldOffsetX) / oldScale;
    CGFloat relY = (self.selectionRect.origin.y - oldOffsetY) / oldScale;
    CGFloat relW = self.selectionRect.size.width / oldScale;
    CGFloat relH = self.selectionRect.size.height / oldScale;

    self.selectionRect = NSMakeRect(
        newOffsetX + relX * newScale,
        newOffsetY + relY * newScale,
        relW * newScale,
        relH * newScale
    );
}

- (void)updateSelectionForCurrentBounds {
    if (NSIsEmptyRect(self.selectionRect) || self.originalImageSize.width <= 0 || self.originalImageSize.height <= 0) {
        return;
    }

    NSSize viewSize = self.bounds.size;
    if (viewSize.width <= 0 || viewSize.height <= 0) return;
    CGFloat scale = MIN(viewSize.width / self.originalImageSize.width, viewSize.height / self.originalImageSize.height);

    CGFloat drawW = self.originalImageSize.width * scale;
    CGFloat drawH = self.originalImageSize.height * scale;
    CGFloat offsetX = (viewSize.width - drawW) / 2.0;
    CGFloat offsetY = (viewSize.height - drawH) / 2.0;

    self.selectionRect = NSMakeRect(offsetX, offsetY, drawW, drawH);
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
    if (NSIsEmptyRect(self.selectionRect)) {
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
