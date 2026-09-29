---
name: android-phone
description: Drive an Android phone over adb (tap, type, read).
version: 1.0.0
author: Snail3D
license: MIT
platforms: [macos, linux]
prerequisites:
  commands: [adb, adbdrv, scrcpy]
metadata:
  hermes:
    tags: [android, adb, phone, automation, mobile, marketplace, messenger]
    related_skills: [facebook-marketplace]
---

# Android Phone Driver (adb)

The phone is a **legible device**: `adbdrv` turns its accessibility tree into text
an agent can read, and turns taps and text into the same events a finger makes. It
is a real phone over adb — no emulator, no cloud, no service account.

## When to Use

- Any app with no API. Facebook Marketplace and Messenger are the usual ones.
- "check my messages", "what's on my phone", "post this for sale".
- Reading a phone-only thing: SMS, notifications, a delivery app.
- Getting a file from the computer into the phone's gallery.
- Not for web pages on the desktop (use a browser tool), and not for desktop GUI
  apps (use a computer-use tool).

## The one rule

**snapshot → act → verify from fresh state.** The tree moves after every action.
Never chain three taps from memory: tap, snapshot, tap. This single discipline is
the difference between working and flailing.

## Setup (once)

On the phone: Developer options → **USB debugging** on → plug in → accept the
prompt. Then make it wireless, which sticks better than pairing codes:

```bash
adb tcpip 5555
adb connect <phone-ip>:5555
adbdrv status
```

Apply the reliability settings over adb rather than tapping menus:

```bash
adb shell settings put global stay_on_while_plugged_in 7    # screen never sleeps while charging
adb shell dumpsys deviceidle whitelist +<your.vpn.app>      # stop Android dozing the VPN
```

For emoji and accents, install **ADBKeyboard** (`com.android.adbkeyboard`). adb's
own `input text` is ASCII-only and drops everything else *silently*. `adbdrv type`
switches ADBKeyboard in for the duration and restores the user's own keyboard
afterwards, so nothing is left broken. `adbdrv status` says which mode is live.

Full walk-through, including the keepalive that survives reboots: `docs/SETUP.md`.

## The commands

| Command | Does |
|---|---|
| `adbdrv status` | device, Android version, awake/locked, foreground app, battery |
| `adbdrv ui` | **snapshot** — every element, indexed, with flags |
| `adbdrv ui --text` | just the words on screen — the fast way to read |
| `adbdrv find "<text>"` | locate text, print matches and coordinates |
| `adbdrv tap <sel>` | tap by text / `id:` / `desc:` / `@n` / `x,y` |
| `adbdrv long <sel>` | long-press, for edit and delete menus |
| `adbdrv scroll up\|down\|top\|bottom` | page the screen |
| `adbdrv type "<text>"` | type into the focused field, unicode-safe |
| `adbdrv key back\|home\|enter\|recents` | hardware keys |
| `adbdrv open <url\|pkg>` | launch an app, activity, or URL |
| `adbdrv wait "<text>" <secs>` | **verify** — block until it appears |
| `adbdrv fg` | which app is in front |
| `adbdrv shot -o /tmp/a.png` | screenshot, then look at it |
| `adbdrv push <file> --dcim` | put a file in the phone gallery |
| `adbdrv watch [--virtual]` | mirror the screen, or a hidden virtual display |
| `adbdrv shell '<cmd>'` | raw adb for anything not wrapped |

Selectors match the element text **or** its content description,
case-insensitively. Exact matches beat substrings and clickable beats
non-clickable, so `adbdrv tap "Send"` picks the real Send button rather than a
label. When two candidates genuinely exist, snapshot and use `adbdrv tap @12`.

## Gotchas that cost real time

