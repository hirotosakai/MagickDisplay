#!/bin/sh
# BuildMagick.sh - build ImageMagick

BUILD_MAGICK=1
VER_MAGICK=7.1.2-31

################################################################################
PATH=/usr/bin:/bin

cd "`dirname $0`"
here=`pwd`
mkdir -p magick
cd magick
mkdir -p bin lib include share doc

workDir=`pwd`
PATH=${workDir}/bin:${here}/tools/bin:${PATH}

export CFLAGS="-arch x86_64 -arch arm64"
export CXXFLAGS="-arch x86_64 -arch arm64"
export CPPFLAGS=-I${workDir}/include
export LDFLAGS=-L${workDir}/lib
export PKG_CONFIG_PATH=${workDir}/lib/pkgconfig
export LIBS="`ls ${workDir}/lib/*.a | sed "s|^.*/||g" | sed "s/^lib/-l/g" | sed "s/\.a$//g" | xargs` -lz -lstdc++"
################################################################################

if [ ! -e ImageMagick-${VER_MAGICK}.tar.xz ]; then
  curl -L -O https://github.com/ImageMagick/ImageMagick/releases/download/${VER_MAGICK}/ImageMagick-${VER_MAGICK}.tar.xz
fi
tar xfz ImageMagick-${VER_MAGICK}.tar.xz
cd ImageMagick-${VER_MAGICK}

./configure --prefix="${workDir}" --disable-dependency-tracking --disable-static --disable-silent-rules --disable-delegate-build --disable-docs --without-magick-plus-plus --without-perl --without-x --with-quantum-depth=8 --disable-hdri \
--with-jpeg --with-png --with-tiff --with-webp --with-raw --with-openjp2 --with-openexr --with-heic --with-jxl --with-fpx --with-uhdr --with-flif \
--without-djvu --without-jbig --without-wmf --without-freetype --without-rsvg \
--without-fontconfig --without-lcms --without-pango --without-bzlib --without-zlib --without-zip --without-zstd --without-lzma --without-xml

if [ $BUILD_MAGICK -eq 0 ]; then
  exit 0
fi

make clean && make && make install || exit 1
cp README.md ../doc/ImageMagick-README.md
cp LICENSE ../doc/ImageMagick-LICENSE
cp NOTICE ../doc/ImageMagick-NOTICE
cd ..

# prepare dylib for MagickDisplay
cp ./lib/libMagick*-7.Q8.dylib ../..
cd ../..
install_name_tool -id "@rpath/libMagickCore-7.Q8.dylib" libMagickCore-7.Q8.dylib
install_name_tool -id "@rpath/libMagickWand-7.Q8.dylib" libMagickWand-7.Q8.dylib
install_name_tool -change "${workDir}/lib/libMagickCore-7.Q8.10.dylib" "@rpath/libMagickCore-7.Q8.dylib" libMagickWand-7.Q8.dylib

exit 0
