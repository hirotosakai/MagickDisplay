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

- (IBAction)orderFrontMyAboutPanel:(id)sender {
    // for rewriting URL to link (<a>)
    NSString *urlString = [NSString stringWithUTF8String:magick_get_url()];
    NSString *linkString = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlString, urlString];

    // create credits in the About panel
    NSString *htmlString = [NSString stringWithFormat:
        @"<!DOCTYPE html>"
         "<html>"
         "<head><meta charset=\"utf-8\"><title>Credits</title></head>"
         "<body style=\"font:normal xx-small system-ui; text-align:left;\">"
         "<p>Built with %@</p>"
         "<p>Features: %s<br/>"
         "Delegates: %s</p>"
         "</body>"
         "</html>",
        [[NSString stringWithUTF8String:magick_get_version()]
            stringByReplacingOccurrencesOfString:urlString withString:linkString],
        magick_get_features(),
        magick_get_delegates()];
    NSData *data = [[NSData alloc] initWithBytes:htmlString.UTF8String length:htmlString.length];
    NSAttributedString *credits = [[NSAttributedString alloc] initWithHTML:data documentAttributes:nil];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             credits, NSAboutPanelOptionCredits,
                             nil];

    // show About panel
    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
}

@end
