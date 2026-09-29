# Getting access

You bought sNuse source access. Here is how to get in.

## Git access

The paid artifact is a private repo: **`snail3d-lab/snuse-source`**.

Email your **GitHub username** and your **Polar order id** to
**snailmail3d@gmail.com** and you will be added as a collaborator, usually within
a day.

## Or just take the zip

If you would rather not wait, the download attached to your purchase is the
complete repo at that revision. Everything runs from it as-is:

```bash
unzip snuse-source.zip && cd snuse-source
./bin/install-mac.sh
```

## Updates

Once you have git access, `git pull` on `main` brings everything new — driver
fixes, new recipes, new skills. There is no separate update to buy.

## What you can do with it

MIT licensed. Fork it, modify it, teach with it, ship your own variant, use it
commercially. No attribution required, though a link back is always welcome.

## What is not included

- **No phone, no account, no credentials.** You bring your own device.
- **No hosted service.** Everything runs on your machines, which is the point.
- **No support contract.** Email works and real bugs get fixed, but this is a
  small catalog, not a company. Do not expect an SLA.
- **No promise that any particular app stays automatable.** Apps change their
  interfaces; the driver reads whatever is on screen, so when an app rearranges
  its buttons the recipes need updating. The mechanics are the durable part.

## If something does not work

Email with the output of these two, and it usually gets solved in one round trip:

```bash
adbdrv status
adbdrv ui --text
```