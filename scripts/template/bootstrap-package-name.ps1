Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path "package.json")) {
    Write-Host "No package.json found; skipping package bootstrap."
    exit 0
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "npm not found; skipping package bootstrap."
    exit 0
}

$package = Get-Content -Raw "package.json" | ConvertFrom-Json -AsHashtable
$currentName = if ($package.ContainsKey("name")) { [string]$package["name"] } else { "" }
$currentPrivate = if ($package.ContainsKey("private")) { [string]$package["private"] } else { "" }
$currentDescription = if ($package.ContainsKey("description")) { [string]$package["description"] } else { "" }

$repoName = Split-Path -Leaf (Get-Location)
$projectName = [regex]::Replace($repoName, "^(?i)work-", "")
if ([string]::IsNullOrWhiteSpace($projectName)) {
    $projectName = $repoName
}

$sanitized = $projectName.ToLowerInvariant()
$sanitized = [regex]::Replace($sanitized, "[^a-z0-9._-]", "-")
$sanitized = [regex]::Replace($sanitized, "-+", "-")
$sanitized = $sanitized.Trim('-', '.', '_')
if ([string]::IsNullOrWhiteSpace($sanitized)) {
    $sanitized = "project-docs"
}

$placeholders = @("template-docs", "work-template-docs")
$shouldReplace = [string]::IsNullOrWhiteSpace($currentName) -or $placeholders.Contains($currentName)

if ($shouldReplace -and $currentName -ne $sanitized) {
    & npm pkg set "name=$sanitized" | Out-Null
    Write-Host "Updated package.json name: $currentName -> $sanitized"
    $metadataChanged = $true
} else {
    Write-Host "Keeping package.json name: $currentName"
}

$templateDescription = "Reusable template for documentation-first projects."
$defaultDescription = "Documentation for $projectName."
$shouldReplaceDescription = $shouldReplace -or [string]::IsNullOrWhiteSpace($currentDescription) -or $currentDescription -eq $templateDescription
$metadataChanged = $false

if ($shouldReplaceDescription -and $currentDescription -ne $defaultDescription) {
    & npm pkg set "description=$defaultDescription" | Out-Null
    Write-Host "Updated package.json description: $currentDescription -> $defaultDescription"
    $metadataChanged = $true
} else {
    Write-Host "Keeping package.json description: $currentDescription"
}

if ($shouldReplace -or [string]::IsNullOrWhiteSpace($currentPrivate)) {
    & npm pkg set "private=true" --json | Out-Null
    Write-Host "Ensured package.json private=true"
    $metadataChanged = $true
} else {
    Write-Host "Keeping package.json private: $currentPrivate"
}

# Regenerate package-lock.json only when package.json metadata was actually updated
if ($metadataChanged) {
    & npm install --package-lock-only | Out-Null
    Write-Host "Regenerated package-lock.json"
} else {
    Write-Host "No package.json metadata changed; skipping package-lock.json regeneration."
}

$settingsPath = ".vscode/settings.json"
if (-not (Test-Path -LiteralPath $settingsPath)) {
    Write-Host "No $settingsPath found; skipping cSpell bootstrap."
    exit 0
}

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

        return ,$items
    }

    return $Node
}

function Get-ProjectWords {
    param([string]$Value)

    return @(
        $Value -split "[^A-Za-z0-9]+" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne "" }
    )
}

$dictionaryName = "$sanitized-words"
$dictionaryFileName = "$dictionaryName.txt"
$dictionaryPath = Join-Path ".vscode" $dictionaryFileName
$templateDictionaryPath = ".vscode/generic-project-words.txt"

$wordSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

foreach ($word in (Get-ProjectWords -Value $repoName)) {
    $null = $wordSet.Add($word)
    $null = $wordSet.Add($word.ToLowerInvariant())
}

foreach ($word in (Get-ProjectWords -Value $projectName)) {
    $null = $wordSet.Add($word)
    $null = $wordSet.Add($word.ToLowerInvariant())
}

foreach ($word in (Get-ProjectWords -Value $sanitized)) {
    $null = $wordSet.Add($word)
    $null = $wordSet.Add($word.ToLowerInvariant())
}

