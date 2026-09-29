#!/usr/bin/env bash
# Keep the phone drivable.
#
# Android drops adbd when the phone reboots, and wireless debugging dies when
# Wi-Fi flaps, so a working setup silently stops working days later. This
# reconnects on a timer. Point it at the phone's stable address (a tailnet IP is
# ideal, because it does not change between networks).
#
#   PHONE_ADDR=100.x.y.z:5555 ./reconnect.sh
#   PHONE_LAN_ADDR=192.168.1.50:5555 ./reconnect.sh   # optional fallback
#
# Run it from launchd/cron every couple of minutes. Quiet when healthy.
set -uo pipefail
LOG="${PHONE_LOG:-$HOME/.android-driver/reconnect.log}"
ADDR="${PHONE_ADDR:-$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.android-driver/config.json'))).get('address',''))" 2>/dev/null)}"
LAN="${PHONE_LAN_ADDR:-}"

[[ -z "$ADDR" ]] && { echo "set PHONE_ADDR or ~/.android-driver/config.json first" >&2; exit 2; }
adb devices | awk '$2=="device"{print $1}' | head -1 | grep -q . && exit 0

out=$(adb connect "$ADDR" 2>&1)
echo "$(date '+%F %T')  no device -> $ADDR: $out" >> "$LOG"
adb devices | awk '$2=="device"{print $1}' | head -1 | grep -q . && exit 0

if [[ -n "$LAN" ]]; then
  out2=$(adb connect "$LAN" 2>&1)
  echo "$(date '+%F %T')  $LAN: $out2" >> "$LOG"
fi
mkdir -p "$(dirname "$LOG")"; tail -200 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
