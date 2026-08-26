# Logs Directory

This directory is a repository anchor for runtime logs.

## Tracking Rules

- `logs/.gitkeep` is tracked to ensure the directory exists in every clone.
- Generated runtime log files in `logs/` are intentionally ignored by Git.
- `logs/README.md` is tracked to document logging expectations.

## Commit Policy

- Do not commit generated log output.
- Keep this file and `.gitkeep` as the only tracked files in `logs/`.
- If you need to share runtime diagnostics, place transient artifacts under `.tmp/`.
