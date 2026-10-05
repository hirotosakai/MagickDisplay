#import "MagickImageHelper.h"
#import "MagickWrapper.h"

@implementation MagickImageHelper

+ (nullable NSBitmapImageRep *)bitmapImageRepWithContentsOfURL:(NSURL *)url
                                                   maxDimension:(NSUInteger)maxDimension
                                                          error:(NSError **)outError {
    if (!url) {
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickImageHelper"
                                            code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"URL specified is nil."}];
        }
        return nil;
    }

    NSError *dataError = nil;
    NSData *fileData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&dataError];
    if (!fileData) {
        NSLog(@"Failed to read file into NSData: %@", dataError);
        if (outError) {
            *outError = dataError;
        }
        return nil;
    }

    size_t w = 0, h = 0;
    unsigned char *pixels = magick_read_image_rgba(url.lastPathComponent.UTF8String,
                                                   fileData.bytes,
                                                   fileData.length,
                                                   (size_t)maxDimension,
                                                   &w,
                                                   &h);
    if (pixels == NULL) {
        NSLog(@"ImageMagick failed to read image RGBA pixels");
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickImageHelper"
                                            code:2
                                        userInfo:@{NSLocalizedDescriptionKey: @"ImageMagick could not extract RGBA pixels from the image."}];
        }
        return nil;
    }

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:w
                                                                    pixelsHigh:h
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSDeviceRGBColorSpace
                                                                   bytesPerRow:w * 4
                                                                  bitsPerPixel:32];
    if (!rep) {
        NSLog(@"Failed to create NSBitmapImageRep from RGBA pixels");
        free(pixels);
        if (outError) {
            *outError = [NSError errorWithDomain:@"MagickImageHelper"
                                            code:3
                                        userInfo:@{NSLocalizedDescriptionKey: @"Failed to create NSBitmapImageRep from RGBA pixels."}];
        }
        return nil;
    }

    memcpy(rep.bitmapData, pixels, w * h * 4);
    free(pixels);

    return rep;
}

@end
