param(
    [string]$ExcelPath = "Voicelines/_oldExcel/VoicelinesMaster.xlsx",
    [string]$VoicelinesRoot = "Voicelines",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

$SpeakerDefinitions = @(
    [pscustomobject]@{ Name = "Aradion"; Folder = "AradionFarseer"; File = "Voicelines_Aradion.j"; Library = "VoicelinesAradion"; Const = "ARADION"; KeyPrefixes = @("Aradion") },
    [pscustomobject]@{ Name = "AtexBlix"; Folder = "AtexBlix"; File = "Voicelines_AtexBlix.j"; Library = "VoicelinesAtexBlix"; Const = "ATEXBLIX"; KeyPrefixes = @("AtexBlix") },
    [pscustomobject]@{ Name = "Aveline"; Folder = "Aveline"; File = "Voicelines_Aveline.j"; Library = "VoicelinesAveline"; Const = "AVELINE"; KeyPrefixes = @("Aveline") },
    [pscustomobject]@{ Name = "BoomBrothers"; Folder = "BoomBrothers"; File = "Voicelines_BoomBrothers.j"; Library = "VoicelinesBoomBrothers"; Const = "BOOMBROTHERS"; KeyPrefixes = @("Boomers", "BoomBrothers") },
    [pscustomobject]@{ Name = "DarkShaman"; Folder = "DarkShaman"; File = "Voicelines_DarkShaman.j"; Library = "VoicelinesDarkShaman"; Const = "DARKSHAMAN"; KeyPrefixes = @("DarkShaman") },
    [pscustomobject]@{ Name = "Demoness"; Folder = "Demoness"; File = "Voicelines_Demoness.j"; Library = "VoicelinesDemoness"; Const = "DEMONESS"; KeyPrefixes = @("Demoness") },
    [pscustomobject]@{ Name = "Garthork"; Folder = "Garthork"; File = "Voicelines_Garthork.j"; Library = "VoicelinesGarthork"; Const = "GARTHORK"; KeyPrefixes = @("Garthork") },
    [pscustomobject]@{ Name = "Granis"; Folder = "Granis"; File = "Voicelines_Granis.j"; Library = "VoicelinesGranis"; Const = "GRANIS"; KeyPrefixes = @("Granis") },
    [pscustomobject]@{ Name = "GrumBloodfang"; Folder = "GrumBloodfang"; File = "Voicelines_GrumBloodfang.j"; Library = "VoicelinesGrumBloodfang"; Const = "GRUMBLOODFANG"; KeyPrefixes = @("GrumBloodfang") },
    [pscustomobject]@{ Name = "GrumBloodfangOld"; Folder = "GrumBloodfangOld"; File = "Voicelines_GrumBloodfangOld.j"; Library = "VoicelinesGrumBloodfangOld"; Const = "GRUMBLOODFANGOLD"; KeyPrefixes = @() },
    [pscustomobject]@{ Name = "Engineer"; Folder = "HeroEngineer"; File = "Voicelines_Engineer.j"; Library = "VoicelinesEngineer"; Const = "ENGINEER"; KeyPrefixes = @("HeroEngineer") },
    [pscustomobject]@{ Name = "Paladin"; Folder = "HeroPaladin"; File = "Voicelines_Paladin.j"; Library = "VoicelinesPaladin"; Const = "PALADIN"; KeyPrefixes = @("HeroPaladin") },
    [pscustomobject]@{ Name = "RestoShaman"; Folder = "HeroRestoshaman"; File = "Voicelines_RestoShaman.j"; Library = "VoicelinesRestoShaman"; Const = "RESTOSHAMAN"; KeyPrefixes = @("HeroRestoshaman", "HeroShaman") },
    [pscustomobject]@{ Name = "Rogue"; Folder = "HeroRogue"; File = "Voicelines_Rogue.j"; Library = "VoicelinesRogue"; Const = "ROGUE"; KeyPrefixes = @("HeroRogue") },
    [pscustomobject]@{ Name = "Warlock"; Folder = "HeroWarlock"; File = "Voicelines_Warlock.j"; Library = "VoicelinesWarlock"; Const = "WARLOCK"; KeyPrefixes = @("HeroWarlock") },
    [pscustomobject]@{ Name = "UndeadWarlock"; Folder = "HeroWarlock"; File = "Voicelines_UndeadWarlock.j"; Library = "VoicelinesUndeadWarlock"; Const = "UNDEADWARLOCK"; KeyPrefixes = @("HeroUndeadWarlock") },
    [pscustomobject]@{ Name = "Warrior"; Folder = "HeroWarrior"; File = "Voicelines_Warrior.j"; Library = "VoicelinesWarrior"; Const = "WARRIOR"; KeyPrefixes = @("HeroWarrior") },
    [pscustomobject]@{ Name = "HumanFemale1"; Folder = "HumanFemale1"; File = "Voicelines_HumanFemale1.j"; Library = "VoicelinesHumanFemale1"; Const = "HUMANFEMALE1"; KeyPrefixes = @("HumanFemale1") },
    [pscustomobject]@{ Name = "Jinzun"; Folder = "Jinzun"; File = "Voicelines_Jinzun.j"; Library = "VoicelinesJinzun"; Const = "JINZUN"; KeyPrefixes = @("Jinzun") },
    [pscustomobject]@{ Name = "Kaelthir"; Folder = "Kaelthir"; File = "Voicelines_Kaelthir.j"; Library = "VoicelinesKaelthir"; Const = "KAELTHIR"; KeyPrefixes = @("Kaelthir") },
    [pscustomobject]@{ Name = "Kribugs"; Folder = "Kribugs"; File = "Voicelines_Kribugs.j"; Library = "VoicelinesKribugs"; Const = "KRIBUGS"; KeyPrefixes = @("Kribugs") },
    [pscustomobject]@{ Name = "Krezgrel"; Folder = "Krezgrel"; File = "Voicelines_Krezgrel.j"; Library = "VoicelinesKrezgrel"; Const = "KREZGREL"; KeyPrefixes = @("Krezgrel") },
    [pscustomobject]@{ Name = "Mordrax"; Folder = "Mordrax"; File = "Voicelines_Mordrax.j"; Library = "VoicelinesMordrax"; Const = "MORDRAX"; KeyPrefixes = @("Mordrax") },
    [pscustomobject]@{ Name = "Narrator"; Folder = "Narrator"; File = "Voicelines_Narrator.j"; Library = "VoicelinesNarrator"; Const = "NARRATOR"; KeyPrefixes = @("Narrator") },
    [pscustomobject]@{ Name = "Nazgrek"; Folder = "Nazgrek"; File = "Voicelines_Nazgrek.j"; Library = "VoicelinesNazgrek"; Const = "NAZGREK"; KeyPrefixes = @("Nazgrek") },
    [pscustomobject]@{ Name = "OrcGrunt"; Folder = "Orc Grunt"; File = "Voicelines_OrcGrunt.j"; Library = "VoicelinesOrcGrunt"; Const = "ORCGRUNT"; KeyPrefixes = @("OrcGrunt") },
    [pscustomobject]@{ Name = "OrcPeon"; Folder = "Orc Peon"; File = "Voicelines_OrcPeon.j"; Library = "VoicelinesOrcPeon"; Const = "ORCPEON"; KeyPrefixes = @("OrcPeon", "Peon") },
    [pscustomobject]@{ Name = "OrcQGiver"; Folder = "OrcQGiver"; File = "Voicelines_OrcQGiver.j"; Library = "VoicelinesOrcQGiver"; Const = "ORCQGIVER"; KeyPrefixes = @("OrcQGiver", "XXX") },
    [pscustomobject]@{ Name = "Satyr"; Folder = "Satyr"; File = "Voicelines_Satyr.j"; Library = "VoicelinesSatyr"; Const = "SATYR"; KeyPrefixes = @("Satyr") },
    [pscustomobject]@{ Name = "Serenthia"; Folder = "Serenthia"; File = "Voicelines_Serenthia.j"; Library = "VoicelinesSerenthia"; Const = "SERENTHIA"; KeyPrefixes = @("Serenthia") },
    [pscustomobject]@{ Name = "Shipmaster"; Folder = "Shipmaster"; File = "Voicelines_Shipmaster.j"; Library = "VoicelinesShipmaster"; Const = "SHIPMASTER"; KeyPrefixes = @("Shipmaster") },
    [pscustomobject]@{ Name = "Thork"; Folder = "Thork"; File = "Voicelines_Thork.j"; Library = "VoicelinesThork"; Const = "THORK"; KeyPrefixes = @("Thork") },
    [pscustomobject]@{ Name = "Valeria"; Folder = "Valeria"; File = "Voicelines_Valeria.j"; Library = "VoicelinesValeria"; Const = "VALERIA"; KeyPrefixes = @("Valeria") },
    [pscustomobject]@{ Name = "VoidEntity"; Folder = "VoidEntity"; File = "Voicelines_VoidEntity.j"; Library = "VoicelinesVoidEntity"; Const = "VOIDENTITY"; KeyPrefixes = @("VoidEntity") },
    [pscustomobject]@{ Name = "Zulkis"; Folder = "Zulkis"; File = "Voicelines_Zulkis.j"; Library = "VoicelinesZulkis"; Const = "ZULKIS"; KeyPrefixes = @("Zulkis") }
)

function ConvertFrom-ExcelValue {
    param([object]$Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Trim()
}

function ConvertTo-AsciiText {
    param([string]$Value)
    if ($null -eq $Value) { return "" }
    $result = $Value
    $result = $result.Replace([string][char]0x00A0, " ")
    $result = $result.Replace([string][char]0x2018, "'").Replace([string][char]0x2019, "'")
    $result = $result.Replace([string][char]0x201C, '"').Replace([string][char]0x201D, '"')
    $result = $result.Replace([string][char]0x2013, "-").Replace([string][char]0x2014, "-")
    $result = $result.Replace([string][char]0x2026, "...")
    $result = $result.Replace([string][char]0x00B4, "'")
    $result = $result -replace "\s+", " "
    return $result.Trim()
}

function ConvertTo-JassString {
    param([string]$Value)
    $result = ConvertTo-AsciiText $Value
    $result = $result.Replace("\", "\\")
    $result = $result.Replace('"', '\"')
    return $result
}

function ConvertTo-CommentText {
    param([string]$Value)
    $result = ConvertTo-AsciiText $Value
    if ($result.Length -gt 180) {
        $result = $result.Substring(0, 177).TrimEnd() + "..."
    }
    return $result
}

function ConvertTo-Identifier {
    param([string]$Value)
    $result = ($Value.ToUpperInvariant() -replace "[^A-Z0-9]+", "_").Trim("_")
    $result = $result -replace "_+", "_"
    if ([string]::IsNullOrWhiteSpace($result)) { return "LINE" }
    return $result
}

function Get-VoicelineKey {
    param([string]$FileName)
    if ([string]::IsNullOrWhiteSpace($FileName)) { return "" }
    $name = $FileName.Replace("/", "\")
    $name = [IO.Path]::GetFileNameWithoutExtension($name)
    return $name.Trim()
}

function ConvertTo-CanonicalVoicelineKey {
    param([string]$Key)
    if ($Key -match "^Peon_(.+)$") {
        return "OrcPeon_" + $matches[1]
    }
    return $Key
}

function Get-KeyPrefix {
    param([string]$Key)
    if ($Key -match "^([^_]+)_") { return $matches[1] }
    if ($Key -match "^(Boomers)") { return "Boomers" }
    return $Key
}

function Read-ZipText {
    param(
        [IO.Compression.ZipArchive]$Zip,
        [string]$Name
    )
    $entry = $Zip.GetEntry($Name)
    if ($null -eq $entry) { return $null }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

function Read-VoicelineExcelRows {
    param([string]$Path)

    $rows = [System.Collections.Generic.List[object]]::new()
    if (-not (Test-Path -LiteralPath $Path)) { throw "Excel workbook not found: $Path" }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path))
    try {
        [xml]$workbook = Read-ZipText -Zip $zip -Name "xl/workbook.xml"
        [xml]$rels = Read-ZipText -Zip $zip -Name "xl/_rels/workbook.xml.rels"
        [xml]$shared = Read-ZipText -Zip $zip -Name "xl/sharedStrings.xml"
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
        $sheetOrder = 0
        foreach ($sheet in $workbook.SelectNodes("//d:sheet", $ns)) {
            $sheetOrder++
            $rid = $sheet.GetAttribute("id", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
            $rel = $rels.Relationships.Relationship | Where-Object { $_.Id -eq $rid }
            if ($null -eq $rel) { continue }

            $target = "xl/" + $rel.Target.TrimStart("/")
            [xml]$ws = Read-ZipText -Zip $zip -Name $target
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

                $fields = @{
                    "File Name" = ""
                    "Text" = ""
                    "Related quest" = ""
                    "Related Event" = ""
                    "Done" = ""
                    "Comment" = ""
                }
                foreach ($col in $cellValues.Keys) {
                    if ($headerByColumn.ContainsKey($col)) {
                        $fields[$headerByColumn[$col]] = $cellValues[$col]
                    }
                }

                $originalKey = Get-VoicelineKey $fields["File Name"]
                if ([string]::IsNullOrWhiteSpace($originalKey)) { continue }
                $key = ConvertTo-CanonicalVoicelineKey $originalKey

                $rows.Add([pscustomobject]@{
                    Key = $key
                    OriginalKey = $originalKey
                    Text = ConvertTo-AsciiText $fields["Text"]
                    FileName = $fields["File Name"]
                    Sheet = [string]$sheet.name
                    SheetOrder = $sheetOrder
                    RowNumber = [int]$row.r
                    RelatedQuest = ConvertTo-AsciiText $fields["Related quest"]
                    RelatedEvent = ConvertTo-AsciiText $fields["Related Event"]
                    Done = ConvertTo-AsciiText $fields["Done"]
                    Comment = ConvertTo-AsciiText $fields["Comment"]
                })
            }
        }
    }
    finally {
        $zip.Dispose()
    }

    return $rows
}

function Get-ExistingVoicelineKeys {
    param([string]$Root)
    $keys = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Root -Filter "Voicelines_*.j" -File -ErrorAction SilentlyContinue) {
        $text = [IO.File]::ReadAllText($file.FullName)
        foreach ($m in [regex]::Matches($text, 'constant\s+string\s+VL_[A-Z0-9_]+_KEY\s*=\s*"((?:[^"\\]|\\.)*)"')) {
            $key = $m.Groups[1].Value.Replace('\"', '"').Replace('\\', '\')
            $keys[$key] = $true
        }
    }
    return $keys
}

function Get-SpeakerNameForKey {
    param([string]$Key)

    if ($Key -match "Aveline$" -and $Key -notmatch "^Aveline_") {
        return "Aveline"
    }
    if ($Key -match "^(Hero[A-Za-z]+_Chat.+?)UndeadWarlock$") {
        return "UndeadWarlock"
    }
    if ($Key -match "^(Hero[A-Za-z]+_Chat.+?)(Engineer|Paladin|Rogue|Shaman|Warlock|Warrior)$") {
        if ($matches[2] -eq "Shaman") { return "RestoShaman" }
        return $matches[2]
    }

    $prefix = Get-KeyPrefix $Key
    foreach ($def in $SpeakerDefinitions) {
        if ($def.KeyPrefixes -contains $prefix) {
            return $def.Name
        }
    }
    return ""
}

function Get-ConstantBase {
    param(
        [object]$Speaker,
        [string]$Key,
        [hashtable]$UsedBases
    )

    $keyPart = $Key
    $isReply = $false
    if ($Key -match "Aveline$" -and $Key -notmatch "^Aveline_") {
        $isReply = $true
    }
    if ($Key -match "^(Hero[A-Za-z]+_Chat.+?)(Engineer|Paladin|Rogue|Shaman|Warlock|Warrior|UndeadWarlock)$") {
        $isReply = $true
    }

    if ($isReply) {
        $keyPart = "Reply_" + $Key
    }
    else {
        foreach ($prefix in $Speaker.KeyPrefixes) {
            $start = $prefix + "_"
            if ($Key.StartsWith($start) -and $prefix -notmatch "^Hero" -and $prefix -ne "Aveline") {
                $keyPart = $Key.Substring($start.Length)
                break
            }
        }
    }

    $base = "VL_" + $Speaker.Const + "_" + (ConvertTo-Identifier $keyPart)
    $candidate = $base
    $index = 2
    while ($UsedBases.ContainsKey($candidate)) {
        $candidate = $base + "_" + $index
        $index++
    }
    $UsedBases[$candidate] = $true
    return $candidate
}

function Get-MetadataComment {
    param([object[]]$Rows)

    $first = @($Rows | Sort-Object SheetOrder, RowNumber | Select-Object -First 1)[0]
    $parts = [System.Collections.Generic.List[string]]::new()
    $parts.Add("Excel draft: $($first.Sheet)")
    $originalKeys = @($Rows | Where-Object { $_.OriginalKey -ne $_.Key } | ForEach-Object { $_.OriginalKey } | Select-Object -Unique)
    if ($originalKeys.Count -gt 0) { $parts.Add("Excel file: $($originalKeys -join ', ')") }
    if (-not [string]::IsNullOrWhiteSpace($first.RelatedQuest)) { $parts.Add("Quest: $($first.RelatedQuest)") }
    if (-not [string]::IsNullOrWhiteSpace($first.RelatedEvent)) { $parts.Add("Event: $($first.RelatedEvent)") }
    if (-not [string]::IsNullOrWhiteSpace($first.Done)) { $parts.Add("Done: $($first.Done)") }
    if (-not [string]::IsNullOrWhiteSpace($first.Comment)) { $parts.Add("Comment: $($first.Comment)") }
    return ConvertTo-CommentText ($parts -join " | ")
}

function New-ConstantBlock {
    param(
        [object]$Speaker,
        [object[]]$Rows,
        [string]$Title
    )

    if ($Rows.Count -eq 0) { return "" }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("")
    $lines.Add("    // $Title")
    $usedBases = @{}
    $lastComment = ""

    $groups = @($Rows | Group-Object Key | Sort-Object {
        @($_.Group | Sort-Object SheetOrder, RowNumber | Select-Object -First 1)[0].SheetOrder
    }, {
        @($_.Group | Sort-Object SheetOrder, RowNumber | Select-Object -First 1)[0].RowNumber
    }, Name)

    foreach ($group in $groups) {
        $groupRows = @($group.Group | Sort-Object SheetOrder, RowNumber)
        $comment = Get-MetadataComment $groupRows
        if ($comment -ne $lastComment) {
            $lines.Add("")
            $lines.Add("    // $comment")
            $lastComment = $comment
        }

        $base = Get-ConstantBase -Speaker $Speaker -Key $group.Name -UsedBases $usedBases
        $lines.Add("    constant string $($base)_KEY = ""$(ConvertTo-JassString $group.Name)""")

        $texts = @($groupRows | ForEach-Object { $_.Text } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
        if ($texts.Count -eq 0) {
            $lines.Add("    constant string $($base)_TEXT = """"")
        }
        else {
            $textIndex = 0
            foreach ($lineText in $texts) {
                if ($textIndex -eq 0) {
                    $lines.Add("    constant string $($base)_TEXT = ""$(ConvertTo-JassString $lineText)""")
                }
                else {
                    $lines.Add("    constant string $($base)_TEXT_ALT$($textIndex) = ""$(ConvertTo-JassString $lineText)""")
                }
                $textIndex++
            }
        }
    }

    $lines.Add("")
    return ($lines -join [Environment]::NewLine)
}

function New-SpeakerLibraryText {
    param(
        [object]$Speaker,
        [object[]]$Rows
    )

    $api = "Global ``VL_$($Speaker.Const)_*`` constants."
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("/**")
    $lines.Add("    $($Speaker.Library)")
    $lines.Add("")
    $lines.Add("    Author: Valdemar")
    $lines.Add("    Version:")
    $lines.Add("")
    $lines.Add("    Description:")
    $lines.Add("    Speaker-owned voiceline key/text constants migrated from legacy")
    $lines.Add("    Excel draft/reference rows. Runtime consumers require this")
    $lines.Add("    library directly when they need these constants.")
    $lines.Add("")
    $lines.Add("    Credits:")
    $lines.Add("    - Voicelines/_oldExcel/VoicelinesMaster.xlsx")
    $lines.Add("")
    $lines.Add("    How to install:")
    $lines.Add("    Import after ``Voicelines.j``. Add runtime registration when a")
    $lines.Add("    consumer starts using these constants.")
    $lines.Add("")
    $lines.Add("    API:")
    $lines.Add("    $api")
    $lines.Add("")
    $lines.Add("**/")
    $lines.Add("library $($Speaker.Library) requires Voicelines")
    $lines.Add("")
    $lines.Add("globals")
    $lines.Add("    constant string VL_$($Speaker.Const)_FOLDER = ""$($Speaker.Folder)""")

    $block = New-ConstantBlock -Speaker $Speaker -Rows $Rows -Title "Legacy Excel draft/reference rows."
    if ([string]::IsNullOrWhiteSpace($block)) {
        $lines.Add("")
        $lines.Add("    // No Excel draft rows were mapped to this speaker yet.")
    }
    else {
        $lines.Add($block.TrimEnd())
    }

    $lines.Add("endglobals")
    $lines.Add("")
    $lines.Add("endlibrary")
    $lines.Add("")
    return ($lines -join [Environment]::NewLine)
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Text
    )
    $encoding = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path -Parent $Path)).Path + "\" + (Split-Path -Leaf $Path), $Text, $encoding)
}

