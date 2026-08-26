---
description: >
  Defines the required workflow for handling GitHub PR review conversations end-to-end:
  review each conversation, apply fixes, commit with traceability, reply in-thread with
  commit reference, and resolve the conversation.
applyTo: '**'
---

# Copilot PR Conversation Workflow

Use this workflow whenever asked to process PR conversations, review threads, or comments,
including prompts such as:

- "review each conversation"
- "fix each conversation"
- "comment each conversation thread"
- "resolve the conversation"

## Required Sequence

1. Discover unresolved review conversations on the active PR.
2. For each conversation thread, determine whether code/docs changes are needed.
3. Implement only the required change for that thread.
4. Commit with traceability. Prefer one commit per conversation when practical.
  If multiple threads require tightly related edits, group them in a single
  commit. Use a Conventional Commit subject that references the thread topic
  or concern.
5. Reply in the same conversation thread with:
   - What changed
   - Why it addresses the feedback
   - The commit SHA (or SHAs) containing the fix
6. Resolve the conversation only after the thread reply is posted and the fix is committed.
7. Repeat until all intended conversations are addressed.

## Thread Reply Requirements

Each in-thread reply should include:

- A concise summary of the change
- A direct commit reference (full or short SHA)
- Any important caveat (if partially addressed)

If a thread cannot be fully addressed, do not resolve it. Reply with blocker details and
next action.

## Operational Rules

- Prefer GitHub CLI (`gh`) for thread replies/resolution in local VS Code sessions.
- If an API path/tool returns permission errors (for example 403), immediately use `gh`
  CLI fallback for replies.
- Do not post only a top-level PR summary when the request asks for conversation handling;
  replies must be in-thread.
- Use this as the default posting pattern for all multiline thread replies:
  - Write reply content to a `.tmp/` body file first.
  - Run file write/validation and `gh api` posting as separate commands.
  - Process one thread at a time (reply -> verify -> resolve), not one large batch script.
  - If command output is missing or truncated, verify thread/comment state before any retry.
- Before posting or editing in-thread replies, sanitize body text to printable characters
  (plus normal newline/tab) and remove control characters such as form feed (`\f`).
  If a bad character is discovered after posting, patch the comment body immediately.

## PR/Issue Body Encoding Guard (Required)

Use these rules whenever creating or editing top-level PR descriptions, PR comments,
or issue comments.

- Always write multiline markdown content to a `.tmp/` body file first and use
  `--body-file` (or read file content for GraphQL body fields).
- Never pass multiline markdown directly as an inline `--body "..."` string.
- Use ASCII punctuation in generated body text (`-` instead of em dash) unless
  non-ASCII characters are explicitly required by the content.
- Validate posted content immediately after submission (`gh pr view --json body`,
  `gh pr comment --editor` check, or equivalent API readback).
- If formatting corruption is detected (for example broken backticks, escaped path
  fragments, mojibake), patch the body immediately using a body file and do not
  proceed until verification is clean.

## Verification Checklist

- [ ] All targeted conversations received in-thread replies
- [ ] Each reply references the relevant commit SHA
- [ ] Each resolved thread is actually marked resolved on the PR
- [ ] Any unresolved thread has an explicit blocker comment

## Commit Message Templates

Use one of these Conventional Commit templates so a commit can be traced back to
a conversation quickly.

Preferred single-thread format:

```text
fix(pr-thread): <path or topic> - <short action>
```

Examples:

```text
fix(pr-thread): scripts/lint-docs - handle empty markdown set
fix(pr-thread): README install step - clarify pwsh requirement
docs(pr-thread): contributing guide - add branch naming example
test(pr-thread): docs lint task - cover windows path case
```

When one commit intentionally addresses multiple tightly related threads:

```text
fix(pr-threads): <shared topic> - address related review feedback
```

Body template (optional but recommended):

```text
Addresses PR review thread(s):
- <thread topic 1>
- <thread topic 2>

Why:
- <brief rationale>
```

Avoid generic messages such as `fix feedback` or `update files`; the subject
should make the conversation reason obvious without opening the diff.

## Ready-To-Run GH CLI Playbook

Use this sequence in local VS Code sessions when processing review conversations.

### 1. Identify Active PR And Unresolved Threads

```powershell
# Confirm current branch and active PR
$branch = git branch --show-current
$prInfo = gh pr view --json number | ConvertFrom-Json
$prNumber = [int]$prInfo.number

# List unresolved review threads (id + path + line + first comment)
$query = @'
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          path
          line
          comments(first:1) {
            nodes { body author { login } }
          }
        }
      }
    }
  }
}
'@

$repoInfo = gh repo view --json owner,name | ConvertFrom-Json
$owner = $repoInfo.owner.login
$repo = $repoInfo.name

$result = gh api graphql -f query="$query" -F owner="$owner" -F repo="$repo" -F number=$prNumber | ConvertFrom-Json
$threads = $result.data.repository.pullRequest.reviewThreads.nodes | Where-Object { -not $_.isResolved }
$threads | Select-Object id,path,line,@{Name='comment';Expression={$_.comments.nodes[0].body}} | Format-Table -AutoSize

# Note: reviewThreads(first:100) returns at most 100 threads per request.
# For very large PRs, paginate with pageInfo{hasNextPage,endCursor} and after:<cursor>
# until all unresolved threads are collected.
```

