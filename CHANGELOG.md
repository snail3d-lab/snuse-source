# Changelog

## 1.0.0
- `adbdrv`: 22-command driver over adb — snapshot, tap-by-label, type, wait, shot,
  push, watch. See-and-act loop with verify-from-fresh-state.
- Handles the duplicate-transport failure (the same phone appearing over USB and
  TCP at once), which otherwise breaks every command after you go wireless.
- UTF-8/emoji text entry via ADBKeyboard, with a temporary-IME switch so the
  user's own keyboard is restored afterwards.
- `reconnect.sh` + launchd/cron recipe so a working setup survives reboots.
- Two agent skills: `android-phone` (mechanics) and `facebook-marketplace`
  (Marketplace listings + Messenger replies, with an approval gate).
- Docs: phone-side setup, recipes, and what actually leaves the machine.
