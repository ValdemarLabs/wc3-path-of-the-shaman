[CmdletBinding()]
param(
    [string]$ManifestPath = '',
    [string]$InnoSetupCompilerPath = '',
    [switch]$GenerateOnly,
    [switch]$SkipPayloadValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
} else {
    Split-Path -Parent $PSCommandPath
}

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $ScriptRoot 'release-manifest.json'
}

function Resolve-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path $ScriptRoot $Path
}

function Test-ManifestSectionEnabled {
    param($Section)

    if ($null -eq $Section) {
        return $false
    }

    $enabledProperty = $Section.PSObject.Properties['enabled']
    if ($null -eq $enabledProperty) {
        return $true
    }

    return [bool]$enabledProperty.Value
}

function Require-Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        throw "Missing required value: $Name"
    }
}

function ConvertTo-InnoFileVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $numbers = [regex]::Matches($Version, '\d+') | ForEach-Object { $_.Value }
    $parts = New-Object System.Collections.Generic.List[string]

    foreach ($number in $numbers) {
        if ($parts.Count -ge 4) {
            break
        }

        $parts.Add($number)
    }

    while ($parts.Count -lt 4) {
        $parts.Add('0')
    }

    return ($parts -join '.')
}

function ConvertTo-InnoStringLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return '"' + ($Value -replace '"', '""') + '"'
}

function ConvertTo-InnoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return ($Value -replace '/', '\')
}

function Test-DirectoryHasPayloadFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }

    $payloadFile = Get-ChildItem -LiteralPath $Path -File -Recurse -Force |
        Where-Object { $_.Name -ne '.gitkeep' } |
        Select-Object -First 1

    return $null -ne $payloadFile
}

function Get-ZipW3xFileName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $w3xEntries = @(
            $zip.Entries |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_.Name) -and
                    $_.Name.EndsWith('.w3x', [System.StringComparison]::OrdinalIgnoreCase)
                } |
                ForEach-Object { $_.Name }
        )
    } finally {
        $zip.Dispose()
    }

    if ($w3xEntries.Count -eq 0) {
        throw "Map archive does not contain a .w3x file: $Path"
    }

    if ($w3xEntries.Count -gt 1) {
        throw "Map archive contains multiple .w3x files. Keep exactly one map file in: $Path"
    }

    return $w3xEntries[0]
}

function Get-ManifestStringArray {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        throw "Missing required value: $Name"
    }

    $items = @($Value)
    if ($items.Count -eq 0) {
        throw "Missing required value: $Name"
    }

    foreach ($item in $items) {
        if ($null -eq $item -or [string]::IsNullOrWhiteSpace([string]$item)) {
            throw "Empty value in: $Name"
        }
    }

    return $items | ForEach-Object { [string]$_ }
}

