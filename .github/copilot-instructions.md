# GitHub Copilot Configuration for Work Template Docs

This repository uses GitHub Copilot custom instructions, agents, and prompts to maintain code quality and consistency.
The configuration has been tailored specifically for this repository.

## Repository Structure

```text
.github/
├── ISSUE_TEMPLATE/           # Standardized issue forms and templates
├── copilot-instructions.md   # Canonical repo-wide Copilot policy
├── instructions/             # Scoped workflow and language rules
├── pull_request_template.md  # Standard PR description and checklist
└── workflows/                # GitHub Actions for automation
```

## Special Instructions

### README Structure Maintenance (REQUIRED)

When a change adds, removes, renames, or repurposes folders or significant files,
update the repository structure sections in `README.md` in the same change.

Follow:

- `.github/instructions/readme-structure-maintenance.instructions.md`

### Ilograph Diagram Sync (REQUIRED)

When a change updates repository structure, significant files, or runtime flow,
update Ilograph sources in `docs/diagrams/` in the same change to avoid drift.

Keep `workspace-overview.ilograph.yaml` deterministic as files evolve:

- Keep top-level sections in functional order (`docs`, `src`, `test`, `scripts`, then tooling/config).
- Keep nested children alphabetized unless explicit runtime flow ordering is needed.
- Keep relations grouped in a consistent sequence (tasks/hooks, CI, governance).

Follow:

- `.github/instructions/ilograph-sync.instructions.md`

### Dependabot Configuration Sync (REQUIRED)

When a change adds, removes, or reorganizes package managers, ecosystems, or directories,
update `.github/dependabot.yml` in the same change to reflect the new structure.

Keep Dependabot configuration synchronized with repository evolution:

- Add entries for new package managers or ecosystems
- Update or remove entries for reorganized or removed directories
- Verify all `directory` paths point to existing manifest files

Follow:

- `.github/instructions/dependabot-sync.instructions.md`

### GitHub Issue Management (REQUIRED)

When asked to create, close, or otherwise manage GitHub issues, follow:

- `.github/instructions/github-issue-management.instructions.md`

This covers the required workflow for avoiding duplicate issue creation and for
closing duplicate issues with a clear pointer back to the canonical issue.

### PR/Issue Linkage Guardrails (REQUIRED)

Template repositories include workflow guardrails for PR-to-issue linkage and issue lifecycle labels.

Files:

- `.github/workflows/check-pr-issue-link.yml`
- `.github/workflows/auto-label-prs.yml`
- `.github/workflows/sync-issue-status-from-pr.yml`

Behavior:

- Validates PRs include linked issue references (`Refs #N` preferred).
- Allows approved override via the PR template checkbox:
  `- [x] No linked issue - reason: ...`
- Ensures `Closes/Fixes/Resolves` targets issues only (never PR numbers).
- Applies `no-issue-needed` label for bots or checked override.
- Syncs linked issue status labels across PR lifecycle (`status: triage`, `status: in progress`,
  `status: done`).

Enforcement mode:

- Default mode is advisory.
- Set repository variable `ISSUE_LINK_ENFORCEMENT_MODE=required` to fail checks
  when no linked issue or override is present.
- For strict enforcement, also configure branch protection to require the
  `Check PR Issue Link` status check.

### PR Conversation Handling (REQUIRED)

When asked to process PR conversations/review threads end-to-end, follow:

- `.github/instructions/copilot-pr-conversation-workflow.instructions.md`

This covers the required flow to review each thread, apply fixes, commit with traceability,
reply in-thread with commit references, and resolve each conversation.

This instruction file also defines a required PR/issue body encoding guard: use
`.tmp/` body files for multiline content and verify posted content to avoid
escaping or encoding corruption.

### PR Template Usage (REQUIRED)

When creating a new pull request, always base the PR description on
`.github/pull_request_template.md`. Populate all sections; do not leave the
template placeholders as-is. The checklist gates in the template mirror the
required gates in these instructions.

### Conventional Commits (REQUIRED)

Use Conventional Commit subjects for all commits created in repositories based
on this template.

