#import <Cocoa/Cocoa.h>

@class MagickImageView;

@interface Document : NSDocument

@property (weak) IBOutlet MagickImageView *imageView;
@property (strong) NSImage *image;
@property (assign) CGFloat originalWidth;
@property (assign) CGFloat originalHeight;

- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)showActualSize:(id)sender;

@end
