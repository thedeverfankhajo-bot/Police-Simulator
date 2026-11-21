[CmdletBinding()]
param(
    [string]$DownloadDirectory = (Join-Path $PSScriptRoot "downloads"),
    [ValidateSet("x64", "arm64", "x86")]
    [string]$Architecture = "x64"
)

$ErrorActionPreference = "Stop"

# This script DOWNLOADS installers only. It never installs or executes them.
# WinGet verifies each installer against the SHA-256 declared by its package manifest.

$packages = @(
    [pscustomobject]@{ Id = "BlenderFoundation.Blender"; Name = "Blender"; License = "GPL-3.0-or-later"; Category = "3D authoring" },
    [pscustomobject]@{ Id = "KDE.Krita"; Name = "Krita"; License = "GPL-3.0-or-later"; Category = "2D painting" },
    [pscustomobject]@{ Id = "GIMP.GIMP"; Name = "GIMP"; License = "GPL-3.0-or-later"; Category = "Image editing" },
    [pscustomobject]@{ Id = "Inkscape.Inkscape"; Name = "Inkscape"; License = "GPL-2.0-or-later"; Category = "Vector graphics" },
    [pscustomobject]@{ Id = "Audacity.Audacity"; Name = "Audacity"; License = "GPL-3.0-or-later"; Category = "Audio editing" },
    [pscustomobject]@{ Id = "LMMS.LMMS"; Name = "LMMS"; License = "GPL-2.0-or-later"; Category = "Music production" },
    [pscustomobject]@{ Id = "Tiled.Tiled"; Name = "Tiled"; License = "GPL-2.0-or-later"; Category = "Level design" }
)

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "WinGet is not available. Use Windows 11 or Windows Server 2025 with App Installer / WinGet."
}

New-Item -ItemType Directory -Path $DownloadDirectory -Force | Out-Null
$DownloadDirectory = (Resolve-Path $DownloadDirectory).Path
$results = [System.Collections.Generic.List[object]]::new()

foreach ($package in $packages) {
    $target = Join-Path $DownloadDirectory $package.Id
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    Write-Host ""
    Write-Host "=== Downloading $($package.Name) ($($package.Id)) ===" -ForegroundColor Cyan

    $output = & winget download --id $package.Id --exact --source winget --architecture $Architecture --platform Windows.Desktop --download-directory $target --accept-source-agreements 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }

    $files = @(
        Get-ChildItem -LiteralPath $target -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName
    )

    if ($exitCode -eq 0 -and $files.Count -gt 0) {
        $fileRecords = @(
            foreach ($file in $files) {
                $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
                [pscustomobject]@{
                    file = $file.FullName.Substring($DownloadDirectory.Length).TrimStart('\')
                    size_bytes = $file.Length
                    sha256 = $hash.Hash.ToLowerInvariant()
                }
            }
        )

        $results.Add([pscustomobject]@{
            id = $package.Id
            name = $package.Name
            category = $package.Category
            declared_license = $package.License
            status = "downloaded"
            files = $fileRecords
            error = $null
        })
    }
    else {
        $results.Add([pscustomobject]@{
            id = $package.Id
            name = $package.Name
            category = $package.Category
            declared_license = $package.License
            status = "failed_or_unavailable"
            files = @()
            error = "WinGet exit code: $exitCode. See the workflow log for details."
        })
    }
}

$report = [pscustomobject]@{
    schema_version = "1.0.0"
    project = "Police Simulator 3D"
    created_utc = (Get-Date).ToUniversalTime().ToString("o")
    platform = "Windows.Desktop"
    architecture = $Architecture
    note = "Downloaded installers only; no software was installed. Review each publisher EULA and license before use or redistribution."
    packages = @($results)
}

$reportPath = Join-Path $DownloadDirectory "download-report.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8

$successCount = @($results | Where-Object { $_.status -eq "downloaded" }).Count
$failureCount = $results.Count - $successCount

Write-Host ""
Write-Host "Download summary: $successCount succeeded, $failureCount failed."
Write-Host "Files: $DownloadDirectory"
Write-Host "Report: $reportPath"

if ($successCount -eq 0) {
    throw "No installers were downloaded. Check WinGet availability, network access, and package availability."
}
