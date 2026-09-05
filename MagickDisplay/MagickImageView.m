#import "MagickImageView.h"

@implementation MagickImageView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self updateImageScaling];
    }
    return self;
}

- (void)setFrame:(NSRect)frame {
    [super setFrame:frame];
}

- (void)updateImageScaling {
    // keep aspect ratio
    self.imageScaling = NSImageScaleProportionallyUpOrDown;
}

@end
