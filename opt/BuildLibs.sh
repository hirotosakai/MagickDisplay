#!/bin/sh
# BuildLibs.sh - build libraries for ImageMagick

BUILD_LIBJPEG=1
BUILD_LIBPNG=1
BUILD_LIBTIFF=1
BUILD_LIBWEBP=1
BUILD_LCMS2=1

BUILD_LIBJBIG=0  # GPL-2.0
BUILD_DJVULIB=0  # GPL-2.0
BUILD_LIBRAW=1
BUILD_OPENJP2=1

BUILD_IMATH=1
BUILD_OPENJPH=1
BUILD_OPENEXR=1

BUILD_LIBDE265=1
BUILD_AOM=1
BUILD_LIBHEIF=1

BUILD_BROTLI=1
BUILD_HIGHWAY=1
BUILD_LIBJXL=1

BUILD_FPX=1
BUILD_LIBULTRAHDR=1
BUILD_FLIF=1

BUILD_FREETYPE=0
BUILD_LIBWMF=0

VER_LIBJPEG=3.2.0
VER_LIBPNG=1.6.58
VER_LIBTIFF=4.7.2
VER_LIBWEBP=1.6.0
VER_LCMS2=2.19.1

VER_JBIGKIT=2.1
VER_DJVULIB=3.5.30
VER_LIBRAW=0.22.2
VER_OPENJP2=2.5.4

VER_IMATH=3.2.2
VER_OPENJPH=0.31.0
VER_OPENEXR=3.4.14

VER_LIBDE265=1.1.3
VER_AOM=3.15.0
VER_LIBHEIF=1.23.4

VER_BROTLI=1.2.0
VER_HIGHWAY=1.4.0
VER_LIBJXL=0.12.0

VER_LIBFPX=main
VER_LIBULTRAHDR=2.0.2
VER_FLIF=0.4

VER_FREETYPE=2.14.3
VER_LIBWMF=0.2.16

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
################################################################################

#### Step 1

## libjpeg
if [ $BUILD_LIBJPEG -eq 1 ] ; then
echo "## Installing libjpeg ##"

if [ ! -e libjpeg-turbo-${VER_LIBJPEG}.tar.gz ]; then
  curl -L -O https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${VER_LIBJPEG}/libjpeg-turbo-${VER_LIBJPEG}.tar.gz
fi
tar xfz libjpeg-turbo-${VER_LIBJPEG}.tar.gz
cd libjpeg-turbo-${VER_LIBJPEG}
unset CFLAGS CXXFLAGS
for a in x86_64 arm64; do
  rm -rf build-${a}
  cmake -S . -B build-${a} -DCMAKE_OSX_ARCHITECTURES:STRING="${a}" -DWITH_SIMD="${a}" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DENABLE_SHARED=OFF -DWITH_TOOLS=OFF -DWITH_TESTS=OFF -DWITH_JPEG7=ON -DWITH_JPEG8=ON
  cmake --build build-${a} -v && cmake --install build-${a} || exit 1
done
for f in libjpeg.a libturbojpeg.a; do
  lipo -create -arch x86_64 build-x86_64/${f} -arch arm64 build-arm64/${f} -output ${workDir}/lib/${f} || exit 1
done
export CFLAGS="-arch x86_64 -arch arm64"
export CXXFLAGS="-arch x86_64 -arch arm64"
cp README.ijg ../doc/libjpeg-turbo-README.ijg
cp LICENSE.md ../doc/libjpeg-turbo-LICENSE.md
cd ..

fi

## libpng
if [ $BUILD_LIBPNG -eq 1 ] ; then
echo "## Building libpng ##"

if [ ! -e libpng-${VER_LIBPNG}.tar.xz ]; then
  curl -L -O https://downloads.sourceforge.net/project/libpng/libpng16/${VER_LIBPNG}/libpng-${VER_LIBPNG}.tar.xz
