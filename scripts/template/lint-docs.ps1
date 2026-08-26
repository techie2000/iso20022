param(
    [switch]$Fix,
    [string[]]$Paths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw "npx not found. Install Node.js/npm to run markdownlint-cli2."
}

$targets = @()
if ($Paths -and $Paths.Count -gt 0) {
    $targets = $Paths
} else {
    $targets = @(git ls-files '*.md' | Where-Object { $_ -and $_.Trim() -ne '' })
}

if ($targets.Count -eq 0) {
    Write-Host "No markdown files found to lint."
    exit 0
}

$argsList = @('--no-install', 'markdownlint-cli2', '--config', '.markdownlint-cli2.yaml')
if ($Fix) {
    $argsList += '--fix'
}
$argsList += $targets

& npx @argsList
exit $LASTEXITCODE
