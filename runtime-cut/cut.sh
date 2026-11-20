#!/bin/sh
# How a runtime built by this recipe (jre21-android-<arch>) is cut down before it ships: its class
# library is linked again with these modules only (jlink), compressed, without debug data. Its
# native libraries are used unchanged; only the libraries listed in LIBRARIES are shipped.
#
#   sh cut.sh <runtime folder> <output folder>
#
# Needs a JDK 21 (jimage and jlink on the PATH) and Python 3. The Android runtime ships no jmods:
# its image is unpacked and linked from those exploded modules, without java.base's hashes of the
# other modules (jlink cannot hash exploded modules) and without generating the method-handle
# classes the image already holds.
set -e
RT=$1
OUT=$2
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
MODULES=java.base,java.desktop,java.xml,java.logging,java.net.http,java.sql,java.naming,jdk.httpserver,jdk.management,jdk.crypto.ec,jdk.unsupported,jdk.charsets,jdk.localedata
LIBRARIES="libjava.so libjimage.so libnet.so libnio.so libzip.so libverify.so libextnet.so libsyslookup.so libprefs.so libmanagement.so libmanagement_ext.so libawt.so libawt_headless.so libfontmanager.so libfreetype.so libjavajpeg.so liblcms.so libmlib_image.so"

jimage extract --dir "$WORK/exploded" "$RT/lib/modules"
python3 "$HERE/strip_module_hashes.py" "$WORK/exploded/java.base/module-info.class"
jlink --module-path "$WORK/exploded" --add-modules "$MODULES" \
    --disable-plugin generate-jli-classes --strip-debug --compress=zip-6 \
    --no-header-files --no-man-pages --output "$WORK/linked"

# The runtime's own files (its lib/modules replaced by the linked one), without its programs.
mkdir -p "$OUT"
(cd "$RT" && find . -type f ! -name '*.so' ! -path './bin/*' ! -name jspawnhelper ! -name jexec) | while read -r f; do
    mkdir -p "$OUT/$(dirname "$f")"
    cp "$RT/$f" "$OUT/$f"
done
cp "$WORK/linked/lib/modules" "$OUT/lib/modules"
# The native libraries shipped, unchanged (libjvm.so from lib/server, or lib/client on 32-bit arm).
for name in $LIBRARIES; do cp "$RT/lib/$name" "$OUT/lib/$name"; done
if [ -f "$RT/lib/server/libjvm.so" ]; then mkdir -p "$OUT/lib/server" && cp "$RT/lib/server/libjvm.so" "$OUT/lib/server/"; fi
if [ -f "$RT/lib/client/libjvm.so" ]; then mkdir -p "$OUT/lib/client" && cp "$RT/lib/client/libjvm.so" "$OUT/lib/client/"; fi
rm -rf "$WORK"
