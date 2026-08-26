param(
    [ValidateSet("apply", "check", "distribute", "classify")]
    [string]$Action = "apply",
    [Alias("Profile")]
    [ValidateSet("generic", "opinionated")]
    [string]$SettingsProfile = "generic",
    [string]$SettingsPath = ".vscode/settings.json",
    [string]$GenericSettingsPath = ".vscode/settings.generic.json",
    [string]$OpinionatedSettingsPath = ".vscode/settings.opinionated.json",
    [string]$PolicyPath = "scripts/template/settings-policy.json",
    [ValidateSet("error", "generic", "opinionated")]
    [string]$UnknownKeyScope = "error"
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
        return $items
    }

    return $Node
}

function Read-JsonAsHashtable {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{}
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @{}
    }

    return ($raw | ConvertFrom-Json -AsHashtable)
}

function Write-HashtableAsJson {
    param(
        [string]$Path,
        [hashtable]$Data
    )

    $sorted = ConvertTo-SortedJsonNode -Node $Data
    $formatted = ($sorted | ConvertTo-Json -Depth 100) -replace "`r?`n", "`n"
    if (-not $formatted.EndsWith("`n")) {
        $formatted += "`n"
    }

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $Path), $formatted, [System.Text.UTF8Encoding]::new($false))
}

function Join-SettingsMaps {
    param(
        [hashtable]$Generic,
        [hashtable]$Opinionated
    )

    $merged = @{}
    foreach ($key in $Generic.Keys) {
        $merged[$key] = $Generic[$key]
    }

    foreach ($key in $Opinionated.Keys) {
        $merged[$key] = $Opinionated[$key]
    }

    return $merged
}

function Test-KeyPatternMatch {
    param(
        [string]$Key,
        [string]$Pattern
    )

    if ($Pattern.EndsWith("*")) {
        $prefix = $Pattern.Substring(0, $Pattern.Length - 1)
        return $Key.StartsWith($prefix, [System.StringComparison]::Ordinal)
    }

    return $Key -ceq $Pattern
}

function Get-KeyScope {
    param(
        [string]$Key,
        [hashtable]$Policy
    )

    $genericPatterns = @($Policy["genericPatterns"])
    foreach ($pattern in $genericPatterns) {
        if (Test-KeyPatternMatch -Key $Key -Pattern ([string]$pattern)) {
            return "generic"
        }
    }

    $opinionatedPatterns = @($Policy["opinionatedPatterns"])
    foreach ($pattern in $opinionatedPatterns) {
        if (Test-KeyPatternMatch -Key $Key -Pattern ([string]$pattern)) {
            return "opinionated"
        }
    }

    return "unknown"
}

function Group-SettingsByPolicy {
    param(
        [hashtable]$Settings,
        [hashtable]$Policy,
        [string]$UnknownScope
    )

    $generic = @{}
    $opinionated = @{}
    $unknownKeys = @()

    foreach ($key in ($Settings.Keys | Sort-Object)) {
        $scope = Get-KeyScope -Key ([string]$key) -Policy $Policy
        switch ($scope) {
            "generic" {
                $generic[$key] = $Settings[$key]
            }
            "opinionated" {
                $opinionated[$key] = $Settings[$key]
            }
            default {
                if ($UnknownScope -eq "generic") {
                    $generic[$key] = $Settings[$key]
                } elseif ($UnknownScope -eq "opinionated") {
                    $opinionated[$key] = $Settings[$key]
                } else {
                    $unknownKeys += [string]$key
                }
            }
        }
    }

    return @{
        generic = $generic
        opinionated = $opinionated
        unknownKeys = $unknownKeys
    }
}

function Get-ExpectedSettings {
    param(
        [string]$RequestedProfile,
        [hashtable]$Generic,
        [hashtable]$Opinionated
    )

    if ($RequestedProfile -eq "generic") {
        return $Generic
    }

    return (Join-SettingsMaps -Generic $Generic -Opinionated $Opinionated)
}

