# ISO 20022 Implementation

This repository supports an ISO 20022 message implementation effort: schema and
message handling, validation, and integration tooling for ISO 20022 financial
messaging standards.

It was generated from a reusable documentation-first template and retains that
template's cross-platform tooling. It collects vendor documentation, internal
implementation notes, and operational references alongside `src/`, which now
holds a working PostgreSQL schema implementation for ISO 20022 MDR Part 2.

## Structure

| Folder | Purpose |
| ------ | ------- |
| [docs/](docs/) | Documentation index for the docs area and subfolders |
| [docs/internal/](docs/internal/) | Internal notes, ADRs, runbooks, and operational references |
| [docs/vendor/](docs/vendor/) | Vendor documentation and third-party references |
| [.gitattributes](.gitattributes) | Git attributes that should stay aligned with template defaults |
| [.gitignore](.gitignore) | Repository ignore rules that affect generated-template parity |
| [images/](images/) | Supporting screenshots and diagrams |
| [logs/](logs/) | Tracked log guidance and anchor files; generated runtime logs remain ignored |
| [scripts/](scripts/) | Scripts directory; `scripts/template/` holds template-provided tooling; add repo-specific scripts in purpose-named subfolders (e.g. `scripts/runtime/`) |
| [src/](src/) | ISO 20022 implementation source code; see [src/README.md](src/README.md) |
| [src/postgres/](src/postgres/) | PostgreSQL schema for ISO 20022 MDR Part 2 (Payments Clearing and Settlement); see [src/postgres/README.md](src/postgres/README.md) |
| [test/](test/) | Placeholder for automated tests verifying the ISO 20022 implementation in `src/`; the PostgreSQL implementation's own test suite lives under [src/postgres/schema/tests/](src/postgres/schema/tests/) |

## Tooling

| File/Folder | Purpose |
| ----------- | ------- |
| [.githooks/](.githooks/) | Git hook scripts used for pre-commit and pre-push validation |
| [.github/](.github/) | GitHub configuration, Copilot policy, issue templates, and workflows |
| [.github/dependabot.yml](.github/dependabot.yml) | Dependabot configuration for automated dependency updates |
| [.github/instructions/](.github/instructions/) | Repository instructions used by Copilot and other tooling |
| [.github/template-sync.yml](.github/template-sync.yml) | Baseline metadata for template drift classification and sync automation |
| [.github/workflows/](.github/workflows/) | GitHub Actions workflows used for automated repository validation |
| [.markdownlint-cli2.yaml](.markdownlint-cli2.yaml) | markdownlint-cli2 configuration aligned with repository linting behavior |
| [.markdownlint.yaml](.markdownlint.yaml) | Shared markdownlint rule configuration used by hooks and CI |
| [.markdownlintignore](.markdownlintignore) | Ignore rules for transient markdown artifacts such as .tmp/ output |
| [.vscode/](.vscode/) | Workspace settings, extension recommendations, MCP config, and cSpell dictionaries |
| [AGENTS.md](AGENTS.md) | Thin cross-agent entrypoint delegating to the canonical Copilot instructions |
| [Makefile](Makefile) | Optional shortcuts for hook setup, sorting, and docs linting |
| [package.json](package.json) | Generic Node metadata and markdownlint-cli2 development dependency |

## Quick Start

```bash
make init
make lint-docs
```

`make init` is the recommended first-run bootstrap command. It configures Git
hooks (`core.hooksPath=.githooks`), normalizes VS Code workspace files, and
updates `package.json` metadata (`name`, `description`) from template defaults
to repository-derived values. It also creates/updates a project-specific cSpell
word list in `.vscode/` and registers it in
`cSpell.customDictionaries` automatically. Documentation placeholders such as
`{{PROJECT_NAME}}` under [docs/](docs/) are also replaced with the project
name derived from the repository folder (with a leading `work-` prefix removed).

Git does not allow a repository template to enforce local `.git/config` values
automatically, so this bootstrap step must be run once per cloned/generated
repository.

The template uses a split VS Code settings model:

- [`.vscode/settings.generic.json`](.vscode/settings.generic.json) stores
   template-safe defaults suitable for all generated repositories.
- [`.vscode/settings.opinionated.json`](.vscode/settings.opinionated.json)
   stores optional personal/team preferences.
- [`.vscode/settings.json`](.vscode/settings.json) is derived from these
   sources via the settings profile workflow.

Run profile targets directly via `make` to apply or check a profile:

```bash
make settings-profile-generic
make settings-profile-opinionated
make settings-profile-check-generic
```

Pre-commit enforces that `.vscode/settings.json` matches the selected profile
(`WORK_TEMPLATE_SETTINGS_PROFILE`, default `generic`) and fails when out of
sync.

## Template Sync Workflow

Use [.github/workflows/check-template-updates.yml](.github/workflows/check-template-updates.yml)
to detect and triage drift between a derived repository and this template.

### Prerequisites

For the workflow to create pull requests automatically, enable the following setting in your derived repository:

#### Repository Settings → Actions → General → Workflow permissions

1. Navigate to your repository on GitHub
2. Go to **Settings → Actions → General**
3. Under **Workflow permissions**, select **Read and write permissions**
4. Check **Allow GitHub Actions to create and approve pull requests**
5. Click **Save**

> **Note:** This setting cannot be enabled programmatically during repository creation.
> It must be configured manually for each derived repository before triggering the
> workflow with `create_sync_pr: true`.

### Configure baseline metadata

Set a baseline commit in
[.github/template-sync.yml](.github/template-sync.yml) inside the derived
repository:

```yaml
template_repo: "techie2000/template-docs"
template_ref: "main"
baseline_ref: "<template_commit_sha_used_for_generation_or_rebaseline>"
comparison_exclude_paths: ""
```

Without `baseline_ref`, the workflow falls back to snapshot mode and cannot
separate intentional local divergence from template evolution.

Use `comparison_exclude_paths` only when a derived repository has a truly
local-only surface that should never be compared. The value is a
comma-separated list of repo-relative files or folder prefixes.

The default comparison scope includes these repo-local template surfaces:

- `.gitattributes`
- `.gitignore`
- `.github/copilot-instructions.md`
- `.github/dependabot.yml`
- `.github/instructions/`
- `.github/ISSUE_TEMPLATE/`
- `.github/pull_request_template.md`
- `.github/workflows/`
- `.githooks/`
- `.markdownlint-cli2.yaml`
- `.markdownlint.yaml`
- `.markdownlintignore`
- `.vscode/`
- `AGENTS.md`
- `Makefile`
- `docs/internal/`
- `scripts/`

### Trigger options

- `workflow_dispatch` for on-demand runs
- Weekly scheduled run (Monday 09:00 UTC)

### Optional automation inputs

- `generate_ai_suggestions: true`
   Generates advisory-only merge guidance for files classified as manual
   conflicts. It never auto-applies changes.
- `create_sync_pr: true`
   Creates or updates a draft PR containing only low-risk categories:
   safe-adopt and clean auto-merge candidates.

Manual-conflict files remain excluded and require maintainer review.

Temporary Files and Diagnostic Output
Transient logs, timing files, build output, and other diagnostic artifacts
should be written under .tmp/ at the repository root rather than the repo
root itself.

The template also includes .markdownlintignore with .tmp/** so temporary
markdown files created in .tmp/ do not fail repository markdown linting. This
keeps diagnostics out of normal documentation validation while still allowing
committed docs to remain fully linted.
