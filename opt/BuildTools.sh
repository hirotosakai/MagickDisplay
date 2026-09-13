#!/bin/sh
# BuildTools.sh - build tools for building ImageMagick

BUILD_LIBTOOL=1
BUILD_PKGCONF=1
BUILD_PKGCONFIG=1
BUILD_CMAKE=1
BUILD_YASM=1

VER_LIBTOOL=2.6.2
VER_PKGCONF=3.0.6
VER_PKGCONFIG=0.29.2
VER_CMAKE=4.4.2
VER_YASM=1.3.0

################################################################################
PATH=/usr/bin:/bin

cd "`dirname $0`"
mkdir -p tools
cd tools
mkdir -p bin lib include share

workDir=`pwd`
PATH=${workDir}/bin:${PATH}
################################################################################

## libtool
if [ $BUILD_LIBTOOL -eq 1 ] ; then
echo "## Building libtool ##"

if [ ! -e libtool-${VER_LIBTOOL}.tar.xz ]; then
  curl -L -O https://ftp.gnu.org/gnu/libtool/libtool-${VER_LIBTOOL}.tar.xz
fi
tar xfz libtool-${VER_LIBTOOL}.tar.xz
cd libtool-${VER_LIBTOOL}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no
make clean && make && make install || exit 1
cd ..

fi

## pkgconf
if [ $BUILD_PKGCONF -eq 1 ] ; then
echo "## Building pkgconf ##"

if [ ! -e pkgconf-${VER_PKGCONF}.tar.xz ]; then
  curl -L -O https://distfiles.ariadne.space/pkgconf/pkgconf-${VER_PKGCONF}.tar.xz
fi
tar xfz pkgconf-${VER_PKGCONF}.tar.xz
cd pkgconf-${VER_PKGCONF}
./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --with-system-libdir=/usr/lib --with-system-includedir=/usr/include
make clean && make && make install || exit 1
cd ..

fi

## pkg-config
if [ $BUILD_PKGCONFIG -eq 1 ] ; then
echo "## Building pkg-config ##"

if [ ! -e pkg-config-${VER_PKGCONFIG}.tar.gz ]; then
  curl -L -O https://pkgconfig.freedesktop.org/releases/pkg-config-${VER_PKGCONFIG}.tar.gz
fi
tar xfz pkg-config-${VER_PKGCONFIG}.tar.gz
cd pkg-config-${VER_PKGCONFIG}
CFLAGS="-Wno-int-conversion" ./configure --prefix="${workDir}" --disable-dependency-tracking --enable-shared=no --with-internal-glib
make clean && make && make install || exit 1
cd ..

fi

## cmake
if [ $BUILD_CMAKE -eq 1 ] ; then
echo "## Building cmake ##"

if [ ! -e cmake-${VER_CMAKE}.tar.gz ]; then
  curl -L -O https://github.com/Kitware/CMake/releases/download/v${VER_CMAKE}/cmake-${VER_CMAKE}.tar.gz
fi
tar xfz cmake-${VER_CMAKE}.tar.gz
cd cmake-${VER_CMAKE}
./bootstrap --prefix="${workDir}"
make clean && make && make install || exit 1
cd ..

fi

## yasm
if [ $BUILD_YASM -eq 1 ] ; then
echo "## Installing yasm ##"

rm -rf yasm
git clone --depth 1 https://github.com/yasm/yasm.git
cd yasm
cmake -S . -B build -DCMAKE_PREFIX_PATH="${workDir}" -DCMAKE_INSTALL_PREFIX="${workDir}" -DBUILD_SHARED_LIBS=OFF -DYASM_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE="Release"
cmake --build build -v && cmake --install build || exit 1
cd ..

fi

### yasm 1.3.0
if [ $BUILD_YASM -eq 2 ] ; then
echo "## Installing yasm ##"

if [ ! -e yasm-${VER_YASM}.tar.gz ]; then
  curl -L -O https://github.com/yasm/yasm/releases/download/v${VER_YASM}/yasm-${VER_YASM}.tar.gz
fi
tar xfz yasm-${VER_YASM}.tar.gz
cd yasm-${VER_YASM}
./configure --prefix="${workDir}" --disable-dependency-tracking --disable-nls
make clean && make && make install || exit 1
cd ..

fi

## zlib.pc
pkgconf --exists zlib
if [ $? -ne 0 ] ; then

zlibh="`xcrun --show-sdk-path`/usr/include/zlib.h"
VER_ZLIB=`grep "^#define ZLIB_VERSION" ${zlibh} | cut -d " " -f3 | sed 's/"//g'`

echo "## Making zlib.pc ##"
zlibpc=${workDir}/lib/pkgconfig/zlib.pc
cat > ${zlibpc} <<'EOF'
prefix=/usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
sharedlibdir=${libdir}
includedir=${prefix}/include

Name: zlib
Description: zlib compression library
Version: @zlibVer@
License: Zlib

Requires:
Libs: -L${libdir} -L${sharedlibdir} -lz
Cflags: -I${includedir}
EOF
sed -i -e "s|@zlibVer@|${VER_ZLIB}|g" ${zlibpc}
rm -f ${zlibpc}-e

fi

exit 0