fi
tar xfz libpng-${VER_LIBPNG}.tar.xz
cd libpng-${VER_LIBPNG}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --disable-tests --with-zlib-prefix=${workDir}
make clean && make && make install || exit 1
cp README ../doc/libpng-README
cp LICENSE ../doc/libpng-LICENSE
cd ..

fi

## libtiff
if [ $BUILD_LIBTIFF -eq 1 ] ; then
echo "## Building libtiff ##"

if [ ! -e tiff-${VER_LIBTIFF}.tar.gz ]; then
  curl -L -O https://download.osgeo.org/libtiff/tiff-${VER_LIBTIFF}.tar.gz
fi
tar xfz tiff-${VER_LIBTIFF}.tar.gz
cd tiff-${VER_LIBTIFF}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --disable-tools --disable-tests --disable-contrib --disable-docs --without-x --disable-libdeflate --disable-jbig --disable-lerc --disable-lzma --disable-zstd --disable-webp
make clean && make && make install || exit 1
cp README.md ../doc/tiff-README.md
cp LICENSE.md ../doc/tiff-LICENSE.md
cd ..

fi

## libwebp
if [ $BUILD_LIBWEBP -eq 1 ] ; then
echo "## Building libwebp ##"

if [ ! -e libwebp-${VER_LIBWEBP}.tar.gz ]; then
  curl -L -O https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${VER_LIBWEBP}.tar.gz