Rules:

- Format the subject as `type(scope): summary` when a scope adds clarity, or
  `type: summary` when it does not.
- Prefer standard types such as `feat`, `fix`, `docs`, `refactor`, `test`,
  `build`, `ci`, and `chore`.
- Keep the subject concise, imperative, and specific to the change.
- Match any workflow-specific scopes or templates already required elsewhere in
  these instructions, such as `fix(pr-thread): ...`.
- Avoid vague subjects such as `updates`, `misc fixes`, or `address feedback`.

Examples:

- `docs: clarify bootstrap behavior in README`
- `fix(pr-thread): scripts/lint-docs - handle empty markdown set`
- `chore(githooks): align pre-commit markdown lint config`

### Markdown Compliance Gate (REQUIRED)

When an agent edits any `*.md` file, it must run this loop before commit or PR update:

1. `make lint-docs-fix`
2. `make lint-docs`
3. If lint still fails, fix remaining issues and rerun `make lint-docs` until clean

Rules:

- Do not commit markdown changes while markdown lint is failing.
- Treat markdown lint failures as blocking, not advisory.

### Markdownlint Ignore Sync (REQUIRED)

Keep markdown ignore behavior aligned across repo linting and local editor diagnostics.

Rules:

- Use `.markdownlint-cli2.yaml` as the canonical source for markdownlint-cli2 and editor ignore globs
  (for example `.tmp/**` and `**/.tmp/**`).
- Keep `.markdownlint.yaml` focused on rule configuration only; do not duplicate ignore globs there.
- Keep `.vscode/settings.json` aligned by setting `markdownlint.configFile` to
  `.markdownlint-cli2.yaml`.
- Keep `package.json` scripts and `scripts/lint-docs.*` commands aligned to use
  `--config .markdownlint-cli2.yaml`.
- If `.markdownlintignore` is changed for other tooling, ensure equivalent `.tmp` exclusions remain in
  `.markdownlint-cli2.yaml` so VS Code diagnostics and CLI lint behavior do not drift.

Verification:

1. Run `make lint-docs-fix`.
2. Run `make lint-docs`.
3. Create a sample markdown file under `.tmp/` (for example
  `Set-Content -Encoding utf8 ./.tmp/markdownlint-ignore-check.md "# sample"`).
4. Run `npx --no-install markdownlint-cli2 --config .markdownlint-cli2.yaml ./.tmp/markdownlint-ignore-check.md`
  and verify `Linting: 0 file(s)`.
5. Remove the sample file after verification.
6. Confirm excluded paths do not surface markdownlint diagnostics in VS Code.

### Commit Failure Recovery (REQUIRED)

If a commit fails because pre-commit checks fail, agents must automatically attempt remediation
before asking the user for manual fixes.

Required flow:

1. Run `make lint-docs-fix`.
2. Run `make lint-docs`.
3. Stage any markdown changes made by auto-fixes.
4. If failure is from VS Code settings ordering, run `make settings-sort` and stage
  `.vscode/settings.json`.
5. Retry the commit operation.

Rules:

- Do not stop at "lint failed" when auto-fix commands are available.
- Only escalate to manual intervention after auto-fix + recheck still fails.

### Cross-Platform NPM Script Portability (REQUIRED)

When editing `package.json` scripts, ensure commands behave the same across
Windows PowerShell/cmd, Bash, and CI shells.

Rules:

- Do not rely on shell-side glob expansion in npm scripts (for example,
  `**/*.test.js`) because expansion behavior differs by shell and npm runtime.
- Prefer Node-native discovery patterns that are shell-agnostic (for example,
  `node --test`), or implement explicit file enumeration in JavaScript when
  scoping is required.
- After changing scripts, validate on the current platform by running the
  script directly (for example, `npm test`) before commit.

Verification:

1. Run the changed npm script(s) locally.
2. Confirm expected files/tasks are discovered and executed.
3. If behavior depends on shell expansion, refactor to a shell-agnostic form.

## Temporary and Diagnostic Output File Placement (REQUIRED)

