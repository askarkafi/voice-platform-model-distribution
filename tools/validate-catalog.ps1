<#
.SYNOPSIS
Validates the Voice Platform model catalog (v0.1) metadata and (optionally) local artifact availability.

.DESCRIPTION
Separates catalog metadata validity (errors) from artifact availability (warnings), because the
distribution tree is designed for remote deployment and local file presence is not mandatory.

.PARAMETER CatalogPath
Path to models.json (default: ..\catalog\models.json relative to this script).

.PARAMETER DistributionRoot
Root of the model-distribution tree used to resolve relative artifact/preview paths (default: parent
of the catalog directory).

.PARAMETER TreatWarningsAsErrors
Fail (exit 1) when availability warnings are present.
#>
[CmdletBinding()]
param(
    [string]$CatalogPath,
    [string]$DistributionRoot,
    [switch]$TreatWarningsAsErrors
)

$ErrorActionPreference = "Stop"

# Resolve defaults from the script location ($PSCommandPath is reliable in -File invocation).
if (-not $CatalogPath) {
    $CatalogPath = Join-Path (Split-Path -Parent $PSCommandPath) "..\catalog\models.json"
}
if (-not $DistributionRoot) {
    $DistributionRoot = Join-Path (Split-Path -Parent $PSCommandPath) ".."
}

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Write-Fail($msg) { $errors.Add($msg) }
function Write-Warn($msg) { $warnings.Add($msg) }

# --- Load and parse catalog ---
if (-not (Test-Path -LiteralPath $CatalogPath)) {
    Write-Fail "Catalog not found: $CatalogPath"
} else {
    try {
        $json = Get-Content -LiteralPath $CatalogPath -Raw
        $catalog = $json | ConvertFrom-Json
    } catch {
        Write-Fail "Invalid JSON in catalog: $($_.Exception.Message)"
        $catalog = $null
    }
}

if ($catalog) {
    # --- Top-level ---
    if ($catalog.schemaVersion -ne 1) {
        Write-Fail "Unsupported schemaVersion: '$($catalog.schemaVersion)'. Expected 1 (v0.1)."
    }
    if ($null -eq $catalog.models -or -not ($catalog.models -is [System.Array])) {
        Write-Fail "'models' must be an array."
    } else {
        $seen = @{}
        foreach ($entry in $catalog.models) {
            $id = $entry.id
            $version = $entry.version
            $type = $entry.type
            $language = $entry.language
            $publishable = $entry.publishable

            # Required fields
            foreach ($f in @('id', 'version', 'type', 'language')) {
                $v = $entry.$f
                if ($null -eq $v -or "$v".Trim() -eq '') {
                    Write-Fail "Entry is missing required field '$f'."
                }
            }
            if ($type -and ($type -ne 'stt' -and $type -ne 'tts')) {
                Write-Fail "Entry '$id' has invalid type '$type'. Expected 'stt' or 'tts'."
            }
            if ($language -and "$language".Trim() -eq '') {
                Write-Fail "Entry '$id' has an empty language."
            }

            # Uniqueness: (type, language, id, version)
            if ($id -and $type -and $language) {
                $key = "$type|$language|$id|$version"
                if ($seen.ContainsKey($key)) {
                    Write-Fail "Duplicate entry identity: $key"
                } else {
                    $seen[$key] = $true
                }
            }

            # Publishable requirements
            if ($publishable) {
                if (-not $entry.sha256 -or $entry.sha256 -notmatch '^[0-9a-fA-F]{64}$') {
                    Write-Fail "Publishable entry '$id' must have a real 64-hex sha256."
                }
                if (-not $entry.sizeBytes -or $entry.sizeBytes -le 0) {
                    Write-Fail "Publishable entry '$id' must have a positive sizeBytes."
                }
                if (-not $entry.artifact -or -not $entry.artifact.path) {
                    Write-Fail "Publishable entry '$id' must declare artifact.path."
                }
            }

            # Field-shape checks
            if ($entry.sha256 -and $entry.sha256 -notmatch '^[0-9a-fA-F]{64}$') {
                Write-Fail "Entry '$id' sha256 must be 64 hex characters."
            }
            if ($null -ne $entry.sizeBytes -and ($entry.sizeBytes -isnot [int] -or $entry.sizeBytes -lt 0)) {
                Write-Fail "Entry '$id' sizeBytes must be a non-negative integer."
            }
            if ($entry.preview) {
                $src = $entry.preview.source
                if ($src -and $src -ne 'bundled' -and $src -ne 'remote') {
                    Write-Fail "Entry '$id' preview.source must be 'bundled' or 'remote'."
                }
            }
            if ($entry.distribution -and $null -eq $entry.distribution.allowedAppIds) {
                Write-Fail "Entry '$id' distribution object must contain allowedAppIds."
            } elseif ($entry.distribution -and $entry.distribution.allowedAppIds) {
                if (-not ($entry.distribution.allowedAppIds -is [System.Array])) {
                    Write-Fail "Entry '$id' distribution.allowedAppIds must be an array."
                } else {
                    foreach ($appId in $entry.distribution.allowedAppIds) {
                        if ("$appId".Trim() -eq '') {
                            Write-Fail "Entry '$id' distribution.allowedAppIds contains an empty app id."
                        }
                    }
                }
            }

            # Availability (warnings / local checksum verification)
            if ($publishable -and $entry.artifact -and $entry.artifact.path) {
                $abs = Join-Path $DistributionRoot ($entry.artifact.path -replace '/', '\')
                if (Test-Path -LiteralPath $abs) {
                    $actual = (Get-FileHash -LiteralPath $abs -Algorithm SHA256).Hash.ToLowerInvariant()
                    $expected = "$($entry.sha256)".ToLowerInvariant()
                    if ($actual -ne $expected) {
                        Write-Fail "Checksum mismatch for locally present artifact '$abs'."
                    } else {
                        Write-Warn "Verified locally present artifact: $($entry.artifact.path)"
                    }
                } else {
                    Write-Warn "Publishable artifact not present locally (remote deployment OK): $($entry.artifact.path)"
                }
            }
            if ($entry.preview -and $entry.preview.source -eq 'remote' -and $entry.preview.path) {
                $abs = Join-Path $DistributionRoot ($entry.preview.path -replace '/', '\')
                if (-not (Test-Path -LiteralPath $abs)) {
                    Write-Warn "Remote preview not present locally (remote deployment OK): $($entry.preview.path)"
                }
            }
        }
    }
}

# --- Report ---
Write-Host "=== Model Catalog Validation ==="
Write-Host ("Catalog: " + (Resolve-Path -LiteralPath $CatalogPath))
if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings ($($warnings.Count)):"
    $warnings | ForEach-Object { Write-Host "  - $_" }
}
if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "ERRORS ($($errors.Count)):"
    $errors | ForEach-Object { Write-Host "  - $_" }
}
$fail = $errors.Count -gt 0 -or ($TreatWarningsAsErrors -and $warnings.Count -gt 0)
Write-Host ""
if ($fail) {
    Write-Host "RESULT: FAIL ($($errors.Count) errors, $($warnings.Count) warnings)"
    exit 1
} else {
    Write-Host "RESULT: OK ($($warnings.Count) warnings)"
    exit 0
}