function Format-JsonText {
    param([hashtable]$Node)

    $sorted = ConvertTo-SortedJsonNode -Node $Node
    $formatted = ($sorted | ConvertTo-Json -Depth 100) -replace "`r?`n", "`n"
    if (-not $formatted.EndsWith("`n")) {
        $formatted += "`n"
    }

    return $formatted
}

$policy = Read-JsonAsHashtable -Path $PolicyPath
if (-not $policy.ContainsKey("genericPatterns") -or -not $policy.ContainsKey("opinionatedPatterns")) {
    throw "Invalid policy file: $PolicyPath. Expected genericPatterns and opinionatedPatterns arrays."
}

$genericSettings = Read-JsonAsHashtable -Path $GenericSettingsPath
$opinionatedSettings = Read-JsonAsHashtable -Path $OpinionatedSettingsPath

switch ($Action) {
    "apply" {
        $expected = Get-ExpectedSettings -RequestedProfile $SettingsProfile -Generic $genericSettings -Opinionated $opinionatedSettings
        Write-HashtableAsJson -Path $SettingsPath -Data $expected
        Write-Host "Applied settings profile '$SettingsProfile' to $SettingsPath"
    }
    "check" {
        $expected = Get-ExpectedSettings -RequestedProfile $SettingsProfile -Generic $genericSettings -Opinionated $opinionatedSettings
        $expectedText = Format-JsonText -Node $expected

        if (-not (Test-Path -LiteralPath $SettingsPath)) {
            Write-Error "Missing settings file: $SettingsPath"
            exit 1
        }

        $actualText = (Get-Content -LiteralPath $SettingsPath -Raw) -replace "`r`n", "`n"
        if ($actualText -ceq $expectedText) {
            Write-Host "Settings profile check passed for '$SettingsProfile'."
            exit 0
        }

        Write-Error "${SettingsPath} does not match the generated '$SettingsProfile' profile. Run: pwsh ./scripts/template/settings-profile.ps1 -Action apply -Profile $SettingsProfile"
        exit 1
    }
    "distribute" {
        if (-not (Test-Path -LiteralPath $SettingsPath)) {
            throw "Settings file not found: $SettingsPath"
        }

        $settings = Read-JsonAsHashtable -Path $SettingsPath
        $split = Group-SettingsByPolicy -Settings $settings -Policy $policy -UnknownScope $UnknownKeyScope
        $unknownKeys = @($split.unknownKeys)

        if ($unknownKeys.Count -gt 0) {
            Write-Error "Unmapped settings keys found in ${SettingsPath}:`n- $($unknownKeys -join "`n- ")`nUpdate ${PolicyPath} or pass -UnknownKeyScope generic|opinionated"
            exit 1
        }

        Write-HashtableAsJson -Path $GenericSettingsPath -Data $split.generic
        Write-HashtableAsJson -Path $OpinionatedSettingsPath -Data $split.opinionated

        $expected = Get-ExpectedSettings -RequestedProfile $SettingsProfile -Generic $split.generic -Opinionated $split.opinionated
        Write-HashtableAsJson -Path $SettingsPath -Data $expected

        Write-Host "Distributed settings into profile sources and applied '$SettingsProfile' to $SettingsPath"
    }
    "classify" {
        if (-not (Test-Path -LiteralPath $SettingsPath)) {
            throw "Settings file not found: $SettingsPath"
        }

        $settings = Read-JsonAsHashtable -Path $SettingsPath
        $rows = @()
        $unknownKeys = @()

        foreach ($key in ($settings.Keys | Sort-Object)) {
            $scope = Get-KeyScope -Key ([string]$key) -Policy $policy
            if ($scope -eq "unknown") {
                $unknownKeys += [string]$key
            }

            $rows += [pscustomobject]@{
                key = [string]$key
                scope = $scope
            }
        }

        $rows | Format-Table -AutoSize | Out-String | Write-Host

        if ($unknownKeys.Count -gt 0) {
            Write-Warning "Unmapped keys found in ${SettingsPath}:`n- $($unknownKeys -join "`n- ")"
            exit 1
        }

        Write-Host "All keys are mapped by $PolicyPath"
    }
}