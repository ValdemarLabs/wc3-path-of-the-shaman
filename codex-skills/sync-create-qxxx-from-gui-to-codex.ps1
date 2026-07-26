$source = "H:\Pelit\PotS_JASS\codex-skills\create-qxxx-from-gui"
$target = "C:\Users\Valtteri\.codex\skills\create-qxxx-from-gui"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Workspace skill copy not found: $source"
}

if (-not (Test-Path -LiteralPath $target)) {
    New-Item -ItemType Directory -Force -Path $target | Out-Null
}

Copy-Item -Recurse -Force -Path (Join-Path $source "*") -Destination $target
Write-Host "Synced workspace copy:"
Write-Host "  Source: $source"
Write-Host "  Target: $target"
