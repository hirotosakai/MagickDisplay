#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSMutableDictionary<NSURL *, NSURL *> *folderContextMap;

- (IBAction)showMyHelp:(id)sender;
- (IBAction)orderFrontMyAboutPanel:(id)sender;
- (IBAction)openDocument:(id)sender;

@end
