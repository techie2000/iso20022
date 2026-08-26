param(
    [string]$ExtensionsPath = ".vscode/extensions.json",
    [switch]$CheckOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-SortedJsonNode {
    param([object]$Node)

    if ($null -eq $Node) {
        return $null
    }

    if ($Node -is [System.Collections.IDictionary]) {
        $sorted = [ordered]@{}
        foreach ($key in ($Node.Keys | Sort-Object)) {
            $sorted[$key] = ConvertTo-SortedJsonNode -Node $Node[$key]
        }
        return $sorted
    }

    if (($Node -is [System.Collections.IEnumerable]) -and -not ($Node -is [string])) {
        $items = @()
        foreach ($item in $Node) {
            $items += ,(ConvertTo-SortedJsonNode -Node $item)
        }

        # For extension ID lists (string arrays), normalize order alphabetically.
        if ($items.Count -gt 0 -and ($items | Where-Object { $_ -isnot [string] } | Measure-Object).Count -eq 0) {
            $items = @($items | Sort-Object)
        }

        # Preserve array shape for empty and single-item arrays.
        return ,$items
    }

    return $Node
}

if (-not (Test-Path -LiteralPath $ExtensionsPath)) {
    throw "Extensions file not found: $ExtensionsPath"
}

$original = Get-Content -LiteralPath $ExtensionsPath -Raw

try {
    $parsed = $original | ConvertFrom-Json -AsHashtable
} catch {
    throw "Failed to parse $ExtensionsPath as JSON. Ensure it contains valid JSON before sorting. $($_.Exception.Message)"
}

$sorted = ConvertTo-SortedJsonNode -Node $parsed
$formatted = ($sorted | ConvertTo-Json -Depth 100) -replace "`r?`n", "`n"
if (-not $formatted.EndsWith("`n")) {
    $formatted += "`n"
}

$normalizedOriginal = $original -replace "`r`n", "`n"

if ($normalizedOriginal -ceq $formatted) {
    Write-Host "extensions.json is already sorted."
    exit 0
}

if ($CheckOnly) {
    Write-Error "extensions.json is not sorted. Run: pwsh ./scripts/template/sort-vscode-extensions.ps1"
    exit 1
}

[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $ExtensionsPath), $formatted, [System.Text.UTF8Encoding]::new($false))
Write-Host "Sorted $ExtensionsPath alphabetically."
