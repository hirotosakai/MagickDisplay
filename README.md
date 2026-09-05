# MagickDisplay

## Overview

MagickDisplay is a simple image viewer for macOS.
By leveraging ImageMagick, it supports a wide variety of file formats.
It also includes a Quick Look extension.
Most of the source code was created using generative AI.

## App

### Basic Features

- When you open an image file, the window is resized to match the image dimensions for display.
  (It is adjusted to ensure it does not exceed the desktop screen.)
- Resizing the window scales the image up or down while maintaining its aspect ratio.
- To optimize memory usage and rendering speed, images that exceed the length of the main display's longer side (either width or height) are resized using ImageMagick to fit within those dimensions.
- If you try to open a file in a format that ImageMagick does not support, an error dialog is displayed, and the window does not open.

### Menu

- Selecting [View > Rotate Left (Right)] rotates the image 90 degrees to the left (right).
  The window is resized to match the new image dimensions.
  (It is adjusted to ensure it does not exceed the desktop screen.)
- Selecting [View > Actual Size] resizes the window to match the image's original dimensions. (Adjusted to ensure it does not exceed the desktop screen.)
- Selecting [Print...] prints the currently displayed image.
  Selecting [Page Setup...] allows you to configure paper size and other print settings.

## Quick Look Extension

- It is configured not to trigger for file formats that can be natively previewed by macOS's standard Quick Look. (Refer to `doc/uti.md` for the list of formats that do trigger it.)
- Images are resized and displayed so that neither their width nor height exceeds 800px.

## Build

To build MagickDisplay, build the project in Xcode or run `xcodebuild` in the Terminal.

Before building MagickDisplay, you need to build ImageMagick (version 7) and place `libMagick{Core,Wand}-7.Q8.dylib` to the project root.
Open the Terminal and run the bundled scripts in the `opt` directory:
1. `BuildTools.sh`  - Tools required to build image libraries and ImageMagick.
2. `BuildLibs.sh`   - Supporting image libraries to add to ImageMagick.
3. `BuildMagick.sh` - ImageMagick itself.

## License

See `LICENSE.md`.
