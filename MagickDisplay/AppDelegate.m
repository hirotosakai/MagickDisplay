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

- (void)attemptToOpenFirstAvailableFileFromList:(NSArray<NSURL *> *)files atIndex:(NSUInteger)index {
    if (index >= files.count) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"No image to open.", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [alert runModal];
        return;
    }

    NSURL *url = files[index];
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
                                                                           display:YES
                                                                 completionHandler:^(NSDocument *doc, BOOL wasAlreadyOpen, NSError *error) {
        // Failed to open, try the next one
        if (!doc) {
#ifdef DEBUG
            NSLog(@"Failed to open %@, trying next... Error: %@", url.lastPathComponent, error.localizedDescription);
#endif
            [self attemptToOpenFirstAvailableFileFromList:files atIndex:index + 1];
        }
    }];
}

- (void)handleOpenURL:(NSURL *)url {
    BOOL isDirectory = NO;
    NSError *error = nil;
    NSURL *resourceURL = [url URLByResolvingSymlinksInPath];
    NSDictionary *values = [resourceURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (values && [values[@"NSURLIsDirectoryKey"] boolValue]) {
        isDirectory = YES;
    }

    if (isDirectory) {
        // save folder URL for navigation permission
        self.navigationFolderURL = url;

        // find the first non-hidden file in the directory
        NSArray<NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url
                                                                includingPropertiesForKeys:nil
                                                                                   options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                     error:&error];
        NSArray *sortedFiles = nil;
        if (files) {
            sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(NSURL *url1, NSURL *url2) {
                return [url1.lastPathComponent compare:url2.lastPathComponent];
            }];
        }
        [self attemptToOpenFirstAvailableFileFromList:sortedFiles ?: @[] atIndex:0];
    } else {
        // Regular file selection
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url 
                                                                               display:YES
                                                                     completionHandler:^(NSDocument *doc, BOOL wasAlreadyOpen, NSError *error) {
            if (!doc && error) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setInformativeText:error.localizedDescription];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                [alert runModal];
            }
        }];
    }
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = YES;
    panel.allowsMultipleSelection = NO;

    if ([panel runModal] == NSModalResponseOK) {
        [self handleOpenURL:panel.URL];
    }
}

- (void)application:(NSApplication *)application openFiles:(NSArray<NSString *> *)filenames {
    for (NSString *path in filenames) {
        NSURL *url = [NSURL fileURLWithPath:path];
        [self handleOpenURL:url];
    }
}

@end
