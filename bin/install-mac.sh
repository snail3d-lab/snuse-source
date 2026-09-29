#!/usr/bin/env bash
# Install the phone bridge on any Mac. Idempotent.
set -euo pipefail
command -v brew >/dev/null || { echo "Homebrew required"; exit 1; }
brew list android-platform-tools >/dev/null 2>&1 || brew install --cask android-platform-tools
brew list scrcpy >/dev/null 2>&1 || brew install scrcpy
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chmod +x "$DIR/bin/adbdrv" "$DIR/bin/reconnect.sh"
ln -sf "$DIR/bin/adbdrv" /opt/homebrew/bin/adbdrv 2>/dev/null \
  || sudo ln -sf "$DIR/bin/adbdrv" /usr/local/bin/adbdrv
mkdir -p "$HOME/.android-driver/shots" "$HOME/.android-driver/state"
echo "installed: adbdrv -> $DIR/bin/adbdrv"
adbdrv devices || true
