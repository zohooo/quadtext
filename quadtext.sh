#!/bin/bash

## this file is modified from zbstudio.sh of ZeroBrane Studio

# see http://stackoverflow.com/a/246128
MAIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $(uname) == 'Darwin' ]]; then
    export MAIN_DIR
    (cd "$MAIN_DIR"; open build/macosx/QuadText.app --args "$@")
else
    (cd "$MAIN_DIR"; $MAIN_DIR/binary/lua $MAIN_DIR/source/main.lua "$@") &
fi
