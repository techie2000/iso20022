# Git Hooks

This directory contains git hooks for automated validation and quality checks.
Hooks run automatically once installed — no manual steps required per commit.

> **Why not Husky?** This project uses native Git hooks via `git config core.hooksPath`
> rather than Husky. This keeps setup lightweight and works in any shell environment.

## Available Hooks

### pre-commit

Runs two checks on every commit attempt:

#### 1. VS Code settings sort (`pwsh` required for pre-push)

If `.vscode/settings.json` exists, the hook runs `scripts/sort-vscode-settings.ps1` to keep
the JSON keys alphabetically sorted. If the sorter modifies the file it is automatically staged
so the sorted version is part of the commit.

During **pre-commit**, if `pwsh` is unavailable,
the sort step is skipped with a warning (commit is not blocked). During **pre-push**, if `pwsh`
is unavailable, the push is **blocked** — you must sort the file before pushing.

#### 2. Markdown linting

Runs `npx --no-install markdownlint-cli2` against every staged `.md` file using the project rules in
`.markdownlint-cli2.yaml`.

**Rules enforced:**

- MD013 — Line length must not exceed 120 characters
- MD040 — Fenced code blocks must declare a language (e.g., `bash`, `json`, `text`)
- MD060 — Table columns must use spaced pipe style
- All other rules enabled in `.markdownlint.yaml`

The hook **fails fast** if `npx` is not available. This is intentional — markdown non-compliance
is caught before review, not during it.

### pre-push

Validates that `.vscode/settings.json` is sorted before code reaches the remote.

If `pwsh` is not available the push is **blocked** — install PowerShell 7+ or sort the file
from a machine where `pwsh` is available before pushing.

**What it checks:**

- Runs `scripts/sort-vscode-settings.ps1 -CheckOnly` and blocks the push if the file is unsorted.

To fix a blocked push, run `pwsh ./scripts/sort-vscode-settings.ps1`, then commit the results
before pushing again.

## Installation

### Setup

```bash
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
chmod +x .githooks/pre-push
```

On Windows, `chmod` may be unavailable and is usually unnecessary. The key setup step is:

```powershell
git config core.hooksPath .githooks
```

### Optional helper scripts

If you prefer named helper commands instead of typing raw git/npx/pwsh commands:

```powershell
pwsh ./scripts/install-hooks.ps1
pwsh ./scripts/settings-sort.ps1
pwsh ./scripts/lint-docs.ps1
```

```bash
bash ./scripts/install-hooks.sh
bash ./scripts/settings-sort.sh
bash ./scripts/lint-docs.sh
```

Use `bash` explicitly for `.sh` helpers so the commands still work in checkouts
where the executable bit is unavailable or not preserved.

If `make` is available, equivalent shortcuts are also provided:

```bash
make install-hooks
make settings-sort
make lint-docs
make lint-docs-fix
```

## Usage

Once installed, hooks run automatically:

```bash
git add docs/README.md
git commit -m "Update docs"
# pre-commit hook runs automatically

git push origin feature/my-branch
# pre-push hook runs automatically
```

### Bypassing Hooks

**Not recommended**, but available if needed:

```bash
# Skip pre-commit checks for a single commit
git commit --no-verify -m "wip: skip checks"

# Skip pre-push checks for a single push
git push --no-verify origin feature/my-branch
```

### Fixing a Failed pre-commit

If the pre-commit hook fails on markdown linting:

1. **Auto-fix (where possible):**

   ```bash
   npx --no-install markdownlint-cli2 --config .markdownlint.yaml --fix <file>.md
   ```

2. **Check manually:**

   ```bash
   npx --no-install markdownlint-cli2 --config .markdownlint.yaml <file>.md
   ```

3. **Common manual fixes:**
   - MD013: Break long lines at 120 characters
   - MD040: Add a language tag to fenced code blocks (` ```bash`, ` ```json`, ` ```text`)
   - MD060: Ensure table header/separator rows use spaced pipes (`| col |`)
   - MD022/MD031/MD032: Add blank lines around headings, lists, and fenced code blocks

### Fixing a Blocked pre-push

If the pre-push hook blocks your push because `.vscode/settings.json` is unsorted:

```bash
pwsh ./scripts/sort-vscode-settings.ps1
git add .vscode/settings.json
git commit -m "chore: sort vscode settings"
git push origin feature/my-branch
```

## Disabling Hooks

```bash
git config --unset core.hooksPath
```

## Requirements

| Tool | Purpose | Install |
| ---- | ------- | ------- |
| `npx` with `markdownlint-cli2` | Markdown linting (pre-commit) | Install Node.js/npm and run `npx --no-install markdownlint-cli2 --version` |
| `pwsh` (PowerShell 7+) | VS Code settings sorting (pre-commit, pre-push) | [Install PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
