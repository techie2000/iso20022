# Docs Directory

This folder stores documentation artifacts for the {{PROJECT_NAME}} repository.

## Subfolders

| Path | Description |
| --- | --- |
| [diagrams/](diagrams/) | Diagram sources, including Ilograph workspace maps. |
| [internal/](internal/) | Internal notes and working documents maintained by the team. |
| [vendor/](vendor/) | Vendor-provided reference documents and templates. |

## Notes

- Keep vendor originals in [vendor/](vendor/) without altering source content.
- Place internal working notes in [internal/](internal/).
- Use [internal/GitHub Label Usage](internal/github-label-usage.md) for issue
  and PR label governance rules.
- Keep Ilograph source files in [diagrams/](diagrams/).

## How to View Ilograph Files

1. Confirm the Ilograph MCP server is configured in
  [.vscode/mcp.json](../.vscode/mcp.json).
2. Open one of the diagram source files.
3. Use your Ilograph tool flow to render the selected YAML and switch
  perspectives from the diagram UI.

If you are using the containerized MCP server, ensure Docker is running before
starting the Ilograph session.
