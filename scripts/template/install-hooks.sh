#!/usr/bin/env sh
set -eu

# Configure the repository to use hooks from .githooks.
git config core.hooksPath .githooks

if command -v chmod >/dev/null 2>&1; then
  chmod +x .githooks/pre-commit .githooks/pre-push || true
fi

configured_path=$(git config --get core.hooksPath)
if [ "$configured_path" != ".githooks" ]; then
  echo "Failed to configure core.hooksPath to .githooks"
  exit 1
fi

echo "Configured git hooks path: $configured_path"
