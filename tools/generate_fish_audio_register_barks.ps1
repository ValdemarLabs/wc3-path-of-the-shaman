param(
    [string]$Source,

    [string]$InputManifest,

    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [Parameter(Mandatory=$true)]
    [string]$ReferenceId,

    [string]$Manifest,
    [string]$Model = "s2-pro",
    [string]$Format = "mp3",
    [int]$Mp3Bitrate = 128,
    [double]$Temperature = 0.7,
    [double]$TopP = 0.7,
    [string]$Latency = "normal",
    [double]$DelaySeconds = 0.2,
    [int]$Retries = 3,
    [int]$RetryDelaySeconds = 4,
    [switch]$AutoTagAll,
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Get-RequiredEnvironmentValue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Name is not set. Set it before running this script."
    }

    return $value
}

function ConvertFrom-JassString {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Value
    )

    return $Value.Replace('\"', '"').Replace('\\', '\')
}

function Get-FunctionBody {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourceText,

        [Parameter(Mandatory=$true)]
        [string]$FunctionName
    )

    $pattern = "(?s)private function $FunctionName takes nothing returns nothing(.*?)endfunction"
    $match = [regex]::Match($SourceText, $pattern)
    if (-not $match.Success) {
        throw "Could not find private function $FunctionName in $Source."
    }

    return $match.Groups[1].Value
}

function Get-ReputationStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Registration
    )

    switch ($Registration) {
        "RegisterNeutralBark" { return "Neutral" }
        "RegisterFriendlyBark" { return "Friendly" }
        "RegisterCovenantBark" { return "Covenant" }
        "RegisterExaltedBark" { return "Exalted" }
        "RegisterCommonBark" { return "Common" }
        default { return "Unknown" }
    }
}

function Get-AutoTagCue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Registration,

        [Parameter(Mandatory=$true)]
        [string]$BarkType
    )

    $status = Get-ReputationStatus -Registration $Registration

    switch ($BarkType) {
        "AI_BARK_GREET" {
            switch ($status) {
                "Neutral" { return "[doubtful]" }
                "Friendly" { return "[relaxed]" }
                "Covenant" { return "[confident]" }
                "Exalted" { return "[grateful]" }
                default { return "[calm]" }
            }
        }
        "AI_BARK_FAREWELL" {
            switch ($status) {
                "Neutral" { return "[worried]" }
                "Friendly" { return "[calm]" }
                "Covenant" { return "[confident]" }
                "Exalted" { return "[grateful]" }
                default { return "[calm]" }
            }
        }
        "AI_BARK_PASSIVE" {
            switch ($status) {
                "Neutral" { return "[indifferent]" }
                default { return "[calm]" }
            }
        }
        "AI_BARK_NORMAL" {
            switch ($status) {
                "Neutral" { return "[worried]" }
                "Friendly" { return "[determined]" }
                "Covenant" { return "[confident]" }
                "Exalted" { return "[confident]" }
                default { return "[determined]" }
            }
        }
        "AI_BARK_AGGRESSIVE" { return "[angry]" }
        "AI_BARK_HOLD" { return "[confident]" }
        "AI_BARK_KICKED" {
            switch ($status) {
                "Neutral" { return "[indifferent]" }
                default { return "[disappointed]" }
            }
        }
        "AI_BARK_IDLE" {
            switch ($status) {
                "Neutral" { return "[worried]" }
                "Friendly" { return "[nostalgic]" }
                "Covenant" { return "[hopeful]" }
                "Exalted" { return "[hopeful]" }
                default { return "[calm]" }
            }
        }
        "AI_BARK_MOVING" {
            switch ($status) {
                "Neutral" { return "[worried]" }
                "Friendly" { return "[calm]" }
                "Covenant" { return "[determined]" }
                "Exalted" { return "[optimistic]" }
                default { return "[determined]" }
            }
        }
        "AI_BARK_ATTACKING" { return "[angry]" }
        "AI_BARK_CASTING" { return "[determined]" }
        "AI_BARK_KILLING" { return "[angry]" }
        "AI_BARK_DROP_ITEMS" { return "[calm]" }
        "AI_BARK_ITEM_GIVEN" { return "[grateful]" }
        "AI_BARK_COMPANION_DIES" { return "[upset]" }
        default { return "[calm]" }
    }
}

function Add-AutoTagCueToText {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter(Mandatory=$true)]
        [string]$Cue
    )

    if ([string]::IsNullOrWhiteSpace($Cue)) {
        return $Text
    }

    $sentences = [regex]::Matches($Text, '[^.!?]+[.!?]*')
    foreach ($sentence in $sentences) {
        $words = [regex]::Matches($sentence.Value, "[A-Za-z0-9']+")
        if ($words.Count -lt 2) {
            continue
        }

        $commaIndex = $sentence.Value.IndexOf(',')
        if (($commaIndex -ge 0) -and ($commaIndex -lt ($sentence.Value.Length - 1))) {
            return $Text.Insert($sentence.Index + $commaIndex + 1, " $Cue")
        }

        $firstWord = $words[0]
        return $Text.Insert($sentence.Index + $firstWord.Index + $firstWord.Length, " $Cue")
    }

    $firstSpace = $Text.IndexOf(' ')
    if (($firstSpace -gt 0) -and ($firstSpace -lt ($Text.Length - 1))) {
        return $Text.Insert($firstSpace, " $Cue")
    }

    return "$Cue $Text"
}

