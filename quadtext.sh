#!/bin/bash

# see http://stackoverflow.com/a/246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# only for macosx
export DYLD_LIBRARY_PATH="$DIR/binary:${DYLD_LIBRARY_PATH}"

(cd "$DIR"; $DIR/binary/lua $DIR/source/main.lua "$@") &
