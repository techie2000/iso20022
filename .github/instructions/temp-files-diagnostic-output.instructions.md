---
description: >
  Directs transient logs, timing files, build output, and other diagnostic
  artifacts to .tmp/ instead of the repository root, and explains the
  supporting markdownlint ignore rule.
applyTo: '**'
---

# Temporary Files and Diagnostic Output

Transient logs, timing files, build output, and other diagnostic artifacts
should be written under `.tmp/` at the repository root rather than the repo
root itself.

The repository includes `.markdownlintignore` with `.tmp/**` so temporary
markdown files created in `.tmp/` do not fail repository markdown linting.
This keeps diagnostics out of normal documentation validation while still
allowing committed docs to remain fully linted.
