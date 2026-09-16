param(
    [Parameter(Mandatory = $true)]
    [string] $SourceMap,

    [Parameter(Mandatory = $true)]
    [string] $BrokenDirectory,

    [Parameter(Mandatory = $true)]
    [string] $FixedDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Targets = [ordered]@{
    'war3campImported\AltarOfStorms.mdx' = @(9)
    'md_cryptsimpleent1.mdx' = @(9)
    'md_cryptsimpleent2.mdx' = @(9)
    'md_cryptsimpleent3.mdx' = @(9)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend2.wmo.mdx' = @(18, 19)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend3.wmo.mdx' = @(24, 25, 26)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a.wmo.mdx' = @(27, 28, 40)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a1.wmo.mdx' = @(27, 28, 40)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend4a2.wmo.mdx' = @(0, 1, 2, 3, 4, 5, 15, 16, 28)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend4b.wmo.mdx' = @(27, 28, 40)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend4d.wmo.mdx' = @(14)
    'world_wmo_dungeon_md_crypt_md_crypt_f_northrend4f.wmo.mdx' = @(18, 19, 21, 22)
}

function Assert-Condition {
    param(
        [bool] $Condition,
        [string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Read-UInt32 {
    param([byte[]] $Bytes, [int] $Offset)
    return [BitConverter]::ToUInt32($Bytes, $Offset)
}

function Read-Int32 {
    param([byte[]] $Bytes, [int] $Offset)
    return [BitConverter]::ToInt32($Bytes, $Offset)
}

function Write-Int32 {
    param([byte[]] $Bytes, [int] $Offset, [int] $Value)
    [Array]::Copy([BitConverter]::GetBytes($Value), 0, $Bytes, $Offset, 4)
}

function Write-UInt32 {
    param([byte[]] $Bytes, [int] $Offset, [uint32] $Value)
    [Array]::Copy([BitConverter]::GetBytes($Value), 0, $Bytes, $Offset, 4)
}

function Get-Sha256 {
    param([byte[]] $Bytes)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
    }
}

function Test-TagAt {
    param(
        [byte[]] $Bytes,
        [int] $Offset,
        [byte[]] $Tag
    )

    if ($Offset + 4 -gt $Bytes.Length) {
        return $false
    }

    return $Bytes[$Offset] -eq $Tag[0] -and
        $Bytes[$Offset + 1] -eq $Tag[1] -and
        $Bytes[$Offset + 2] -eq $Tag[2] -and
        $Bytes[$Offset + 3] -eq $Tag[3]
}

function Get-MdxChunks {
    param(
        [byte[]] $Bytes,
        [string] $Context
    )

    Assert-Condition ($Bytes.Length -ge 12) "$Context is too small to be an MDX file."
    Assert-Condition ([Text.Encoding]::ASCII.GetString($Bytes, 0, 4) -eq 'MDLX') "$Context has no MDLX header."

    $chunks = [Collections.Generic.List[object]]::new()
    $position = 4

    while ($position -lt $Bytes.Length) {
        Assert-Condition ($position + 8 -le $Bytes.Length) "$Context has a truncated top-level chunk header at byte $position."
        $tag = [Text.Encoding]::ASCII.GetString($Bytes, $position, 4)
        $size = [int64](Read-UInt32 $Bytes ($position + 4))
        $end = [int64]$position + 8 + $size
        Assert-Condition ($end -le $Bytes.Length) "$Context has an out-of-bounds $tag chunk at byte $position."

        $chunks.Add([pscustomobject]@{
            Tag = $tag
            HeaderOffset = $position
            DataOffset = $position + 8
            Size = [int]$size
            EndOffset = [int]$end
        })
        $position = [int]$end
    }

    Assert-Condition ($position -eq $Bytes.Length) "$Context has unparsed trailing bytes."
    return $chunks.ToArray()
}

function Get-SingleChunk {
    param(
        [object[]] $Chunks,
        [string] $Tag,
        [string] $Context,
        [bool] $Required = $true
    )

    $matches = @($Chunks | Where-Object { $_.Tag -ceq $Tag })
    Assert-Condition ($matches.Count -le 1) "$Context contains more than one $Tag chunk."
    if ($Required) {
        Assert-Condition ($matches.Count -eq 1) "$Context has no $Tag chunk."
    }
    if ($matches.Count -eq 0) {
        return $null
    }
    return $matches[0]
}

function Get-Geosets {
    param(
        [byte[]] $Bytes,
        [object] $Chunk,
        [string] $Context
    )

    $vertexTag = [Text.Encoding]::ASCII.GetBytes('VRTX')
    $faceTag = [Text.Encoding]::ASCII.GetBytes('PVTX')
    $records = [Collections.Generic.List[object]]::new()
    $position = $Chunk.DataOffset
    $index = 0

    while ($position -lt $Chunk.EndOffset) {
        Assert-Condition ($position + 4 -le $Chunk.EndOffset) "$Context has a truncated geoset size at byte $position."
        $size = [int64](Read-UInt32 $Bytes $position)
        Assert-Condition ($size -ge 4) "$Context has an invalid geoset size at byte $position."
        $end = [int64]$position + $size
        Assert-Condition ($end -le $Chunk.EndOffset) "$Context has an out-of-bounds geoset $index."

        $vertexCount = $null
        $faceIndexCount = $null
        for ($cursor = $position + 4; $cursor -le $end - 8; $cursor++) {
            if ($null -eq $vertexCount -and (Test-TagAt $Bytes $cursor $vertexTag)) {
                $vertexCount = [int](Read-UInt32 $Bytes ($cursor + 4))
            }
            elseif ($null -eq $faceIndexCount -and (Test-TagAt $Bytes $cursor $faceTag)) {
                $faceIndexCount = [int](Read-UInt32 $Bytes ($cursor + 4))
            }
            if ($null -ne $vertexCount -and $null -ne $faceIndexCount) {
                break
            }
        }

        Assert-Condition ($null -ne $vertexCount) "$Context geoset $index has no VRTX field."
        Assert-Condition ($null -ne $faceIndexCount) "$Context geoset $index has no PVTX field."
        $records.Add([pscustomobject]@{
            Index = $index
            Offset = $position
            Size = [int]$size
            VertexCount = $vertexCount
            FaceIndexCount = $faceIndexCount
        })
        $position = [int]$end
        $index++
    }

    Assert-Condition ($position -eq $Chunk.EndOffset) "$Context GEOS chunk did not end on a geoset boundary."
    return $records.ToArray()
}

function Get-VariableRecords {
    param(
        [byte[]] $Bytes,
        [object] $Chunk,
        [string] $Context
    )

    $records = [Collections.Generic.List[object]]::new()
    $position = $Chunk.DataOffset
    $index = 0
    while ($position -lt $Chunk.EndOffset) {
        Assert-Condition ($position + 4 -le $Chunk.EndOffset) "$Context has a truncated $($Chunk.Tag) record size."
        $size = [int64](Read-UInt32 $Bytes $position)
        Assert-Condition ($size -ge 4) "$Context has an invalid $($Chunk.Tag) record size at byte $position."
        $end = [int64]$position + $size
        Assert-Condition ($end -le $Chunk.EndOffset) "$Context has an out-of-bounds $($Chunk.Tag) record $index."
        $records.Add([pscustomobject]@{ Index = $index; Offset = $position; Size = [int]$size })
        $position = [int]$end
        $index++
    }
    Assert-Condition ($position -eq $Chunk.EndOffset) "$Context $($Chunk.Tag) chunk did not end on a record boundary."
    return $records.ToArray()
}

function Convert-ReferencedIndex {
    param(
        [int] $OldIndex,
        [int[]] $RemovedIndices,
        [string] $Context
    )

    if ($OldIndex -eq -1) {
        return -1
    }
    Assert-Condition ($OldIndex -ge 0) "$Context contains unsupported negative index $OldIndex."
    Assert-Condition (-not ($RemovedIndices -contains $OldIndex)) "$Context directly references a record selected for removal at index $OldIndex."
    return $OldIndex - @($RemovedIndices | Where-Object { $_ -lt $OldIndex }).Count
}

function New-FilteredGeosPayload {
    param(
        [byte[]] $Bytes,
        [object[]] $Geosets,
        [int[]] $RemovedIndices
    )

    $stream = [IO.MemoryStream]::new()
    try {
        foreach ($geoset in $Geosets) {
            if (-not ($RemovedIndices -contains $geoset.Index)) {
                $stream.Write($Bytes, $geoset.Offset, $geoset.Size)
            }
        }
        return $stream.ToArray()
    }
    finally {
        $stream.Dispose()
    }
}

function New-FilteredGeoaPayload {
    param(
        [byte[]] $Bytes,
        [object] $Chunk,
        [int[]] $RemovedGeosets,
        [string] $Context
    )

    if ($null -eq $Chunk) {
        return [pscustomobject]@{ Payload = $null; RemovedIndices = [int[]]@() }
    }

    $records = @(Get-VariableRecords $Bytes $Chunk $Context)
    $removedAnimations = [Collections.Generic.List[int]]::new()
    $stream = [IO.MemoryStream]::new()
    try {
        foreach ($record in $records) {
            Assert-Condition ($record.Size -ge 28) "$Context GEOA record $($record.Index) is too small."
            $geosetId = Read-Int32 $Bytes ($record.Offset + 24)
            if ($RemovedGeosets -contains $geosetId) {
                $removedAnimations.Add($record.Index)
                continue
            }

            $copy = [byte[]]::new($record.Size)
            [Array]::Copy($Bytes, $record.Offset, $copy, 0, $record.Size)
            $newGeosetId = Convert-ReferencedIndex $geosetId $RemovedGeosets "$Context GEOA record $($record.Index)"
            Write-Int32 $copy 24 $newGeosetId
            $stream.Write($copy, 0, $copy.Length)
        }
        return [pscustomobject]@{
            Payload = $stream.ToArray()
            RemovedIndices = $removedAnimations.ToArray()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function New-RemappedBonePayload {
    param(
        [byte[]] $Bytes,
        [object] $Chunk,
        [int[]] $RemovedGeosets,
        [int[]] $RemovedGeosetAnimations,
        [string] $Context
    )

    if ($null -eq $Chunk) {
        return $null
    }

    $payload = [byte[]]::new($Chunk.Size)
    [Array]::Copy($Bytes, $Chunk.DataOffset, $payload, 0, $Chunk.Size)
    $position = 0
    $index = 0
    while ($position -lt $payload.Length) {
        Assert-Condition ($position + 12 -le $payload.Length) "$Context has a truncated BONE record $index."
        $nodeSize = [int64](Read-UInt32 $payload $position)
        Assert-Condition ($nodeSize -ge 96) "$Context has an invalid BONE node size at record $index."
        $end = [int64]$position + $nodeSize + 8
        Assert-Condition ($end -le $payload.Length) "$Context has an out-of-bounds BONE record $index."

        $geosetOffset = [int]($position + $nodeSize)
        $animationOffset = $geosetOffset + 4
        $geosetId = Read-Int32 $payload $geosetOffset
        $animationId = Read-Int32 $payload $animationOffset
        $newGeosetId = Convert-ReferencedIndex $geosetId $RemovedGeosets "$Context BONE record $index geoset"
        $newAnimationId = Convert-ReferencedIndex $animationId $RemovedGeosetAnimations "$Context BONE record $index geoset animation"
        Write-Int32 $payload $geosetOffset $newGeosetId
        Write-Int32 $payload $animationOffset $newAnimationId
        $position = [int]$end
        $index++
    }
    Assert-Condition ($position -eq $payload.Length) "$Context BONE chunk did not end on a record boundary."
    return $payload
}

function Write-Chunk {
    param(
        [IO.MemoryStream] $Stream,
        [string] $Tag,
        [byte[]] $Payload
    )

    $tagBytes = [Text.Encoding]::ASCII.GetBytes($Tag)
    Assert-Condition ($tagBytes.Length -eq 4) "Invalid MDX chunk tag $Tag."
    $sizeBytes = [BitConverter]::GetBytes([uint32]$Payload.Length)
    $Stream.Write($tagBytes, 0, 4)
    $Stream.Write($sizeBytes, 0, 4)
    $Stream.Write($Payload, 0, $Payload.Length)
}

function Repair-Mdx {
    param(
        [byte[]] $Bytes,
        [int[]] $ExpectedRemovedGeosets,
        [string] $Context
    )

    $chunks = @(Get-MdxChunks $Bytes $Context)
    $versChunk = Get-SingleChunk $chunks 'VERS' $Context
    Assert-Condition ($versChunk.Size -ge 4) "$Context has a truncated VERS chunk."
    $version = Read-UInt32 $Bytes $versChunk.DataOffset
    $geosChunk = Get-SingleChunk $chunks 'GEOS' $Context
    $geosets = @(Get-Geosets $Bytes $geosChunk $Context)
    $actualBad = @($geosets | Where-Object { $_.VertexCount -gt 0 -and $_.FaceIndexCount -eq 0 } | ForEach-Object { $_.Index })
    $expected = @($ExpectedRemovedGeosets | Sort-Object)
    $actual = @($actualBad | Sort-Object)
    Assert-Condition (($expected -join ',') -ceq ($actual -join ',')) "$Context zero-face geosets changed: expected [$($expected -join ',')], found [$($actual -join ',')]."

    $newGeosPayload = New-FilteredGeosPayload $Bytes $geosets $expected
    $geoaChunk = Get-SingleChunk $chunks 'GEOA' $Context $false
    $geoaResult = New-FilteredGeoaPayload $Bytes $geoaChunk $expected $Context
    $boneChunk = Get-SingleChunk $chunks 'BONE' $Context $false
    $newBonePayload = New-RemappedBonePayload $Bytes $boneChunk $expected $geoaResult.RemovedIndices $Context

    $stream = [IO.MemoryStream]::new()
    try {
        $magic = [Text.Encoding]::ASCII.GetBytes('MDLX')
        $stream.Write($magic, 0, 4)
        foreach ($chunk in $chunks) {
            if ($chunk.Tag -ceq 'GEOS') {
                Write-Chunk $stream 'GEOS' $newGeosPayload
            }
            elseif ($chunk.Tag -ceq 'GEOA') {
                Write-Chunk $stream 'GEOA' $geoaResult.Payload
            }
            elseif ($chunk.Tag -ceq 'BONE') {
                Write-Chunk $stream 'BONE' $newBonePayload
            }
            else {
                $stream.Write($Bytes, $chunk.HeaderOffset, 8 + $chunk.Size)
            }
        }
        $fixedBytes = $stream.ToArray()
    }
    finally {
        $stream.Dispose()
    }

    $fixedChunks = @(Get-MdxChunks $fixedBytes "$Context repaired output")
    $fixedVersChunk = Get-SingleChunk $fixedChunks 'VERS' "$Context repaired output"
    Assert-Condition ((Read-UInt32 $fixedBytes $fixedVersChunk.DataOffset) -eq $version) "$Context changed MDX version during repair."
    $fixedGeosChunk = Get-SingleChunk $fixedChunks 'GEOS' "$Context repaired output"
    $fixedGeosets = @(Get-Geosets $fixedBytes $fixedGeosChunk "$Context repaired output")
    $remainingBad = @($fixedGeosets | Where-Object { $_.VertexCount -gt 0 -and $_.FaceIndexCount -eq 0 })
    Assert-Condition ($remainingBad.Count -eq 0) "$Context repaired output still has zero-face geosets."
    Assert-Condition ($fixedGeosets.Count -eq $geosets.Count - $expected.Count) "$Context repaired output has an unexpected geoset count."

    $expectedSize = $Bytes.Length - (@($geosets | Where-Object { $expected -contains $_.Index } | Measure-Object Size -Sum).Sum)
    if ($null -ne $geoaChunk) {
        $geoaRecords = @(Get-VariableRecords $Bytes $geoaChunk $Context)
        $expectedSize -= (@($geoaRecords | Where-Object { $geoaResult.RemovedIndices -contains $_.Index } | Measure-Object Size -Sum).Sum)
    }
    Assert-Condition ($fixedBytes.Length -eq $expectedSize) "$Context repaired output size differs from the exact removed-record total."

    return [pscustomobject]@{
        Bytes = $fixedBytes
        Version = $version
        OriginalGeosets = $geosets.Count
        FixedGeosets = $fixedGeosets.Count
        RemovedGeosets = $expected
        RemovedGeosetAnimations = [int[]]$geoaResult.RemovedIndices
    }
}

$sourceRoot = [IO.Path]::GetFullPath($SourceMap)
$brokenRoot = [IO.Path]::GetFullPath($BrokenDirectory)
$fixedRoot = [IO.Path]::GetFullPath($FixedDirectory)
Assert-Condition (Test-Path -LiteralPath $sourceRoot -PathType Container) "Source map directory does not exist: $sourceRoot"
Assert-Condition (Test-Path -LiteralPath $brokenRoot -PathType Container) "BrokenModels directory does not exist: $brokenRoot"
Assert-Condition (Test-Path -LiteralPath $fixedRoot -PathType Container) "Fixed directory does not exist: $fixedRoot"

$reportPath = Join-Path (Split-Path -Parent $brokenRoot) 'RepairReport.csv'
Assert-Condition (-not (Test-Path -LiteralPath $reportPath)) "Repair report already exists: $reportPath"

$leafNames = @($Targets.Keys | ForEach-Object { [IO.Path]::GetFileName($_) })
Assert-Condition (($leafNames | Select-Object -Unique).Count -eq $leafNames.Count) 'Target model filenames are not unique; flat output would collide.'

foreach ($relativePath in $Targets.Keys) {
    $sourcePath = Join-Path $sourceRoot $relativePath
    $leafName = [IO.Path]::GetFileName($relativePath)
    $brokenPath = Join-Path $brokenRoot $leafName
    $fixedPath = Join-Path $fixedRoot $leafName
    Assert-Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Required source model does not exist: $sourcePath"
    Assert-Condition (-not (Test-Path -LiteralPath $brokenPath)) "Refusing to overwrite: $brokenPath"
    Assert-Condition (-not (Test-Path -LiteralPath $fixedPath)) "Refusing to overwrite: $fixedPath"
}

$results = [Collections.Generic.List[object]]::new()
foreach ($relativePath in $Targets.Keys) {
    $sourcePath = Join-Path $sourceRoot $relativePath
    $leafName = [IO.Path]::GetFileName($relativePath)
    $brokenPath = Join-Path $brokenRoot $leafName
    $fixedPath = Join-Path $fixedRoot $leafName
    $originalBytes = [IO.File]::ReadAllBytes($sourcePath)
    $repair = Repair-Mdx $originalBytes ([int[]]$Targets[$relativePath]) $relativePath

    [IO.File]::WriteAllBytes($brokenPath, $originalBytes)
    [IO.File]::WriteAllBytes($fixedPath, $repair.Bytes)

    $brokenBytes = [IO.File]::ReadAllBytes($brokenPath)
    $fixedBytes = [IO.File]::ReadAllBytes($fixedPath)
    Assert-Condition ((Get-Sha256 $brokenBytes) -ceq (Get-Sha256 $originalBytes)) "BrokenModels copy verification failed for $leafName."
    Assert-Condition ((Get-Sha256 $fixedBytes) -ceq (Get-Sha256 $repair.Bytes)) "Fixed copy verification failed for $leafName."

    $results.Add([pscustomobject]@{
        SourceRelativePath = $relativePath
        FileName = $leafName
        MdxVersion = $repair.Version
        OriginalBytes = $originalBytes.Length
        FixedBytes = $repair.Bytes.Length
        RemovedGeosets = ($repair.RemovedGeosets -join ';')
        RemovedGeosetAnimations = ($repair.RemovedGeosetAnimations -join ';')
        OriginalSha256 = Get-Sha256 $originalBytes
        FixedSha256 = Get-Sha256 $repair.Bytes
    })
}

Assert-Condition ($results.Count -eq 12) "Expected 12 repaired models, produced $($results.Count)."
$removedTotal = ($results | ForEach-Object { if ($_.RemovedGeosets) { @($_.RemovedGeosets -split ';').Count } else { 0 } } | Measure-Object -Sum).Sum
Assert-Condition ($removedTotal -eq 32) "Expected to remove 32 zero-face geosets, removed $removedTotal."
$results | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding UTF8
$results | Format-Table FileName, MdxVersion, RemovedGeosets, RemovedGeosetAnimations, OriginalBytes, FixedBytes -AutoSize
"Copied and repaired $($results.Count) models; removed $removedTotal zero-face geosets."
"Report: $reportPath"