When running commands or scripts that produce log files, timing files, build output, or any other
transient diagnostic files, **never write them to the repository root**.

Rules:

- Always redirect output to `.tmp/` at the repository root (e.g., `.tmp/backend_build.log`,
  `.tmp/migration-run-20260409.log`).
- The `.tmp/` directory is already in `.gitignore` and will not be committed.
- Patterns like `*_timing.txt`, `*_build.log`, `migration-run-*.log`, and `tmp_*.log` are also
  gitignored as a safety net, but prefer `.tmp/` placement over relying on the safety net.
- If a script or `make` target currently writes to the repo root, update it to write to `.tmp/`
  in the same change.

Example:

```powershell
$outDir = Join-Path (git rev-parse --show-toplevel) ".tmp"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
go build ./... 2>&1 | Tee-Object "$outDir/backend_build.log"
```

## Markdown Authoring Guardrail (REQUIRED)

When creating or editing markdown files, use the `markdownlint` rules defined in
`.markdownlint.yaml` to ensure consistent formatting and style:

1. Before pushing, run `make lint-docs-fix` then `make lint-docs`; if lint still fails, fix manually until clean.

### Markdown Line Length Prevention (REQUIRED)

Prevent line-length lint failures (`MD013`) before running lint commands.

Rules:

- While drafting or editing markdown prose, hard-wrap text to 120 characters or fewer.
- Do not wait for lint output to discover long lines; wrap proactively as part of authoring.
- For changed markdown files, run a pre-check for long lines before final linting:
  `rg -n "^.{121,}$" --glob "*.md" --glob "docs/**/*.md" --glob ".github/**/*.md"`
  (or equivalent PowerShell search).
- If a long line is unavoidable (for example, a URL), use valid markdown structure that avoids
  overlong prose lines where possible (reference links, list formatting, or line breaks).

### Markdown EOF Hygiene (REQUIRED)

Prevent end-of-file formatting failures before running lint commands.

Rules:

- End every markdown file with exactly one trailing newline.
- Do not leave a markdown file without a final newline after edits.
- Do not accumulate extra blank lines at the end of the file while patching or appending content.
- Before final linting, do a quick EOF sanity check on changed markdown files if the edit path did
  not already preserve the final newline.

Workflow requirement for markdown edits:

1. Write/update markdown with proactive wrapping.
2. Ensure the file still ends with exactly one trailing newline.
3. Run long-line pre-check and fix hits.
4. Run `make lint-docs-fix`.
5. Run `make lint-docs`.
6. Resolve any remaining markdownlint issues before commit.

### Diagram Standards (REQUIRED)

**Prescribe both Mermaid and Ilograph where they each fit best.**

- **Mermaid for inline docs**: Keep diagrams embedded in markdown so they render
  directly in GitHub and VS Code without extra tooling.
- **Ilograph for deep-dive architecture**: Use `docs/diagrams/*.ilograph.yaml`
  when interactive exploration and richer multi-perspective views improve
  understanding.
- **Keep both in sync** when a markdown Mermaid view and an Ilograph view describe
  the same structure or runtime behavior.

- **Format**: Mermaid markdown code blocks
- **Location**: Embedded in README.md, ADRs, or separate `.md` files in `docs/diagrams/`
- **Types**: Use appropriate Mermaid diagram types:
  - `flowchart` - Process flows, decision trees
  - `sequenceDiagram` - API interactions, component communication
  - `classDiagram` - Object models, data structures
  - `erDiagram` - Database schemas, entity relationships
  - `stateDiagram` - State machines, lifecycle flows
  - `gitGraph` - Branching strategies
  - `gantt` - Project timelines

#### Mermaid Best Practices

##### Mermaid Label Line Break Rule (REQUIRED)

When writing multi-line Mermaid node labels:

- Use `<br/>` inside quoted labels.
- Do **not** use escaped newline tokens like `\n` in labels.

Required pre-check before finalizing diagram markdown:

1. Search changed diagram markdown for literal `\n` text.
2. Replace any `\n` label content with `<br/>`.

This prevents visible `\n` artifacts in rendered diagrams in GitHub and VS Code previews.

