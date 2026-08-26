---
applyTo: '**/*.ps1,**/*.psm1'
---

# PowerShell Approved Verbs

When writing or modifying PowerShell functions or cmdlets in this repository:

- Use only [approved PowerShell verbs](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
  for function names.
- Do not introduce new functions with unapproved verbs such as `Ask`, `Do`,
  `Handle`, or `Process` unless they are part of an external interface that
  cannot be changed.
- Prefer standard verb-noun naming, such as:
  - `Get-...`
  - `Set-...`
  - `New-...`
  - `Remove-...`
  - `Test-...`
  - `Invoke-...`
  - `Start-...`
  - `Stop-...`
  - `Read-...`
  - `Write-...`
- If a requested name would use an unapproved verb, rename it to the closest approved verb before finalizing the change.
- Treat `PSScriptAnalyzer` rule `PSUseApprovedVerbs` as blocking for newly written or edited PowerShell code.
- Before finalizing PowerShell changes, quickly check function names for verb compliance.

## Examples

- Use `Read-Choice` instead of `Ask-Choice`
- Use `Invoke-ReportGeneration` instead of `Do-ReportGeneration`
- Use `Start-Processing` instead of `Handle-Processing`
