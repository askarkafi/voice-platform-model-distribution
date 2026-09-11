param(
    [string]$Tag = "models-v0.2.0",
    [string]$TargetRemoteHost = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $PSCommandPath
$DistributionRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$ReleasesDir = Join-Path $DistributionRoot "releases\$Tag"

if (-not (Test-Path -LiteralPath $ReleasesDir)) {
    $ReleasesDir = Join-Path $DistributionRoot "packages\tts\fa"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Voice Platform -- Model Distribution Release Publisher" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Source directory: $ReleasesDir"
Write-Host "Release Tag:      $Tag"
Write-Host ""

$packages = Get-ChildItem -Path $ReleasesDir -Filter "*.zip"
$count = $packages.Count
Write-Host "Packages ready for upload ($count files):" -ForegroundColor Green

foreach ($p in $packages) {
    $sha = (Get-FileHash -LiteralPath $p.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $mb = [math]::Round($p.Length / 1MB, 2)
    $name = $p.Name
    Write-Host "  * $name ($mb MB)" -ForegroundColor White
    Write-Host "    SHA-256: $sha" -ForegroundColor Gray
}

Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Option 1: Publish to GitHub Releases (via gh CLI)" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"
$fileListStr = ($packages | ForEach-Object { "`"$($_.FullName)`"" }) -join " "
Write-Host "To create release and upload all assets:" -ForegroundColor White
Write-Host "gh release create $Tag $fileListStr --repo askarkafi/voice-platform-model-distribution --title `"Voice Models $Tag`" --notes `"Release of real Persian Piper VITS TTS models: Amir, Reza Ibrahim, Gyro, and Ganji Adabi.`"" -ForegroundColor Green
Write-Host ""
Write-Host "Or if release $Tag already exists:" -ForegroundColor White
Write-Host "gh release upload $Tag $fileListStr --repo askarkafi/voice-platform-model-distribution --clobber" -ForegroundColor Green
Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Option 2: Upload to Custom Static Server / CDN" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"
Write-Host "SCP / Rsync:" -ForegroundColor White
Write-Host "scp `"$ReleasesDir\*.zip`" user@your-server:/var/www/voice-platform/releases/$Tag/" -ForegroundColor Green
Write-Host ""
Write-Host "----------------------------------------------------------" -ForegroundColor Yellow
Write-Host "Option 3: Run Local Test HTTP Server" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------"
Write-Host "python -m http.server 8080 --directory `"$DistributionRoot`"" -ForegroundColor Green
Write-Host ""
