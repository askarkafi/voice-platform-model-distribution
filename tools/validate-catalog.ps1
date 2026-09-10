param(
    [string]$CatalogPath = (Join-Path $PSScriptRoot "..\catalog\models.json"),
    [string]$SchemaPath = (Join-Path $PSScriptRoot "..\catalog\schema\models.schema.json")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CatalogPath)) {
    throw "Catalog file not found: $CatalogPath"
}

if (-not (Test-Path $SchemaPath)) {
    throw "Schema file not found: $SchemaPath"
}

try {
    $catalog = Get-Content -Raw -Path $CatalogPath | ConvertFrom-Json
    $schema = Get-Content -Raw -Path $SchemaPath | ConvertFrom-Json
}
catch {
    throw "Catalog or schema is not valid JSON: $($_.Exception.Message)"
}

if ($catalog.schemaVersion -ne 1) {
    throw "Unsupported catalog schemaVersion: $($catalog.schemaVersion)"
}

if ($null -eq $catalog.models) {
    throw "Catalog must contain a 'models' array."
}

Write-Host "Catalog JSON: OK"
Write-Host "Schema JSON: OK"
Write-Host "schemaVersion: $($catalog.schemaVersion)"
Write-Host "Model count: $($catalog.models.Count)"
Write-Host ""
Write-Host "Note: this lightweight validator currently checks JSON syntax and catalog basics; full JSON Schema validation will be added only if needed."
