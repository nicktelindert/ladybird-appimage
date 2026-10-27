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
cp -ra /opt/ladybird/usr/bin/* "$APPDIR/usr/bin/" 2>/dev/null || true
cp -ra /opt/ladybird/usr/lib/* "$APPDIR/usr/lib/" 2>/dev/null || true
cp -ra /opt/ladybird/usr/share/* "$APPDIR/usr/share/" 2>/dev/null || true
[ -d /opt/angle/lib ] && cp -ra /opt/angle/lib/* "$APPDIR/usr/lib/" 2>/dev/null || true

echo "3. Kopieer de Arch glibc dynamic loader..."
# Pak de fysieke loader van Arch mee
cp -L /usr/lib/ld-linux-x86-64.so.2 "$APPDIR/usr/lib/"

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
