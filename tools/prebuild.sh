#!/usr/bin/env bash

# Input params
#   $SRCROOT # well, maybe we should find a way to pass it

set -x

git submodule update --remote --merge

ROOT_SOURCE="$PWD/.."
ROOT_XCODE="$ROOT_SOURCE/StudentsManager-IOS"

DLIB_ROOT="$ROOT_SOURCE/submodules/dlib"
DLIB_DIR="$ROOT_SOURCE/third-party/dlib"


if [ ! -d "$DLIB_DIR" ]; then
    mkdir -p "$DLIB_DIR"
        [ $? -eq 0 ] || exit 1

fi

cd "$DLIB_DIR"
cmake -G Xcode "$DLIB_ROOT/dlib" -DCMAKE_XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS="iphoneos iphonesimulator" -DCMAKE_XCODE_ATTRIBUTE_SDKROOT="iphoneos"
