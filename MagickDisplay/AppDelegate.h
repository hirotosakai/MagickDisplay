#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSURL *navigationFolderURL;

- (IBAction)showMyHelp:(id)sender;
- (IBAction)orderFrontMyAboutPanel:(id)sender;
- (IBAction)openDocument:(id)sender;

@end
