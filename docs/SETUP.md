# Setup

Two sides: the Mac (or Linux box) that drives, and the phone that is driven.

## Host

```bash
./bin/install-mac.sh
```

That installs `adb` + `scrcpy` via Homebrew, links `adbdrv` onto your PATH, and
creates `~/.android-driver/`. On Linux use your package manager for
`android-tools-adb` and `scrcpy`, then symlink `bin/adbdrv` somewhere on PATH.

## Phone, once

1. **Developer options** — Settings → About phone → tap **Build number** seven
   times. (On some ROMs it is under About → Software information.)
2. **USB debugging** → on.
3. Plug in and accept the **Allow USB debugging?** prompt. Tick *always allow from
   this computer* so it does not ask again.

Verify:

```bash
adb devices          # should show <serial>  device   (not "unauthorized")
```

`unauthorized` means the prompt is still waiting on the phone screen. Look at the
phone.

## Make it wireless

Wireless debugging in Settings works, but pairing codes and a random port that
changes every reboot are a poor foundation. Going through `tcpip` once is simpler
and sticks to a port you choose:

```bash
adb tcpip 5555                        # adbd now listens on all interfaces:5555
adb shell ip -4 addr show wlan0       # find the phone's LAN address
adb connect <that-ip>:5555
adbdrv status
```

You can unplug now. Everything below works over the network.

**Wireless debugging is optional.** If you prefer it, enable it and pair with
`adb pair <ip:port> <code>`. Both can coexist: `adb_wifi_enabled=1` alongside
`service.adb.tcp.port=5555`. Switch between them freely.

**Tailscale (or any VPN mesh) is the best address.** A tailnet IP is stable across
Wi-Fi and cellular, so `adb connect <tailnet-ip>:5555` keeps working when the
phone leaves the house — and the traffic never leaves your own network.

## Settings you can apply over adb instead of tapping

```bash
adb shell settings put global stay_on_while_plugged_in 7   # screen never sleeps while charging
adb shell settings put global adb_wifi_enabled 1           # the Wireless debugging toggle
adb shell dumpsys deviceidle whitelist +<your.vpn.app>     # stop Android dozing the VPN
```

`stay_on_while_plugged_in` is the single biggest reliability win: if the screen
sleeps, uiautomator cannot read the tree and every command starts failing.

Also turn on **Disable adb authorization timeout** in Developer options. Without
it, an authorized host is forgotten after 7 days and your setup silently stops.

## Unicode and emoji

adb's own `input text` is ASCII-only and drops everything else *silently*. Install
ADBKeyboard (`com.android.adbkeyboard`) on the phone, and the driver will switch it
in for the duration of a `type`, then restore your real keyboard:

```bash
adb install ADBKeyboard.apk
adb shell ime enable com.android.adbkeyboard/.AdbIME
```

`adbdrv status` tells you which mode you are in. Leaving ADBKeyboard selected would
give you a blank keyboard, which is why the driver always switches back.

## Keep it alive

Wireless adb dies on reboot. Run `bin/reconnect.sh` on a timer and it heals
itself. Store the address once:

```bash
cat > ~/.android-driver/config.json <<'EOF'
{ "address": "<tailnet-ip>:5555" }
EOF
```

macOS — `~/Library/LaunchAgents/com.snuse.reconnect.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.snuse.reconnect</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>/ABSOLUTE/PATH/TO/bin/reconnect.sh</string>
  </array>
  <key>StartInterval</key><integer>120</integer>
  <key>RunAtLoad</key><true/>
</dict></plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.snuse.reconnect.plist
```

Linux: `*/2 * * * * /path/to/bin/reconnect.sh` in crontab.

## When it stops working

In this order. It resolves nearly everything.

1. `adb devices` — nothing there? Run `bin/reconnect.sh` and read its log.
2. **The money test:** `nc -z <phone-ip> 5555`. Refused means adbd is not
   listening: the phone rebooted or wireless adb was torn down. Over USB,
   `adb tcpip 5555` again.
3. `adbdrv status` — if it says `asleep` or unlocked is false, wake the phone and
   unlock it.
4. `adbdrv ui` prints "Couldn't read the screen"? Either it is locked or a secure
   window is up.
5. Still stuck: `adb kill-server && adb start-server`, replug USB, re-authorize.

**Never diagnose from a settings toggle.** Wireless debugging can read "on" while
nothing is listening. Port state is the truth.

**`more than one device/emulator`** — the same phone is attached twice (USB *and*
`:5555`, or `:5555` plus an mDNS entry). `adbdrv` collapses duplicates and prefers
USB automatically; raw `adb` needs `-s <serial>`.