#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readonly) NSMutableDictionary<NSURL *, NSURL *> *folderContextMap;

- (IBAction)showMyHelp:(id)sender;
- (IBAction)orderFrontMyAboutPanel:(id)sender;
- (IBAction)openDocument:(id)sender;

@end

NS_ASSUME_NONNULL_END
