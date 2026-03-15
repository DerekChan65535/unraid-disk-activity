<?PHP
/* Copyright 2026, Derek
 * License: GPLv2
 *
 * DiskActivity.php - JSON API endpoint returning disk activity percentages.
 * Called via AJAX from the front-end JavaScript.
 *
 * Returns JSON keyed by disk name: {"app": 5, "zpool~cache": 82, ...}
 * Also includes device-keyed data: {"_devices": {"sda": 5, "nvme0n1": 82}}
 */

// Authentication is handled by nginx auth_request module.
// All requests reaching this script are already authenticated.

$varroot = '/var/local/emhttp';
$activityIni = "$varroot/disk_activity.ini";
$disksIni = "$varroot/disks.ini";

header('Content-Type: application/json');

if (!file_exists($activityIni)) {
  echo '{}';
  exit;
}

$activity = @parse_ini_file($activityIni);
if ($activity === false) {
  echo '{}';
  exit;
}

// Clamp all values to 0-100
foreach ($activity as $dev => &$pct) {
  $val = intval($pct);
  $pct = max(0, min(100, $val));
}
unset($pct);

// Build device-to-name mapping from disks.ini
$result = [];
$disks = @parse_ini_file($disksIni, true);
if ($disks !== false) {
  foreach ($disks as $section => $disk) {
    $dev = $disk['device'] ?? '';
    if ($dev !== '' && isset($activity[$dev])) {
      $result[$section] = $activity[$dev];
    }
  }
}

// Also include raw device data for flexibility
$result['_devices'] = $activity;

// Include display setting so front-end knows the render mode
$cfgFile = '/boot/config/plugins/disk.activity/disk.activity.cfg';
$defaultFile = dirname(__DIR__) . '/default.cfg';
$cfg = [];
if (file_exists($defaultFile)) $cfg = @parse_ini_file($defaultFile) ?: [];
if (file_exists($cfgFile)) $cfg = array_merge($cfg, @parse_ini_file($cfgFile) ?: []);
$result['_config'] = ['display' => $cfg['display'] ?? 'bar'];

echo json_encode($result);