function Find-InnoSetupCompiler {
    param([string]$ExplicitPath)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        if (Test-Path -LiteralPath $ExplicitPath -PathType Leaf) {
            return $ExplicitPath
        }

        throw "Inno Setup compiler was not found at: $ExplicitPath"
    }

    $command = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $candidates.Add((Join-Path $programFilesX86 'Inno Setup 6\ISCC.exe'))
        $candidates.Add((Join-Path $programFilesX86 'Inno Setup 7\ISCC.exe'))
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidates.Add((Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'))
        $candidates.Add((Join-Path $env:ProgramFiles 'Inno Setup 7\ISCC.exe'))
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw 'Inno Setup compiler was not found. Install Inno Setup 6.7+ or Inno Setup 7, or pass -InnoSetupCompilerPath.'
}

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Manifest not found: $ManifestPath"
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

Require-Text -Name 'installerVersion' -Value $manifest.installerVersion

$includeMap = Test-ManifestSectionEnabled -Section $manifest.map
$includeLocalFiles = Test-ManifestSectionEnabled -Section $manifest.localFiles
$includeRebirthMod = Test-ManifestSectionEnabled -Section $manifest.rebirthMod

if (-not ($includeMap -or $includeLocalFiles -or $includeRebirthMod)) {
    throw 'At least one installer section must be enabled.'
}

if ($includeMap) {
    Require-Text -Name 'map.version' -Value $manifest.map.version
    Require-Text -Name 'map.source' -Value $manifest.map.source

    $mapSourcePath = Resolve-RelativePath -Path $manifest.map.source
    if (-not $SkipPayloadValidation) {
        if (-not (Test-Path -LiteralPath $mapSourcePath -PathType Leaf)) {
            throw "Map payload archive not found: $mapSourcePath"
        }

        if (-not $mapSourcePath.EndsWith('.zip', [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Map payload must be a .zip archive: $mapSourcePath"
        }
    }
}

if ($includeLocalFiles) {
    Require-Text -Name 'localFiles.version' -Value $manifest.localFiles.version
    Require-Text -Name 'localFiles.source' -Value $manifest.localFiles.source

    $localFilesSourcePath = Resolve-RelativePath -Path $manifest.localFiles.source
    if (-not $SkipPayloadValidation -and -not (Test-DirectoryHasPayloadFiles -Path $localFilesSourcePath)) {
        throw "Local files payload folder is missing or empty: $localFilesSourcePath"
    }
}

if ($includeRebirthMod) {
    Require-Text -Name 'rebirthMod.version' -Value $manifest.rebirthMod.version
    $rebirthArchiveList = @(Get-ManifestStringArray -Name 'rebirthMod.archives' -Value $manifest.rebirthMod.archives)

    if ($rebirthArchiveList.Count -gt 4) {
        throw 'The installer currently supports up to 4 Rebirth mod archives.'
    }

    foreach ($rebirthArchive in $rebirthArchiveList) {
        $rebirthArchivePath = Resolve-RelativePath -Path $rebirthArchive
        if (-not $SkipPayloadValidation -and -not (Test-Path -LiteralPath $rebirthArchivePath -PathType Leaf)) {
            throw "Rebirth mod archive not found: $rebirthArchivePath"
        }
    }
}

$generatedIncludePath = Join-Path $ScriptRoot 'release-version.generated.iss'
$installerFileVersion = ConvertTo-InnoFileVersion -Version $manifest.installerVersion

$mapVersion = if ($includeMap) { [string]$manifest.map.version } else { 'Not included' }
$mapArchiveSource = if ($includeMap) { ConvertTo-InnoRelativePath -Value ([string]$manifest.map.source) } else { 'payload\map\not-included.zip' }
$mapArchiveFileName = if ($includeMap) { [System.IO.Path]::GetFileName([string]$manifest.map.source) } else { 'not-included.zip' }
$mapInstalledFileName = if ($includeMap -and -not $SkipPayloadValidation) {
    Get-ZipW3xFileName -Path (Resolve-RelativePath -Path $manifest.map.source)
} elseif ($includeMap) {
    [System.IO.Path]::GetFileNameWithoutExtension([string]$manifest.map.source) + '.w3x'
} else {
    'Path of the Shaman.w3x'
}

$localFilesVersion = if ($includeLocalFiles) { [string]$manifest.localFiles.version } else { 'Not included' }
$localFilesSource = if ($includeLocalFiles) { ConvertTo-InnoRelativePath -Value ([string]$manifest.localFiles.source) } else { 'payload\local-files' }

$rebirthModVersion = if ($includeRebirthMod) { [string]$manifest.rebirthMod.version } else { 'Not included' }
$rebirthArchiveList = if ($includeRebirthMod) {
    @(Get-ManifestStringArray -Name 'rebirthMod.archives' -Value $manifest.rebirthMod.archives)
} else {
    @()
}

$includeLines = New-Object System.Collections.Generic.List[string]
$includeLines.Add('#define InstallerVersion ' + (ConvertTo-InnoStringLiteral -Value ([string]$manifest.installerVersion)))
$includeLines.Add('#define InstallerFileVersion ' + (ConvertTo-InnoStringLiteral -Value $installerFileVersion))
$includeLines.Add('#define IncludeMap ' + $(if ($includeMap) { '1' } else { '0' }))
$includeLines.Add('#define MapVersion ' + (ConvertTo-InnoStringLiteral -Value $mapVersion))
$includeLines.Add('#define MapArchiveSource ' + (ConvertTo-InnoStringLiteral -Value $mapArchiveSource))
$includeLines.Add('#define MapArchiveFileName ' + (ConvertTo-InnoStringLiteral -Value $mapArchiveFileName))
$includeLines.Add('#define MapInstalledFileName ' + (ConvertTo-InnoStringLiteral -Value $mapInstalledFileName))
$includeLines.Add('#define IncludeLocalFiles ' + $(if ($includeLocalFiles) { '1' } else { '0' }))
$includeLines.Add('#define LocalFilesVersion ' + (ConvertTo-InnoStringLiteral -Value $localFilesVersion))
$includeLines.Add('#define LocalFilesSource ' + (ConvertTo-InnoStringLiteral -Value $localFilesSource))
$includeLines.Add('#define IncludeRebirthMod ' + $(if ($includeRebirthMod) { '1' } else { '0' }))
$includeLines.Add('#define RebirthModVersion ' + (ConvertTo-InnoStringLiteral -Value $rebirthModVersion))
for ($i = 0; $i -lt 4; $i++) {
    $archiveNumber = $i + 1
    if ($i -lt $rebirthArchiveList.Count) {
        $archiveSource = ConvertTo-InnoRelativePath -Value $rebirthArchiveList[$i]
        $archiveFileName = [System.IO.Path]::GetFileName($rebirthArchiveList[$i])
        $includeLines.Add("#define IncludeRebirthArchive$archiveNumber 1")
        $includeLines.Add("#define RebirthArchive$archiveNumber" + 'Source ' + (ConvertTo-InnoStringLiteral -Value $archiveSource))
        $includeLines.Add("#define RebirthArchive$archiveNumber" + 'FileName ' + (ConvertTo-InnoStringLiteral -Value $archiveFileName))
    } else {
        $includeLines.Add("#define IncludeRebirthArchive$archiveNumber 0")
        $includeLines.Add("#define RebirthArchive$archiveNumber" + 'Source "not-included.rar"')
        $includeLines.Add("#define RebirthArchive$archiveNumber" + 'FileName "not-included.rar"')
    }
}

Set-Content -LiteralPath $generatedIncludePath -Value $includeLines -Encoding ASCII
Write-Host "Generated $generatedIncludePath"

if ($GenerateOnly) {
    return
}

$compilerPath = Find-InnoSetupCompiler -ExplicitPath $InnoSetupCompilerPath
$scriptPath = Join-Path $ScriptRoot 'PathOfTheShaman.iss'

Write-Host "Building installer with $compilerPath"
& $compilerPath $scriptPath

if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compiler failed with exit code $LASTEXITCODE"
}
