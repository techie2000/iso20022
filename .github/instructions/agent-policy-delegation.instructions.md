---
description: >
  Enforces a single canonical AI policy source in this repository while allowing
  lightweight discovery stubs and scoped instruction files.
applyTo: '**'
---

# Canonical Agent Policy Delegation

Use this instruction whenever creating or modifying agent-facing policy files
(for example `AGENTS.md`, `.github/copilot-instructions.md`, or files under
`.github/instructions/`).

## Canonical Source Of Truth

- Repository-wide policy lives in `.github/copilot-instructions.md`.
- Root discovery files (such as `AGENTS.md`) must remain thin stubs that
  delegate to the canonical file.
- Do not maintain duplicate full-policy copies in `CLAUDE.md`, `CURSOR.md`,
  `GEMINI.md`, or similar files.

## Scoped Instructions

- Use `.github/instructions/` for focused rules tied to workflows or file
  patterns.
- Keep scoped files narrow and additive; do not restate the entire canonical
  policy.
- Include YAML frontmatter with `applyTo` so targeting is explicit.

## Update Rule

When policy location, discovery behavior, or instruction layout changes:

- Update `AGENTS.md` if delegation/discovery behavior changes
- Update `README.md` in the same change with any path or workflow impact

Goal: one clear policy source, discoverable from root, with scoped extensions
that stay consistent and avoid policy drift.
