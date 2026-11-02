#!/bin/sh

set -eu

export ARCH=$(uname -m)
export OUTPATH=./dist
export APPDIR=./AppDir

mkdir -p "$OUTPATH" "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share"

echo "1. Haal appimagetool op..."
curl -sL "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage" -o /usr/bin/appimagetool
chmod +x /usr/bin/appimagetool

echo "2. Kopieer Ladybird bestanden naar AppDir..."
rsync -a /opt/ladybird/usr/lib/	"$APPDIR/usr/lib/"
rsync -a /opt/ladybird/usr/bin/	"$APPDIR/usr/bin/"
rsync -a /opt/ladybird/usr/share/ "$APPDIR/usr/share/"

# Kopieer expliciet de systeem-libs waar Ladybird/Qt tegen linkt:
cp -L /usr/lib/libwoff2*.so* /opt/ladybird/usr/lib/ 2>/dev/null || true
cp -L /usr/lib/libbrotli*.so* /opt/ladybird/usr/lib/ 2>/dev/null || true
cp -L /usr/lib/libfreetype.so* /opt/ladybird/usr/lib/ 2>/dev/null || true
cp -L /usr/lib/libfontconfig.so* /opt/ladybird/usr/lib/ 2>/dev/null || true
cp -L /usr/lib/libharfbuzz.so* /opt/ladybird/usr/lib/ 2>/dev/null || true
cp -L /usr/lib/libicu*.so* /opt/ladybird/usr/lib/ 2>/dev/null || true

# Kopieer eventuele Qt6 platform plugins van het systeem als vcpkg ze daarvan gebruikte:
if [ -d /usr/lib/qt6/plugins ]; then
    mkdir -p /opt/ladybird/usr/lib/qt6/plugins
    cp -ra /usr/lib/qt6/plugins/. /opt/ladybird/usr/lib/qt6/plugins/
fi

echo "4. Maak AppRun aan..."
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:$LD_LIBRARY_PATH"
export XDG_DATA_DIRS="$HERE/usr/share:$XDG_DATA_DIRS"

# Start de binary direct via de meegeleverde loader of het systeem
exec "$HERE/usr/bin/Ladybird" "$@"
EOF
chmod +x "$APPDIR/AppRun"

echo "5. Haal metadata op (desktop & icoon)..."
curl -sL "https://raw.githubusercontent.com/LadybirdBrowser/ladybird/master/Base/res/icons/128x128/app-browser.png" -o "$APPDIR/org.ladybird.Ladybird.png"
curl -sL "https://raw.githubusercontent.com/LadybirdBrowser/ladybird/master/Meta/CMake/freedesktop/org.ladybird.Ladybird.desktop" -o "$APPDIR/org.ladybird.Ladybird.desktop"
ln -sf org.ladybird.Ladybird.png "$APPDIR/.DirIcon"

echo "6. Bouw de AppImage met vanilla appimagetool..."

APPIMAGE_EXTRACT_AND_RUN=1 appimagetool "$APPDIR" "$OUTPATH/Ladybird-$ARCH.AppImage"

echo "Done!"
