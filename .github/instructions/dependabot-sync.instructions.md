---
description: >
  Ensures Dependabot configuration stays synchronized as package managers,
  ecosystems, and directory structures change in the repository.
applyTo: '**'
---

# Dependabot Configuration Sync

Use this instruction to keep `.github/dependabot.yml` synchronized with changes
to package management, ecosystems, and directory structures in the repository.

## Scope

Track these files:

- `.github/dependabot.yml`

## Purpose

Dependabot automates dependency updates across supported ecosystems. The configuration
must remain accurate as the repository evolves to avoid missed dependencies or
stale Dependabot entries that target nonexistent directories or outdated package managers.

## When to Update dependabot.yml

### Adding a New Package Manager or Ecosystem

Update `.github/dependabot.yml` in the same PR when:

1. A new `package.json` is added to a subdirectory (additional npm workspaces)
2. A `requirements.txt`, `Pipfile`, or `pyproject.toml` is added (Python)
3. A `Gemfile` is added (Ruby)
4. A `go.mod` is added (Go)
5. A `pom.xml` or `build.gradle` is added (Java/Kotlin)
6. A `Dockerfile` is added that pulls base images or dependencies requiring tracking
7. Any other package manager or ecosystem is introduced into the repository

### Removing or Reorganizing Directories

Update `.github/dependabot.yml` when:

1. A directory containing `package.json` is removed or merged
2. A directory is moved to a different location (update the `directory` path)
3. A package manager setup is migrated or replaced with a different one
4. A subdirectory dependency management is consolidated or split

### Ecosystem Deprecation

Update `.github/dependabot.yml` when:

1. Support for a package manager or ecosystem is being retired
2. A subdirectory no longer uses a particular package manager
3. A workflow or dependency strategy is no longer relevant

## Configuration Pattern

Each entry in `dependabot.yml` must include:

- `package-ecosystem`: The supported ecosystem (e.g., `npm`, `pip`, `go`, `github-actions`)
- `directory`: The path to the manifest file or workspace root (e.g., `/`, `./backend/`, `./services/api/`)
- `schedule`: Frequency and timing of update checks
- `labels`: Classification tags for PRs (e.g., `dependencies`, `npm`, `python`)
- `reviewers` / `assignees`: Owners responsible for reviewing and merging (optional but recommended)
- `commit-message`: Prefix and scope conventions for consistency with Conventional Commits

## Supported Package Ecosystems

Refer to [Dependabot supported ecosystems](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/about-dependabot-version-updates#supported-repositories-and-ecosystems):

- `npm` — Node.js / JavaScript
- `pip` — Python
- `bundler` — Ruby
- `cargo` — Rust
- `composer` — PHP
- `docker` — Docker base images
- `elm` — Elm
- `github-actions` — GitHub Actions workflows
- `gitsubmodule` — Git submodules
- `gomod` — Go
- `gradle` — Java / Gradle
- `maven` — Java / Maven
- `mix` — Elixir
- `nuget` — .NET / NuGet
- `pub` — Dart

## Verification Checklist

Before finalizing any change to repository structure or adding new package managers:

- [ ] All active package managers in the repo have entries in `dependabot.yml`
- [ ] All `directory` paths in `dependabot.yml` point to existing manifest files or directories
- [ ] No orphaned entries remain for removed or deprecated directories
- [ ] Labels and commit prefixes follow the repository's Conventional Commits convention
- [ ] Reviewers and assignees are correctly set (if applicable)
- [ ] Schedule intervals and times are consistent with team preferences

## Quality Gate

After updating `dependabot.yml`:

1. Run `cat .github/dependabot.yml` to verify syntax is valid YAML
2. Confirm no syntax errors exist (use `yamllint` if available in the repository)
3. Verify all `directory` paths exist in the repository
4. Test that the updated configuration is reachable by Dependabot

Tip: GitHub displays Dependabot configuration errors in the "Code security and analysis" settings panel.
If entries are misconfigured, GitHub will show warnings there.

## Example Workflow: Adding Python Dependencies

### Scenario: Add `requirements.txt` to `./scripts/requirements/`

1. Create `./scripts/requirements/requirements.txt`
2. In the same PR, add a new entry to `.github/dependabot.yml`:

   ```yaml
   - package-ecosystem: pip
     directory: "/scripts/requirements/"
     schedule:
       interval: weekly
       day: monday
       time: "10:00"
     labels:
       - dependencies
       - python
     commit-message:
       prefix: "chore(deps):"
       include: "scope"
   ```

3. Verify the YAML is valid and the directory path is correct
4. Commit with a message like: `chore(deps): add Python dependency tracking for scripts/requirements/`

## Example Workflow: Moving a Subdirectory

### Scenario: Reorganize `./backend/` to `./services/backend/`

1. Move the directory and its `package.json`
2. Update `.github/dependabot.yml` to change:

   ```yaml
   # Old entry (REMOVE)
   - package-ecosystem: npm
     directory: "/backend/"

   # New entry (ADD)
   - package-ecosystem: npm
     directory: "/services/backend/"
   ```

3. Commit with a message like: `chore(deps): update npm path after backend reorganization`

## Operational Rules

- Prefer weekly or monthly schedules to avoid Dependabot PR spam
- Group related updates by ecosystem label (e.g., `dependencies`, `npm`, `python`)
- Use consistent commit message prefixes across all entries
- Keep `open-pull-requests-limit` reasonable (e.g., 5-10) to prevent overwhelming the review queue
- Document any intentional omissions or excluded ecosystems in a comment in `dependabot.yml`

## Post-Merge Verification

After a change that adds or removes package managers:

1. GitHub will run a Dependabot check within hours or days
2. Verify in the "Security" → "Dependabot alerts" section that the new ecosystem is being scanned
3. If no PRs appear after a week, check `.github/dependabot.yml` syntax or the directory path

If updates are delayed, check the repository's "Code security and analysis" settings for Dependabot errors.
