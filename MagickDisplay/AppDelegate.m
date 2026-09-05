#import "AppDelegate.h"
#import "MagickWrapper.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    magick_init();
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    magick_terminate();
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction)showMyHelp:(id)sender {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Help" withExtension:@"html"];
#ifdef DEBUG
    NSLog(@"showMyHelp %@", url);
#endif
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
