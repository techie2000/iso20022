#!/usr/bin/env sh
set -eu

if ! command -v npx >/dev/null 2>&1; then
  echo "npx not found. Install Node.js/npm to run markdownlint-cli2."
  exit 1
fi

fix_flag=""
if [ "${1-}" = "--fix" ]; then
  fix_flag="--fix"
  shift
fi

if [ "$#" -gt 0 ]; then
  # Lint explicit paths passed by caller.
  if [ -n "$fix_flag" ]; then
    npx --no-install markdownlint-cli2 --config .markdownlint-cli2.yaml --fix "$@"
  else
    npx --no-install markdownlint-cli2 --config .markdownlint-cli2.yaml "$@"
  fi
  exit $?
fi

first_tracked_md_file=$(git ls-files '*.md' | head -n 1)
if [ -z "$first_tracked_md_file" ]; then
  echo "No markdown files found to lint."
  exit 0
fi

# Lint all tracked markdown files in the repository.
if [ -n "$fix_flag" ]; then
  git ls-files -z '*.md' | xargs -0 npx --no-install markdownlint-cli2 --config .markdownlint-cli2.yaml --fix
else
  git ls-files -z '*.md' | xargs -0 npx --no-install markdownlint-cli2 --config .markdownlint-cli2.yaml
fi
