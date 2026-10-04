#import <Cocoa/Cocoa.h>

@class MagickImageView;

@interface Document : NSDocument

@property (weak) IBOutlet MagickImageView *imageView;
@property (strong) NSImage *image;
@property (assign) CGFloat originalWidth;
@property (assign) CGFloat originalHeight;
@property (strong) NSArray<NSURL *> *cachedFiles;
@property (assign) NSUInteger currentFileIndex;
@property (strong) NSString *navigationFolderPath;

- (IBAction)rotateLeft:(id)sender;
- (IBAction)rotateRight:(id)sender;
- (IBAction)showActualSize:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)openPrevFile:(id)sender;
- (IBAction)openPrevFileInWindow:(id)sender;
- (IBAction)openNextFile:(id)sender;
- (IBAction)openNextFileInWindow:(id)sender;

@end