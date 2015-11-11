#!/usr/bin/env bash

## this file is modified from build-linux.sh of ZeroBrane Studio

# setup some directories
MAIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

BIN_DIR="$MAIN_DIR/binary"
BUILD_DIR="$MAIN_DIR/build"
TEMP_DIR="$MAIN_DIR/release"

INSTALL_DIR="$TEMP_DIR/local"

# number of parallel jobs used for building
MAKEFLAGS="-j4"

# flags for manual building with gcc
if [ "$(uname -m)" = "x86_64" ]; then FPIC="-fpic"; else FPIC=""; fi
BUILD_FLAGS="-O2 -shared -s -I $INSTALL_DIR/include -L $INSTALL_DIR/lib $FPIC"

# paths configuration
SOURCEFORGE="http://downloads.sourceforge.net/project"

WXWIDGETS_BASENAME="wxWidgets-2.8.12"
WXWIDGETS_FILENAME="$WXWIDGETS_BASENAME.tar.gz"
WXWIDGETS_URL="$SOURCEFORGE/wxwindows/2.8.12/$WXWIDGETS_FILENAME"

LUAS="52"
LUAD="5.2"
LUA_BASENAME="lua-5.2.4"
LUA_FILENAME="$LUA_BASENAME.tar.gz"
LUA_URL="http://www.lua.org/ftp/$LUA_FILENAME"

WXLUA_BASENAME="wxLua-2.8.12.3-src"
WXLUA_FILENAME="$WXLUA_BASENAME.tar.gz"
WXLUA_URL="$SOURCEFORGE/wxlua/wxlua/2.8.12.3/$WXLUA_FILENAME"

ICONV_BASENAME="libiconv-1.14"
ICONV_FILENAME="$ICONV_BASENAME.tar.gz"
ICONV_URL="http://ftp.gnu.org/pub/gnu/libiconv/$ICONV_FILENAME"

LUAICONV_BASENAME="lua-iconv-master"
LUAICONV_FILENAME="$LUAICONV_BASENAME.tar.gz"
LUAICONV_URL="https://github.com/ittner/lua-iconv/archive/master.tar.gz"

# exit if the command line is empty
if [ $# -eq 0 ]; then
    echo "Usage: $0 LIBRARY..."
    exit 0
fi

WXLUASTRIP="/strip"
WXWIDGETSDEBUG="--disable-debug"
WXLUABUILD="MinSizeRel"

# iterate through the command line arguments
for ARG in "$@"; do
    case $ARG in
    wxwidgets)
        BUILD_WXWIDGETS=true
        ;;
    lua)
        BUILD_LUA=true
        ;;
    wxlua)
        BUILD_WXLUA=true
        ;;
    luaiconv)
        BUILD_ICONV=true
        BUILD_LUAICONV=true
        ;;
    debug)
        WXLUASTRIP=""
        WXWIDGETSDEBUG="--enable-debug=max --enable-debug_gdb"
        WXLUABUILD="Debug"
        TEMP_DIR="$MAIN_DIR/debug"
        INSTALL_DIR="$TEMP_DIR/local"
        ;;
    all)
        BUILD_WXWIDGETS=true
        BUILD_LUA=true
        BUILD_WXLUA=true
        BUILD_ICONV=true
        BUILD_LUAICONV=true
        ;;
    *)
        echo "Error: invalid argument $ARG"
        exit 1
        ;;
    esac
done

# check for g++
if [ ! "$(which g++)" ]; then
    echo "Error: g++ isn't found. Please install GNU C++ compiler."
    exit 1
fi

# check for cmake
if [ ! "$(which cmake)" ]; then
    echo "Error: cmake isn't found. Please install CMake and add it to PATH."
    exit 1
fi

# check for wget
if [ ! "$(which wget)" ]; then
    echo "Error: wget isn't found. Please install GNU Wget."
    exit 1
fi

# preparing source code
function prepare_source {
    # $1 = basename, $2 = filename, $3 = url
    if [ ! -d $1 ]; then
        if [ ! -f $2 ]; then
            wget --no-check-certificate -c "$3" -O "$2" || { echo "Error: failed to download $2"; exit 1; }
        fi
        tar -xzf "$2"
    fi
}

# create the temporary directory
mkdir -p "$TEMP_DIR" || { echo "Error: cannot create directory $TEMP_DIR"; exit 1; }
cd $TEMP_DIR

# create the installation directory
mkdir -p "$INSTALL_DIR" || { echo "Error: cannot create directory $INSTALL_DIR"; exit 1; }