### 2. Fix One Thread At A Time (Prefer One Commit Per Thread)

```powershell
# After making code/doc changes for one thread:
git add -A
git commit -m "fix(pr-thread): <path or topic> - <short action>"

# Capture commit SHA for thread reply text
$sha = git rev-parse --short HEAD
Write-Output "Committed: $sha"
```

### 3. Reply In The Same Thread With Commit Reference

```powershell
# Prepare multiline reply in a file (avoid inline escaped newlines)
$threadId = "<REVIEW_THREAD_NODE_ID>"
$bodyPath = ".tmp/thread-reply-$threadId.md"
New-Item -ItemType Directory -Force -Path ".tmp" | Out-Null

@"
Addressed in commit $sha.

Summary:
- <what changed>
- <why this resolves feedback>
"@ | Set-Content -Encoding utf8 $bodyPath

# Validate file exists before posting
if (-not (Test-Path $bodyPath)) {
  throw "Reply body file was not created: $bodyPath"
}

$replyBody = Get-Content -Raw $bodyPath

$replyMutation = @'
mutation($threadId:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$threadId, body:$body}) {
    comment { id url }
  }
}
'@

gh api graphql -f query="$replyMutation" -F threadId="$threadId" -f body="$replyBody"
```

### 4. Verify Reply Before Resolving (Required)

```powershell
# Verify the thread has the newly posted reply before resolving.
# If verification is inconclusive, do not resolve yet.
$verifyQuery = @'
query($owner:String!, $repo:String!, $number:Int!, $threadId:ID!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id
          comments(last:1) { nodes { body url } }
        }
      }
    }
  }
}
'@

$verifyResult = gh api graphql -f query="$verifyQuery" -F owner="$owner" -F repo="$repo" -F number=$prNumber | ConvertFrom-Json
$thread = $verifyResult.data.repository.pullRequest.reviewThreads.nodes | Where-Object { $_.id -eq $threadId }

if (-not $thread) {
  throw "Thread not found during verification: $threadId"
}

if (-not $thread.comments.nodes -or -not $thread.comments.nodes[0].url) {
  throw "Reply verification failed for thread: $threadId"
}
```

### 5. Resolve The Thread After Reply Is Posted

```powershell
$resolveMutation = @'
mutation($threadId:ID!) {
  resolveReviewThread(input:{threadId:$threadId}) {
    thread { id isResolved }
  }
}
'@

gh api graphql -f query="$resolveMutation" -F threadId="$threadId"
```

### 6. Verify No Intended Threads Were Missed

```powershell
$result = gh api graphql -f query="$query" -F owner="$owner" -F repo="$repo" -F number=$prNumber | ConvertFrom-Json
$result.data.repository.pullRequest.reviewThreads.nodes |
  Select-Object id,isResolved,path,line |
  Format-Table -AutoSize

# If your PR can exceed 100 review threads, run this verification over paginated results.
```

If any thread remains unresolved intentionally, leave a blocker reply and keep it open.

### 7. Repeat Per Thread (No Bulk Posting)

```powershell
# Repeat steps 3, 4, and 5 for each thread ID individually.
# Avoid posting/replying to multiple thread IDs in one combined loop command.
```

## Post-Merge Cleanup

After the PR is merged, perform cleanup so local and remote branches stay tidy.

### Required Checklist

- [ ] Confirm PR state is `MERGED`
- [ ] Ensure local working tree is clean before branch switches/deletes
- [ ] Switch to `main`
- [ ] Fast-forward `main` from `origin/main`
- [ ] Delete merged feature branch locally
- [ ] Delete merged feature branch on remote (if it still exists)

### Ready-To-Run Cleanup Commands

```powershell
# Example for PR number 5
$prNumber = 5

$pr = gh pr view $prNumber --json state,headRefName,baseRefName | ConvertFrom-Json
if ($pr.state -ne "MERGED") {
  throw "PR #$prNumber is not merged. Cleanup skipped."
}

git status --short
git checkout $pr.baseRefName
git fetch --prune origin
git pull --ff-only origin $pr.baseRefName

# Delete local branch if present and different from current branch
$currentBranch = git branch --show-current
if ($pr.headRefName -ne $currentBranch) {
  git branch -d $pr.headRefName
}

# Delete remote branch if present
git push origin --delete $pr.headRefName
```

If remote branch deletion fails because the branch is already removed, treat that as
non-blocking and continue.
