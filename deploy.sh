#!/bin/bash
#
# deploy.sh - Quick deploy to Unraid server for testing
#             Copies files directly (no TXZ packaging needed)
#
# Usage: ./deploy.sh [server_ip]
# Example: ./deploy.sh 192.168.2.202
#

set -e

SERVER="${1:-192.168.2.202}"
PLUGIN_DIR="/usr/local/emhttp/plugins/disk.activity"
SOURCE_DIR="$(dirname "$0")/source/usr/local/emhttp/plugins/disk.activity"

echo "Deploying disk.activity plugin to root@${SERVER}..."

# Stop existing daemon if running
ssh "root@${SERVER}" "[ -f ${PLUGIN_DIR}/scripts/rc.disk_activity ] && ${PLUGIN_DIR}/scripts/rc.disk_activity stop 2>/dev/null || true"

# Create plugin directory structure on server
ssh "root@${SERVER}" "mkdir -p ${PLUGIN_DIR}/{scripts,include,assets,event/started,event/stopping_svcs}"

# Copy all files
scp "${SOURCE_DIR}/scripts/disk_activity" "root@${SERVER}:${PLUGIN_DIR}/scripts/"
scp "${SOURCE_DIR}/scripts/rc.disk_activity" "root@${SERVER}:${PLUGIN_DIR}/scripts/"
scp "${SOURCE_DIR}/include/DiskActivity.php" "root@${SERVER}:${PLUGIN_DIR}/include/"
scp "${SOURCE_DIR}/DiskActivityColumn.page" "root@${SERVER}:${PLUGIN_DIR}/"
scp "${SOURCE_DIR}/assets/disk-activity.css" "root@${SERVER}:${PLUGIN_DIR}/assets/"
scp "${SOURCE_DIR}/event/started/disk_activity_start" "root@${SERVER}:${PLUGIN_DIR}/event/started/"
scp "${SOURCE_DIR}/event/stopping_svcs/disk_activity_stop" "root@${SERVER}:${PLUGIN_DIR}/event/stopping_svcs/"

# Set permissions
ssh "root@${SERVER}" "chmod +x ${PLUGIN_DIR}/scripts/disk_activity ${PLUGIN_DIR}/scripts/rc.disk_activity ${PLUGIN_DIR}/event/started/disk_activity_start ${PLUGIN_DIR}/event/stopping_svcs/disk_activity_stop"

# Start daemon if array is running
ssh "root@${SERVER}" "if grep -q 'mdState=STARTED' /var/local/emhttp/var.ini 2>/dev/null; then ${PLUGIN_DIR}/scripts/rc.disk_activity start; echo 'Daemon started'; else echo 'Array not started - daemon will start when array starts'; fi"

echo ""
echo "Deploy complete! Refresh the Array Devices page in your browser."