$null = $wordSet.Add($sanitized.ToLowerInvariant())

$seedPaths = @($templateDictionaryPath, $dictionaryPath)
foreach ($seedPath in $seedPaths) {
    if (-not (Test-Path -LiteralPath $seedPath)) {
        continue
    }

    foreach ($line in (Get-Content -LiteralPath $seedPath)) {
        $trimmed = $line.Trim()
        if ($trimmed -ne "") {
            $null = $wordSet.Add($trimmed)
        }
    }
}

$sortedWords = @($wordSet | Sort-Object)
$wordListContent = ($sortedWords -join "`n")
if (-not $wordListContent.EndsWith("`n")) {
    $wordListContent += "`n"
}
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $dictionaryPath), $wordListContent, [System.Text.UTF8Encoding]::new($false))
Write-Host "Ensured cSpell word list: $dictionaryPath"

$settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json -AsHashtable

# Settings files in this template use flat dotted keys for cSpell.* (see
# .vscode/settings.generic.json), not a nested "cSpell": {...} object. Target
# the flat key, and fold in any legacy nested customDictionaries entries so a
# previously mis-registered settings.json self-heals instead of ending up
# with two conflicting customDictionaries blocks.
if (-not $settings.ContainsKey("cSpell.customDictionaries") -or -not ($settings["cSpell.customDictionaries"] -is [System.Collections.IDictionary])) {
    $settings["cSpell.customDictionaries"] = @{}
}
$customDictionaries = $settings["cSpell.customDictionaries"]

if ($settings.ContainsKey("cSpell") -and ($settings["cSpell"] -is [System.Collections.IDictionary])) {
    $legacyCSpell = $settings["cSpell"]
    if ($legacyCSpell.ContainsKey("customDictionaries") -and ($legacyCSpell["customDictionaries"] -is [System.Collections.IDictionary])) {
        foreach ($key in @($legacyCSpell["customDictionaries"].Keys)) {
            if (-not $customDictionaries.ContainsKey($key)) {
                $customDictionaries[$key] = $legacyCSpell["customDictionaries"][$key]
            }
        }
        $legacyCSpell.Remove("customDictionaries")
    }
    if ($legacyCSpell.Count -eq 0) {
        $settings.Remove("cSpell")
    }
}

$customDictionaries[$dictionaryName] = @{
    addWords = $true
    description = "Project-specific accepted words"
    name = $dictionaryName
    path = '${workspaceFolder}/.vscode/' + $dictionaryFileName
    scope = "workspace"
}

$sortedSettings = ConvertTo-SortedJsonNode -Node $settings
$formattedSettings = ($sortedSettings | ConvertTo-Json -Depth 100) -replace "`r?`n", "`n"
if (-not $formattedSettings.EndsWith("`n")) {
    $formattedSettings += "`n"
}
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $settingsPath), $formattedSettings, [System.Text.UTF8Encoding]::new($false))
Write-Host "Ensured cSpell dictionary registration: $dictionaryName"

$docsTokens = [ordered]@{
    "{{PROJECT_NAME}}" = $projectName
    "{{REPO_NAME}}" = $repoName
}
$docsPath = Join-Path (Get-Location) "docs"
$docsUpdated = 0
if (Test-Path -LiteralPath $docsPath -PathType Container) {
    foreach ($docFile in (Get-ChildItem -Path $docsPath -Recurse -File | Where-Object {
        $_.Extension -eq ".md" -or $_.Name -like "*.ilograph.yaml"
    })) {
        $content = [System.IO.File]::ReadAllText($docFile.FullName)

        $updatedContent = $content
        foreach ($token in $docsTokens.Keys) {
            $updatedContent = $updatedContent.Replace($token, $docsTokens[$token])
        }

        if ($updatedContent -eq $content) {
            continue
        }

        [System.IO.File]::WriteAllText($docFile.FullName, $updatedContent, [System.Text.UTF8Encoding]::new($false))
        $docsUpdated += 1
    }
}
Write-Host "Updated docs placeholders: $docsUpdated"
