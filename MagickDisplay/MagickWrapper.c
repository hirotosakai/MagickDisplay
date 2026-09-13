#include "MagickWrapper.h"
#include <stdio.h>
#include <stdlib.h>

// hack for ".../ImageMagick-7/MagickCore/magick-type.h:190:31 Typedef redefinition with different types ('struct _ExceptionInfo' vs 'union ExceptionInfo')"
#define ExceptionInfo MagickExceptionInfo
#include <MagickWand/MagickWand.h>
#undef ExceptionInfo

void magick_init(void) {
    MagickWandGenesis();
#ifdef DEBUG
    fprintf(stderr, "Version: %s\n", MagickGetVersion(NULL));
    fprintf(stderr, "Features: %s\n", GetMagickFeatures());
    fprintf(stderr, "Delegates: %s\n", GetMagickDelegates());
#endif
}

void magick_terminate(void) {
    MagickWandTerminus();
}

const char* magick_get_version(void) {
    return MagickGetVersion(NULL);
}

const char* magick_get_features(void) {
    return GetMagickFeatures();
}

const char* magick_get_delegates(void) {
    return GetMagickDelegates();
}

const char* magick_get_url(void) {
    return MagickAuthoritativeURL; // MagickCore/version.h
}

unsigned char* magick_read_image_rgba(const char* filename, const unsigned char* data, size_t length, size_t max_dimension, size_t* out_width, size_t* out_height) {
    MagickWand *wand = NewMagickWand();
    if (wand == NULL) return NULL;

    // set filename to identify file format
    if (MagickSetFilename(wand, filename) == MagickFalse) {
        DestroyMagickWand(wand);
        return NULL;
    }

    if (MagickReadImageBlob(wand, data, length) == MagickFalse) {
        DestroyMagickWand(wand);
        return NULL;
    }

    size_t w = MagickGetImageWidth(wand);
    size_t h = MagickGetImageHeight(wand);

#ifdef DEBUG
    fprintf(stderr, "magick_read_image_rgba() will read image Filename: %s Size: %zu x %zu\n", filename, w, h);
#endif

    // resize if the larger dimension exceeds max_dimension
    size_t max_dim = (w > h) ? w : h;
    if (max_dimension > 0 && max_dim > max_dimension) {
        double scale = (double)max_dimension / (double)max_dim;
        w = (size_t)(w * scale);
        h = (size_t)(h * scale);
        if (w == 0) w = 1;
        if (h == 0) h = 1;

        MagickResizeImage(wand, w, h, LanczosFilter);
    }

    if (out_width) *out_width = w;
    if (out_height) *out_height = h;

    // check for integer overflow in w * h * 4 calculation
    if (w == 0 || h == 0) {
        DestroyMagickWand(wand);
        return NULL;
    }
    size_t num_pixels = w * h;
    if (num_pixels / w != h) {
        DestroyMagickWand(wand);
        return NULL;
    }
    size_t total_bytes = num_pixels * 4;
    if (total_bytes / 4 != num_pixels) {
        DestroyMagickWand(wand);
        return NULL;
    }

    // allocate buffer for RGBA (4 bytes per pixel)
    unsigned char *pixels = (unsigned char *)malloc(total_bytes);
    if (pixels == NULL) {
        DestroyMagickWand(wand);
        return NULL;
    }

    // fetch raw pixels ("RGBA" format)
    if (MagickExportImagePixels(wand, 0, 0, w, h, "RGBA", CharPixel, pixels) == MagickFalse) {
        free(pixels);
        DestroyMagickWand(wand);
        return NULL;
    }

#ifdef DEBUG
    fprintf(stderr, "magick_read_image_rgba() successfully read image RGBA. Size: %zu x %zu\n", w, h);
#endif

    DestroyMagickWand(wand);
    return pixels;
}
