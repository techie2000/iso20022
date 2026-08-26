Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configure the repository to use hooks from .githooks.
& git config core.hooksPath .githooks

$configuredPath = (& git config --get core.hooksPath).Trim()
if ($configuredPath -ne ".githooks") {
    throw "Failed to configure core.hooksPath to .githooks"
}

Write-Host "Configured git hooks path: $configuredPath"
