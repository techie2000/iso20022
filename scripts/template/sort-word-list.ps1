param(
    [string[]]$WordListPaths = @(),
    [string]$WordListGlob = ".vscode/*-words.txt",
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-SortedWordListContent {
    param([string]$Path)

    $original = Get-Content -LiteralPath $Path -Raw
    $normalizedOriginal = $original -replace "`r`n", "`n"

    $lines = $normalizedOriginal -split "`n"
    if ($lines.Count -gt 0 -and $lines[-1] -eq "") {
        $lines = $lines[0..($lines.Count - 2)]
    }

    $entries = @()
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -ne "") {
            $entries += $trimmed
        }
    }

    # Preserve case variants (e.g., Euroclear and euroclear) while removing exact duplicates.
    $sortedEntries = $entries | Sort-Object -CaseSensitive -Unique
    $formatted = ($sortedEntries -join "`n")
    if (-not $formatted.EndsWith("`n")) {
        $formatted += "`n"
    }

    return [ordered]@{
        Original = $normalizedOriginal
        Formatted = $formatted
    }
}

$resolvedWordListPaths = $WordListPaths
if ($resolvedWordListPaths.Count -eq 0) {
    $resolvedWordListPaths = @(
        Get-ChildItem -Path $WordListGlob -File -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName }
    )
}

$missing = @($resolvedWordListPaths | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($missing.Count -gt 0) {
    foreach ($path in $missing) {
        Write-Host "Skipping missing word list: $path"
    }
}

$existing = @($resolvedWordListPaths | Where-Object { Test-Path -LiteralPath $_ })
if ($existing.Count -eq 0) {
    Write-Host "No word list files found to sort."
    exit 0
}

$changedPaths = @()
foreach ($path in $existing) {
    $comparison = Get-SortedWordListContent -Path $path
    if ($comparison.Original -ceq $comparison.Formatted) {
        Write-Host "Word list already sorted: $path"
        continue
    }

    if ($CheckOnly) {
        $changedPaths += $path
        continue
    }

    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $path), $comparison.Formatted, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Sorted word list: $path"
}

if ($CheckOnly -and $changedPaths.Count -gt 0) {
    Write-Error "Word lists are not sorted. Run: pwsh ./scripts/template/sort-word-list.ps1"
    exit 1
}

exit 0
