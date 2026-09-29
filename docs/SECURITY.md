# Security and trust

## What touches the network

Nothing but your own `adb` connection. There is no service, no telemetry, no
account, no analytics and no cloud component. `adbdrv` is a local CLI that shells
out to the `adb` binary you installed and reads the responses back. The only
outbound traffic is whatever you point at it — for the bundled recipes that means
your own local model, or the app you are driving.

## What the trust actually is

Pairing a host authorizes that host's adb key for **full shell access to the
phone**. That is not a narrow permission; it is roughly the access a developer has
over a debug build. Treat it that way:

- Authorize only machines you control.
- Read the **Allow USB debugging** prompt before ticking *always allow*.
- Turn on **Disable adb authorization timeout** deliberately, knowing it means the
  key does not expire.
- **Never expose port 5037 (or a device on 5555) on an untrusted network.** On a
  tailnet it is already private; on open Wi-Fi it would be a shell prompt for
  whoever finds it. Tunnel it instead:

  ```bash
  ssh -f -N -L 5037:localhost:5037 user@owner-host
  export ADB_SERVER_SOCKET=tcp:localhost:5037
  ```

## What the agent cannot see

Android marks secure windows — banking apps, password managers, payment sheets —
as non-accessible, and uiautomator cannot read them. That is a deliberate OS
protection and it is a good thing. If a task requires a secure window, the user
does it by hand. Do not look for a way around it; there isn't one, and its absence
is the feature.

Anything else on the screen **is** visible, including its text. That is the point,
but it also means the agent can read whatever is on screen while it works. Scope
tasks so it is looking at what you meant it to look at.

## Actions that need a human

The bundled skills treat these as approval-gated, and you should keep it that way
for anything you build on top:

- Sending a message
- Publishing, editing or deleting a listing
- Deleting anything
- Anything involving money, addresses, or a commitment on the user's behalf

The gate is cheap: draft it, show one line, send on "yes". Automation that sends
before a human has seen it will eventually send something expensive.

## Rates, and the platform's rules

Automating an app can violate its terms. Driving your own logged-in phone is far
less likely to be flagged than an emulator or a fresh device, because it is the
same device, account, IP and app — but it is still automation, and platforms
notice patterns: volume, timing, identical wording, actions faster than a human.

The bundled Marketplace/Messenger skill encodes the countermeasures — a few
actions an hour, human pacing, varied wording, and a hard stop on any checkpoint.
Do not remove them to go faster. An account restricted for automation costs more
than any amount of throughput.

**A checkpoint means stop.** CAPTCHA, "confirm it's you", a password or 2FA prompt
or a temporary block is the platform telling you to back off. Screenshot it, tell
the user, and stop. Do not attempt to solve it.

## Screenshots and logs

`adbdrv shot` writes PNGs and `~/.android-driver/` accumulates device state and
snapshots. They can contain message text and personal data. `.gitignore` in this
repo excludes them, and `~/.android-driver/` is outside any repo by default — keep
it that way if you fork this and point it at a real inbox.