```markdown
## Example Architecture Diagram

\`\`\`mermaid
flowchart LR
    A[Input] --> B{Decision}
    B -->|Yes| C[Process]
    B -->|No| D[Skip]
    C --> E[Output]

    style A fill:#e1f5ff
    style E fill:#d4edda
    style D fill:#fff3cd
\`\`\`

## Example Sequence Diagram

\`\`\`mermaid
sequenceDiagram
    participant Client
    participant API
    participant DB

    Client->>API: POST /users
    API->>DB: INSERT user
    DB-->>API: Success
    API-->>Client: 201 Created
\`\`\`

## Example State Diagram

\`\`\`mermaid
stateDiagram-v2
    [*] --> New
    New --> Processing: Submit
    Processing --> Completed: Success
    Processing --> Failed: Error
    Failed --> Processing: Retry
    Completed --> [*]
\`\`\`
```

#### Why Mermaid?

- ✅ **Version Control**: Text-based diagrams tracked in Git
- ✅ **Collaboration**: Easy to review and update in PRs
- ✅ **Rendering**: Works in GitHub, VS Code, and most documentation tools
- ✅ **No Binary Files**: Avoid binary image files that cause merge conflicts
- ✅ **Consistency**: Standardized syntax across all diagrams
- ✅ **Maintainability**: Update diagrams as code changes

**DO NOT** use:

- ❌ Binary image files (PNG, JPG) for architecture diagrams
- ❌ External diagram tools (draw.io, Visio) unless absolutely necessary
- ❌ ASCII art (hard to read and maintain)
- ❌ External hosting (links break, requires external accounts)

#### Color Scheme for Dark Mode

Use medium-saturation colors that work in both light and dark modes:

```yaml
services/components: "#2C5F8D" (medium blue) with white text
processing/intermediate: "#17A2B8" (teal) with white text
success/output: "#28A745" (medium green) with white text
errors/validation: "#D9534F" (medium red) with white text
warnings/DLQ: "#F0AD4E" (medium orange) with dark text
backgrounds: "#555" (dark gray) with white text
```

## Documentation Artifact Guidance

This section provides **trigger-based** guidance on when to create durable
documentation artifacts. Only create artifacts when they serve a clear purpose;
avoid over-prescribing documentation.

### ADR (Architecture Decision Record)

**Trigger**: A change introduces a durable architectural, tooling, governance,
or workflow decision.

**When to create**:

- Alternatives were evaluated and a choice was made
- The decision affects multiple areas or future contributors
- The decision is unlikely to change in the near term
- Future maintainers would benefit from understanding the "why," not just
  the "what"

**Why**: Durable decisions deserve justification and historical context. ADRs
prevent rehashing decisions and document the trade-offs considered.

### Runbooks and Checklists

**Trigger**: A process is repeatable, operational, and easy to get wrong.

**When to create**:

- Setup flows or onboarding procedures
- Incident response or troubleshooting workflows
- Maintenance tasks that happen periodically
- Complex workflows with many manual steps or decision points

**Why**: Step-by-step guidance reduces operational errors and onboarding
friction. Checklists ensure nothing is missed in high-stress situations.

### Changelog or Release Notes

**Trigger**: Only for versioned releases or externally visible behavior changes.

**When to create**:

- New version is being released to users or customers
- A breaking change or significant feature is introduced
- Users or external teams need to know about the change

**When NOT to create**:

- Internal refactoring with no user-visible impact
- Every internal documentation edit
- Temporary fixes or experiments

**Why**: Avoid changelog noise. Focus on signal for end users; changelogs are not development journals.

### Log Files (log.md)

**Trigger**: Only for bounded chronological records with a clear owner and
retention purpose.

**When to create**:

- Migration logs (tracking progress and decisions during a migration)
- Meeting notes or decision journals (with dates, attendees, outcomes)
- Incident timelines (when and how issues were discovered and resolved)
- Ongoing records with a clear owner and maintenance commitment

**When NOT to create**:

- Generic "log.md" files scattered across the repo without purpose
- Logs with no clear retention policy or owner
- Transient debug output or build artifacts (use `.tmp/` for these)