# build wxWidgets
if [ $BUILD_WXWIDGETS ]; then
    prepare_source $WXWIDGETS_BASENAME $WXWIDGETS_FILENAME $WXWIDGETS_URL
    cd "$WXWIDGETS_BASENAME"
    ./configure --prefix="$INSTALL_DIR" $WXWIDGETSDEBUG --disable-shared --enable-unicode \
        --enable-compat28 \
        --with-libjpeg=builtin --with-libpng=builtin --with-libtiff=no --with-expat=no \
     	--with-zlib=builtin --disable-richtext --with-gtk=2 \
        CFLAGS="-Os -fPIC" CXXFLAGS="-Os -fPIC"
    make $MAKEFLAGS || { echo "Error: failed to build wxWidgets"; exit 1; }
    make install
    # with wxwidgets 2.8 we need to build stc separately
    cd contrib/src/stc
    make $MAKEFLAGS || { echo "Error: failed to build wxSTC"; exit 1; }
    make install
    cd ../../..
    cd ..
fi

# build Lua
if [ $BUILD_LUA ]; then
    prepare_source $LUA_BASENAME $LUA_FILENAME $LUA_URL
    cd "$LUA_BASENAME"
    # use POSIX as it has minimum dependencies (no readline and no ncurses required)
    # LUA_USE_DLOPEN is required for loading libraries
    (cd src; make all MYCFLAGS="$FPIC -DLUA_USE_POSIX -DLUA_USE_DLOPEN" MYLIBS="-Wl,-E -ldl") \
        || { echo "Error: failed to build Lua"; exit 1; }
    make install INSTALL_TOP="$INSTALL_DIR"
    cd ..
fi

# build wxLua
if [ $BUILD_WXLUA ]; then
    prepare_source $WXLUA_BASENAME $WXLUA_FILENAME $WXLUA_URL
    cd "$WXLUA_BASENAME"
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DCMAKE_BUILD_TYPE=$WXLUABUILD -DBUILD_SHARED_LIBS=FALSE \
        -DwxWidgets_CONFIG_EXECUTABLE="$INSTALL_DIR/bin/wx-config" \
        -DwxWidgets_COMPONENTS="stc;html;aui;adv;core;net;base" \
        -DwxLuaBind_COMPONENTS="stc;html;aui;adv;core;net;base" \
        -DwxLua_LUA_LIBRARY_USE_BUILTIN=FALSE \
        -DwxLua_LUA_LIBRARY_VERSION=$LUAD \
 	    -DwxLua_LUA_LIBRARY="$INSTALL_DIR/lib/liblua.a" \
        -DwxLua_LUA_INCLUDE_DIR="$INSTALL_DIR/include" .
    (cd modules/luamodule; make $MAKEFLAGS) || { echo "Error: failed to build wxLua"; exit 1; }
    (cd modules/luamodule; make install$WXLUASTRIP)
    [ -f "$INSTALL_DIR/lib/libwx.so" ] || { echo "Error: libwx.so isn't found"; exit 1; }
    cd ..
fi

if [ $BUILD_ICONV ]; then
    prepare_source $ICONV_BASENAME $ICONV_FILENAME $ICONV_URL
    cd "$ICONV_BASENAME"
    sed -i 's/\(_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");\)/\/*\1*\//' srclib/stdio.in.h
    ./configure --prefix="$INSTALL_DIR" --disable-shared --enable-static --disable-nls
    make $MAKEFLAGS || { echo "Error: failed to build iconv"; exit 1; }
    make install
    cd ..
fi

if [ $BUILD_LUAICONV ]; then
    prepare_source $LUAICONV_BASENAME $LUAICONV_FILENAME $LUAICONV_URL
    cd "$LUAICONV_BASENAME"
    gcc -c -o iconv.lo $BUILD_FLAGS luaiconv.c
    gcc -o iconv.so $BUILD_FLAGS iconv.lo -liconv
    cp iconv.so "$INSTALL_DIR/bin"
    [ -f "$INSTALL_DIR/bin/iconv.so" ] || { echo "Error: iconv.so isn't found"; exit 1; }
    cd ..
fi

# now copy the compiled dependencies to binary directory
if [ ! -d $BIN_DIR ]; then
    mkdir -p "$BIN_DIR" || { echo "Error: cannot create directory $BIN_DIR"; exit 1; }
fi

[ $BUILD_LUA ] && cp "$INSTALL_DIR/bin/lua" "$BIN_DIR"
[ $BUILD_WXLUA ] && cp "$INSTALL_DIR/lib/libwx.so" "$BIN_DIR/wx.so"
[ $BUILD_LUAICONV ] && cp "$INSTALL_DIR/bin/iconv.so" "$BIN_DIR/iconv.so"

echo "*** Build has been successfully completed ***"
exit 0
