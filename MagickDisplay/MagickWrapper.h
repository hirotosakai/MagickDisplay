#ifndef MAGICK_WRAPPER_H
#define MAGICK_WRAPPER_H

#include <stddef.h>

// initialize and clean up ImageMagck
void magick_init(void);
void magick_terminate(void);

// get ImageMagick info
const char* magick_get_version(void);
const char* magick_get_features(void);
const char* magick_get_delegates(void);
const char* magick_get_url(void);

// read image and returns RGBA raw pixels (4 bytes per pixel)
// If max_dimension > 0 and the larger side of the image exceeds it, the image is resized to fit.
unsigned char* magick_read_image_rgba(const char* filename, const unsigned char* data, size_t length, size_t max_dimension, size_t* out_width, size_t* out_height);

#endif // MAGICK_WRAPPER_H