**Why**: Focused, purposeful logs aid troubleshooting and knowledge transfer.
Unfocused or orphaned logs create clutter and confusion.

## Documentation Conventions

This section formalizes the minimal set of conventions for maintaining
consistent, navigable documentation across the repository. Follow these rules
to ensure clarity, discoverability, and low maintenance burden.

### 1. README.md is the Primary Human Entrypoint

README.md at the repository root must:

- List all stable top-level folders that contributors navigate directly
- Include critical root-level workflow files (Makefile, package.json, key
  config files)
- Provide a clear mental model of repository purpose and structure
- Link to deeper documentation where needed

When repository structure changes, update README.md in the same PR.

### 2. Each Subdirectory Has a Local README.md

Subdirectories with multiple files or a distinct purpose must have their own README.md:

- `docs/README.md` → overview of docs area and its subfolders
- `docs/internal/README.md` → what belongs in internal documentation
- `docs/vendor/README.md` → what belongs in vendor documentation
- `scripts/README.md` → overview of available scripts (if complex)

Each local README acts as a landing page for that directory and documents what
belongs there, not a duplicate of parent README information.

### 3. Repo-Wide Agent Policy Has One Canonical Source

All agent and automation policy is maintained in one place:

- `.github/copilot-instructions.md` is the canonical source for all repo-wide policies
- `.github/instructions/` contains scoped rules (language-specific, workflow-specific)
- Cross-tool agent files (e.g., AGENTS.md, CLAUDE.md, CURSOR.md) must
  **delegate** to these canonical sources instead of duplicating rules

Maintain one source of truth. Prevent policy drift through duplication.

### 4. Update README.md and Ilograph Sources Together

When repository structure, major workflow, or ownership boundaries change:

- Update README.md in the same PR
- Update Ilograph sources in `docs/diagrams/workspace-overview.ilograph.yaml`
  in the same change

This ensures both human-facing navigation and machine-readable architecture stay
in sync. (Already enforced by `ilograph-sync.instructions.md` and
`readme-structure-maintenance.instructions.md`.)

### 5. Create an ADR for Durable Decisions

Create an ADR when a change introduces an architectural, tooling, governance,
or contributor workflow decision and alternatives were considered.

Location: `docs/internal/adr-<date>-<short-title>.md` (or similar ADR naming convention).

Do not create ADRs for every change; only for decisions that will stand and
matter to future maintainers.

### 6. Create Runbooks for Repeatable Operations

Create a runbook or checklist for repeatable operational procedures:

- Setup flows and onboarding procedures
- Incident response or troubleshooting workflows
- Maintenance tasks that happen periodically
- Complex workflows with many manual steps or decision points

Location: `docs/internal/runbook-<title>.md` or `docs/internal/<title>-checklist.md`.

### 7. Create Changelogs Only for Versioned or External Changes

Create or update changelog/release-note entries only for:

- Versioned releases published to users or customers
- Breaking changes or significant features with external impact
- Changes users or external teams need to know about

Do NOT force changelog entries for:

- Internal refactoring with no user-visible impact
- Every internal documentation edit
- Temporary fixes or experiments

### 8. Create Logs Only for Bounded Records with Purpose

Create log-style documents only for:

- Migration logs (track progress and decisions during migrations)
- Meeting notes or decision journals (with dates, attendees, outcomes)
- Incident timelines (discovery, escalation, resolution)
- Ongoing records with a clear owner and maintenance commitment

Do NOT scatter generic `log.md` files across the repo; logs must have purpose and ownership.

### 9. Prefer Tool-Neutral Documentation

Documentation files should be tool-agnostic. Only add tool-specific instruction
files (e.g., CLAUDE.md, GEMINI.md, CURSOR.md) when:

- The tool actually requires repo-root discovery files
- Team verification confirms the tool looks for these files
- The tool-specific file is a minimal stub that delegates to canonical policy
  (not a full policy duplicate)

Avoid maintaining separate instruction files per tool unless absolutely
necessary. A single AGENTS.md entrypoint is preferable.
