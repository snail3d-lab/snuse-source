# Recipes

Working patterns, and the traps in each.

## Read the screen, without opening anything

The cheapest read is the notification shade and the app's list view — both show
the latest line and change nothing:

```bash
adbdrv shell 'dumpsys notification --noredact' | grep -E "android.title|android.text"
adbdrv ui --text        # on a list screen, e.g. an inbox
```

Opening a thread marks it read on the server side. That is fine when the user is
already in the conversation and destructive when they are triaging unread. Make
the distinction explicit before you act.

## Verify, always

```bash
adbdrv tap "Send"
adbdrv ui --text | grep "the message you sent"   # confirm it is in the thread
```

A message that never landed looks exactly like one that did until you check. The
same applies to a tap: read the result back, do not assume.

## Post a Marketplace listing

Marketplace is a multi-step composer whose buttons move between steps, so snapshot
after every single action.

```bash
# 1. get the photos onto the phone from the Mac
adbdrv push ~/photos/lamp-hero.jpg --dcim

# 2. open the composer
adbdrv open com.facebook.katana
adbdrv tap "Marketplace"
adbdrv tap "Selling"
adbdrv tap "Create new listing"
adbdrv tap "Item for sale"
```

The photo picker is a system app with an almost empty accessibility tree — the
thumbnails carry no useful text. Select by tapping tiles in a grid, then **Done**,
and confirm the photo count on the composer before moving on.

Then: Title, Price (digits only; `0` means Free), Category, Condition,
Description, Location. Finally **Publish** — photos upload first. Wait for the
live confirmation, and **never double-tap Publish**, because that creates two
listings.

## Read and answer messages, with an approval gate

```
read the thread  ->  draft the reply  ->  show the user one line  ->  send on yes
```

Draft the reply into a small JSON ledger (per-thread: last-seen text, what you
sent, when). Two things fall out of that: a duplicate reply becomes impossible, and
"anything new?" becomes a diff instead of a crawl through the app.

Send, then verify:

```bash
adbdrv tap "Type a message"        # focus the composer (ids vary by ROM)
adbdrv type "the reply"
adbdrv ui --text                   # VERIFY it is in the box before sending
adbdrv tap "Send"
adbdrv ui --text                   # verify it left
```

Caps worth enforcing in code, not by intention: a few listings a day, a dozen
messages a day, one follow-up per thread until they answer. Vary the wording —
identical replies to many threads is textbook spam detection. On a CAPTCHA, a
password prompt or "you're temporarily blocked": **stop, screenshot, tell the
user.** That is the platform asking you to back off, and tapping through it is how
accounts get restricted.

## Translate a conversation

Run it locally first; a small local model is good enough to *read* with:

```bash
curl -s http://127.0.0.1:11434/api/generate -d '{
  "model":"<your-model>","stream":false,
  "prompt":"Translate to natural Kenyan Swahili. Output only the translation:\n<text>"}'
```

Good enough to read, **not** good enough to send blind. A small model asked for
"typhoid" once produced "malaria/typhoid" — inventing a disease inside a sentence
about a different one. Review and correct every translation before a human sees
it, and never let one carry a medical, financial or travel instruction unchecked.

Hand the user both versions and let them pick the language.

## Watch the phone

```bash
adbdrv watch                                   # mirror the real screen
adbdrv watch --virtual --app com.facebook.katana
```

`--virtual` (Android 14+, scrcpy 3+) creates a hidden display, so the agent works
on a screen the user cannot see and their real screen stays theirs. Some apps
misbehave on a virtual display — fall back if the tree looks wrong.

Often a single `adbdrv shot -o /tmp/a.png` plus a look at the PNG is cheaper and
more reliable than a video stream.

## Drive the phone's browser over CDP

When an app's accessibility tree is too thin, the browser gives you a real DOM:

```bash
adbdrv shell 'am start -a android.intent.action.VIEW -d https://m.example.com'
adb forward tcp:9222 localabstract:chrome_devtools_remote
```

Point any CDP client at `localhost:9222`. Note that a fresh login from a new
browser can trigger a security checkpoint, so prefer the app when the app works.

## One host owns the connection

Android accepts several adb hosts, but keeping one machine as the owner avoids
confusion about which one is paired. Other machines borrow its server over an ssh
tunnel — never expose adb on the network:

```bash
ssh -f -N -L 5037:localhost:5037 user@owner-host
export ADB_SERVER_SOCKET=tcp:localhost:5037
adbdrv status
```

Remember that a non-interactive ssh session does not read `~/.zprofile`, so
Homebrew is not on PATH and `adb`/`adbdrv` look missing when they are not.