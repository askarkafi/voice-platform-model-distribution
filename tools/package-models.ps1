<#
.SYNOPSIS
Packages Piper VITS Persian TTS models from KafiCar assets into standard Voice Platform model packages.

.DESCRIPTION
Each Piper VITS package contains:
  - Exactly one model file (<model_name>.onnx)
  - The shared tokens.txt file
  - The espeak-ng-data directory

Output packages are written to:
  - voice-platform-model-distribution/packages/tts/fa/
  - voice-platform-model-distribution/releases/models-v0.2.0/
  - Voice Platform/reference-app/src/main/assets/models/
#>
param(
    [string]$SourceDir = "D:\Projects\KafiCar\app\src\main\assets\vits-piper-fa_IR-ganji-medium",
    [string]$DistributionRoot = "D:\Projects\voice-platform-model-distribution",
    [string]$ReferenceAppModelsDir = "D:\Projects\Voice Platform\reference-app\src\main\assets\models"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceDir)) {
    throw "Source directory does not exist: $SourceDir"
}

$tokensPath = Join-Path $SourceDir "tokens.txt"
$espeakPath = Join-Path $SourceDir "espeak-ng-data"

if (-not (Test-Path -LiteralPath $tokensPath)) {
    throw "tokens.txt missing in $SourceDir"
}
if (-not (Test-Path -LiteralPath $espeakPath)) {
    throw "espeak-ng-data missing in $SourceDir"
}

$distPackagesDir = Join-Path $DistributionRoot "packages\tts\fa"
$distReleasesDir = Join-Path $DistributionRoot "releases\models-v0.2.0"

New-Item -ItemType Directory -Force -Path $distPackagesDir | Out-Null
New-Item -ItemType Directory -Force -Path $distReleasesDir | Out-Null
if ($ReferenceAppModelsDir) {
    New-Item -ItemType Directory -Force -Path $ReferenceAppModelsDir | Out-Null
}

$tempBase = Join-Path ([System.IO.Path]::GetTempPath()) "vp-model-staging-$([System.Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Force -Path $tempBase | Out-Null

$modelsToPackage = @(
    @{ Id = "fa_IR-amir-medium"; OnnxName = "fa_IR-amir-medium.onnx"; DisplayName = "Amir" },
    @{ Id = "fa_IR-reza_ibrahim-medium"; OnnxName = "fa_IR-reza_ibrahim-medium.onnx"; DisplayName = "Reza Ibrahim" },
    @{ Id = "fa_IR-gyro-medium"; OnnxName = "fa_IR-gyro-medium.onnx"; DisplayName = "Gyro" },
    @{ Id = "fa_IR-ganji_adabi-medium"; OnnxName = "fa_IR-ganji_adabi-medium.onnx"; DisplayName = "Ganji Adabi" }
)

$results = @()

try {
    foreach ($m in $modelsToPackage) {
        $id = $m.Id
        $onnxPath = Join-Path $SourceDir $m.OnnxName
        if (-not (Test-Path -LiteralPath $onnxPath)) {
            Write-Warning "Skipping $($id): ONNX file not found at $onnxPath"
            continue
        }

        Write-Host "Packaging $($m.DisplayName) ($id)..." -ForegroundColor Cyan
        $stageDir = Join-Path $tempBase $id
        New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

        # Copy files
        Copy-Item -LiteralPath $onnxPath -Destination (Join-Path $stageDir $m.OnnxName)
        Copy-Item -LiteralPath $tokensPath -Destination (Join-Path $stageDir "tokens.txt")
        Copy-Item -LiteralPath $espeakPath -Destination (Join-Path $stageDir "espeak-ng-data") -Recurse

        # Create zip in temp
        $tempZip = Join-Path $tempBase "$id.zip"
        if (Test-Path -LiteralPath $tempZip) { Remove-Item -LiteralPath $tempZip -Force }

        # Use .NET System.IO.Compression for deterministic fast zip
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($stageDir, $tempZip, [System.IO.Compression.CompressionLevel]::Optimal, $false)

        $fileInfo = Get-Item -LiteralPath $tempZip
        $sizeBytes = $fileInfo.Length
        $sha256 = (Get-FileHash -LiteralPath $tempZip -Algorithm SHA256).Hash.ToLowerInvariant()

        # Copy to targets
        $targetInPackages = Join-Path $distPackagesDir "$id.zip"
        $targetInReleases = Join-Path $distReleasesDir "$id.zip"
        Copy-Item -LiteralPath $tempZip -Destination $targetInPackages -Force
        Copy-Item -LiteralPath $tempZip -Destination $targetInReleases -Force

        if ($ReferenceAppModelsDir -and (Test-Path -LiteralPath $ReferenceAppModelsDir)) {
            $targetInRefApp = Join-Path $ReferenceAppModelsDir "$id.zip"
            Copy-Item -LiteralPath $tempZip -Destination $targetInRefApp -Force
        }

        $results += [PSCustomObject]@{
            Id = $id
            DisplayName = $m.DisplayName
            SizeBytes = $sizeBytes
            Sha256 = $sha256
            PackagePath = "packages/tts/fa/$id.zip"
            ReleasePath = "releases/models-v0.2.0/$id.zip"
        }

        # Cleanup stage dir to save space
        Remove-Item -LiteralPath $stageDir -Recurse -Force
        Remove-Item -LiteralPath $tempZip -Force
    }
}
finally {
    if (Test-Path -LiteralPath $tempBase) {
        Remove-Item -LiteralPath $tempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=== Packaging Complete ===" -ForegroundColor Green
$results | Format-Table Id, DisplayName, SizeBytes, Sha256 -AutoSize

$results | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $DistributionRoot "tools\packaged-models-metadata.json") -Encoding utf8
Write-Host "Metadata written to tools\packaged-models-metadata.json" -ForegroundColor Green