$speakerByName = @{}
foreach ($def in $SpeakerDefinitions) {
    $speakerByName[$def.Name] = $def
}

$excelRows = @(Read-VoicelineExcelRows -Path $ExcelPath)
$existingKeys = Get-ExistingVoicelineKeys -Root $VoicelinesRoot
$rowsBySpeaker = @{}
$skippedNoSpeaker = 0
$skippedExisting = 0
$skippedNoText = 0

foreach ($row in $excelRows) {
    if ([string]::IsNullOrWhiteSpace($row.Text)) {
        $skippedNoText++
        continue
    }
    $speakerName = Get-SpeakerNameForKey -Key $row.Key
    if ([string]::IsNullOrWhiteSpace($speakerName) -or -not $speakerByName.ContainsKey($speakerName)) {
        $skippedNoSpeaker++
        continue
    }
    if ($existingKeys.ContainsKey($row.Key)) {
        $skippedExisting++
        continue
    }
    if (-not $rowsBySpeaker.ContainsKey($speakerName)) {
        $rowsBySpeaker[$speakerName] = [System.Collections.Generic.List[object]]::new()
    }
    $rowsBySpeaker[$speakerName].Add($row)
}

$created = 0
$updated = 0
$unchanged = 0
$importedRows = 0

foreach ($speaker in $SpeakerDefinitions) {
    $path = Join-Path $VoicelinesRoot $speaker.File
    $speakerRows = @()
    if ($rowsBySpeaker.ContainsKey($speaker.Name)) {
        $speakerRows = @($rowsBySpeaker[$speaker.Name])
    }
    $importedRows += $speakerRows.Count

    if (Test-Path -LiteralPath $path) {
        if ($speakerRows.Count -eq 0) {
            $unchanged++
            continue
        }
        $content = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $path).Path)
        $block = New-ConstantBlock -Speaker $speaker -Rows $speakerRows -Title "Legacy Excel draft/reference rows not yet wired to active code."
        if ($content -notmatch "(?m)^endglobals\s*$") {
            throw "Could not find endglobals in $path"
        }
        $newContent = [regex]::Replace($content, "(?m)^endglobals\s*$", ($block + "endglobals" + [Environment]::NewLine), 1)
        if ($Apply) {
            $encoding = [Text.UTF8Encoding]::new($false)
            [IO.File]::WriteAllText((Resolve-Path -LiteralPath $path).Path, $newContent, $encoding)
        }
        $updated++
    }
    else {
        $newContent = New-SpeakerLibraryText -Speaker $speaker -Rows $speakerRows
        if ($Apply) {
            $fullPath = Join-Path (Resolve-Path -LiteralPath $VoicelinesRoot).Path $speaker.File
            $encoding = [Text.UTF8Encoding]::new($false)
            [IO.File]::WriteAllText($fullPath, $newContent, $encoding)
        }
        $created++
    }
}

[pscustomobject]@{
    mode = $(if ($Apply) { "Apply" } else { "DryRun" })
    excel_rows = $excelRows.Count
    imported_rows = $importedRows
    skipped_existing_jass = $skippedExisting
    skipped_no_text = $skippedNoText
    skipped_no_speaker_mapping = $skippedNoSpeaker
    libraries_created = $created
    libraries_updated = $updated
    libraries_unchanged = $unchanged
} | Format-List

if (-not $Apply) {
    Write-Host "Dry run only. Re-run with -Apply to write JASS files."
}
