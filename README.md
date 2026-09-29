# sNuse

**Give an AI agent your Android phone — over your own network, with no cloud in the middle.**

sNuse turns a real Android phone into something an agent can read and operate: it
renders the phone's accessibility tree as text, taps buttons by the words printed
on them, types unicode, and verifies every result from a fresh snapshot.

It is roughly 600 lines of Python wrapping `adb`, plus the agent skills that make
it useful. There is no server, no emulator, no phone farm, and no account with a
third party. Nothing about your phone leaves your machines.

## Why this exists

The app you need has no API. Facebook hands individuals no Marketplace API and
none for personal Messenger; plenty of other apps are the same. So the phone is
not a workaround — it is the only honest route.

Driving your own phone is also the *safest* route: it is the same device, the same
account, the same IP and the same app doing the same actions as if you tapped it
yourself. An emulator on a datacenter IP is the thing that gets accounts killed.

## How it works

```
your AI agent  (anything that can run a shell)
   └── adbdrv  ──── adb ────►  your phone  (wireless debugging, Android 11+)
                   └── scrcpy ──► a window, when you want to watch
```

One Mac runs the adb connection; any other machine on your network can borrow it.
Because a tailnet IP does not change between Wi-Fi and cellular, a phone with
Tailscale is reachable from anywhere — and still never leaves your own network.

## Quick start

```bash
./bin/install-mac.sh                 # adb + scrcpy + adbdrv on PATH
```

On the phone, once: enable Developer options, turn on **USB debugging**, plug it
in, accept the prompt, then hand it the network:

```bash
adb tcpip 5555                       # listen on all interfaces
adb connect <phone-ip>:5555
adbdrv status
```

Full walk-through, including the settings you can apply over adb instead of
tapping through menus: **[docs/SETUP.md](docs/SETUP.md)**.

## The loop

```
adbdrv status                  # is it there, awake, unlocked, which app is up
adbdrv ui                      # SNAPSHOT: every element, indexed
adbdrv ui --text               # just the words on screen - the fast way to read
adbdrv tap "Marketplace"       # ACT: by the label the user sees
adbdrv type "hello"            #      unicode + emoji
adbdrv wait "Sent" 20          # VERIFY: block until it appears
adbdrv shot -o /tmp/x.png      # look at it with your own eyes
```

| Command | Does |
|---|---|
| `adbdrv status` | device, Android version, awake/locked, foreground app, battery |
| `adbdrv ui [--text\|--json]` | snapshot the screen, indexed and labelled |
| `adbdrv find "<text>"` | locate text, print matches and coordinates |
| `adbdrv tap <sel>` | tap by text / `id:` / `desc:` / `@n` / `x,y` |
| `adbdrv long <sel>` | long-press, for edit and delete menus |
| `adbdrv scroll up\|down\|top\|bottom` | page the screen |
| `adbdrv type "<text>"` | type into the focused field (unicode-safe) |
| `adbdrv key back\|home\|enter\|recents` | hardware keys |
| `adbdrv open <url\|pkg\|pkg/activity>` | launch anything |
| `adbdrv wait "<text>" <secs>` | block until text appears |
| `adbdrv fg` | which app is in front |
| `adbdrv shot [-o file]` | screenshot |
| `adbdrv push <file> --dcim` | put a file in the phone gallery |
| `adbdrv watch [--virtual]` | mirror the screen, or a hidden virtual display |
| `adbdrv connect <ip:5555>` | attach over the network |
| `adbdrv shell '<cmd>'` | raw adb for anything not wrapped |

**The one rule: snapshot → act → verify.** The tree moves after every action.
Never chain three taps from memory — tap, snapshot, tap. That single discipline is
the difference between an agent that works and one that flails.

## The skills

The driver is the hands; the skills are the judgement.

- **`skills/android-phone/`** — the mechanics, the failure table, and the settings
  that stop it silently dying (screen-awake while charging, battery-whitelisting
  your VPN so Android does not doze it).
- **`skills/facebook-marketplace/`** — posting, editing, renewing and selling
  Marketplace listings, plus reading and answering Messenger. Includes the part
  that matters most: **an approval gate.** Drafts by default, hard caps on volume,
  varied wording, and a stop-on-checkpoint rule. An account flagged for automation
  costs more than any listing.

They are written to be dropped into an agent's skill directory as-is. If you drive
these conversations with an agent, read `skills/facebook-marketplace/SKILL.md`
before you let it send anything.

## Honest limits

- **Most apps need the screen unlocked.** Secure windows — banking, password
  managers — are invisible to accessibility, by design. sNuse cannot and should
  not see them.
- **Driving the phone uses it.** Unless you use `adbdrv watch --virtual` (Android
  14+, scrcpy 3+), the phone's own screen shows exactly what the agent is doing.
- **Emoji and accents need ADBKeyboard** installed on the phone. Without it, text
  entry is ASCII-only and non-ASCII is dropped silently. The driver switches the
  IME in and back out, so your own keyboard is never left broken.
- **Wireless adb does not survive a reboot.** `bin/reconnect.sh` plus a launchd or
  cron entry fixes that; a working setup otherwise dies quietly days later.
- **Meta watches for automation.** The skill's caps, human pacing and wording
  variation are not decoration. Use your own account and accept that a checkpoint
  means stop.

## Layout

```
bin/adbdrv           the driver
bin/reconnect.sh     keep the phone attached across reboots
bin/install-mac.sh   bootstrap any Mac
skills/              agent skills (drop into your agent's skill dir)
docs/SETUP.md        phone setup, and the adb-settable shortcuts
docs/RECIPES.md      Marketplace, Messenger, translation, files
docs/SECURITY.md     what touches the network, and what does not
```

MIT licensed. Fork it, teach with it, ship your own variant.