fi
tar xfz libwebp-${VER_LIBWEBP}.tar.gz
cd libwebp-${VER_LIBWEBP}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --disable-png --disable-jpeg --disable-tiff --disable-gif
make clean && make && make install || exit 1
cp README.md ../doc/libwebp-README.md
cp COPYING ../doc/libwebp-COPYING
rm -f ../bin/*webp*
cd ..

fi

## lcms2
if [ $BUILD_LCMS2 -eq 1 ] ; then
echo "## Building lcms2 ##"

if [ ! -e lcms2-${VER_LCMS2}.tar.gz ]; then
  curl -L -O https://downloads.sourceforge.net/project/lcms/lcms/${VER_LCMS2}/lcms2-${VER_LCMS2}.tar.gz
fi
tar xfz lcms2-${VER_LCMS2}.tar.gz
cd lcms2-${VER_LCMS2}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no
make clean && make && make install || exit 1
cp README.md ../doc/lcms2-README.md
cp LICENSE ../doc/lcms2-LICENSE
cd ..

fi

#### Step 2

## libjbig
if [ $BUILD_LIBJBIG -eq 1 ] ; then
echo "## Building libjbig ##"

if [ ! -e jbigkit-${VER_JBIGKIT}.tar.gz ]; then
  curl -L -O https://www.cl.cam.ac.uk/~mgk25/jbigkit/download/jbigkit-${VER_JBIGKIT}.tar.gz
fi
tar xfz jbigkit-${VER_JBIGKIT}.tar.gz
cd jbigkit-${VER_JBIGKIT}
make lib CFLAGS="-g -O2 ${CFLAGS}" || exit 1
cp -p libjbig/libjbig*.a ${workDir}/lib
cp -p libjbig/*.h ${workDir}/include
cp ANNOUNCE ../doc/jbigkit-ANNOUNCE
cp COPYING ../doc/jbigkit-COPYING
cd ..

fi

## libdjvu
if [ $BUILD_DJVULIB -eq 1 ] ; then
echo "## Building libdjvu ##"

if [ ! -e djvulibre-${VER_DJVULIB}.tar.gz ]; then
  curl -L -O https://twds.dl.sourceforge.net/project/djvu/DjVuLibre/${VER_DJVULIB}/djvulibre-${VER_DJVULIB}.tar.gz
fi
tar xfz djvulibre-${VER_DJVULIB}.tar.gz
cd djvulibre-${VER_DJVULIB}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --disable-xmltools --disable-desktopfiles
make clean && make && make install || exit 1
cp README ../doc/djvulibre-README
cp COPYRIGHT ../doc/djvulibre-COPYRIGHT
rm -rf ../share/djvu
cd ..

fi

## libraw
if [ $BUILD_LIBRAW -eq 1 ] ; then
echo "## Building libraw ##"

if [ ! -e LibRaw-${VER_LIBRAW}.tar.gz ]; then
  curl -L -O https://www.libraw.org/data/LibRaw-${VER_LIBRAW}.tar.gz
fi
tar xfz LibRaw-${VER_LIBRAW}.tar.gz
cd LibRaw-${VER_LIBRAW}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --disable-lcms --disable-examples
make clean && make && make install || exit 1
cp README.md ../doc/LibRaw-README.md
cp COPYRIGHT ../doc/LibRaw-COPYRIGHT
cd ..

fi

## libopenjp2
if [ $BUILD_OPENJP2 -eq 1 ] ; then
echo "## Building libopenjp2 ##"

if [ ! -e openjpeg-${VER_OPENJP2}.tar.gz ]; then
  curl -L -o openjpeg-${VER_OPENJP2}.tar.gz https://github.com/uclouvain/openjpeg/archive/refs/tags/v${VER_OPENJP2}.tar.gz
fi
tar xfz openjpeg-${VER_OPENJP2}.tar.gz
cd openjpeg-${VER_OPENJP2}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_DOC=OFF -DBUILD_CODEC=OFF  -DCMAKE_C_FLAGS="-Wno-unused-command-line-argument"
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/openjpeg-README.md
cp LICENSE ../doc/openjpeg-LICENSE
cd ..

fi

#### Step 3

## Imath
if [ $BUILD_IMATH -eq 1 ] ; then
echo "## Building imath ##"

if [ ! -e Imath-${VER_IMATH}.tar.gz ]; then
  curl -L -O https://github.com/AcademySoftwareFoundation/Imath/releases/download/v${VER_IMATH}/Imath-${VER_IMATH}.tar.gz
fi
tar xfz Imath-${VER_IMATH}.tar.gz
cd Imath-${VER_IMATH}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_WEBSITE=OFF -DPYTHON=OFF -DPYBIND11=OFF
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/Imath-README.md
cp LICENSE.md ../doc/Imath-LICENSE.md
cd ..

fi

## OpenJPH
if [ $BUILD_OPENJPH -eq 1 ] ; then
echo "## Building openjph ##"

if [ ! -e OpenJPH-${VER_OPENJPH}.tar.gz ]; then
  curl -L -o OpenJPH-${VER_OPENJPH}.tar.gz https://github.com/aous72/OpenJPH/archive/refs/tags/${VER_OPENJPH}.tar.gz
fi
tar xfz OpenJPH-${VER_OPENJPH}.tar.gz
cd OpenJPH-${VER_OPENJPH}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DOJPH_BUILD_TESTS=OFF -DOJPH_BUILD_EXECUTABLES=OFF -DOJPH_ENABLE_TIFF_SUPPORT=OFF
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/OpenJPH-README.md
cp LICENSE ../doc/OpenJPH-LICENSE
cd ..

fi

## OpenEXR
if [ $BUILD_OPENEXR -eq 1 ] ; then
echo "## Building openexr ##"

if [ ! -e openexr-${VER_OPENEXR}.tar.gz ]; then
  curl -L -O https://github.com/AcademySoftwareFoundation/openexr/releases/download/v${VER_OPENEXR}/openexr-${VER_OPENEXR}.tar.gz
fi
tar xfz openexr-${VER_OPENEXR}.tar.gz
cd openexr-${VER_OPENEXR}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_WEBSITE=OFF -DOPENEXR_INSTALL_DOCS=OFF -DOPENEXR_BUILD_PYTHON=OFF -DOPENEXR_BUILD_EXAMPLES=OFF -DOPENEXR_BUILD_TOOLS=OFF -DOPENEXR_FORCE_INTERNAL_DEFLATE=ON
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/openexr-README.md
cp LICENSE.md ../doc/openexr-LICENSE.md
cd ..

fi

#### Step 4

## libde265
if [ $BUILD_LIBDE265 -eq 1 ] ; then
echo "## Building libde265 ##"

if [ ! -e libde265-${VER_LIBDE265}.tar.gz ]; then
  curl -L -O https://github.com/strukturag/libde265/releases/download/v${VER_LIBDE265}/libde265-${VER_LIBDE265}.tar.gz
fi
tar xfz libde265-${VER_LIBDE265}.tar.gz
cd libde265-${VER_LIBDE265}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DENABLE_SDL=OFF
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/libde265-README.md
cp COPYING ../doc/libde265-COPYING
cd ..

fi

## aom
if [ $BUILD_AOM -eq 1 ] ; then
echo "## Building aom ##"

if [ ! -e aom-${VER_AOM}.tar.gz ]; then
  rm -rf aom
  git clone --depth 1 --branch v${VER_AOM} https://aomedia.googlesource.com/aom
  tar cfz aom-${VER_AOM}.tar.gz aom
fi
tar xfz aom-${VER_AOM}.tar.gz
cd aom
unset CFLAGS CXXFLAGS
for a in x86_64 arm64; do
  rm -rf build-${a}
  if [ ${a} = "x86_64" ]; then
    isX86_64=1
    isArm64=0
  else
    isX86_64=0
    isArm64=1
  fi
  cmake -S . -B build-${a} -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DCONFIG_SHARED=OFF -DENABLE_TOOLS=OFF -DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_DOCS=OFF -DCMAKE_OSX_ARCHITECTURES:STRING="${a}" -DAOM_TARGET_CPU="${a}" \
  -DAOM_ARCH_X86_64=${isX86_64} -DAOM_ARCH_AARCH64=${isArm64}
  cmake --build build-${a} -v && cmake --install build-${a} || exit 1
done
for f in libaom.a; do
  lipo -create -arch x86_64 build-x86_64/${f} -arch arm64 build-arm64/${f} -output ${workDir}/lib/${f} || exit 1
done
export CFLAGS="-arch x86_64 -arch arm64"
export CXXFLAGS="-arch x86_64 -arch arm64"
cp README.md ../doc/aom-README.md
cp LICENSE ../doc/aom-LICENSE
cd ..

fi

## libheif
if [ $BUILD_LIBHEIF -eq 1 ] ; then
echo "## Building libheif ##"

if [ ! -e libheif-${VER_LIBHEIF}.tar.gz ]; then
  curl -L -O https://github.com/strukturag/libheif/releases/download/v${VER_LIBHEIF}/libheif-${VER_LIBHEIF}.tar.gz
fi
tar xfz libheif-${VER_LIBHEIF}.tar.gz
cd libheif-${VER_LIBHEIF}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DENABLE_PLUGIN_LOADING=OFF -DWITH_EXAMPLES=OFF -DBUILD_DOCUMENTATION=OFF -DWITH_X265=OFF -DWITH_X264=OFF -DWITH_OpenH264_DECODER=OFF -DWITH_OpenH264_ENCODER=OFF -DWITH_AOM_ENCODER=OFF -DWITH_GDK_PIXBUF=OFF
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/libheif-README.md
cp COPYING ../doc/libheif-COPYING
cd ..

fi

#### Step 5

### brotli
if [ $BUILD_BROTLI -eq 1 ] ; then
echo "## Building brotli ##"

if [ ! -e brotli-${VER_BROTLI}.tar.gz ]; then
  curl -L -o brotli-${VER_BROTLI}.tar.gz https://github.com/google/brotli/archive/refs/tags/v${VER_BROTLI}.tar.gz
fi
tar xfz brotli-${VER_BROTLI}.tar.gz
cd brotli-${VER_BROTLI}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBROTLI_BUILD_TOOLS=OFF -DBROTLI_DISABLE_TESTS=ON
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/brotli-README.md
cp LICENSE ../doc/brotli-LICENSE
cd ..

fi

### libhwy
if [ $BUILD_HIGHWAY -eq 1 ] ; then
echo "## Building libhwy ##"

if [ ! -e highway-${VER_HIGHWAY}.tar.gz ]; then
  curl -L -o highway-${VER_HIGHWAY}.tar.gz https://github.com/google/highway/archive/refs/tags/${VER_HIGHWAY}.tar.gz
fi
tar xfz highway-${VER_HIGHWAY}.tar.gz
cd highway-${VER_HIGHWAY}
rm -rf builddir
cmake -S . -B builddir -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DHWY_ENABLE_CONTRIB=OFF -DHWY_ENABLE_EXAMPLES=OFF -DHWY_ENABLE_TESTS=OFF
cmake --build builddir -v && cmake --install builddir || exit 1
cp README.md ../doc/highway-README.md
cp LICENSE ../doc/highway-LICENSE
cd ..

fi

### libjxl
if [ $BUILD_LIBJXL -eq 1 ] ; then
echo "## Building libjxl ##"

if [ ! -e libjxl-${VER_LIBJXL}.tar.gz ]; then
  curl -L -o libjxl-${VER_LIBJXL}.tar.gz https://github.com/libjxl/libjxl/archive/refs/tags/v${VER_LIBJXL}.tar.gz
fi
tar xfz libjxl-${VER_LIBJXL}.tar.gz
cd libjxl-${VER_LIBJXL}
rm -rf build
cmake -S . -B build -DCMAKE_OSX_ARCHITECTURES:STRING="arm64;x86_64" -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DJPEGXL_TEST_TOOLS=OFF -DJPEGXL_ENABLE_TOOLS=OFF -DJPEGXL_ENABLE_DOXYGEN=OFF -DJPEGXL_ENABLE_MANPAGES=OFF -DJPEGXL_ENABLE_BENCHMARK=OFF -DJPEGXL_ENABLE_EXAMPLES=OFF -DJPEGXL_ENABLE_JNI=OFF -DJPEGXL_STATIC=ON -DJPEGXL_ENABLE_SJPEG=OFF -DJPEGXL_ENABLE_OPENEXR=OFF -DENABLE_SKCMS_DEFAULT=NO -DJPEGXL_ENABLE_SKCMS=OFF -DJPEGXL_FORCE_SYSTEM_LCMS2=ON
cmake --build build -v && cmake --install build || exit 1
cp README.md ../doc/libjxl-README.md
cp LICENSE ../doc/libjxl-LICENSE
cd ..

fi

#### Step 6

## libfpx
if [ $BUILD_FPX -eq 1 ] ; then
echo "## Building libfpx ##"

if [ ! -e libfpx-${VER_LIBFPX}.zip ]; then
  curl -L -o libfpx-${VER_LIBFPX}.zip https://github.com/ImageMagick/libfpx/archive/refs/heads/${VER_LIBFPX}.zip
fi
unzip -o libfpx-${VER_LIBFPX}.zip
cd libfpx-${VER_LIBFPX}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no
make clean && make && make install || exit 1
cp README ../doc/libfpx-README
cd ..

fi

## libultrahdr
if [ $BUILD_LIBULTRAHDR -eq 1 ] ; then

if [ ! -e libultrahdr-${VER_LIBULTRAHDR}.tar.gz ]; then
  curl -L -o libultrahdr-${VER_LIBULTRAHDR}.tar.gz https://github.com/google/libultrahdr/archive/refs/tags/v${VER_LIBULTRAHDR}.tar.gz
fi
tar xfz libultrahdr-${VER_LIBULTRAHDR}.tar.gz
cd libultrahdr-${VER_LIBULTRAHDR}
unset CFLAGS CXXFLAGS
for a in x86_64 arm64; do
  rm -rf build-${a}
  cmake -S . -B build-${a} -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DUHDR_BUILD_EXAMPLES=OFF -DCMAKE_OSX_ARCHITECTURES:STRING="${a}"
  cmake --build build-${a} -v && cmake --install build-${a} || exit 1
done
for f in libuhdr.a; do
  lipo -create -arch x86_64 build-x86_64/${f} -arch arm64 build-arm64/${f} -output ${workDir}/lib/${f} || exit 1
done
export CFLAGS="-arch x86_64 -arch arm64"
export CXXFLAGS="-arch x86_64 -arch arm64"
cp README.md ../doc/libultrahdr-README.md
cp LICENSE ../doc/libultrahdr-LICENSE
cd ..

fi

## FLIF
if [ $BUILD_FLIF -eq 1 ] ; then

if [ ! -e FLIF-${VER_FLIF}.tar.gz ]; then
  curl -L -o FLIF-${VER_FLIF}.tar.gz https://github.com/FLIF-hub/FLIF/archive/refs/tags/v${VER_FLIF}.tar.gz
fi
tar xfz FLIF-${VER_FLIF}.tar.gz
cd FLIF-${VER_FLIF}/src
patch -p0 <<'EOF'
*** Makefile.orig	Sun Nov 21 22:31:43 2021
--- Makefile	Sat Aug 29 15:20:31 2026
***************
*** 57,62 ****
--- 57,63 ----
  # Decoder + encoder library - LGPL
  libflif$(LIBEXT): $(FILES_O) library/flif-interface.o
  	$(CXX) -shared -std=gnu++11 $(CPPFLAGS) $(CXXFLAGS) $(LIB_OPTIMIZATIONS) -Wall -fPIC -o libflif$(LIBEXTV) $(FILES_O) library/flif-interface.o -Wl,$(SONAME),libflif$(LIBEXTV) $(LDFLAGS)
+ 	ar cqs libflif.a $(FILES_O) library/flif-interface.o
  	ln -sf libflif$(LIBEXTV) libflif$(LIBEXT)
  
  libflif.dbg$(LIBEXT): $(FILES_H) $(FILES_CPP) library/*.h library/*.hpp library/*.cpp
EOF
for a in x86_64 arm64; do
  make clean; rm -f libflif.a libflif.a-${a}
  make PREFIX=${workDir} CFLAGS="-arch ${a} -I${workDir}/include" CXXFLAGS="-arch ${a} -I${workDir}/include" LDFLAGS="-L${workDir}/lib -lpng -lz" || exit 1
  mv libflif.a libflif.a-${a}
done
lipo -create -arch x86_64 libflif.a-x86_64 -arch arm64 libflif.a-arm64 -output ${workDir}/lib/libflif.a || exit 1
install -m 644 library/*.h ../../include
cd ..
cp README.md ../doc/FLIF-README.md
cp LICENSE ../doc/FLIF-LICENSE
cd ..

fi

## freetype
if [ $BUILD_FREETYPE -eq 1 ] ; then

if [ ! -e freetype-${VER_FREETYPE}.tar.xz ]; then
  curl -L -O https://sourceforge.net/projects/freetype/files/freetype2/${VER_FREETYPE}/freetype-${VER_FREETYPE}.tar.xz
fi

tar xfz freetype-${VER_FREETYPE}.tar.xz
cd freetype-${VER_FREETYPE}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --enable-freetype-config --with-bzip2=no --with-png=no --with-harfbuzz=no --with-brotli=no --with-librsvg=no
make clean && make && make install || exit 1
cd ..

fi

## libwmf
if [ $BUILD_LIBWMF -eq 1 ] ; then

if [ ! -e libwmf-${VER_LIBWMF}.tar.gz ]; then
  curl -L -O https://github.com/caolanm/libwmf/releases/download/v${VER_LIBWMF}/libwmf-${VER_LIBWMF}.tar.gz
fi

tar xfz libwmf-${VER_LIBWMF}.tar.gz
cd libwmf-${VER_LIBWMF}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --enable-gd --disable-pixbuf --without-x
make clean && make && make install || exit 1
cd ..

fi

exit 0
