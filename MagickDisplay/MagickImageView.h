#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MagickImageView : NSImageView

@property (nonatomic, assign) NSRect selectionRect;
@property (nonatomic, assign) NSSize originalImageSize;
@property (nonatomic, readonly) BOOL hasSelection;

- (CGFloat)currentScale;
- (NSRect)imageDrawingFrame;
- (NSRect)selectedImageRect;
- (IBAction)selectAll:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