| Symptom | Cause and fix |
|---|---|
| `Couldn't read the screen` | Locked, or a secure window (banking, passwords) — those are invisible by design. Wake it, then ask the user to unlock. |
| Stale snapshot | uiautomator is flaky right after a tap. `adbdrv` retries; if it is still stale, sleep a second and snapshot again. |
| Tapped the wrong element | Duplicate labels. Snapshot, then use `@n` or an `id:`. |
| Text went nowhere | The field was not focused. Tap the field, then type. |
| Keyboard covers the button | `adbdrv key back`, then tap. |
| Emoji or accents lost | ADBKeyboard is not installed. |
| Actions land one tap behind | UI animation. `adbdrv tap "X" --then-wait 2`, or `adbdrv wait`. |
| Wrong app in front | Check `adbdrv fg` before acting; never assume. |
| Tapping through an app's menu | Each hop costs 2.5–4s and the buttons move between steps. Try the app's own deeplink first — it usually jumps straight to the screen: `adbdrv shell 'am start -a android.intent.action.VIEW -d "fb://marketplace"'`. |
| `adbdrv pull` is not a command | Correct — only `push` exists. For files off the phone use raw adb: `adb -s <serial> pull /sdcard/DCIM/Camera/x.jpg /tmp/`. |
| `adbdrv ui` returns 2 elements on a screen full of buttons | A React/Flutter canvas surface — uiautomator cannot see it. `adbdrv shot` and locate the control by pixel, then tap by `x,y`. |
| An `@n` tap hits the wrong thing | Indices belong to a single snapshot. The keyboard opening/closing or any scroll renumbers them. Re-snapshot immediately before each tap. |
| Pushed a photo, but the picker will not show it | Android 15 drops the media-scan broadcast. Force it: `adbdrv shell 'content call --uri content://media/external/file --method scan_file --arg <path>'`. Scan **once** — each call inserts a new row. |
| `more than one device/emulator` | The same phone is on two transports (USB **and** `:5555`, or `:5555` plus an mDNS entry). `adbdrv` auto-picks USB; raw `adb` needs `-s <serial>`. |
| Screenshot is a corrupt PNG | Do not pipe `exec-out screencap -p` directly. `adbdrv shot` writes to `/sdcard` and pulls the file. |
| Everything fails at once | The screen slept. `adbdrv wake`, and set `stay_on_while_plugged_in`. |

## When it stops working

Work down this list.

1. `adb devices` — if empty, run `bin/reconnect.sh` and read its log.
2. **The money test:** `nc -z <phone-ip> 5555`. Refused means adbd is not
   listening: the phone rebooted or wireless adb was torn down. Over USB,
   `adb tcpip 5555` again.
3. Try the other address (LAN vs VPN/tailnet) if you have both.
4. Only then reach for the cable.

Never conclude "wireless debugging is off" from a failed connection — the toggle
can read on while nothing listens. Port state is the truth.

## Translating a conversation

Read without destroying state, and never ship a raw machine translation.

The thread list and the notification shade show the latest line and change
nothing, so for a triage pass use `adbdrv ui --text` on the list, or
`adbdrv shell 'dumpsys notification --noredact'` and read the `android.title` and
`android.text` fields. Opening a thread marks it read server-side — fine when the
user is already in the conversation, destructive when they are triaging. Say which
one you are doing before you do it.

Translate locally first:

```bash
curl -s http://127.0.0.1:11434/api/generate -d '{"model":"<model>","stream":false,
  "prompt":"Translate to natural <language>. Output only the translation:\n<text>"}'
```

Good enough to read with, not good enough to send blind — a small model asked for
one disease once produced a different one in the same sentence. Review and correct
every translation before a human sees it, and never let one carry a medical,
financial, or travel instruction unchecked.

When replying, hand the user the original and the translation, and let them pick
the language. The agent never picks it for them.

## Reporting back

Give the user the answer, not the tree: "3 unread — one asks whether the lamp is
still available, another wants Saturday pickup" beats a dump of element indices.
Keep indices, package names and coordinates out of the reply.