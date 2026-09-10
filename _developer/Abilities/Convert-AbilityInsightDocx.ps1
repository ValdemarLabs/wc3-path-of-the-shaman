param(
    [string]$SourcePath = (Join-Path $PSScriptRoot 'Warcraft 3 WE Ability Insight.docx'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'Warcraft 3 WE Ability Insight.md')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$script:WordNamespace = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
$script:RelationshipNamespace = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
$script:Comments = @{}
$script:CommentContexts = @{}
$script:DocumentRelationships = @{}

function Get-ZipEntryText {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Name,
        [switch]$Optional
    )

    $entry = $Archive.GetEntry($Name)
    if ($null -eq $entry) {
        if ($Optional) {
            return $null
        }
        throw "Required DOCX part is missing: $Name"
    }

    $reader = [System.IO.StreamReader]::new($entry.Open())
    try {
        return $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

function Get-WordAttribute {
    param(
        [System.Xml.XmlNode]$Node,
        [string]$Name
    )

    if ($null -eq $Node) {
        return ''
    }
    return $Node.GetAttribute($Name, $script:WordNamespace)
}

function Test-EnabledProperty {
    param([System.Xml.XmlNode]$Node)

    if ($null -eq $Node) {
        return $false
    }
    $value = Get-WordAttribute $Node 'val'
    return $value -notin @('0', 'false', 'off', 'none')
}

function ConvertTo-MarkdownText {
    param([AllowEmptyString()][string]$Text)

    if ($null -eq $Text) {
        return ''
    }

    $escaped = $Text.Replace('\', '\\')
    $escaped = $escaped.Replace('*', '\*').Replace('_', '\_')
    $escaped = $escaped.Replace('[', '\[').Replace(']', '\]')
    $escaped = $escaped.Replace('<', '&lt;').Replace('>', '&gt;')
    return $escaped
}

function ConvertTo-LinkTarget {
    param([string]$Target)

    return $Target.Replace(' ', '%20').Replace('(', '%28').Replace(')', '%29')
}

function Get-PlainText {
    param(
        [System.Xml.XmlNode]$Node,
        [System.Xml.XmlNamespaceManager]$NamespaceManager,
        [switch]$IncludeDeleted
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($child in $Node.ChildNodes) {
        switch ($child.LocalName) {
            't' { $parts.Add($child.InnerText) }
            'delText' { if ($IncludeDeleted) { $parts.Add($child.InnerText) } }
            'tab' { $parts.Add("`t") }
            'br' { $parts.Add("`n") }
            'del' { if ($IncludeDeleted) { $parts.Add((Get-PlainText $child $NamespaceManager -IncludeDeleted)) } }
            default {
                if ($child.HasChildNodes) {
                    $parts.Add((Get-PlainText $child $NamespaceManager -IncludeDeleted:$IncludeDeleted))
                }
            }
        }
    }
    return ($parts -join '')
}

function Convert-Run {
    param(
        [System.Xml.XmlNode]$Run,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($child in $Run.ChildNodes) {
        switch ($child.LocalName) {
            't' { $parts.Add((ConvertTo-MarkdownText $child.InnerText)) }
            'delText' { $parts.Add((ConvertTo-MarkdownText $child.InnerText)) }
            'tab' { $parts.Add('    ') }
            'br' { $parts.Add('<br>') }
            'noBreakHyphen' { $parts.Add('-') }
            'softHyphen' { $parts.Add('&shy;') }
            'commentReference' {
                $id = Get-WordAttribute $child 'id'
                $parts.Add("<sup>[comment $id](#comment-$id)</sup>")
            }
        }
    }

    $text = $parts -join ''
    if (-not $text) {
        return ''
    }

    $properties = $Run.SelectSingleNode('./w:rPr', $NamespaceManager)
    if ($null -ne $properties) {
        if (Test-EnabledProperty ($properties.SelectSingleNode('./w:b', $NamespaceManager))) {
            $text = "**$text**"
        }
        if (Test-EnabledProperty ($properties.SelectSingleNode('./w:i', $NamespaceManager))) {
            $text = "*$text*"
        }
        if ((Test-EnabledProperty ($properties.SelectSingleNode('./w:strike', $NamespaceManager))) -or
            (Test-EnabledProperty ($properties.SelectSingleNode('./w:dstrike', $NamespaceManager)))) {
            $text = "~~$text~~"
        }

        $vertical = Get-WordAttribute ($properties.SelectSingleNode('./w:vertAlign', $NamespaceManager)) 'val'
        if ($vertical -eq 'superscript') {
            $text = "<sup>$text</sup>"
        }
        elseif ($vertical -eq 'subscript') {
            $text = "<sub>$text</sub>"
        }
    }

    return $text
}

function Convert-InlineNode {
    param(
        [System.Xml.XmlNode]$Node,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )

    switch ($Node.LocalName) {
        'r' { return Convert-Run $Node $NamespaceManager }
        'hyperlink' {
            $label = Convert-Container $Node $NamespaceManager
            $relationshipId = $Node.GetAttribute('id', $script:RelationshipNamespace)
            $anchor = Get-WordAttribute $Node 'anchor'
            if ($relationshipId -and $script:DocumentRelationships.ContainsKey($relationshipId)) {
                return "[$label]($(ConvertTo-LinkTarget $script:DocumentRelationships[$relationshipId]))"
            }
            if ($anchor) {
                return "[$label](#$anchor)"
            }
            return $label
        }
        'ins' { return Convert-Container $Node $NamespaceManager }
        'del' {
            $deleted = Convert-Container $Node $NamespaceManager
            if ($deleted) {
                return "<del>$deleted</del>"
            }
            return ''
        }
        'sdt' { return Convert-Container $Node $NamespaceManager }
        'smartTag' { return Convert-Container $Node $NamespaceManager }
        'fldSimple' {
            $label = Convert-Container $Node $NamespaceManager
            $instruction = Get-WordAttribute $Node 'instr'
            if ($instruction -match 'HYPERLINK\s+"([^"]+)"') {
                return "[$label]($(ConvertTo-LinkTarget $Matches[1]))"
            }
            return $label
        }
        default {
            if ($Node.HasChildNodes) {
                return Convert-Container $Node $NamespaceManager
            }
            return ''
        }
    }
}

function Convert-Container {
    param(
        [System.Xml.XmlNode]$Node,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )

    $parts = [System.Collections.Generic.List[string]]::new()
    $fieldParts = [System.Collections.Generic.List[string]]::new()
    $fieldActive = $false
    $fieldResult = $false
    $fieldTarget = ''
    foreach ($child in $Node.ChildNodes) {
        if ($child.LocalName -in @('pPr', 'rPr', 'bookmarkStart', 'bookmarkEnd', 'commentRangeStart', 'commentRangeEnd', 'proofErr')) {
            continue
        }

        if ($child.LocalName -eq 'r') {
            $fieldCharacter = $child.SelectSingleNode('./w:fldChar', $NamespaceManager)
            if ($null -ne $fieldCharacter) {
                $fieldType = Get-WordAttribute $fieldCharacter 'fldCharType'
                if ($fieldType -eq 'begin') {
                    $fieldActive = $true
                    $fieldResult = $false
                    $fieldTarget = ''
                    $fieldParts.Clear()
                }
                elseif ($fieldType -eq 'separate') {
                    $fieldResult = $true
                }
                elseif ($fieldType -eq 'end') {
                    $label = $fieldParts -join ''
                    if ($fieldTarget -and $label) {
                        $parts.Add("[$label]($(ConvertTo-LinkTarget $fieldTarget))")
                    }
                    else {
                        $parts.Add($label)
                    }
                    $fieldActive = $false
                    $fieldResult = $false
                    $fieldTarget = ''
                    $fieldParts.Clear()
                }
                continue
            }

            $instruction = $child.SelectSingleNode('./w:instrText', $NamespaceManager)
            if ($fieldActive -and $null -ne $instruction) {
                if ($instruction.InnerText -match 'HYPERLINK\s+"([^"]+)"') {
                    $fieldTarget = $Matches[1]
                }
                continue
            }
        }

        $converted = Convert-InlineNode $child $NamespaceManager
        if ($fieldActive) {
            if ($fieldResult) {
                $fieldParts.Add($converted)
            }
        }
        else {
            $parts.Add($converted)
        }
    }
    if ($fieldActive -and $fieldParts.Count -gt 0) {
        $parts.Add(($fieldParts -join ''))
    }
    return ($parts -join '')
}

function New-HeadingSlug {
    param(
        [string]$Text,
        [hashtable]$SlugCounts
    )

    $slug = $Text.ToLowerInvariant()
    $slug = $slug -replace '[‘’''“”"`]', ''
    $slug = $slug -replace '[^\p{L}\p{Nd}]+', '-'
    $slug = $slug.Trim('-')
    if (-not $slug) {
        $slug = 'section'
    }

    if ($SlugCounts.ContainsKey($slug)) {
        $SlugCounts[$slug]++
        return "$slug-$($SlugCounts[$slug])"
    }
    $SlugCounts[$slug] = 1
    return $slug
}

function Convert-Paragraph {
    param(
        [System.Xml.XmlNode]$Paragraph,
        [System.Xml.XmlNamespaceManager]$NamespaceManager,
        [hashtable]$SlugCounts,
        [System.Collections.Generic.List[object]]$Headings,
        [ref]$TitleSeen
    )

    $plainText = ((Get-PlainText $Paragraph $NamespaceManager) -replace '\s+', ' ').Trim()
    $markdown = (Convert-Container $Paragraph $NamespaceManager).Trim()
    $bookmarkAnchors = @($Paragraph.SelectNodes('.//w:bookmarkStart', $NamespaceManager) | ForEach-Object {
        Get-WordAttribute $_ 'name'
    } | Where-Object { $_ -and $_ -ne '_GoBack' } | ForEach-Object {
        '<a id="' + [System.Net.WebUtility]::HtmlEncode($_) + '"></a>'
    })
    $bookmarkPrefix = if ($bookmarkAnchors.Count -gt 0) { ($bookmarkAnchors -join "`n") + "`n" } else { '' }

    $commentIds = @($Paragraph.SelectNodes('.//w:commentReference', $NamespaceManager) | ForEach-Object { Get-WordAttribute $_ 'id' })
    foreach ($commentId in $commentIds) {
        if (-not $script:CommentContexts.ContainsKey($commentId)) {
            $script:CommentContexts[$commentId] = $plainText
        }
    }

    $styleNode = $Paragraph.SelectSingleNode('./w:pPr/w:pStyle', $NamespaceManager)
    $style = Get-WordAttribute $styleNode 'val'
    if ($style -eq 'Title') {
        if (-not $TitleSeen.Value) {
            $TitleSeen.Value = $true
            $slug = New-HeadingSlug $plainText $SlugCounts
            $Headings.Add([pscustomobject]@{ Level = 1; Text = $plainText; Slug = $slug })
            return "$bookmarkPrefix<a id=`"$slug`"></a>`n# $markdown"
        }
        return "$bookmarkPrefix*$markdown*"
    }

    if ($style -match '^Heading([1-6])$') {
        if (-not $plainText) {
            return $bookmarkPrefix.TrimEnd()
        }
        $level = [Math]::Min(6, [int]$Matches[1] + 1)
        $displayText = $plainText -replace '^[@-]', ''
        $displayMarkdown = $markdown -replace '^\\?[@-]', ''
        if ($displayText -eq 'Table of Contents') {
            $displayText = 'Source navigation index'
            $displayMarkdown = 'Source navigation index'
        }
        $slug = New-HeadingSlug $displayText $SlugCounts
        $Headings.Add([pscustomobject]@{ Level = $level; Text = $displayText; Slug = $slug })
        return "$bookmarkPrefix<a id=`"$slug`"></a>`n$('' + ('#' * $level)) $displayMarkdown"
    }

    if ($style -eq 'Subtitle') {
        return "$bookmarkPrefix> $markdown"
    }

    $numbering = $Paragraph.SelectSingleNode('./w:pPr/w:numPr', $NamespaceManager)
    if ($null -ne $numbering) {
        $levelNode = $numbering.SelectSingleNode('./w:ilvl', $NamespaceManager)
        $level = 0
        if ($null -ne $levelNode) {
            $level = [int](Get-WordAttribute $levelNode 'val')
        }
        return "$bookmarkPrefix$('    ' * $level)- $markdown"
    }

    return "$bookmarkPrefix$markdown"
}

function Convert-Table {
    param(
        [System.Xml.XmlNode]$Table,
        [System.Xml.XmlNamespaceManager]$NamespaceManager
    )

    $rows = @($Table.SelectNodes('./w:tr', $NamespaceManager))
    if ($rows.Count -eq 0) {
        return ''
    }

    $renderedRows = [System.Collections.Generic.List[object]]::new()
    $columnCount = 0
    foreach ($row in $rows) {
        $cells = [System.Collections.Generic.List[string]]::new()
        foreach ($cell in $row.SelectNodes('./w:tc', $NamespaceManager)) {
            $paragraphs = [System.Collections.Generic.List[string]]::new()
            foreach ($paragraph in $cell.SelectNodes('./w:p', $NamespaceManager)) {
                $value = (Convert-Container $paragraph $NamespaceManager).Trim()
                if ($value) {
                    $paragraphs.Add($value)
                }
            }
            $cells.Add((($paragraphs -join '<br>') -replace '\|', '\|'))
        }
        $columnCount = [Math]::Max($columnCount, $cells.Count)
        $renderedRows.Add($cells)
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    if ($columnCount -eq 2) {
        $header = @('Tag', 'Description')
    }
    else {
        $header = for ($index = 0; $index -lt $columnCount; $index++) { "Column $($index + 1)" }
    }
    $lines.Add('| ' + ($header -join ' | ') + ' |')
    $lines.Add('| ' + ((1..$columnCount | ForEach-Object { '---' }) -join ' | ') + ' |')
    foreach ($row in $renderedRows) {
        $values = for ($index = 0; $index -lt $columnCount; $index++) {
            if ($index -lt $row.Count) { $row[$index] } else { '' }
        }
        $lines.Add('| ' + ($values -join ' | ') + ' |')
    }
    return $lines -join "`n"
}

$resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
$sourceItem = Get-Item -LiteralPath $resolvedSource
$sourceHash = (Get-FileHash -LiteralPath $resolvedSource -Algorithm SHA256).Hash.ToLowerInvariant()
$archive = [System.IO.Compression.ZipFile]::OpenRead($resolvedSource)

try {
    [xml]$document = Get-ZipEntryText $archive 'word/document.xml'
    [xml]$commentsDocument = Get-ZipEntryText $archive 'word/comments.xml'
    [xml]$relationships = Get-ZipEntryText $archive 'word/_rels/document.xml.rels' -Optional

    $namespaceManager = [System.Xml.XmlNamespaceManager]::new($document.NameTable)
    $namespaceManager.AddNamespace('w', $script:WordNamespace)
    $namespaceManager.AddNamespace('r', $script:RelationshipNamespace)

    if ($null -ne $relationships) {
        foreach ($relationship in $relationships.DocumentElement.ChildNodes) {
            if ($relationship.TargetMode -eq 'External') {
                $script:DocumentRelationships[$relationship.Id] = $relationship.Target
            }
        }
    }

    foreach ($comment in $commentsDocument.SelectNodes('//w:comment', $namespaceManager)) {
        $id = Get-WordAttribute $comment 'id'
        $paragraphs = @($comment.SelectNodes('./w:p', $namespaceManager) | ForEach-Object {
            (Get-PlainText $_ $namespaceManager -IncludeDeleted).Trim()
        } | Where-Object { $_ })
        $text = $paragraphs -join "`n`n"
        $kind = 'Comment'
        if ($text -match '(?i)merkitse ratkaistuksi|mark(ed)? (as )?resolved') {
            $kind = 'Resolution marker (exported as comment text)'
        }
        elseif ($text -match '(?i)avattu uudelleen|reopen(ed)?') {
            $kind = 'Reopen marker (exported as comment text)'
        }
        $script:Comments[$id] = [pscustomobject]@{
            Id = $id
            Author = $comment.GetAttribute('author', $script:WordNamespace)
            Date = $comment.GetAttribute('date', $script:WordNamespace)
            Text = $text
            Kind = $kind
        }
    }

    $commentReferenceIds = @($document.SelectNodes('//w:body//w:commentReference', $namespaceManager) | ForEach-Object {
        Get-WordAttribute $_ 'id'
    })
    $uniqueCommentReferenceIds = @($commentReferenceIds | Sort-Object -Unique)
    $missingCommentBodies = @($uniqueCommentReferenceIds | Where-Object { -not $script:Comments.ContainsKey($_) })
    $unanchoredComments = @($script:Comments.Keys | Where-Object { $_ -notin $uniqueCommentReferenceIds })
    if ($missingCommentBodies.Count -gt 0 -or $unanchoredComments.Count -gt 0) {
        throw "Comment integrity check failed. Missing bodies: $($missingCommentBodies -join ', '); unanchored comments: $($unanchoredComments -join ', ')"
    }

    $blocks = [System.Collections.Generic.List[string]]::new()
    $headings = [System.Collections.Generic.List[object]]::new()
    $slugCounts = @{}
    $titleSeen = $false
    foreach ($node in $document.SelectNodes('//w:body/*', $namespaceManager)) {
        if ($node.LocalName -eq 'p') {
            $converted = Convert-Paragraph $node $namespaceManager $slugCounts $headings ([ref]$titleSeen)
        }
        elseif ($node.LocalName -eq 'tbl') {
            $converted = Convert-Table $node $namespaceManager
        }
        else {
            continue
        }

        if ($converted) {
            $blocks.Add($converted)
        }
    }

    $tocLines = [System.Collections.Generic.List[string]]::new()
    foreach ($heading in $headings | Where-Object { $_.Level -gt 1 }) {
        $indent = '  ' * ($heading.Level - 2)
        $tocText = ConvertTo-MarkdownText $heading.Text
        $tocLines.Add("$indent- [$tocText](#$($heading.Slug))")
    }
    $tocLines.Add('- [Comments](#comments)')

    $commentLines = [System.Collections.Generic.List[string]]::new()
    foreach ($comment in $script:Comments.Values | Sort-Object { [int]$_.Id }) {
        $context = if ($script:CommentContexts.ContainsKey($comment.Id) -and $script:CommentContexts[$comment.Id]) {
            $script:CommentContexts[$comment.Id]
        }
        else {
            '(Point comment; no range text was exported.)'
        }
        $commentLines.Add("<a id=`"comment-$($comment.Id)`"></a>")
        $commentLines.Add("### Comment $($comment.Id)")
        $commentLines.Add('')
        $commentLines.Add("- **Author:** $(ConvertTo-MarkdownText $comment.Author)")
        $commentLines.Add("- **Date:** $(ConvertTo-MarkdownText $comment.Date)")
        $commentLines.Add("- **Kind:** $(ConvertTo-MarkdownText $comment.Kind)")
        $commentLines.Add("- **Context:** $(ConvertTo-MarkdownText $context)")
        $commentLines.Add('')
        foreach ($paragraph in $comment.Text -split "(`r?`n){2,}") {
            $commentLines.Add((ConvertTo-MarkdownText $paragraph))
            $commentLines.Add('')
        }
    }

    $sourceModified = $sourceItem.LastWriteTime.ToString("yyyy-MM-dd HH':'mm':'ss zzz", [System.Globalization.CultureInfo]::InvariantCulture)
    $preamble = @(
        '> Source: `Warcraft 3 WE Ability Insight.docx`  ',
        '> Original document credit: HiveWorkshop user **ScrewTheTrees** — [The Warcraft 3 Ability Insight Document](https://www.hiveworkshop.com/threads/the-warcraft-3-ability-insight-document.294584/)  ',
        "> Source modified: $sourceModified  ",
        "> Source SHA-256: ``$sourceHash``  ",
        '> Conversion notes: Word heading styles became Markdown headings; list nesting, hyperlinks, the tag table, and inline emphasis are retained. Inserted revision text is shown normally, while deleted revision text is shown with strikethrough. All exported comments are linked inline and reproduced in the Comments appendix. The DOCX contains no modern resolved-comment status part, so resolution/reopen events that survived only as comment text are labeled as such without inferring thread relationships.',
        '',
        '<a id="contents"></a>',
        '## Table of Contents',
        '',
        ($tocLines -join "`n"),
        ''
    ) -join "`n"

    $generatorNote = '<!-- Generated by Convert-AbilityInsightDocx.ps1. Regenerate from the DOCX instead of hand-editing converted source content. -->'
    $bodyAfterTitle = @($blocks | Select-Object -Skip 1) -join "`n`n"
    $output = $generatorNote + "`n`n" + $blocks[0] + "`n`n" + $preamble + "`n" + $bodyAfterTitle + "`n`n<a id=`"comments`"></a>`n## Comments`n`n" + ($commentLines -join "`n")
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
    [System.IO.File]::WriteAllText($resolvedOutput, $output, [System.Text.UTF8Encoding]::new($false))

    Write-Output "Generated: $resolvedOutput"
    Write-Output "Headings: $($headings.Count)"
    Write-Output "Comments: $($script:Comments.Count)"
    Write-Output "Inline comment references: $($commentReferenceIds.Count)"
    Write-Output "Comment references with context: $($script:CommentContexts.Count)"
}
finally {
    $archive.Dispose()
}
