#!/usr/bin/env bash

## this file is modified from build-macosx.sh of ZeroBrane Studio

# setup some directories
MAIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

BIN_DIR="$MAIN_DIR/binary"
BUILD_DIR="$MAIN_DIR/build"
TEMP_DIR="$MAIN_DIR/release"

INSTALL_DIR="$TEMP_DIR/local"

# Mac OS X global settings
MACOSX_ARCH="i386"
MACOSX_VERSION="10.6"

# number of parallel jobs used for building
MAKEFLAGS="-j4"

# flags for manual building with gcc
MACOSX_FLAGS="-arch $MACOSX_ARCH -mmacosx-version-min=$MACOSX_VERSION"
BUILD_FLAGS="-O2 -arch x86_64 -dynamiclib -undefined dynamic_lookup $MACOSX_FLAGS -I $INSTALL_DIR/include -L $INSTALL_DIR/lib"

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
    debug)
        WXLUASTRIP=""
        WXWIDGETSDEBUG="--enable-debug=max"
        WXLUABUILD="Debug"
        TEMP_DIR="$MAIN_DIR/debug"
        INSTALL_DIR="$TEMP_DIR/local"
        ;;
    all)
        BUILD_WXWIDGETS=true
        BUILD_LUA=true
        BUILD_WXLUA=true
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
            wget -c "$3" -O "$2" || { echo "Error: failed to download $2"; exit 1; }
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
     	--with-zlib=builtin --disable-richtext \
	    --enable-macosx_arch=$MACOSX_ARCH --with-macosx-version-min=$MACOSX_VERSION \
        CFLAGS="-Os" CXXFLAGS="-Os"
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
    sed -i "" 's/PLATS=/& macosx_dylib/' Makefile
    # -O1 fixes this issue with for Lua 5.2 with i386: http://lua-users.org/lists/lua-l/2013-05/msg00070.html
    printf "macosx_dylib:\n" >> src/Makefile
    printf "\t\$(MAKE) LUA_A=\"liblua$LUAS.dylib\" AR=\"\$(CC) -dynamiclib $MACOSX_FLAGS -o\" RANLIB=\"strip -u -r\" \\\\\n" >> src/Makefile
    printf "\tMYCFLAGS=\"-O1 -DLUA_USE_LINUX $MACOSX_FLAGS\" MYLDFLAGS=\"$MACOSX_FLAGS\" MYLIBS=\"-lreadline\" lua\n" >> src/Makefile
    printf "\t\$(MAKE) MYCFLAGS=\"-DLUA_USE_LINUX $MACOSX_FLAGS\" MYLDFLAGS=\"$MACOSX_FLAGS\" luac\n" >> src/Makefile
    make macosx_dylib || { echo "Error: failed to build Lua"; exit 1; }
    make install INSTALL_TOP="$INSTALL_DIR"
    cp src/liblua$LUAS.dylib "$INSTALL_DIR/lib"
    # otherwise wxlua could not find it
    cp src/liblua$LUAS.dylib "$INSTALL_DIR/lib/liblua.dylib"
    strip -u -r "$INSTALL_DIR/bin/lua"
    [ -f "$INSTALL_DIR/lib/liblua$LUAS.dylib" ] || { echo "Error: liblua$LUAS.dylib isn't found"; exit 1; }
    cd ..
fi

# build wxLua
if [ $BUILD_WXLUA ]; then
    prepare_source $WXLUA_BASENAME $WXLUA_FILENAME $WXLUA_URL
    cd "$WXLUA_BASENAME"
    # otherwise wxwidgets could not be successfully compiled
    sed -i "" 's/\(#define wxLUA_USE_wxPopupWindow\)/\/\/\1/' modules/wxbind/setup/wxluasetup.h
    sed -i "" 's/\(#define wxLUA_USE_wxPopupTransientWindow\)/\/\/\1/' modules/wxbind/setup/wxluasetup.h
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DCMAKE_BUILD_TYPE=$WXLUABUILD -DBUILD_SHARED_LIBS=FALSE \
        -DCMAKE_OSX_ARCHITECTURES=$MACOSX_ARCH -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_VERSION \
        -DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
        -DwxWidgets_CONFIG_EXECUTABLE="$INSTALL_DIR/bin/wx-config" \
        -DwxWidgets_COMPONENTS="stc;html;aui;adv;core;net;base" \
        -DwxLuaBind_COMPONENTS="stc;html;aui;adv;core;net;base" \
        -DwxLua_LUA_LIBRARY_USE_BUILTIN=FALSE \
        -DwxLua_LUA_LIBRARY_VERSION=$LUAD \
 	    -DwxLua_LUA_LIBRARY="$INSTALL_DIR/lib/liblua$LUAS.dylib" \
        -DwxLua_LUA_INCLUDE_DIR="$INSTALL_DIR/include" .
    (cd modules/luamodule; make $MAKEFLAGS) || { echo "Error: failed to build wxLua"; exit 1; }
    (cd modules/luamodule; make install$WXLUASTRIP)
    if [ $WXLUASTRIP ]; then strip -u -r "$INSTALL_DIR/lib/libwx.dylib"; fi
    [ -f "$INSTALL_DIR/lib/libwx.dylib" ] || { echo "Error: libwx.dylib isn't found"; exit 1; }
    cd ..
fi

# now copy the compiled dependencies to binary directory
if [ ! -d $BIN_DIR ]; then
    mkdir -p "$BIN_DIR" || { echo "Error: cannot create directory $BIN_DIR"; exit 1; }
fi

[ $BUILD_LUA ] && cp "$INSTALL_DIR/bin/lua" "$INSTALL_DIR/lib/liblua$LUAS.dylib" "$BIN_DIR"
[ $BUILD_WXLUA ] && cp "$INSTALL_DIR/lib/libwx.dylib" "$BIN_DIR/wx.dylib"

echo "*** Build has been successfully completed ***"
exit 0
