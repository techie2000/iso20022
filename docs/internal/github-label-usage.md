# GitHub Label Usage

This repository uses a small set of workflow-managed labels for issue and PR
governance.

## Label Catalog

| Label | Applied To | Meaning | Managed By |
| --- | --- | --- | --- |
| `status: triage` | Issues | New or reopened issue pending active implementation work. | Automation + maintainers |
| `status: in progress` | Issues | Linked implementation work is active (for example, an open PR references the issue). | Automation + maintainers |
| `status: done` | Issues | Linked implementation work is completed (typically after merge/close flow). | Automation + maintainers |
| `no-issue-needed` | Pull requests | PR is intentionally allowed without a linked issue (bot PR or approved override). | Automation + maintainers |

## Usage Rules

1. For normal feature/fix PRs, include an issue reference in the PR body (for
   example `Refs #123`) instead of relying on `no-issue-needed`.
2. Use `Closes/Fixes #N` only when `#N` is an issue, never when `#N` is a pull
   request.
3. Only use the `No linked issue` PR template override when there is a valid
   reason; include that reason in the PR description.
4. Do not manually apply `status:*` labels as a first step. Prefer allowing the
   workflows to set lifecycle state, then correct manually only if automation
   cannot infer the right state.
5. If manual correction is needed, keep exactly one lifecycle label on an issue
   at a time: `status: triage`, `status: in progress`, or `status: done`.

## Workflow Behavior

- [`.github/workflows/auto-label-issues.yml`](../../.github/workflows/auto-label-issues.yml)
  ensures issue lifecycle labels exist and applies `status: triage` on new
  issues.
- [`.github/workflows/auto-label-prs.yml`](../../.github/workflows/auto-label-prs.yml)
  applies or removes `no-issue-needed` based on bot authorship and the PR
  template override checkbox.
- [`.github/workflows/sync-issue-status-from-pr.yml`](../../.github/workflows/sync-issue-status-from-pr.yml)
  updates linked issue lifecycle labels as PR state changes.
- [`.github/workflows/backfill-labels.yml`](../../.github/workflows/backfill-labels.yml)
  can reconcile legacy repositories or drifted label states.

## Maintainer Notes

- If automation cannot label due to token restrictions (for example fork-related
  permission limits), add labels manually and leave a short comment noting why.
- Keep label names stable. If you rename a label, update all workflow files and
  this document in the same PR.
