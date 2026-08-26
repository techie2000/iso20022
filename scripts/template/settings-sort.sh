#!/usr/bin/env sh
set -eu

if ! command -v pwsh >/dev/null 2>&1; then
  echo "pwsh not found. Install PowerShell 7+ to sort VS Code settings."
  exit 1
fi

# Delegate to the canonical wrapper that sorts settings, extensions, and cSpell word lists.
pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/template/settings-sort.ps1 "$@"
