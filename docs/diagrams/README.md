# Ilograph Diagrams

This folder contains interactive Ilograph source files that provide visual overviews of the
repository structure and runtime behavior.

## Files

| File | Purpose |
| --- | --- |
| [workspace-overview.ilograph.yaml](workspace-overview.ilograph.yaml) | High-level repository map showing folder and file relationships, plus runtime validation flow. |

## Viewing Diagrams

1. Ensure the Ilograph MCP server is configured in [.vscode/mcp.json](../../.vscode/mcp.json).
2. Open the desired `.ilograph.yaml` file in VS Code.
3. Use your Ilograph tool to render the diagram and switch between perspectives.
4. Hover over resources to view full descriptions.

If using the containerized MCP server, confirm Docker is running before starting Ilograph
sessions.

The MCP image in `.vscode/mcp.json` intentionally tracks `:latest`. This image is updated
infrequently, and when updates do land we want contributors to pick them up without
manual version bump follow-up.

## Keeping Diagrams in Sync

These diagrams must be kept synchronized with the actual repository structure and runtime
behavior. When you make changes that affect:

- **Repository structure** (new/moved folders or significant files): Update
  [workspace-overview.ilograph.yaml](workspace-overview.ilograph.yaml)

See [.github/instructions/ilograph-sync.instructions.md](../../.github/instructions/ilograph-sync.instructions.md)
for the complete drift-prevention policy.

## Quality Gate

After editing diagram YAML files:

1. Run `make lint-docs-fix`
2. Run `make lint-docs`
3. Resolve any remaining markdown lint issues before committing

## Resource Descriptions

Each resource in the diagrams includes:

- **name**: The folder or file name
- **subtitle**: Brief classification or role
- **description**: Detailed purpose and context (visible on focus/hover in Ilograph)
- **color**: Visual grouping (consistent across related resources)

When adding new resources, include all four fields to maintain consistency and
aid contributor onboarding.
