#import "PreviewProvider.h"
#import "MagickWrapper.h"
#import "MagickImageHelper.h"

@implementation PreviewProvider

/*

 Use a QLPreviewProvider to provide data-based previews.
 
 To set up your extension as a data-based preview extension:

 - Modify the extension's Info.plist by setting
   <key>QLIsDataBasedPreview</key>
   <true/>
 
 - Add the supported content types to QLSupportedContentTypes array in the extension's Info.plist.

 - Change the NSExtensionPrincipalClass to this class.
   e.g.
   <key>NSExtensionPrincipalClass</key>
   <string>PreviewProvider</string>
 
 - Implement providePreviewForFileRequest:completionHandler:
 
 */

+ (void)initialize {
    if (self == [PreviewProvider class]) {
        magick_init();
    }
}

- (void)providePreviewForFileRequest:(QLFilePreviewRequest *)request completionHandler:(void (^)(QLPreviewReply * _Nullable reply, NSError * _Nullable error))handler
{
#if 0
    //You can create a QLPreviewReply in several ways, depending on the format of the data you want to return.
    //To return NSData of a supported content type:
    
    UTType* contentType = UTTypeUTF8PlainText; //replace with your data type

    QLPreviewReply* reply = [[QLPreviewReply alloc] initWithDataOfContentType:contentType contentSize:CGSizeMake(800, 800) dataCreationBlock:^NSData * _Nullable(QLPreviewReply * _Nonnull replyToUpdate, NSError *__autoreleasing  _Nullable * _Nullable error) {
        
        NSData* data = [@"Hello, World" dataUsingEncoding:NSUTF8StringEncoding];
        
        //setting the stringEncoding for text and html data is optional and defaults to NSUTF8StringEncoding
        replyToUpdate.stringEncoding = NSUTF8StringEncoding;
        
        //initialize your data here

        return data;
    }];
#endif
#ifdef DEBUG
    NSLog(@"providePreviewForFileRequest %@ | %@", request.fileURL, request.fileURL.lastPathComponent);
#endif

    NSError *loadError = nil;
    NSBitmapImageRep *rep = [MagickImageHelper bitmapImageRepWithContentsOfURL:request.fileURL
                                                                  maxDimension:600
                                                                         error:&loadError];
    if (!rep) {
        handler(nil, loadError);
        return;
    }

    size_t w = rep.pixelsWide;
    size_t h = rep.pixelsHigh;

    // by drawing directly into a bitmap context
    QLPreviewReply* reply = [[QLPreviewReply alloc] initWithContextSize:CGSizeMake(w, h) isBitmap:YES drawingBlock:^BOOL(CGContextRef _Nonnull context, QLPreviewReply * _Nonnull replyToUpdate, NSError *__autoreleasing  _Nullable * _Nullable error) {
        CGContextDrawImage(context, CGRectMake(0, 0, w, h), rep.CGImage);
        return YES;
    }];

    handler(reply, nil);
}

@end