function Get-RegisterBarkRows {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath
    )

    $sourceText = Get-Content -LiteralPath $SourcePath -Raw
    $body = Get-FunctionBody -SourceText $sourceText -FunctionName "RegisterBarks"
    $pattern = 'call\s+(Register(?:Neutral|Friendly|Covenant|Exalted|Common)Bark)\s*\(\s*(AI_BARK_[A-Z_]+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)'
    $matches = [regex]::Matches($body, $pattern)
    $rows = [System.Collections.Generic.List[object]]::new()

    foreach ($match in $matches) {
        $registration = $match.Groups[1].Value
        $barkType = $match.Groups[2].Value
        $text = ConvertFrom-JassString -Value $match.Groups[3].Value
        $soundKey = ConvertFrom-JassString -Value $match.Groups[4].Value
        $cue = Get-AutoTagCue -Registration $registration -BarkType $barkType
        $ttsText = $text

        if ($AutoTagAll) {
            $ttsText = Add-AutoTagCueToText -Text $text -Cue $cue
        }

        $rows.Add([pscustomobject]@{
            registration = $registration
            reputation = Get-ReputationStatus -Registration $registration
            bark_type = $barkType
            sound_key = $soundKey
            file_name = "$soundKey.$Format"
            auto_tag = $(if ($AutoTagAll) { $cue } else { "" })
            text = $text
            tts_text = $ttsText
        })
    }

    return $rows
}

function Get-ManifestRows {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )

    $rows = Import-Csv -LiteralPath $ManifestPath
    foreach ($row in $rows) {
        if ([string]::IsNullOrWhiteSpace($row.file_name)) {
            throw "Manifest row is missing file_name in $ManifestPath."
        }

        if ([string]::IsNullOrWhiteSpace($row.tts_text)) {
            if ([string]::IsNullOrWhiteSpace($row.text)) {
                throw "Manifest row for $($row.file_name) is missing tts_text and text in $ManifestPath."
            }

            $row.tts_text = $row.text
        }
    }

    return $rows
}

function Invoke-FishTextToSpeech {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,

        [Parameter(Mandatory=$true)]
        [string]$Text,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "model" = $Model
    }

    $payload = @{
        text = $Text
        reference_id = $ReferenceId
        format = $Format
        mp3_bitrate = $Mp3Bitrate
        temperature = $Temperature
        top_p = $TopP
        latency = $Latency
        normalize = $true
        prosody = @{
            speed = 1.0
            volume = 0
            normalize_loudness = $true
        }
    } | ConvertTo-Json -Depth 6

    $tempPath = "$OutputPath.part"
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            if (Test-Path -LiteralPath $tempPath) {
                Remove-Item -LiteralPath $tempPath -Force
            }

            Invoke-WebRequest `
                -Uri "https://api.fish.audio/v1/tts" `
                -Method Post `
                -Headers $headers `
                -ContentType "application/json" `
                -Body $payload `
                -OutFile $tempPath

            Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force
            return
        }
        catch {
            if (Test-Path -LiteralPath $tempPath) {
                Remove-Item -LiteralPath $tempPath -Force
            }

            if ($attempt -eq $Retries) {
                throw
            }

            Write-Warning "Attempt $attempt failed for $([IO.Path]::GetFileName($OutputPath)); retrying in $RetryDelaySeconds seconds."
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}

if ([string]::IsNullOrWhiteSpace($InputManifest) -and [string]::IsNullOrWhiteSpace($Source)) {
    throw "Set either -InputManifest or -Source."
}

if (-not [string]::IsNullOrWhiteSpace($InputManifest)) {
    $rows = Get-ManifestRows -ManifestPath $InputManifest
    Write-Host "Loaded $($rows.Count) RegisterBarks lines from $InputManifest."
}
else {
    $resolvedSource = Resolve-Path -LiteralPath $Source
    $rows = Get-RegisterBarkRows -SourcePath $resolvedSource
}

if ($rows.Count -eq 0) {
    throw "No RegisterBarks rows were found."
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

if ([string]::IsNullOrWhiteSpace($Manifest)) {
    $Manifest = Join-Path $OutputDir "manifest.csv"
}

if ([string]::IsNullOrWhiteSpace($InputManifest)) {
    $rows | Export-Csv -LiteralPath $Manifest -NoTypeInformation -Encoding UTF8
    Write-Host "Found $($rows.Count) RegisterBarks lines in $Source."
    Write-Host "Manifest: $Manifest"
}

if ($DryRun) {
    $rows | Select-Object file_name, reputation, bark_type, auto_tag, text | Format-Table -AutoSize
    Write-Host "Dry run complete. No audio files were generated."
    exit 0
}

$apiKey = Get-RequiredEnvironmentValue -Name "FISH_API_KEY"
$generated = 0
$skipped = 0

foreach ($row in $rows) {
    $outputPath = Join-Path $OutputDir $row.file_name

    if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
        Write-Host "skip $($row.file_name)"
        $skipped++
        continue
    }

    Write-Host "generate $($row.file_name)"
    Invoke-FishTextToSpeech -ApiKey $apiKey -Text $row.tts_text -OutputPath $outputPath
    $generated++

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Milliseconds ([int]($DelaySeconds * 1000))
    }
}

Write-Host "Done. Generated: $generated. Skipped: $skipped."
