#!/usr/bin/env bash
set -e

# Install dependencies
pacman -S --needed --no-confirm autoconf-archive base-devel ccache cmake curl git less libgl libpulse nasm ninja python qt6-base qt6-positioning qt6-tools ttf-liberation tar unzip wayland xcb-util-wm zip

# Prepare AppDir one level above ladybird
ROOT_DIR="$(pwd)"
APPDIR="$ROOT_DIR/AppDir"

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/bin"

# Clone ladybird repository
if [ ! -d "ladybird" ]; then
    git clone https://github.com/LadybirdBrowser/ladybird.git
fi

cd ladybird

# Build and install using the AppDir outside the ladybird directory
cmake --preset Release -B Build/release -DCMAKE_INSTALL_PREFIX="$APPDIR/usr"
cmake --build Build/release
cmake --install Build/release

# ldd scan

cd "$ROOT_DIR"

echo "=== 1. Setting up LD_LIBRARY_PATH for scanning ==="
export LD_LIBRARY_PATH="$APPDIR/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

echo "=== 2. Iterative LDD Scan (Copying missing host dependencies) ==="
while true; do
    # Scan all binaries and shared libraries in AppDir for missing dependencies
    MISSING=$(find "$APPDIR" -type f \( -name "*.so*" -o -executable \) -exec ldd {} 2>/dev/null \; | grep "not found" | awk '{print $1}' | sort -u)

    if [ -z "$MISSING" ]; then
        echo "Check completed: All shared libraries are successfully bundled!"
        break
    fi

    COPIED=0
    for lib in $MISSING; do
        # Locate the target library file in host /usr/lib
        TARGET_LIB=$(find /usr/lib -maxdepth 2 -name "$lib*" -print -quit)

        if [ -n "$TARGET_LIB" ]; then
            echo " -> Copying from host /usr/lib: $lib"
            cp -cL "$TARGET_LIB" "$APPDIR/usr/lib/$lib" 2>/dev/null || true
            COPIED=$((COPIED + 1))
        fi
    done

    # Break loop if a missing library cannot be found anywhere in host /usr/lib
    if [ "$COPIED" -eq 0 ]; then
        echo "Warning: The following dependencies could not be found in host /usr/lib:"
        echo "$MISSING"
        break
    fi
done

echo "=== 3. Copying Qt6 Platform Plugins ==="
# Copy Qt6 platform plugins (Wayland / XCB / etc.) from host /usr/lib
if [ -d /usr/lib/qt6/plugins ]; then
    mkdir -p "$APPDIR/usr/lib/qt6/plugins"
    cp -ra /usr/lib/qt6/plugins/. "$APPDIR/usr/lib/qt6/plugins/"
fi

## add AppRun

echo "=== 4. Creating AppRun Script ==="
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"

# Safe LD_LIBRARY_PATH export
export LD_LIBRARY_PATH="$HERE/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Point Qt to bundled plugins
export QT_PLUGIN_PATH="$HERE/usr/lib/qt6/plugins"

# Point to bundled resource files
export XDG_DATA_DIRS="$HERE/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

exec "$HERE/usr/bin/Ladybird" "$@"
EOF

chmod +x "$APPDIR/AppRun"

echo "=== 5. Generating AppImage with appimagetool ==="

# Create dist directory in root if it doesn't exist
mkdir -p "$ROOT_DIR/dist"

# Download appimagetool if not available on host
    echo "Downloading appimagetool..."
    curl -LO "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x appimagetool-x86_64.AppImage
    export APPIMAGETOOL="./appimagetool-x86_64.AppImage"

# Build the final AppImage directly into the dist folder
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$ROOT_DIR/dist/Ladybird-x86_64.AppImage"

echo "=== SUCCESS: $ROOT_DIR/dist/Ladybird-x86_64.AppImage created! ==="
