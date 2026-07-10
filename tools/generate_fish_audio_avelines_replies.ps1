param(
    [string]$Source = "AI/Specific/AI_Aveline.j",
    [string]$OutputDir = "tools/temp/AvelineReplyLines",
    [string]$Manifest = "tools/temp/aveline_reply_lines.csv",
    [string]$ReferenceId = $env:FISH_REFERENCE_ID,
    [string]$Model = "s2-pro",
    [string]$Format = "mp3",
    [int]$Mp3Bitrate = 128,
    [double]$Temperature = 0.7,
    [double]$TopP = 0.7,
    [ValidateSet("low", "balanced", "normal")]
    [string]$Latency = "normal",
    [int]$Retries = 3,
    [double]$RetryDelaySeconds = 3.0,
    [string]$TagPrefix = "",
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$requestedFunctions = @(
    "RegisterUndeadWarlockReplies",
    "RegisterShamanReplies",
    "RegisterEngineerReplies",
    "RegisterPaladinReplies"
)

function ConvertFrom-JassString {
    param([string]$Value)

    return $Value.Replace('\"', '"').Replace('\\', '\')
}

function Get-PlainTextSecret {
    param([securestring]$Secret)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-FunctionBody {
    param(
        [string]$SourceText,
        [string]$FunctionName
    )

    $startPattern = "private\s+function\s+$([regex]::Escape($FunctionName))\s+takes\s+nothing\s+returns\s+nothing"
    $startMatch = [regex]::Match($SourceText, $startPattern)
    if (-not $startMatch.Success) {
        throw "Function not found: $FunctionName"
    }

    $endIndex = $SourceText.IndexOf("endfunction", $startMatch.Index + $startMatch.Length)
    if ($endIndex -lt 0) {
        throw "Missing endfunction for: $FunctionName"
    }

    return $SourceText.Substring($startMatch.Index + $startMatch.Length, $endIndex - ($startMatch.Index + $startMatch.Length))
}

function Get-AvelineRows {
    param([string]$SourcePath)

    $sourceText = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8
    $rows = New-Object System.Collections.Generic.List[object]
    $replyPattern = 'call\s+RegisterReply\("((?:[^"\\]|\\.)*)",\s*"((?:[^"\\]|\\.)*)"\)'

    foreach ($functionName in $requestedFunctions) {
        $body = Get-FunctionBody -SourceText $sourceText -FunctionName $functionName
        foreach ($match in [regex]::Matches($body, $replyPattern)) {
            $soundKey = ConvertFrom-JassString $match.Groups[1].Value
            $text = ConvertFrom-JassString $match.Groups[2].Value
            $outputKey = "${soundKey}Aveline"

            $rows.Add([pscustomobject]@{
                function = $functionName
                sound_key = $soundKey
                output_key = $outputKey
                filename = "${outputKey}.mp3"
                text = $text
            })
        }
    }

    return $rows
}

function Invoke-FishTts {
    param(
        [object]$Row,
        [string]$ApiKey
    )

    $outputPath = Join-Path $OutputDir $Row.filename
    if ((Test-Path -LiteralPath $outputPath) -and (-not $Force)) {
        Write-Host "skip existing $($Row.filename)"
        return
    }

    $ttsText = $Row.text
    if ($TagPrefix -ne "") {
        $ttsText = "${TagPrefix}${ttsText}"
    }

    $payload = @{
        text = $ttsText
        reference_id = $ReferenceId
        format = $Format
        mp3_bitrate = $Mp3Bitrate
        temperature = $Temperature
        top_p = $TopP
        latency = $Latency
        normalize = $true
        prosody = @{
            speed = 1
            volume = 0
            normalize_loudness = $true
        }
    } | ConvertTo-Json -Depth 5

    $headers = @{
        Authorization = "Bearer $ApiKey"
        model = $Model
    }

    $lastError = $null
    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            $response = Invoke-WebRequest `
                -Uri "https://api.fish.audio/v1/tts" `
                -Method Post `
                -Headers $headers `
                -ContentType "application/json" `
                -Body $payload `
                -TimeoutSec 180 `
                -OutFile $outputPath

            Write-Host "generated $($Row.filename)"
            return
        }
        catch {
            $lastError = $_
            if ($attempt -lt $Retries) {
                Start-Sleep -Seconds ($RetryDelaySeconds * $attempt)
            }
        }
    }

    throw "Failed $($Row.filename): $lastError"
}

$rows = Get-AvelineRows -SourcePath $Source
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Manifest) | Out-Null
$rows | Export-Csv -LiteralPath $Manifest -NoTypeInformation -Encoding UTF8

Write-Host "Manifest: $Manifest"
Write-Host "Output directory: $OutputDir"
Write-Host "Lines: $($rows.Count)"

if ($DryRun) {
    foreach ($row in $rows) {
        Write-Host "dry-run $($row.filename): $($row.text)"
    }
    exit 0
}

if (-not $ReferenceId) {
    throw "Missing Fish voice reference id. Pass -ReferenceId or set FISH_REFERENCE_ID."
}

$apiKey = $env:FISH_API_KEY
if (-not $apiKey) {
    $secureKey = Read-Host "Fish API key" -AsSecureString
    $apiKey = Get-PlainTextSecret $secureKey
}

foreach ($row in $rows) {
    Invoke-FishTts -Row $row -ApiKey $apiKey
}
