param(
    [ValidateSet("Scan", "Generate")]
    [string]$Mode = "Scan",

    [string]$MasterRoot = "H:\Pelit\WC3_PotS_Files\001 OFFICIAL FILES\Pots\Sound\Voicelines",
    [string]$TempRoot = "tools/temp/fishaudio-review",
    [string]$ExcelPath = "Voicelines/_oldExcel/VoicelinesMaster.xlsx",
    [string]$Manifest = "tools/temp/voicelines/voicelines-scan.csv",
    [string[]]$Speaker = @(),
    [string[]]$Keys = @(),
    [string]$ReferenceId = $env:FISH_REFERENCE_ID,
    [string]$Model = "s2-pro",
    [string]$Format = "mp3",
    [int]$Mp3Bitrate = 128,
    [double]$Temperature = 0.7,
    [double]$TopP = 0.7,
    [ValidateSet("low", "balanced", "normal")]
    [string]$Latency = "normal",
    [int]$Retries = 3,
    [int]$RetryDelaySeconds = 4,
    [double]$DelaySeconds = 0.2,
    [int]$MaxCount = 0,
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$Speaker = @($Speaker | ForEach-Object { $_ -split ',' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })

$PrefixFolders = @{
    "Aradion" = "AradionFarseer"
    "AtexBlix" = "AtexBlix"
    "Aveline" = "Aveline"
    "Boomers" = "BoomBrothers"
    "BoomBrothers" = "BoomBrothers"
    "DarkShaman" = "DarkShaman"
    "Demoness" = "Demoness"
    "Garthork" = "Garthork"
    "Granis" = "Granis"
    "GrumBloodfang" = "GrumBloodfang"
    "HeroEngineer" = "HeroEngineer"
    "HeroPaladin" = "HeroPaladin"
    "HeroRestoshaman" = "HeroRestoshaman"
    "HeroRogue" = "HeroRogue"
    "HeroShaman" = "HeroRestoshaman"
    "HeroUndeadWarlock" = "HeroWarlock"
    "HeroWarlock" = "HeroWarlock"
    "HeroWarrior" = "HeroWarrior"
    "HumanFemale1" = "HumanFemale1"
    "Jinzun" = "Jinzun"
    "Kaelthir" = "Kaelthir"
    "Kribugs" = "Kribugs"
    "Krezgrel" = "Krezgrel"
    "Mordrax" = "Mordrax"
    "Narrator" = "Narrator"
    "Nazgrek" = "Nazgrek"
    "OrcGrunt" = "Orc Grunt"
    "OrcPeon" = "Orc Peon"
    "Peon" = "Orc Peon"
    "OrcQGiver" = "OrcQGiver"
    "Satyr" = "Satyr"
    "Serenthia" = "Serenthia"
    "Shipmaster" = "Shipmaster"
    "Thork" = "Thork"
    "Valeria" = "Valeria"
    "VoidEntity" = "VoidEntity"
    "XXX" = "OrcQGiver"
    "Zulkis" = "Zulkis"
}

function ConvertFrom-JassString {
    param([string]$Value)
    return $Value.Replace('\"', '"').Replace('\\', '\')
}

function ConvertFrom-ExcelValue {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Trim()
}

function Get-KeyPrefix {
    param([string]$Key)
    if ($Key -match "^([^_]+)_") { return $matches[1] }
    if ($Key -match "^(Boomers)") { return "Boomers" }
    return $Key
}

function ConvertTo-CanonicalVoicelineKey {
    param([string]$Key)
    if ($Key -match "^Peon_(.+)$") {
        return "OrcPeon_" + $matches[1]
    }
    return $Key
}

function Format-SequenceKey {
    param(
        [string]$SoundType,
        [int]$LineIndex
    )

    return "{0}{1:D4}" -f $SoundType, $LineIndex
}

function Get-ExpectedFolderForKey {
    param([string]$Key)

    if ($Key -match "Aveline$" -and $Key -notmatch "^Aveline_") {
        return "Aveline\ReplyLines"
    }
    if ($Key -match "^Aveline_Chat") {
        return "Aveline\ChatOther"
    }
    if ($Key -match "^(Hero[A-Za-z]+_Chat.+?)UndeadWarlock$") {
        return "HeroReplyLines\HeroWarlockReplyLines"
    }
    if ($Key -match "^(Hero[A-Za-z]+_Chat.+?)(Engineer|Paladin|Rogue|Shaman|Warlock|Warrior)$") {
        return "HeroReplyLines\Hero$($matches[2])ReplyLines"
    }
    if ($Key -match "^(HeroRogue|HeroWarlock|HeroUndeadWarlock)_Chat") {
        return "$(Get-ExpectedFolderForPrefix -Prefix (Get-KeyPrefix $Key))\ChatOther"
    }
    if ($Key -match "^(HeroEngineer|HeroPaladin|HeroRestoshaman|HeroShaman|HeroWarrior)_Chat") {
        return "$(Get-ExpectedFolderForPrefix -Prefix (Get-KeyPrefix $Key))\ChatLines"
    }

    return Get-ExpectedFolderForPrefix -Prefix (Get-KeyPrefix $Key)
}

function Get-ExpectedFolderForPrefix {
    param([string]$Prefix)
    if ($PrefixFolders.ContainsKey($Prefix)) { return $PrefixFolders[$Prefix] }
    return $Prefix
}

function Add-Row {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$Key,
        [string]$Text,
        [string]$Source,
        [string]$ExpectedFolder,
        [string]$RowType = "definition",
        [string]$DefinitionId = ""
    )

    if ([string]::IsNullOrWhiteSpace($Key)) { return }
    if ([string]::IsNullOrWhiteSpace($ExpectedFolder)) {
        $ExpectedFolder = Get-ExpectedFolderForKey -Key $Key
    }

    $Rows.Add([pscustomobject]@{
        key = $Key
        text = $Text
        source = $Source
        expected_folder = $ExpectedFolder
        row_type = $RowType
        definition_id = $DefinitionId
    })
}

function Get-AudioIndex {
    param([string]$Root)

    $index = @{}
    if (-not (Test-Path -LiteralPath $Root)) { return $index }

    $rootPath = (Resolve-Path -LiteralPath $Root).Path
    foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File | Where-Object { $_.Extension -in ".mp3", ".wav" }) {
        $key = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        $relative = $file.FullName.Substring($rootPath.Length).TrimStart('\')
        if (-not $index.ContainsKey($key)) {
            $index[$key] = [System.Collections.Generic.List[string]]::new()
        }
        $index[$key].Add($relative)
    }

    return $index
}

function Get-JassRows {
    $rows = [System.Collections.Generic.List[object]]::new()
    $soundTypeByConstant = @{}

    foreach ($voiceFile in Get-ChildItem -LiteralPath "Voicelines" -Filter "Voicelines_*.j" -File -ErrorAction SilentlyContinue) {
        $voiceText = [IO.File]::ReadAllText($voiceFile.FullName)
        foreach ($m in [regex]::Matches($voiceText, 'constant\s+string\s+(VL_[A-Z0-9_]+_TYPE)\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $soundTypeByConstant[$m.Groups[1].Value] = ConvertFrom-JassString $m.Groups[2].Value
        }
    }

    foreach ($file in Get-ChildItem -LiteralPath "Voicelines" -Filter "Voicelines_*.j" -File -ErrorAction SilentlyContinue) {
        $text = [IO.File]::ReadAllText($file.FullName)
        $folderByPrefix = @{}
        foreach ($m in [regex]::Matches($text, 'constant\s+string\s+VL_([A-Z0-9]+)_FOLDER\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $folderByPrefix[$m.Groups[1].Value] = ConvertFrom-JassString $m.Groups[2].Value
        }

        $keyByBase = @{}
        foreach ($m in [regex]::Matches($text, 'constant\s+string\s+(VL_[A-Z0-9]+(?:_[A-Z0-9]+)+)_KEY\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $keyByBase[$m.Groups[1].Value] = ConvertFrom-JassString $m.Groups[2].Value
        }

        $textsByBase = @{}
        foreach ($m in [regex]::Matches($text, 'constant\s+string\s+(VL_[A-Z0-9]+(?:_[A-Z0-9]+)+)_TEXT(?:_ALT\d+)?\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $base = $m.Groups[1].Value
            if ($keyByBase.ContainsKey($base)) {
                if (-not $textsByBase.ContainsKey($base)) {
                    $textsByBase[$base] = [System.Collections.Generic.List[string]]::new()
                }
                $textsByBase[$base].Add((ConvertFrom-JassString $m.Groups[2].Value))
            }
        }

        foreach ($base in $keyByBase.Keys) {
            $prefix = $base.Split('_')[1]
            $folder = ""
            if ($folderByPrefix.ContainsKey($prefix)) { $folder = $folderByPrefix[$prefix] }

            if ($textsByBase.ContainsKey($base)) {
                foreach ($lineText in $textsByBase[$base]) {
                    Add-Row -Rows $rows -Key $keyByBase[$base] -Text $lineText -Source $file.Name -ExpectedFolder $folder -DefinitionId "$($file.Name):$base"
                }
            }
            else {
                Add-Row -Rows $rows -Key $keyByBase[$base] -Text "" -Source $file.Name -ExpectedFolder $folder -DefinitionId "$($file.Name):$base"
            }
        }

        $voicedProfilePattern = 'RegisterVoicedProfile\(\s*[A-Z0-9_]+\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*(VL_[A-Z0-9_]+_TYPE)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)'
        $extraVendorTexts = @(
            "Take your time. The right purchase is worth considering.",
            "A wise purchase. I hope it serves you well.",
            "Good choice. That belongs in capable hands.",
            "I can put that back into useful circulation.",
            "Fair value for something you no longer need.",
            "A productive exchange for both of us.",
            "Your pack changed, and my shelves did too. Good trade.",
            "All that browsing and not a single coin moved.",
            "Nothing suited you? That is disappointing."
        )

        foreach ($m in [regex]::Matches($text, $voicedProfilePattern)) {
            $soundTypeConstant = $m.Groups[7].Value
            if (-not $soundTypeByConstant.ContainsKey($soundTypeConstant)) { continue }

            $firstLine = [int]$m.Groups[8].Value
            $extraFirstLine = [int]$m.Groups[9].Value
            $familyConstant = $soundTypeConstant -replace '_\d+_TYPE$', ''
            foreach ($candidateConstant in $soundTypeByConstant.Keys) {
                if (($candidateConstant -replace '_\d+_TYPE$', '') -ne $familyConstant) { continue }

                $soundType = $soundTypeByConstant[$candidateConstant]
                for ($i = 0; $i -lt 6; $i++) {
                    $lineIndex = $firstLine + $i
                    Add-Row -Rows $rows -Key (Format-SequenceKey -SoundType $soundType -LineIndex $lineIndex) -Text (ConvertFrom-JassString $m.Groups[$i + 1].Value) -Source $file.Name -ExpectedFolder "" -DefinitionId "$($file.Name):$($candidateConstant):$lineIndex"
                }
                for ($i = 0; $i -lt $extraVendorTexts.Count; $i++) {
                    $lineIndex = $extraFirstLine + $i
                    Add-Row -Rows $rows -Key (Format-SequenceKey -SoundType $soundType -LineIndex $lineIndex) -Text $extraVendorTexts[$i] -Source $file.Name -ExpectedFolder "" -DefinitionId "$($file.Name):$($candidateConstant):$lineIndex"
                }
            }
        }

        $profileSoundTypes = @{}
        $profileSoundTypePattern = 'call\s+VendorLines_RegisterProfileSoundType\(\s*([A-Z0-9_]+)\s*,\s*(VL_[A-Z0-9_]+_TYPE)\s*\)'
        foreach ($m in [regex]::Matches($text, $profileSoundTypePattern)) {
            $profileSoundTypes[$m.Groups[1].Value] = $m.Groups[2].Value
        }

        $directProfileLinePattern = 'call\s+VendorLines_RegisterProfileVoiceLine\(\s*([A-Z0-9_]+)\s*,\s*[^,]+\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*(\d+)\s*\)'
        foreach ($m in [regex]::Matches($text, $directProfileLinePattern)) {
            $profileConstant = $m.Groups[1].Value
            if (-not $profileSoundTypes.ContainsKey($profileConstant)) { continue }

            $soundTypeConstant = $profileSoundTypes[$profileConstant]
            if (-not $soundTypeByConstant.ContainsKey($soundTypeConstant)) { continue }

            $lineIndex = [int]$m.Groups[3].Value
            Add-Row -Rows $rows -Key (Format-SequenceKey -SoundType $soundTypeByConstant[$soundTypeConstant] -LineIndex $lineIndex) -Text (ConvertFrom-JassString $m.Groups[2].Value) -Source $file.Name -ExpectedFolder "" -DefinitionId "$($file.Name):${profileConstant}:$lineIndex"
        }

        # Drunk/Night vendor replies are authored once per reusable voice
        # profile and occupy seven consecutive keys: five recollections, a
        # task request, and a forgiveness reply.
        $drunkVendorPattern = 'call\s+RegisterVendorVoice\(\s*(VL_[A-Z0-9_]+_TYPE)\s*,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)'
        foreach ($m in [regex]::Matches($text, $drunkVendorPattern)) {
            $soundTypeConstant = $m.Groups[1].Value
            if (-not $soundTypeByConstant.ContainsKey($soundTypeConstant)) { continue }

            $firstLine = [int]$m.Groups[2].Value
            $folder = ConvertFrom-JassString $m.Groups[3].Value
            for ($i = 0; $i -lt 7; $i++) {
                $lineIndex = $firstLine + $i
                Add-Row -Rows $rows -Key (Format-SequenceKey -SoundType $soundTypeByConstant[$soundTypeConstant] -LineIndex $lineIndex) -Text (ConvertFrom-JassString $m.Groups[4 + $i].Value) -Source $file.Name -ExpectedFolder $folder -DefinitionId "$($file.Name):${soundTypeConstant}:$lineIndex"
            }
        }

        $vendorCatalogs = @{}
        $vendorCatalogCount = 0
        $catalogCallPattern = '(?m)^\s*call\s+(RegisterBasicProfile|RegisterCatalogBasicProfile)\(([^\r\n]+)\)'
        foreach ($m in [regex]::Matches($text, $catalogCallPattern)) {
            $arguments = @([regex]::Matches($m.Groups[2].Value, '"((?:[^"\\]|\\.)*)"') | ForEach-Object { ConvertFrom-JassString $_.Groups[1].Value })
            if ($arguments.Count -lt 5) { continue }

            $vendorCatalogCount++
            $catalogTexts = @($arguments | Select-Object -Skip 1)
            if ($m.Groups[1].Value -eq "RegisterBasicProfile") {
                $catalogTexts += $extraVendorTexts
            }
            $vendorCatalogs[$arguments[0]] = [pscustomobject]@{
                index = $vendorCatalogCount
                texts = $catalogTexts
            }
        }

        $voiceFamilies = @{}
        $familyPattern = 'call\s+RegisterVoiceFamily\(\s*(VL_[A-Z0-9_]+_TYPE)\s*,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)'
        foreach ($m in [regex]::Matches($text, $familyPattern)) {
            if (-not $soundTypeByConstant.ContainsKey($m.Groups[1].Value)) { continue }

            $folder = ConvertFrom-JassString $m.Groups[3].Value
            $folder = $folder.Replace('Pots\Sound\Voicelines\', '').TrimEnd('\')
            $voiceFamilies[$m.Groups[1].Value] = [pscustomobject]@{
                sound_type = $soundTypeByConstant[$m.Groups[1].Value]
                first_line = [int]$m.Groups[2].Value
                folder = $folder
            }
        }

        $catalogVoicePattern = 'call\s+RegisterVoiceCatalog\(\s*(VL_[A-Z0-9_]+_TYPE)\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)'
        foreach ($m in [regex]::Matches($text, $catalogVoicePattern)) {
            $familyConstant = $m.Groups[1].Value
            $catalogName = ConvertFrom-JassString $m.Groups[2].Value
            if (-not $voiceFamilies.ContainsKey($familyConstant) -or -not $vendorCatalogs.ContainsKey($catalogName)) { continue }

            $family = $voiceFamilies[$familyConstant]
            $catalog = $vendorCatalogs[$catalogName]
            $firstLine = $family.first_line + ($catalog.index - 1) * 19
            for ($i = 0; $i -lt $catalog.texts.Count; $i++) {
                $lineIndex = $firstLine + $i
                Add-Row -Rows $rows -Key (Format-SequenceKey -SoundType $family.sound_type -LineIndex $lineIndex) -Text $catalog.texts[$i] -Source $file.Name -ExpectedFolder $family.folder -DefinitionId "$($file.Name):${familyConstant}:${catalogName}:$lineIndex"
            }
        }

        $questVoiceTypes = @{}
        foreach ($m in [regex]::Matches($text, 'ExSound_RegisterSequence\(\s*(VL_[A-Z0-9_]+_TYPE)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')) {
            $typeConstant = $m.Groups[1].Value
            $firstLine = [int]$m.Groups[2].Value
            if ($firstLine -lt 1000 -and $typeConstant -notin @('VL_NAZGREK_GENERIC_TYPE', 'VL_ZULKIS_GENERIC_TYPE')) { continue }
            if (-not $soundTypeByConstant.ContainsKey($typeConstant)) { continue }

            $textFamily = switch -Regex ($typeConstant) {
                'NAZGREK' { 'NAZGREK'; break }
                'ZULKIS' { 'ZULKIS'; break }
                'OGRE_BONECRUSHER' { 'BONECRUSHER'; break }
                'ELARINDOR' { 'ELARINDOR'; break }
                'GOBLIN' { 'GOBLIN'; break }
                'HUMAN' { 'HUMAN'; break }
                'ORC' { 'ORC'; break }
                'SATYR' { 'SATYR'; break }
                'TAUREN' { 'TAUREN'; break }
                default { '' }
            }
            if ([string]::IsNullOrWhiteSpace($textFamily)) { continue }

            $folder = ConvertFrom-JassString $m.Groups[4].Value
            $questVoiceTypes[$typeConstant] = [pscustomobject]@{
                family = $textFamily
                sound_type = $soundTypeByConstant[$typeConstant]
                folder = $folder.Replace('Pots\Sound\Voicelines\', '').TrimEnd('\')
                first_line = $firstLine
                last_line = [int]$m.Groups[3].Value
            }
        }

        $vendorQuestTexts = @{}
        foreach ($m in [regex]::Matches($text, 'constant\s+string\s+VL_VENDORQUEST_([A-Z0-9]+)_(\d{4})\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $vendorQuestTexts["$($m.Groups[1].Value):$([int]$m.Groups[2].Value)"] = ConvertFrom-JassString $m.Groups[3].Value
        }

        $heroQuestTextConstants = @(
            'VL_QUEST_HERO_ACCEPT',
            'VL_QUEST_HERO_COMPLETE_KILL',
            'VL_QUEST_HERO_COMPLETE_TALK',
            'VL_QUEST_HERO_COMPLETE_FETCH',
            'VL_QUEST_HERO_PROGRESS',
            'VL_QUEST_HERO_REQUEST_SUPPLY',
            'VL_QUEST_HERO_ASK_TO_BUY'
        )
        $heroQuestTexts = @()
        foreach ($constantName in $heroQuestTextConstants) {
            $m = [regex]::Match($text, 'constant\s+string\s+' + [regex]::Escape($constantName) + '\s*=\s*"((?:[^"\\]|\\.)*)"')
            if ($m.Success) { $heroQuestTexts += (ConvertFrom-JassString $m.Groups[1].Value) }
        }

        $heroGenericTexts = @{}
        foreach ($m in [regex]::Matches($text, 'constant\s+string\s+VL_(NAZGREK|ZULKIS)_GENERIC_(\d{4})_TEXT\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $heroGenericTexts["$($m.Groups[1].Value):$([int]$m.Groups[2].Value)"] = ConvertFrom-JassString $m.Groups[3].Value
        }

        $dailyQuestTexts = @{}
        $dailySetPattern = 'call\s+RegisterDailySet\(\s*(VL_[A-Z0-9_]+_TYPE)\s*,\s*[^,]+,\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)'
        foreach ($m in [regex]::Matches($text, $dailySetPattern)) {
            for ($i = 0; $i -lt 3; $i++) {
                $dailyQuestTexts["$($m.Groups[1].Value):$([int]$m.Groups[2].Value + $i)"] = ConvertFrom-JassString $m.Groups[3 + $i].Value
            }
        }

        foreach ($typeConstant in $questVoiceTypes.Keys) {
            $voiceType = $questVoiceTypes[$typeConstant]
            $textFamily = $voiceType.family
            for ($lineIndex = $voiceType.first_line; $lineIndex -le $voiceType.last_line; $lineIndex++) {
                $lineText = ""
                $sourceIndex = $lineIndex
                if ($lineIndex -ge 1000) { $sourceIndex = $lineIndex - 1000 }
                $textKey = "${textFamily}:$sourceIndex"
                $dailyKey = "${typeConstant}:$lineIndex"
                if ($vendorQuestTexts.ContainsKey($textKey)) {
                    $lineText = $vendorQuestTexts[$textKey]
                }
                elseif ($dailyQuestTexts.ContainsKey($dailyKey)) {
                    $lineText = $dailyQuestTexts[$dailyKey]
                }
                elseif ($textFamily -in @('NAZGREK', 'ZULKIS') -and $heroGenericTexts.ContainsKey($textKey)) {
                    $lineText = $heroGenericTexts[$textKey]
                }
                elseif ($textFamily -in @('NAZGREK', 'ZULKIS') -and $sourceIndex -le $heroQuestTexts.Count) {
                    $lineText = $heroQuestTexts[$sourceIndex - 1]
                }
                if (-not [string]::IsNullOrWhiteSpace($lineText)) {
                    Add-Row -Rows $rows -Key (Format-SequenceKey -SoundType $voiceType.sound_type -LineIndex $lineIndex) -Text $lineText -Source $file.Name -ExpectedFolder $voiceType.folder -DefinitionId "$($file.Name):${typeConstant}:$lineIndex"
                }
            }
        }
    }

    foreach ($file in Get-ChildItem -LiteralPath "AI" -Recurse -Filter "*.j" -File -ErrorAction SilentlyContinue) {
        $text = [IO.File]::ReadAllText($file.FullName)
        foreach ($m in [regex]::Matches($text, 'AI_RegisterBarkLine(?:ForReputation)?\([^\r\n]*?,\s*AI_BARK_[A-Z_]+,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"')) {
            Add-Row -Rows $rows -Key (ConvertFrom-JassString $m.Groups[2].Value) -Text (ConvertFrom-JassString $m.Groups[1].Value) -Source $file.FullName -ExpectedFolder ""
        }
        foreach ($m in [regex]::Matches($text, 'Register(?:Neutral|Friendly|Covenant|Exalted|Common)Bark\(\s*AI_BARK_[A-Z_]+,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"')) {
            Add-Row -Rows $rows -Key (ConvertFrom-JassString $m.Groups[2].Value) -Text (ConvertFrom-JassString $m.Groups[1].Value) -Source $file.FullName -ExpectedFolder ""
        }
        foreach ($m in [regex]::Matches($text, 'RegisterBark\([^\r\n]*?,\s*AI_BARK_[A-Z_]+,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"')) {
            Add-Row -Rows $rows -Key (ConvertFrom-JassString $m.Groups[1].Value) -Text (ConvertFrom-JassString $m.Groups[2].Value) -Source $file.FullName -ExpectedFolder ""
        }
        foreach ($m in [regex]::Matches($text, 'Register(?:Engineer)?Chat\([^\r\n]*?"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"')) {
            Add-Row -Rows $rows -Key (ConvertFrom-JassString $m.Groups[1].Value) -Text (ConvertFrom-JassString $m.Groups[2].Value) -Source $file.FullName -ExpectedFolder ""
        }
        foreach ($m in [regex]::Matches($text, 'RegisterReply\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*AI_[A-Za-z]+_ProfileId\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"')) {
            Add-Row -Rows $rows -Key ((ConvertFrom-JassString $m.Groups[1].Value) + (ConvertFrom-JassString $m.Groups[2].Value)) -Text (ConvertFrom-JassString $m.Groups[3].Value) -Source $file.FullName -ExpectedFolder ""
        }
        foreach ($m in [regex]::Matches($text, 'RegisterReply\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')) {
            Add-Row -Rows $rows -Key ((ConvertFrom-JassString $m.Groups[1].Value) + "Aveline") -Text (ConvertFrom-JassString $m.Groups[2].Value) -Source $file.FullName -ExpectedFolder "Aveline\ReplyLines"
        }
    }

    foreach ($file in Get-ChildItem -LiteralPath "SoundAndMusic" -Filter "*.j" -File -ErrorAction SilentlyContinue) {
        $text = [IO.File]::ReadAllText($file.FullName)
        foreach ($m in [regex]::Matches($text, 'ExSound_Register\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"Pots\\\\Sound\\\\Voicelines\\\\((?:[^"\\]|\\.)*)"')) {
            $key = ConvertFrom-JassString $m.Groups[1].Value
            $path = ConvertFrom-JassString $m.Groups[2].Value
            $folder = Split-Path -Parent $path
            Add-Row -Rows $rows -Key $key -Text "" -Source $file.FullName -ExpectedFolder $folder -RowType "registration"
        }
        foreach ($m in [regex]::Matches($text, 'ExSound_RegisterKeyInFolder\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"Pots\\\\Sound\\\\Voicelines\\\\((?:[^"\\]|\\.)*)"')) {
            $key = ConvertFrom-JassString $m.Groups[1].Value
            $folder = (ConvertFrom-JassString $m.Groups[2].Value).TrimEnd('\')
            Add-Row -Rows $rows -Key $key -Text "" -Source $file.FullName -ExpectedFolder $folder -RowType "registration"
        }
    }

    return $rows
}

function Get-ExcelRows {
    $rows = [System.Collections.Generic.List[object]]::new()
    if (-not (Test-Path -LiteralPath $ExcelPath)) { return $rows }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ExcelPath))
    try {
        function Read-ZipText {
            param([string]$Name)
            $entry = $zip.GetEntry($Name)
            if ($null -eq $entry) { return $null }
            $reader = [IO.StreamReader]::new($entry.Open())
            try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
        }

        [xml]$workbook = Read-ZipText "xl/workbook.xml"
        [xml]$rels = Read-ZipText "xl/_rels/workbook.xml.rels"
        [xml]$shared = Read-ZipText "xl/sharedStrings.xml"
        $sharedStrings = @()
        if ($shared) {
            $sns = [Xml.XmlNamespaceManager]::new($shared.NameTable)
            $sns.AddNamespace("d", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
            foreach ($si in $shared.SelectNodes("//d:si", $sns)) {
                $parts = @($si.SelectNodes(".//d:t", $sns) | ForEach-Object { $_."#text" })
                $sharedStrings += ($parts -join "")
            }
        }

        $ns = [Xml.XmlNamespaceManager]::new($workbook.NameTable)
        $ns.AddNamespace("d", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
        foreach ($sheet in $workbook.SelectNodes("//d:sheet", $ns)) {
            $rid = $sheet.GetAttribute("id", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
            $rel = $rels.Relationships.Relationship | Where-Object { $_.Id -eq $rid }
            if ($null -eq $rel) { continue }
            $target = "xl/" + $rel.Target.TrimStart("/")
            [xml]$ws = Read-ZipText $target
            $wns = [Xml.XmlNamespaceManager]::new($ws.NameTable)
            $wns.AddNamespace("d", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")

            $headerByColumn = @{}
            foreach ($row in $ws.SelectNodes("//d:sheetData/d:row", $wns)) {
                $cellValues = @{}
                foreach ($c in $row.SelectNodes("d:c", $wns)) {
                    $ref = $c.r
                    if ($ref -notmatch "^([A-Z]+)") { continue }
                    $col = $matches[1]
                    $value = ""
                    if ($c.t -eq "s" -and $c.v -ne $null) {
                        $idx = [int]$c.v
                        if ($idx -lt $sharedStrings.Count) { $value = $sharedStrings[$idx] }
                    }
                    elseif ($c.t -eq "inlineStr") {
                        $value = @($c.SelectNodes(".//d:t", $wns) | ForEach-Object { $_."#text" }) -join ""
                    }
                    elseif ($c.v -ne $null) {
                        $value = [string]$c.v
                    }
                    $cellValues[$col] = ConvertFrom-ExcelValue $value
                }

                if ($headerByColumn.Count -eq 0) {
                    foreach ($col in $cellValues.Keys) {
                        if ($cellValues[$col] -match "^(File Name|Text|Related quest|Related Event|Done|Comment)$") {
                            $headerByColumn[$col] = $cellValues[$col]
                        }
                    }
                    continue
                }

                $fileName = ""
                $lineText = ""
                foreach ($col in $cellValues.Keys) {
                    if ($headerByColumn.ContainsKey($col)) {
                        if ($headerByColumn[$col] -eq "File Name") { $fileName = $cellValues[$col] }
                        if ($headerByColumn[$col] -eq "Text") { $lineText = $cellValues[$col] }
                    }
                }
                if ([string]::IsNullOrWhiteSpace($fileName)) { continue }
                $key = [IO.Path]::GetFileNameWithoutExtension($fileName)
                $key = ConvertTo-CanonicalVoicelineKey $key
                Add-Row -Rows $rows -Key $key -Text $lineText -Source ("Excel:" + $sheet.name) -ExpectedFolder ""
            }
        }
    }
    finally {
        $zip.Dispose()
    }

    return $rows
}

function Add-ToRowIndex {
    param(
        [hashtable]$Index,
        [object]$Row
    )

    if (-not $Index.ContainsKey($Row.key)) {
        $Index[$Row.key] = [System.Collections.Generic.List[object]]::new()
    }
    $Index[$Row.key].Add($Row)
}

function Build-ScanRows {
    $jassRows = @(Get-JassRows)
    $excelRows = @(Get-ExcelRows)
    $masterIndex = Get-AudioIndex -Root $MasterRoot
    $tempIndex = Get-AudioIndex -Root $TempRoot
    $jassIndex = @{}
    $excelIndex = @{}
    $keys = @{}

    foreach ($row in $jassRows) {
        Add-ToRowIndex -Index $jassIndex -Row $row
        $keys[$row.key] = $true
    }
    foreach ($row in $excelRows) {
        Add-ToRowIndex -Index $excelIndex -Row $row
        $keys[$row.key] = $true
    }
    foreach ($key in $masterIndex.Keys) { $keys[$key] = $true }
    foreach ($key in $tempIndex.Keys) { $keys[$key] = $true }

    $scanRows = [System.Collections.Generic.List[object]]::new()
    foreach ($key in @($keys.Keys | Sort-Object)) {
        if ($Speaker.Count -gt 0) {
            $folderForFilter = Get-ExpectedFolderForKey $key
            $speakerMatches = $false
            foreach ($speakerFilter in $Speaker) {
                if (-not [string]::IsNullOrWhiteSpace($speakerFilter) -and ($key -like "$speakerFilter*" -or $folderForFilter -like "$speakerFilter*" -or $folderForFilter -like "*$speakerFilter*")) {
                    $speakerMatches = $true
                    break
                }
            }
            if (-not $speakerMatches) { continue }
        }

        $j = @()
        if ($jassIndex.ContainsKey($key)) { $j = @($jassIndex[$key]) }
        $e = @()
        if ($excelIndex.ContainsKey($key)) { $e = @($excelIndex[$key]) }
        $texts = @($j | Where-Object { -not [string]::IsNullOrWhiteSpace($_.text) } | ForEach-Object { $_.text } | Sort-Object -Unique)
        $excelTexts = @($e | Where-Object { -not [string]::IsNullOrWhiteSpace($_.text) } | ForEach-Object { $_.text } | Sort-Object -Unique)
        $expectedFolders = @($j | Where-Object { -not [string]::IsNullOrWhiteSpace($_.expected_folder) } | ForEach-Object { $_.expected_folder } | Sort-Object -Unique)
        $definitionIds = @($j | Where-Object { $_.row_type -ne "registration" } | ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_.definition_id)) { $_.definition_id } else { "$($_.source)|$($_.text)" }
        } | Sort-Object -Unique)
        if ($expectedFolders.Count -eq 0) { $expectedFolders = @(Get-ExpectedFolderForKey $key) }
        $masterPaths = @()
        if ($masterIndex.ContainsKey($key)) { $masterPaths = @($masterIndex[$key]) }
        $tempPaths = @()
        if ($tempIndex.ContainsKey($key)) { $tempPaths = @($tempIndex[$key]) }

        $folderMismatch = $false
        if ($masterPaths.Count -gt 0 -and $expectedFolders.Count -gt 0) {
            foreach ($path in $masterPaths) {
                $actualFolder = Split-Path -Parent $path
                if ($expectedFolders -notcontains $actualFolder) { $folderMismatch = $true }
            }
        }

        $scanRows.Add([pscustomobject]@{
            key = $key
            speaker = Get-KeyPrefix $key
            file_name = "$key.$Format"
            text = ($texts -join " || ")
            expected_folder = ($expectedFolders -join " || ")
            present_in_master = ($masterPaths.Count -gt 0)
            pending_review = ($tempPaths.Count -gt 0)
            missing_audio = ($j.Count -gt 0 -and $masterPaths.Count -eq 0 -and $tempPaths.Count -eq 0)
            excel_only = ($e.Count -gt 0 -and $j.Count -eq 0 -and $excelTexts.Count -gt 0)
            excel_only_blank_text = ($e.Count -gt 0 -and $j.Count -eq 0 -and $excelTexts.Count -eq 0)
            jass_only = ($j.Count -gt 0 -and $e.Count -eq 0)
            duplicate_key = ($definitionIds.Count -gt 1)
            duplicate_text_variants = ($texts.Count -gt 1)
            orphan_audio = ($masterPaths.Count -gt 0 -and $j.Count -eq 0 -and $e.Count -eq 0)
            folder_mismatch = $folderMismatch
            master_paths = ($masterPaths -join " || ")
            temp_paths = ($tempPaths -join " || ")
            jass_sources = (@($j | ForEach-Object { $_.source } | Sort-Object -Unique) -join " || ")
            excel_sources = (@($e | ForEach-Object { $_.source } | Sort-Object -Unique) -join " || ")
            excel_text = ($excelTexts -join " || ")
        })
    }

    return $scanRows
}

function Get-RequiredEnvironmentValue {
    param([string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) { throw "$Name is not set." }
    return $value
}

function Get-ReferenceIdForRow {
    param([object]$Row)
    $envName = "FISH_REFERENCE_ID_" + (($Row.speaker -replace "[^A-Za-z0-9]", "_").ToUpperInvariant())
    $specific = [Environment]::GetEnvironmentVariable($envName)
    if (-not [string]::IsNullOrWhiteSpace($specific)) { return $specific }
    if (-not [string]::IsNullOrWhiteSpace($ReferenceId)) { return $ReferenceId }
    throw "Missing Fish reference id. Set -ReferenceId, FISH_REFERENCE_ID, or $envName."
}

function Invoke-FishTextToSpeech {
    param([string]$ApiKey, [string]$Text, [string]$OutputPath, [string]$VoiceReferenceId)

    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "model" = $Model
    }
    $payload = @{
        text = $Text
        reference_id = $VoiceReferenceId
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
            if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
            Invoke-WebRequest -Uri "https://api.fish.audio/v1/tts" -Method Post -Headers $headers -ContentType "application/json" -Body $payload -OutFile $tempPath -TimeoutSec 180
            Move-Item -LiteralPath $tempPath -Destination $OutputPath -Force
            return
        }
        catch {
            if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
            if ($attempt -eq $Retries) { throw }
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }
}

$scanRows = @(Build-ScanRows)
$manifestDir = Split-Path -Parent $Manifest
if (-not [string]::IsNullOrWhiteSpace($manifestDir)) {
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
}
$scanRows | Export-Csv -LiteralPath $Manifest -NoTypeInformation -Encoding UTF8

$summary = [pscustomobject]@{
    total_rows = $scanRows.Count
    present_in_master = @($scanRows | Where-Object { $_.present_in_master }).Count
    pending_review = @($scanRows | Where-Object { $_.pending_review }).Count
    missing_audio = @($scanRows | Where-Object { $_.missing_audio }).Count
    excel_only = @($scanRows | Where-Object { $_.excel_only }).Count
    excel_only_blank_text = @($scanRows | Where-Object { $_.excel_only_blank_text }).Count
    jass_only = @($scanRows | Where-Object { $_.jass_only }).Count
    duplicate_text_variants = @($scanRows | Where-Object { $_.duplicate_text_variants }).Count
    orphan_audio = @($scanRows | Where-Object { $_.orphan_audio }).Count
    folder_mismatch = @($scanRows | Where-Object { $_.folder_mismatch }).Count
}

Write-Host "Scan report: $Manifest"
$summary | Format-List

if ($Mode -eq "Scan") {
    exit 0
}

$ambiguousRows = @($scanRows | Where-Object { $_.duplicate_text_variants -and -not $_.present_in_master -and -not [string]::IsNullOrWhiteSpace($_.text) })
if ($ambiguousRows.Count -gt 0) {
    Write-Warning "Skipping $($ambiguousRows.Count) missing rows with duplicate text variants. Resolve them in JASS/Excel before generation."
}

$generationRows = @($scanRows | Where-Object {
    (-not $_.present_in_master -or $Force) `
        -and (-not $_.pending_review -or $Force) `
        -and -not $_.duplicate_text_variants `
        -and -not [string]::IsNullOrWhiteSpace($_.text) `
        -and -not [string]::IsNullOrWhiteSpace($_.jass_sources)
})
if ($Keys.Count -gt 0) {
    $keySet = @{}
    foreach ($requestedKey in $Keys) {
        $keySet[$requestedKey] = $true
        if ($scanRows.key -notcontains $requestedKey) {
            throw "Requested voiceline key was not found: $requestedKey"
        }
    }
    $generationRows = @($generationRows | Where-Object { $keySet.ContainsKey($_.key) })
}
if ($MaxCount -gt 0) { $generationRows = @($generationRows | Select-Object -First $MaxCount) }

if ($DryRun) {
    $generationRows | Select-Object key, expected_folder, file_name, text | Format-Table -AutoSize
    Write-Host "Dry run complete. No audio files were generated."
    exit 0
}

$apiKey = Get-RequiredEnvironmentValue -Name "FISH_API_KEY"
$generated = 0
$skipped = 0
foreach ($row in $generationRows) {
    $folder = @($row.expected_folder -split " \\|\\| " | Sort-Object Length -Descending)[0]
    $outputDir = Join-Path $TempRoot $folder
    $outputPath = Join-Path $outputDir $row.file_name
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

    if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
        Write-Host "skip review-existing $($row.file_name)"
        $skipped++
        continue
    }

    Write-Host "generate review $($row.file_name)"
    Invoke-FishTextToSpeech -ApiKey $apiKey -Text $row.text -OutputPath $outputPath -VoiceReferenceId (Get-ReferenceIdForRow -Row $row)
    $generated++

    if ($DelaySeconds -gt 0) {
        Start-Sleep -Milliseconds ([int]($DelaySeconds * 1000))
    }
}

Write-Host "Done. Generated: $generated. Skipped: $skipped. Review root: $TempRoot"
