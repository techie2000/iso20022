#!/bin/bash
# Lint PowerShell scripts using PSScriptAnalyzer.
#
# Usage:
#   ./lint-powershell.sh [FILES...]
#
# If no files are specified, lints all .ps1 files in scripts/.
#
# Exit codes:
#   0 = no violations found
#   1 = violations found
#   2 = script error or PSScriptAnalyzer not available

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$REPO_ROOT/scripts/template"
SETTINGS_FILE="$SCRIPTS_DIR/PSScriptAnalyzerSettings.psd1"

# Check if pwsh is available
if ! command -v pwsh &> /dev/null; then
    echo "Error: pwsh (PowerShell 7+) is required to run PSScriptAnalyzer"
    echo "Install PowerShell 7+ or run linting from a shell where pwsh is available"
    exit 2
fi

# Determine which files to lint
if [ $# -gt 0 ]; then
    FILES=("$@")
else
    mapfile -t FILES < <(find "$SCRIPTS_DIR" -maxdepth 1 -name "*.ps1" -type f \
        ! -name "PSScriptAnalyzerSettings.psd1" | sort)
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No PowerShell files to lint"
    exit 0
fi

# Create a temporary PowerShell script to run the linting
TEMP_SCRIPT=$(mktemp)
trap "rm -f '$TEMP_SCRIPT'" EXIT

cat > "$TEMP_SCRIPT" << 'PWSH_SCRIPT'
param([string[]]$Files, [string]$SettingsFile)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

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

$Violations = @()
foreach ($File in $Files) {
    if (-not (Test-Path $File)) {
        Write-Host "Warning: File not found: $File" -ForegroundColor Yellow
        continue
    }

    $Results = Invoke-ScriptAnalyzer -Path $File -Settings $SettingsFile -ErrorAction Continue
    if ($Results) {
        $Violations += $Results
    }
}

if ($Violations.Count -eq 0) {
    Write-Host "✓ PowerShell linting passed"
    exit 0
}

Write-Host ""
Write-Host "✗ PowerShell linting found $($Violations.Count) violation(s):" -ForegroundColor Red
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
PWSH_SCRIPT

# Run via pwsh
pwsh -NoProfile -ExecutionPolicy Bypass -File "$TEMP_SCRIPT" -Files "${FILES[@]}" -SettingsFile "$SETTINGS_FILE"
exit $?
