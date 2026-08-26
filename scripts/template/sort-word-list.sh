#!/usr/bin/env sh
set -eu

if ! command -v pwsh >/dev/null 2>&1; then
  echo "pwsh not found. Install PowerShell 7+ to sort word list files."
  exit 1
fi

# Delegate to the canonical sorter implementation.
pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/template/sort-word-list.ps1 "$@"
