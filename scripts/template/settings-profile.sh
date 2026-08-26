#!/usr/bin/env sh
set -eu

if ! command -v pwsh >/dev/null 2>&1; then
  echo "pwsh not found. Install PowerShell 7+ to run settings profile tooling."
  exit 1
fi

# Delegate to the canonical profile implementation.
pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/template/settings-profile.ps1 "$@"