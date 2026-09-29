---
name: facebook-marketplace
description: Post, renew and sell Marketplace listings; answer Messenger buyer messages.
version: 1.0.0
author: Snail3D
license: MIT
platforms: [macos, linux]
prerequisites:
  commands: [adb, adbdrv]
metadata:
  hermes:
    tags: [facebook, marketplace, messenger, selling, phone]
    related_skills: [android-phone]
---

# Facebook Marketplace and Messenger, driven from the phone

Meta gives individuals **no API** for Marketplace listings and none for personal
Messenger. The phone is therefore not a workaround — it is the only route, and
driving your own logged-in app is also the *safest* route: it is the same device,
account, IP and app as every other listing you have posted.

**Read the `android-phone` skill first.** This is the playbook; that one is the
hands.

## When to Use

- "post this to Marketplace", "list the lamp", "put this up for sale"
- "any new messages?", "did anyone reply?", "answer this buyer"
- "mark it sold", "renew my listings", "what's still active"

## Non-negotiables

These protect the account. An account flagged for automation loses Marketplace,
and that costs more than any single listing.

1. **A human yes before anything leaves the phone.** Draft mode is the default.
   Publishing a listing is never automatic. Approve drafts in one batch.
2. **Human pace.** Seconds between actions, not milliseconds. Never two listings
   back to back.
3. **Caps enforced in code, not by intention**: a few listings a day, roughly a
   dozen messages a day, one follow-up per thread until the buyer replies. Keep
   the counts in the ledger and refuse when over.
4. **Vary the words.** The same reply to many threads is textbook spam detection.
   Compose each reply for that person.
5. **Same phone, same account, always.** No emulators, no fresh installs, no VPN
   hopping, no "just this once" desktop login.
6. **Stop on a checkpoint.** CAPTCHA, "confirm it's you", a password or 2FA
   prompt, or "you're temporarily blocked" means stop, screenshot, and tell the
   user. Do not try to solve it and do not tap through it. That is the platform
   asking you to back off.

## Reading the inbox

```bash
adbdrv open com.facebook.orca
adbdrv wait "Chats" 15
adbdrv ui --text
adbdrv shot -o /tmp/inbox.png
```

Unread state is usually a **dot, not text**, so the tree will not report it.
Either read the screenshot or compare the thread list against each thread's
`last_seen_text` in the ledger — a changed last line means a new message. The
ledger is the reliable signal.

To read one conversation: `adbdrv tap "<buyer>"`, then `adbdrv ui --text`. The
tree comes out in visual order, so the tail is the recent exchange. To tell who
said what: anything at the tail that is not in that thread's `sent[]` is theirs.

Opening a thread marks it read. Fine when the user is already in the
conversation, destructive when they are triaging — say which you are doing.

## Answering a buyer

```bash
adbdrv tap "<buyer>"
adbdrv ui --text
adbdrv tap "Type a message"        # focus the composer (ids vary by ROM)
adbdrv type "<the reply>"
adbdrv ui --text                   # VERIFY it is in the box before sending
adbdrv tap "Send"                  # content-desc is "Send <emoji>"; "Send" matches
adbdrv ui --text                   # verify it left, into the thread
```

A reply that never landed looks identical to one that did until you check. Then
append to the ledger: `sent[]`, `last_replied_at`, and bump the day's count.

**Draft mode**: write the reply into the ledger as `status: pending` and show the
user one line per person — who asked what, and the reply you propose. On their
yes, send it and flip it to `sent`. Several can be approved at once.

Reply shapes that work on Marketplace:

| They ask | Answer with |
|---|---|
| "still available?" | Yes, plus a nudge to a day and time. Never a bare "yes". |
| "what's your lowest?" | Hold the price, or one small final concession. No haggling loops. |
| "will you ship?" | Yes or no plus cost, or pickup-only. Answer the same way every time. |
| "where are you?" | The meetup spot the user chose. Never a home address. |
| "can you hold it?" | Only with a day and time attached, otherwise first come. |

