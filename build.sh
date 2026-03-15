#!/bin/bash
#
# build.sh - Build the TXZ package for disk.activity plugin
#
# Usage: ./build.sh [version]
# Example: ./build.sh 2026.03.09
#

set -e

PLUGIN_NAME="disk.activity"
VERSION="${1:-2026.03.09}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/source"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT="${BUILD_DIR}/${PLUGIN_NAME}-${VERSION}.txz"
MD5_FILE="${BUILD_DIR}/${PLUGIN_NAME}-${VERSION}.md5"

echo "Building ${PLUGIN_NAME} v${VERSION}..."

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Ensure all scripts have LF line endings (not CRLF)
echo "Fixing line endings..."
find "$SOURCE_DIR" -type f \( -name '*.sh' -o -name 'disk_activity' -o -name 'rc.disk_activity' \
  -o -name 'disk_activity_start' -o -name 'disk_activity_stop' \) -exec sed -i 's/\r$//' {} +
find "$SOURCE_DIR" -type f \( -name '*.page' -o -name '*.php' -o -name '*.css' -o -name '*.cfg' \) \
  -exec sed -i 's/\r$//' {} +

# Ensure scripts are executable
chmod +x "$SOURCE_DIR/usr/local/emhttp/plugins/disk.activity/scripts/disk_activity"
chmod +x "$SOURCE_DIR/usr/local/emhttp/plugins/disk.activity/scripts/rc.disk_activity"
chmod +x "$SOURCE_DIR/usr/local/emhttp/plugins/disk.activity/event/started/disk_activity_start"
chmod +x "$SOURCE_DIR/usr/local/emhttp/plugins/disk.activity/event/stopping_svcs/disk_activity_stop"

# Create the TXZ (Slackware package format)
# The archive should contain paths relative to / (i.e., usr/local/emhttp/...)
cd "$SOURCE_DIR"
tar cJf "$OUTPUT" usr/
cd "$SCRIPT_DIR"

echo "Package built: $OUTPUT"
echo "Size: $(du -h "$OUTPUT" | cut -f1)"

# Generate MD5 checksum file
MD5=$(md5sum "$OUTPUT" | cut -d' ' -f1)
echo "$MD5" > "$MD5_FILE"
echo "MD5: $MD5"
echo "MD5 file: $MD5_FILE"

echo ""
echo "Build artifacts in $BUILD_DIR:"
ls -lh "$BUILD_DIR"
echo ""
echo "=== Publishing checklist ==="
echo "1. Create GitHub release v${VERSION}"
echo "2. Upload ${PLUGIN_NAME}-${VERSION}.txz as a release asset"
echo "3. Copy ${PLUGIN_NAME}-${VERSION}.md5 to repo root"
echo "4. Update GITHUB_USER in disk.activity.plg with your GitHub username"
echo "5. Commit and push disk.activity.plg to the main branch"
echo ""
echo "Local install:"
echo "  scp $OUTPUT root@<server>:/boot/config/plugins/${PLUGIN_NAME}/"
echo "  ssh root@<server> upgradepkg --install-new /boot/config/plugins/${PLUGIN_NAME}/${PLUGIN_NAME}-${VERSION}.txz"
