#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Lint PowerShell scripts using PSScriptAnalyzer.

.DESCRIPTION
    Runs PSScriptAnalyzer against all PowerShell scripts in the repository
    or specific files if provided.

.PARAMETER Files
    Optional array of file paths to lint. If not provided, lints all .ps1 files in scripts/.

.PARAMETER Fix
    Not used (PSScriptAnalyzer doesn't auto-fix). Present for consistency with lint-docs.ps1.

.EXAMPLE
    .\lint-powershell.ps1
    .\lint-powershell.ps1 -Files scripts/check-service-coupling.ps1

.OUTPUTS
    Console: PSScriptAnalyzer violations if found.

.EXIT CODES
    0 = no violations found
    1 = violations found
    2 = script error or PSScriptAnalyzer not installed
#>

param(
    [string[]]$Files,
    [switch]$Fix
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$RepoRoot = git rev-parse --show-toplevel
$ScriptsDir = Join-Path $RepoRoot 'scripts/template'
$SettingsFile = Join-Path $ScriptsDir 'PSScriptAnalyzerSettings.psd1'

# Verify PSScriptAnalyzer is installed
try {
    $AnalyzerModule = Get-Module -Name PSScriptAnalyzer -ErrorAction Stop
    if ($null -eq $AnalyzerModule) {
        Import-Module PSScriptAnalyzer -ErrorAction Stop | Out-Null
    }
}
catch {
    Write-Host "Error: PSScriptAnalyzer module not found" -ForegroundColor Red
    Write-Host "Install it with: Install-Module -Name PSScriptAnalyzer -Repository PSGallery -Force"
    exit 2
}

# Determine which files to lint
if ($Files -and ($Files.Count -gt 0 -or ($Files -is [string] -and $Files -ne ''))) {
    # Files parameter provided and non-empty
    $FilesToLint = @($Files) | Where-Object { $_ } # Filter out empty strings
}
else {
    # No files specified; find all .ps1 files in scripts directory
    $FilesToLint = @(Get-ChildItem -Path $ScriptsDir -Filter '*.ps1' -File |
        Where-Object { $_.Name -ne 'PSScriptAnalyzerSettings.psd1' } |
        Select-Object -ExpandProperty FullName)
}

if (@($FilesToLint).Count -eq 0) {
    Write-Host "No PowerShell files to lint"
    exit 0
}

# Run PSScriptAnalyzer
$Violations = @()
foreach ($File in $FilesToLint) {
    if (-not (Test-Path $File)) {
        Write-Host "Warning: File not found: $File" -ForegroundColor Yellow
        continue
    }

    $Results = Invoke-ScriptAnalyzer -Path $File -Settings $SettingsFile -ErrorAction Continue
    if ($Results) {
        $Violations += $Results
    }
}

# Report results
if (@($Violations).Count -eq 0) {
    Write-Host "✓ PowerShell linting passed"
    exit 0
}

Write-Host ""
Write-Host "✗ PowerShell linting found $(@($Violations).Count) violation(s):" -ForegroundColor Red
Write-Host ""

$Violations | Format-Table -Property @(
    @{Label = 'File'; Expression = { Split-Path -Leaf $_.ScriptName }},
    @{Label = 'Line'; Expression = { $_.Line }},
    @{Label = 'Rule'; Expression = { $_.RuleName }},
    @{Label = 'Message'; Expression = { $_.Message }}
) -AutoSize

Write-Host ""
Write-Host "See PSScriptAnalyzer documentation for rule details:"
Write-Host "https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/rules-overview"
Write-Host ""

exit 1
