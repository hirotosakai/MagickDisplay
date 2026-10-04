#import <Cocoa/Cocoa.h>

@interface MagickImageView : NSImageView

@property (nonatomic, assign) NSRect selectionRect;
@property (nonatomic, assign) NSSize originalImageSize;

@end