Never confirm a price or a shipping offer that is not already in the listing
without checking with the user first.

## Creating a listing

**Verified end-to-end on a C59 Pro running Android 15.** The text below is what
the screens actually said.

Four taps from a cold start. Learn the deeplink and you skip the tab bar
(Marketplace is tab 4 of 6, so tapping it blind is a guess).

```bash
adbdrv open com.facebook.katana
# the first launch after a login shows a SYSTEM dialog, not an FB screen:
#   "Save your login info?"  ->  "Not now"
adbdrv tap "Not now"

adbdrv shell 'am start -a android.intent.action.VIEW -d "fb://marketplace"'
# lands ON Marketplace: "Marketplace, Heading", tabs For you / Local / Jobs

adbdrv tap "Sell"            # -> the SELLING HUB, not the composer
adbdrv tap "Create listing"  # -> "Create new listing" type chooser
adbdrv tap "One item"        # -> the composer
```

### The screens, in order

| Screen | What it says | Tap |
|---|---|---|
| Marketplace | "Marketplace, Heading" · For you / Local / Jobs | `Sell` (Button) |
| **Selling hub** | Shipping orders · Inbox · **Your listings** · Announcements · Profile · **Create listing** | `Create listing` |
| Listing type | **One item** · Multiple items · Vehicle · Home for sale or rent · Sale event | `One item` |
| Composer | "<Your name>, Listing on Marketplace" | fill it |

Two corrections to the obvious guess:

- **"Sell" does not open the composer.** It opens the *Selling hub* — your
  listings, inbox, payout account, "chats to answer". The composer is one tap
  deeper, behind **Create listing**.
- **The type option is "One item", not "Item for sale".**

Every one of these screens runs in
`com.facebook.katana.activity.react.ImmersiveReactActivity`, so `adbdrv fg`
confirming that activity tells you *nothing* about which step you are on. Verify
by text — `"Sell"` and `"Create listing"` live under the same class.

### The composer is a 4-step wizard

Not one screen. The footer reads "Step N of 4" (it says "1 of 3" at first, then
grows once the extra sections load — trust the fields, not the number).

| Step | Screen | Holds |
|---|---|---|
| 1 | the composer | Photos, Title, Price, Category, Condition, Description, More details (Tags, SKU), promote toggle, privacy |
| 2 | **Delivery method** | Location, Delivery method, Meetup preferences |
| 3 | **List in more places** | Marketplace on/off, ~20 group checkboxes, then **Publish** |

**Step 1.** "Record a video" (1 min max), "Add photos / video" (reads
`Photos: 0/10 · Videos: 0/1`, warns *"Choose your listing's main photo first"* —
**the first photo you pick becomes the main photo**), then **Required:** Title,
Price, Category, Condition, Description. Below that "More details": Tags, SKU,
a promote-after-publishing toggle, and a "Hide from friends" switch.

**Facebook puts each field's label in `desc`, not `text`** — `desc='Price, , ,'`,
with the value landing in `text` (`desc` then reads `'Price, $5, ,'`). So address
fields with `desc:`:

```bash
adbdrv tap "desc:Price"   # the EditText
adbdrv tap "Price"        # WRONG - hits the non-clickable label TextView
```

That one bites hard: the label is an *exact* text match, so it outscores the
field. Likewise a bare `tap "Next"` can grab the **header** Next at `(659,104)`,
which is often a no-op. The real Next is the bottom-bar button, and it is
**disabled** (`clickable=False`) until the step validates — check before tapping,
or you will tap a dead button and conclude the flow is stuck.

**Step 2 — Delivery method is the step that blocks.** It defaults to *Shipping &
local pickup*, which makes **"Select shipping label" render red and disables
Next** until a label is configured. Unless the user is genuinely shipping, switch
it:

