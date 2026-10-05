#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MagickImageHelper : NSObject

+ (nullable NSBitmapImageRep *)bitmapImageRepWithContentsOfURL:(NSURL *)url
                                                   maxDimension:(NSUInteger)maxDimension
                                                          error:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
