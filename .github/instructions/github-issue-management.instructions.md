---
description: >
  Defines the required workflow for managing GitHub issues, including duplicate
  prevention before creation and duplicate closure procedures. Ensures issue
  history stays traceable back to a canonical issue.
applyTo: '**'
---

# GitHub Issue Management Workflow

Use this workflow whenever asked to process GitHub issues, create issues, or close issues,
including prompts such as:

- "raise a GitHub issue"
- "create a GitHub issue"
- "close duplicate issues"
- "manage issue tracking"

## Prevention: Check Before Creating (REQUIRED)

Before creating any GitHub issue, verify that no equivalent issue already exists.

1. Identify 2-4 search terms from the proposed issue title or summary.
2. Run `gh issue list --search "<keywords>" --limit 10`.
3. Review the results and confirm the issue does not already exist.
4. If an equivalent issue exists, use that issue number instead of creating a duplicate.
5. Only create a new issue when the search confirms there is no matching issue.

Example:

```powershell
# Search for an existing issue before creating a new one.
gh issue list --search "docs lint hook bootstrap" --limit 10

# If no equivalent issue exists, create the new issue using a body file.
gh issue create --title "Bootstrap: normalize docs lint setup" --body-file .tmp/issue-body.md
```

This prevents duplicate issues from being created in the first place.

## Duplicate Issue Closure Procedure (REQUIRED)

When closing an issue as a duplicate:

1. Close the issue with reason `duplicate` via `gh issue close <num> --reason duplicate`.
2. Add a reference comment immediately pointing to the canonical issue using this format:
   `Duplicate of #<CANONICAL_NUM> - follow that issue for the implementation.`
3. Do not leave a closed duplicate without a pointer, because users landing on the closed issue
   need a direct path to the active issue.

Example command:

```text
gh issue comment <DUP_NUM> --body "Duplicate of #<CANONICAL_NUM> - follow that issue for the implementation."
```

## Canonical Issue Link Format

Keep duplicate-pointer comments minimal and consistent:

- Format: `Duplicate of #<NUM> - follow that issue for the implementation.`
- Placement: Post the comment on the closed duplicate immediately after closure.
- Timing: Post the pointer before moving on to other issue work.

## Verification

After closing duplicate issues:

1. Verify at least one comment exists on each closed duplicate.
2. Confirm the comment references the correct canonical issue number.
3. Confirm the link is discoverable, for example with `gh issue view <DUP> --json comments`.

## When Not To Apply

- The issue is closed for a reason other than `duplicate`.
- The issue is closed per user request without a canonical replacement.
- The issue remains open.

## Operational Rules

- Prefer `gh issue list`, `gh issue create`, `gh issue comment`, and `gh issue close` for consistency.
- For multiline issue bodies or comments, write the content to a file under `.tmp/` first and use
  `--body-file` when supported.
- Keep comments concise and actionable.
- If multiple duplicates exist, add pointers to all of them before ending the session.
- Record issue mappings in the session context when working through a larger duplicate batch.

## Example Workflow

```powershell
# Scenario: close issues 33-35 as duplicates of #38.

# 1. Close each duplicate.
gh issue close 33 --reason duplicate
gh issue close 34 --reason duplicate
gh issue close 35 --reason duplicate

# 2. Add pointer comments immediately.
gh issue comment 33 --body "Duplicate of #38 - follow that issue for the implementation."
gh issue comment 34 --body "Duplicate of #38 - follow that issue for the implementation."
gh issue comment 35 --body "Duplicate of #38 - follow that issue for the implementation."

# 3. Verify the comments are present.
gh issue view 33 --json comments
```

## Quality Gate

- [ ] New issues were searched for before creation.
- [ ] All closed duplicates have pointer comments.
- [ ] Each pointer references the correct canonical issue number.
- [ ] Pointer comments are discoverable and consistent in format.