```bash
adbdrv tap "desc:Delivery method"   # dropdown
adbdrv tap "Local pickup only"      # sidesteps the whole shipping-label setup
adbdrv tap "Public meetup"          # meetup preference - NEVER door pickup
```

Location arrives pre-filled from the profile. Then tap the bottom Next at
`(360,1520)`.

**Step 3 — "List in more places."** Marketplace is already checked. The city's
group checkboxes are **unchecked and must stay that way** — ticking them posts the
item into every buy/sell group around, which is spam and the fastest route to a
restriction. Confirm the footer reads *"Publish your listing in 1 place."*

**The final screen is invisible to uiautomator.** Its controls are drawn on a
React canvas — the tree returns 2 elements and no Publish at all. Read it as
pixels instead:

```bash
adbdrv shot -o /tmp/final.png
```

The Publish pill is the only saturated Facebook-blue blob (`#1877F2`) in the
bottom bar. On 720x1640 it spans x[502..662], y[1464..1542] — centre
**`(583,1504)`**. Tap it once. The app returns to the Selling hub and the item
appears under **Your listings** as *"In Review"* before going *Available*.

### Photos

**Photos are the wall.** Marketplace will not publish without at least one, and
the driver cannot invent one. Check what is actually on the phone before you
promise a listing — and look at the photo before you use it:

```bash
adb -s <serial> shell 'ls -lt /sdcard/DCIM/Camera/ | head'
adb -s <serial> pull /sdcard/DCIM/Camera/<file>.jpg /tmp/item.jpg   # then LOOK
```

`adbdrv` deliberately has **no `pull`** — use raw adb. It runs ~28 MB/s over a
LAN (~0.1s for a 3 MB photo), so pulling a photo to actually look at it is cheap.
To go the other direction, push from the computer into the camera roll:

```bash
adbdrv push ~/photos/lamp-hero.jpg --dcim
```

**Android 15 ignores the media-scan broadcast** that `push --dcim` fires, so the
file lands on disk and the picker never sees it. Force it through the provider:

```bash
adbdrv shell 'content call --uri content://media/external/file \
  --method scan_file --arg /sdcard/DCIM/Camera/hero.jpg'
```

Two side effects:

- **Every scan inserts another row.** Repeating it produced 5 duplicate MediaStore
  entries for one file, which the picker showed as 5 identical tiles. Scan once,
  then verify with
  `content query --uri content://media/external/images/media --projection _display_name | grep <name>`.
- **A photo with no EXIF date sorts LAST.** A generated test image had none, so
  MediaStore dated it 1970 and it sat at the very bottom of the gallery — the
  opposite of where a freshly-shot photo appears.

The picker is Facebook's own **Gallery** album view. Its tiles are `CheckBox`
nodes whose `desc` is `"Photo taken on <date>"`:

```bash
adbdrv ui                            # locate the tile
adbdrv tap @19                       # or its exact x,y
adbdrv tap "Next"                    # confirms (a "1" badge appears)
adbdrv ui --text | grep "Photos:"   # must read "Photos: 1/10" before moving on
```

**Verify the photo before publishing** — screenshot the composer and look at it.
With a grid of near-identical thumbnails it is trivially easy to attach the wrong
one, and the listing is public the moment you hit Publish.

### Timing

`adbdrv tap` returns in well under a second. The cost is the app's own screen
transition: **2.5–4s** per step. So never `sleep` — poll for a string that proves
you arrived, and the step finishes the instant it is ready:

```bash
adbdrv tap "Sell"; adbdrv wait "Create listing" 10
```

A verified full listing — photo picked, all fields, published — runs about **25
screen transitions**, so roughly **a minute of app time** once the photo exists.
Budget a few minutes the first time through a new flow, because you should be
reading every screen.

**Re-snapshot before every tap.** `@n` indices belong to one snapshot. Opening or
closing the keyboard, or the view scrolling, renumbers everything — tapping a
stale `@31` hits whatever moved into that slot. When a tap does nothing, that is
almost always why; snapshot again rather than tapping harder.

