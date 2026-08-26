---
description: >
  Prevents diagram drift by requiring Ilograph YAML sources in docs/diagrams/
  to be updated whenever repository structure or runtime flow changes.
applyTo: '**'
---

# Ilograph Diagram Sync

Use this instruction to keep repository Ilograph files accurate as the codebase
evolves.

## Scope

Track these files:

- `docs/diagrams/*.ilograph.yaml`

## Required Updates

1. When folders, significant files, or ownership boundaries change, update
   `workspace-overview.ilograph.yaml` in the same PR.
2. Keep resource names and relation labels aligned with actual paths and
   behavior in `src/`, `scripts/`, and `test/`.
3. If a change intentionally does not update diagrams, document why in the PR
   summary.

## Ordering Rules (Deterministic)

Use a stable ordering policy so diagram diffs remain small as files are added.

1. Keep top-level `resources` children in functional order:
   `docs`, `src`, `test`, `scripts`, then tooling/config sections.
2. Within each node's `children`, use alphabetical order unless a strict
   runtime flow sequence is required.
3. Keep `perspectives[].relations` grouped and ordered consistently:
   Makefile/task relations first, hook/script relations second, CI relations
   third, and governance/instruction relations last.
4. Prefer one relation per edge (`from` -> `to`) for easier review and clearer
   diffs when adding new nodes.
5. When adding a new file/folder, insert it at its sorted position instead of
   appending to the end.

## Quality Gate

Before finalizing markdown or instruction updates related to diagrams:

1. Run `make lint-docs-fix`
2. Run `make lint-docs`
3. Resolve any remaining markdown lint issues
