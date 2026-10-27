#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook:x86-64-v3-check.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=https://raw.githubusercontent.com/LadybirdBrowser/ladybird/refs/heads/master/Base/res/icons/128x128/app-browser.png
export DESKTOP=https://raw.githubusercontent.com/LadybirdBrowser/ladybird/refs/heads/master/Meta/CMake/freedesktop/org.ladybird.Ladybird.desktop

echo "Fetching quick-sharun..."
curl -sL "https://github.com/pkgforge-dev/sharun/releases/latest/download/sharun-x86_64" -o /usr/bin/quick-sharun
chmod +x /usr/bin/quick-sharun

# Deploy dependencies
export LD_LIBRARY_PATH="/opt/ladybird/usr/lib:/opt/angle/usr/lib"
export LD_SHARUN="/lib/ld-linux-x86-64.so.2"

quick-sharun \
    /opt/ladybird/usr/bin/* \
    /opt/ladybird/usr/lib \
    /opt/angle/lib \
    /opt/ladybird/usr/share/*

unset LD_LIBRARY_PATH
mv -v ./AppDir/lib/angle/usr/lib/* ./AppDir/lib

quick-sharun --make-appimage

pacman -S --noconfirm vulkan-swrast # app now needs a vulkan device to launch
quick-sharun --test ./dist/*.AppImage