Cold start to an open composer: **4 taps, ~15s of app time**, plus whatever you
spend reading the screen. That is the honest number to quote.

### The fields

1. **Title.** Short and searchable — the words a buyer would actually type. No
   ALL CAPS, no emoji spam.
2. **Price.** Digits only. `0` means Free, and only when the user said free.
3. **Category.** Must match the item; it decides who sees the listing.
4. **Condition.** New / Used - Like New / Used - Good / Used - Fair.
5. **Description.** What it is, size, material, what is included.
6. **Location and meetup.** A public spot, never home.
7. **Publish.** Photos upload first, then the listing goes live. Wait for the
   live text. **Never double-tap Publish** — that creates two listings, and both
   have to be deleted.

Expect friction: "this looks similar to a listing you already have", a boost
upsell, an occasional "pending review", and a first-run location permission
dialog (deny it unless the listing needs it).

### Screenshots of this flow are account data

The Selling hub shows the payout account, live listing counts and "chats to
answer". Treat a screenshot of this flow as sensitive, and keep it out of any
repo you publish.

## Managing what is live

Under Marketplace → Selling → Your listings:

- **Renew** — listings expire after about a week; renewing keeps them visible.
- **Edit listing** — price, title, description.
- **Mark as sold** — do it promptly; live listings for sold items waste buyer
  messages and attract reports.
- **Delete listing** — for mistakes and duplicates.

Reconcile against this screen whenever the user asks what is still up. The phone
is the truth; the ledger is a cache and it drifts.

## Ledger

Read it before acting, write it after acting. It is what stops a duplicate reply
and what makes "anything new?" a one-second answer instead of a crawl through the
app.

```json
{
  "mode": "draft",
  "auto_reply": false,
  "quiet_hours": [22, 7],
  "counts": {"day": "2026-01-01", "listings_today": 0, "messages_today": 0},
  "listings": {"<title>": {"status": "live", "price": 45, "posted": "..."}},
  "threads": {"<buyer>": {"last_seen_text": "...", "last_replied_at": "...", "sent": []}}
}
```

## Which account

If the user's main Facebook is also their personal life, raise the option of a
dedicated selling profile before automating anything. A restriction lands on
whichever account is used, and that choice is the user's, not the agent's.

## Keeping this skill true

Verified **end-to-end** against **Facebook `580.0.0.51.74`** (versionCode
475019271, last updated 2026-09-28) on **Android 15 / sdk 35**: on 2026-09-29 a
listing was created and published through this exact flow. Every screen, label
and coordinate below was read off a device, not inferred.

Facebook ships a new build every week or two and the composer is a React screen,
so it *will* move. Check the version before trusting the flow above:

```bash
adbdrv shell 'dumpsys package com.facebook.katana | grep versionName'
```

If it is no longer `580.x`, re-walk the flow. It costs about a minute and tells
you exactly which screen changed:

```bash
adbdrv shell 'am start -a android.intent.action.VIEW -d "fb://marketplace"'
adbdrv wait "Sell" 15           || echo "MARKETPLACE or DEEPLINK MOVED"
adbdrv tap "Sell"
adbdrv wait "Create listing" 10 || echo "SELLING HUB MOVED"
adbdrv tap "Create listing"
adbdrv wait "One item" 10       || echo "TYPE CHOOSER MOVED"
adbdrv tap "One item"
adbdrv wait "Title" 10          || echo "COMPOSER MOVED"
```

Fix the labels here **in the same session you find the change.** A skill that is
confidently wrong is worse than no skill, because the next agent trusts it.

**Re-verify early if:** the deeplink lands on the feed instead of Marketplace
(`fb://` schemes drift), a listing publishes but never shows under *Your
listings*, or `adbdrv tap` starts missing a field it used to hit.

## Reporting

One line per person, decision first: "still available, wants Saturday pickup →
drafted 'Yes, Saturday 10am at the library works.'" Keep element indices, package
names and tap coordinates out of the reply.