#import <Cocoa/Cocoa.h>

@class MagickImageView;

@interface Document : NSDocument

@property (nonatomic, weak) IBOutlet MagickImageView *imageView;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, assign) CGFloat originalWidth;
@property (nonatomic, assign) CGFloat originalHeight;
@property (nonatomic, copy) NSArray<NSURL *> *cachedFiles;
@property (nonatomic, assign) NSUInteger currentFileIndex;
@property (nonatomic, strong) NSURL *navigationFolderURL;

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
