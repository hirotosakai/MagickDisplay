#import <Cocoa/Cocoa.h>

@interface MagickImageView : NSImageView

@property (assign) NSRect selectionRect;
@property (assign) NSSize originalImageSize;

@end
