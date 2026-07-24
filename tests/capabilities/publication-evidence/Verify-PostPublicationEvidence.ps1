[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repository,
    [Parameter(Mandatory)][string]$Tag,
    [Parameter(Mandatory)][string]$ExpectedCommit,
    [Parameter(Mandatory)][string]$FeaturePath,
    [Parameter(Mandatory)][ValidateRange(1, [int]::MaxValue)][int]$IssueNumber,
    [Parameter(Mandatory)][ValidateRange(1, [int]::MaxValue)][int]$PullRequestNumber,
    [Parameter(Mandatory)][string]$OwnedBranch,
    [string]$DefaultBranch = 'main',
    [string]$ApiBaseUri = 'https://api.github.com',
    [string]$Token = $(if ($env:GH_TOKEN) { $env:GH_TOKEN } else { $env:GITHUB_TOKEN }),
    [string[]]$ExpectedReleaseAssetNames = @(),
    [string]$ExpectedLauncherAssetName = 'Invoke-MeAndAIQuickAdoption.ps1',
    [string]$ExpectedLauncherSourcePath = 'scripts/Invoke-MeAndAIQuickAdoption.ps1',
    [string]$ExpectedBundleAssetName = '',
    [string]$ExpectedBundleSourceInventoryPath = 'scripts/quick-adoption/bundle.sources.json'
)

$ErrorActionPreference = 'Stop'
$originalValidationCulture = [Threading.Thread]::CurrentThread.CurrentCulture
try {
    [Threading.Thread]::CurrentThread.CurrentCulture =
        [Globalization.CultureInfo]::InvariantCulture

function Assert-PostPublicationCondition {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw "TEST-0065 $Message"
    }
}

function ConvertTo-ApiPath {
    param([Parameter(Mandatory)][string]$Value)

    return (($Value -split '/') | ForEach-Object {
        [uri]::EscapeDataString($_)
    }) -join '/'
}

function Remove-MarkdownBlockContainerPrefix {
    param([AllowEmptyString()][string]$Line)

    $remaining = [string]$Line
    do {
        $before = $remaining
        $remaining = [regex]::Replace(
            $remaining,
            '^(?: {0,3}>[ \t]?)+',
            ''
        )
        $remaining = [regex]::Replace(
            $remaining,
            '^ {0,3}(?:[-+*]|\d{1,9}[.)])[ \t]+',
            ''
        )
    } while ($remaining -cne $before)
    return $remaining
}

function Get-MarkdownCodeSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    $lines = @([regex]::Matches(
        $text,
        '(?m)^(?<content>[^\r\n]*)(?<eol>\r?\n|$)'
    ) | Where-Object { $_.Length -gt 0 })
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $openingLine = [string]$lines[$lineIndex].Groups['content'].Value
        $opening = [regex]::Match(
            $openingLine,
            '^(?: {0,3}>[ \t]?)*(?:[ \t]*(?:[-+*]|\d+[.)])[ \t]+)?[ \t]*(?<marker>`{3,}|~{3,})(?<info>.*)$'
        )
        if (-not $opening.Success) { continue }
        $marker = [string]$opening.Groups['marker'].Value
        $markerCharacter = [string]$marker[0]
        if ($markerCharacter -ceq '`' -and
            $opening.Groups['info'].Value.Contains('`')) { continue }
        $closingPattern =
            '^(?: {0,3}>[ \t]?)*[ \t]*(?:' +
            [regex]::Escape($markerCharacter) + '){' +
            $marker.Length + ',}[ \t]*$'
        $closingLineIndex = -1
        for ($candidateIndex = $lineIndex + 1;
            $candidateIndex -lt $lines.Count;
            $candidateIndex++) {
            if ([regex]::IsMatch(
                [string]$lines[$candidateIndex].Groups['content'].Value,
                $closingPattern
            )) {
                $closingLineIndex = $candidateIndex
                break
            }
        }
        $spanEnd = if ($closingLineIndex -ge 0) {
            $lines[$closingLineIndex].Index +
                $lines[$closingLineIndex].Length
        }
        else { $text.Length }
        $contentStart = $lines[$lineIndex].Index +
            $lines[$lineIndex].Length
        $contentEnd = if ($closingLineIndex -ge 0) {
            $lines[$closingLineIndex].Index
        }
        else { $text.Length }
        $spans.Add([pscustomobject]@{
            Index = $lines[$lineIndex].Index
            Length = $spanEnd - $lines[$lineIndex].Index
            Value = $text.Substring(
                $lines[$lineIndex].Index,
                $spanEnd - $lines[$lineIndex].Index
            )
            Content = $text.Substring(
                $contentStart,
                [Math]::Max(0, $contentEnd - $contentStart)
            )
            Kind = 'Fenced'
        })
        if ($closingLineIndex -ge 0) {
            $lineIndex = $closingLineIndex
        }
        else { break }
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?m)(?:\A|\r?\n\r?\n)(?<code>(?:(?: {4}|\t)[^\r\n]+(?:\r?\n|$))+)'
    )) {
        $codeGroup = $match.Groups['code']
        if (Test-MarkdownSpanOverlap -Index $codeGroup.Index `
            -Length 1 -Spans @($spans)) { continue }
        $spans.Add([pscustomobject]@{
            Index = $codeGroup.Index
            Length = $codeGroup.Length
            Value = $codeGroup.Value
            Content = [regex]::Replace(
                $codeGroup.Value, '(?m)^(?: {4}|\t)', ''
            )
            Kind = 'Indented'
        })
    }
    foreach ($line in [regex]::Matches(
        $text,
        '(?m)^(?<content>[^\r\n]*)(?<eol>\r?\n|$)'
    ) | Where-Object { $_.Length -gt 0 }) {
        $rawLine = [string]$line.Groups['content'].Value
        $containerCode = [regex]::Match(
            $rawLine,
            '^(?:(?: {0,3}>[ \t]?)+)(?<indent> {4}|\t)(?<content>[^\r\n]+)$'
        )
        if (-not $containerCode.Success) {
            $containerCode = [regex]::Match(
                $rawLine,
                '^(?:(?: {0,3}>[ \t]?)* {0,3}(?:[-+*]|\d{1,9}[.)]))(?<indent> {5,}|\t+)(?<content>[^\r\n]+)$'
            )
        }
        if (-not $containerCode.Success -or
            (Test-MarkdownSpanOverlap -Index $line.Index `
                -Length 1 -Spans @($spans))) { continue }
        $spans.Add([pscustomobject]@{
            Index = $line.Index
            Length = $line.Length
            Value = $line.Value
            Content = $containerCode.Groups['content'].Value
            Kind = 'Indented'
        })
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?s)(?<!`)(?<ticks>`+)(?!`)(?<content>.*?)(?<!`)\k<ticks>(?!`)'
    )) {
        if (Test-MarkdownSpanOverlap -Index $match.Index `
            -Length 1 -Spans @($spans)) { continue }
        $spans.Add([pscustomobject]@{
            Index = $match.Index
            Length = $match.Length
            Value = $match.Value
            Content = $match.Groups['content'].Value
            Kind = 'Inline'
        })
    }
    return @($spans | Sort-Object Index)
}

function Get-MarkdownHtmlCommentSpans {
    param([AllowEmptyString()][string]$Markdown)

    return @([regex]::Matches(
        [string]$Markdown,
        '(?s)<!--.*?(?:-->|\z)'
    ))
}

function Get-MarkdownNonRenderingHtmlSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches(
        $text,
        '(?is)<(?<tag>pre|script|style|textarea)(?:\s[^>]*)?>.*?(?:</\k<tag>\s*>|\z)'
    )) {
        $spans.Add([pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Value = $match.Value; Kind = 'HtmlType1'
        })
    }
    $lines = @([regex]::Matches(
        $text,
        '(?m)^(?<content>[^\r\n]*)(?<eol>\r?\n|$)'
    ) | Where-Object { $_.Length -gt 0 })
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $containerLine = Remove-MarkdownBlockContainerPrefix `
            -Line ([string]$lines[$lineIndex].Groups['content'].Value)
        $htmlType = $null
        if ($containerLine -cmatch '^ {0,3}<\?') {
            $htmlType = [pscustomobject]@{ Kind = 'HtmlType3'; End = '\?>' }
        }
        elseif ($containerLine -cmatch '^ {0,3}<![A-Z]') {
            $htmlType = [pscustomobject]@{ Kind = 'HtmlType4'; End = '>' }
        }
        elseif ($containerLine -cmatch '^ {0,3}<!\[CDATA\[') {
            $htmlType = [pscustomobject]@{ Kind = 'HtmlType5'; End = '\]\]>' }
        }
        if ($null -eq $htmlType -or
            (Test-MarkdownSpanOverlap -Index $lines[$lineIndex].Index `
                -Length 1 -Spans @($spans))) { continue }

        $lastLineIndex = $lineIndex
        $normalizedBlock = $containerLine
        while (-not [regex]::IsMatch($normalizedBlock, $htmlType.End) -and
            $lastLineIndex + 1 -lt $lines.Count) {
            $lastLineIndex++
            $normalizedBlock += "`n" +
                (Remove-MarkdownBlockContainerPrefix -Line `
                    ([string]$lines[$lastLineIndex].Groups['content'].Value))
        }
        $spanEnd = $lines[$lastLineIndex].Index +
            $lines[$lastLineIndex].Length
        $spans.Add([pscustomobject]@{
            Index = $lines[$lineIndex].Index
            Length = $spanEnd - $lines[$lineIndex].Index
            Value = $text.Substring(
                $lines[$lineIndex].Index,
                $spanEnd - $lines[$lineIndex].Index
            )
            Kind = [string]$htmlType.Kind
        })
        $lineIndex = $lastLineIndex
    }
    $blockTags =
        'address|article|aside|base|basefont|blockquote|body|caption|center|' +
        'col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|' +
        'figure|footer|form|frame|frameset|h[1-6]|head|header|hr|html|' +
        'iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|' +
        'optgroup|option|p|param|search|section|summary|table|tbody|td|' +
        'tfoot|th|thead|title|tr|track|ul'
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $line = [string]$lines[$lineIndex].Groups['content'].Value
        $containerLine = Remove-MarkdownBlockContainerPrefix -Line $line
        $isType6Block = [regex]::IsMatch(
            $containerLine,
            '(?i)^ {0,3}</?(?:' + $blockTags + ')(?:[ \t]+|/?>|$)'
        )
        $isType7Block = [regex]::IsMatch(
            $containerLine,
            '^ {0,3}</?[A-Za-z]'
        ) -and [string]::IsNullOrWhiteSpace(
            (Remove-MarkdownInlineHtmlTags -Text $containerLine)
        )
        if (-not $isType6Block -and -not $isType7Block) { continue }
        if (Test-MarkdownSpanOverlap -Index $lines[$lineIndex].Index `
            -Length 1 -Spans @($spans)) { continue }
        $lastLineIndex = $lineIndex
        for ($candidateIndex = $lineIndex + 1;
            $candidateIndex -lt $lines.Count;
            $candidateIndex++) {
            $candidateLine = Remove-MarkdownBlockContainerPrefix `
                -Line ([string]$lines[$candidateIndex].Groups['content'].Value)
            if ($candidateLine -match '^[ \t]*$') { break }
            $lastLineIndex = $candidateIndex
        }
        $spanEnd = $lines[$lastLineIndex].Index +
            $lines[$lastLineIndex].Length
        $spans.Add([pscustomobject]@{
            Index = $lines[$lineIndex].Index
            Length = $spanEnd - $lines[$lineIndex].Index
            Value = $text.Substring(
                $lines[$lineIndex].Index,
                $spanEnd - $lines[$lineIndex].Index
            )
            Kind = if ($isType6Block) { 'HtmlType6' } else { 'HtmlType7' }
        })
        $lineIndex = $lastLineIndex
    }
    return @($spans | Sort-Object Index)
}

function Test-MarkdownCharacterEscaped {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][int]$Index
    )

    $backslashes = 0
    for ($position = $Index - 1;
        $position -ge 0 -and $Text[$position] -ceq '\';
        $position--) {
        $backslashes++
    }
    return ($backslashes % 2) -eq 1
}

function Get-MarkdownEscapedLinkSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($match in @(Get-MarkdownInlineLinkEvidence `
        -Markdown $text -EscapedOpeningOnly)) {
        $spans.Add([pscustomobject]@{
            Index = $match.Index
            Length = $match.Length
            Value = $text.Substring($match.Index, $match.Length)
        })
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?<!\!)\[[^\]]+\][ \t]*\[[^\]]*\]'
    )) {
        if ((Test-MarkdownCharacterEscaped `
                -Text $text -Index $match.Index) -and
            @($spans | Where-Object {
                $_.Index -eq $match.Index -and $_.Length -eq $match.Length
            }).Count -eq 0) {
            $spans.Add([pscustomobject]@{
                Index = $match.Index
                Length = $match.Length
                Value = $match.Value
            })
        }
    }
    return @($spans)
}

function Test-MarkdownSpanOverlap {
    param(
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][int]$Length,
        [object[]]$Spans = @()
    )

    foreach ($span in $Spans) {
        if ($Index -lt ([int]$span.Index + [int]$span.Length) -and
            ($Index + $Length) -gt [int]$span.Index) {
            return $true
        }
    }
    return $false
}

function Test-MarkdownAsciiPunctuationCharacter {
    param([Parameter(Mandatory)][char]$Character)

    $code = [int]$Character
    return ($code -ge 33 -and $code -le 47) -or
        ($code -ge 58 -and $code -le 64) -or
        ($code -ge 91 -and $code -le 96) -or
        ($code -ge 123 -and $code -le 126)
}

function ConvertFrom-MarkdownLinkDestination {
    param([AllowEmptyString()][string]$Destination)

    $decoded = [Net.WebUtility]::HtmlDecode([string]$Destination)
    $result = [Text.StringBuilder]::new($decoded.Length)
    for ($index = 0; $index -lt $decoded.Length; $index++) {
        if ($decoded[$index] -ceq '\' -and
            $index + 1 -lt $decoded.Length -and
            (Test-MarkdownAsciiPunctuationCharacter `
                -Character $decoded[$index + 1])) {
            [void]$result.Append($decoded[$index + 1])
            $index++
            continue
        }
        [void]$result.Append($decoded[$index])
    }
    return $result.ToString()
}

function Get-MarkdownInlineLinkEvidence {
    param(
        [AllowEmptyString()][string]$Markdown,
        [object[]]$ProtectedSpans = @(),
        [switch]$EscapedOpeningOnly
    )

    $text = [string]$Markdown
    $links = [System.Collections.Generic.List[object]]::new()
    for ($start = 0; $start -lt $text.Length; $start++) {
        if ($text[$start] -cne '[') { continue }
        $openingEscaped = Test-MarkdownCharacterEscaped `
            -Text $text -Index $start
        if (($EscapedOpeningOnly -and -not $openingEscaped) -or
            (-not $EscapedOpeningOnly -and $openingEscaped)) { continue }
        $isImage = $start -gt 0 -and $text[$start - 1] -ceq '!' -and
            -not (Test-MarkdownCharacterEscaped `
                -Text $text -Index ($start - 1))
        if ($isImage -or (Test-MarkdownSpanOverlap `
                -Index $start -Length 1 -Spans $ProtectedSpans)) { continue }

        $depth = 1
        $cursor = $start + 1
        $labelEnd = -1
        while ($cursor -lt $text.Length) {
            $protected = @($ProtectedSpans | Where-Object {
                $cursor -ge [int]$_.Index -and
                    $cursor -lt ([int]$_.Index + [int]$_.Length)
            } | Sort-Object Index | Select-Object -First 1)
            if ($protected.Count -eq 1) {
                $cursor = [int]$protected[0].Index +
                    [int]$protected[0].Length
                continue
            }
            if ($text[$cursor] -ceq '\' -and
                $cursor + 1 -lt $text.Length -and
                (Test-MarkdownAsciiPunctuationCharacter `
                    -Character $text[$cursor + 1])) {
                $cursor += 2
                continue
            }
            if ($text[$cursor] -ceq '[') { $depth++ }
            elseif ($text[$cursor] -ceq ']') {
                $depth--
                if ($depth -eq 0) {
                    $labelEnd = $cursor
                    break
                }
            }
            $cursor++
        }
        if ($labelEnd -lt 0 -or $labelEnd + 1 -ge $text.Length -or
            $text[$labelEnd + 1] -cne '(') { continue }

        $cursor = $labelEnd + 2
        while ($cursor -lt $text.Length -and
            [char]::IsWhiteSpace($text[$cursor])) { $cursor++ }
        $destinationStart = $cursor
        $destinationEnd = -1
        if ($cursor -lt $text.Length -and $text[$cursor] -ceq '<') {
            $destinationStart = ++$cursor
            while ($cursor -lt $text.Length) {
                if ($text[$cursor] -ceq "`r" -or
                    $text[$cursor] -ceq "`n" -or
                    $text[$cursor] -ceq '<') { break }
                if ($text[$cursor] -ceq '\' -and
                    $cursor + 1 -lt $text.Length -and
                    (Test-MarkdownAsciiPunctuationCharacter `
                        -Character $text[$cursor + 1])) {
                    $cursor += 2
                    continue
                }
                if ($text[$cursor] -ceq '>') {
                    $destinationEnd = $cursor
                    $cursor++
                    break
                }
                $cursor++
            }
            if ($destinationEnd -lt 0) { continue }
        }
        else {
            $parenthesisDepth = 0
            while ($cursor -lt $text.Length) {
                if ([char]::IsWhiteSpace($text[$cursor])) { break }
                if ($text[$cursor] -ceq '\' -and
                    $cursor + 1 -lt $text.Length -and
                    (Test-MarkdownAsciiPunctuationCharacter `
                        -Character $text[$cursor + 1])) {
                    $cursor += 2
                    continue
                }
                if ($text[$cursor] -ceq '(') {
                    $parenthesisDepth++
                }
                elseif ($text[$cursor] -ceq ')') {
                    if ($parenthesisDepth -eq 0) { break }
                    $parenthesisDepth--
                }
                $cursor++
            }
            if ($parenthesisDepth -ne 0) { continue }
            $destinationEnd = $cursor
        }

        $whitespaceStart = $cursor
        while ($cursor -lt $text.Length -and
            [char]::IsWhiteSpace($text[$cursor])) { $cursor++ }
        if ($cursor -ge $text.Length) { continue }
        if ($text[$cursor] -cne ')') {
            if ($cursor -eq $whitespaceStart -or
                $text[$cursor] -notin @('"', "'", '(')) { continue }
            $titleCloser = if ($text[$cursor] -ceq '(') { ')' } else {
                $text[$cursor]
            }
            $cursor++
            $titleClosed = $false
            while ($cursor -lt $text.Length) {
                if ($text[$cursor] -ceq '\' -and
                    $cursor + 1 -lt $text.Length -and
                    (Test-MarkdownAsciiPunctuationCharacter `
                        -Character $text[$cursor + 1])) {
                    $cursor += 2
                    continue
                }
                if ($text[$cursor] -ceq $titleCloser) {
                    $titleClosed = $true
                    $cursor++
                    break
                }
                $cursor++
            }
            if (-not $titleClosed) { continue }
            while ($cursor -lt $text.Length -and
                [char]::IsWhiteSpace($text[$cursor])) { $cursor++ }
            if ($cursor -ge $text.Length -or
                $text[$cursor] -cne ')') { continue }
        }

        $rawDestination = $text.Substring(
            $destinationStart,
            $destinationEnd - $destinationStart
        )
        $links.Add([pscustomobject]@{
            Index = $start
            Length = $cursor - $start + 1
            Label = $text.Substring($start + 1, $labelEnd - $start - 1)
            Target = ConvertFrom-MarkdownLinkDestination `
                -Destination $rawDestination
            Style = 'Inline'
            ReferenceKey = ''
        })
        $start = $cursor
    }
    return @($links)
}

function Get-MarkdownHttpAutolinkSpans {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($angle in [regex]::Matches(
        $text,
        '(?i)<(?<url>https?://[^\s<>]+)>'
    )) {
        $spans.Add([pscustomobject]@{
            Index = $angle.Index
            Length = $angle.Length
            Value = $angle.Groups['url'].Value
            RawValue = $angle.Groups['url'].Value
            IsAngle = $true
            HasMarkupContinuation = $false
        })
    }
    foreach ($scheme in [regex]::Matches($text, '(?i)https?://')) {
        $start = $scheme.Index
        if (@($spans | Where-Object {
            -not $_.IsAngle -and $start -ge [int]$_.Index -and
                $start -lt ([int]$_.Index + [int]$_.Length)
        }).Count -gt 0) { continue }
        if ($start -gt 0) {
            $previous = $text[$start - 1]
            if (-not [char]::IsWhiteSpace($previous) -and
                $previous -notin @('*', '_', '~', '(')) { continue }
        }
        $domainStart = $start + $scheme.Length
        $domainMatch = [regex]::Match(
            $text.Substring($domainStart),
            '^(?<domain>[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+)'
        )
        if (-not $domainMatch.Success) { continue }
        $segments = @($domainMatch.Groups['domain'].Value.Split('.'))
        if ($segments[-1].Contains('_') -or
            $segments[-2].Contains('_')) { continue }

        $domainEnd = $domainStart + $domainMatch.Length
        $maximumEnd = $domainEnd
        while ($maximumEnd -lt $text.Length -and
            -not [char]::IsWhiteSpace($text[$maximumEnd]) -and
            $text[$maximumEnd] -cne '<' -and
            $text[$maximumEnd] -cne '`') { $maximumEnd++ }
        $rawCandidate = $text.Substring($start, $maximumEnd - $start)
        $end = $maximumEnd
        while ($end -gt $domainEnd -and
            '?!. ,:*_~'.Replace(' ', '').Contains(
                [string]$text[$end - 1]
            )) { $end-- }
        while ($end -gt $domainEnd -and $text[$end - 1] -ceq ')') {
            $candidate = $text.Substring($start, $end - $start)
            $openCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq '('
            }).Count
            $closeCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq ')'
            }).Count
            if ($closeCount -le $openCount) { break }
            $end--
        }
        $candidate = $text.Substring($start, $end - $start)
        $entitySuffix = [regex]::Match($candidate, '&[A-Za-z0-9]+;$')
        if ($entitySuffix.Success) {
            $end = $start + $entitySuffix.Index
            $candidate = $text.Substring($start, $end - $start)
        }
        if ($end -lt $domainEnd) { continue }
        $continuation = if ($maximumEnd -lt $text.Length) {
            $text.Substring($maximumEnd)
        } else { '' }
        $spans.Add([pscustomobject]@{
            Index = $start
            Length = $end - $start
            Value = $candidate
            RawValue = $rawCandidate
            IsAngle = $false
            HasMarkupContinuation = $continuation -match
                '^(?:<!--|</?[A-Za-z]|`)'
        })
    }
    return @($spans | Sort-Object Index, Length -Unique)
}

function Get-MarkdownVisibleHttpUrlSpans {
    param([AllowEmptyString()][string]$Text)

    $spans = [System.Collections.Generic.List[object]]::new()
    foreach ($scheme in [regex]::Matches([string]$Text, '(?i)https?://')) {
        $start = $scheme.Index
        if (@($spans | Where-Object {
            $start -ge [int]$_.Index -and
                $start -lt ([int]$_.Index + [int]$_.Length)
        }).Count -gt 0) { continue }
        $end = $start + $scheme.Length
        while ($end -lt $Text.Length -and
            -not [char]::IsWhiteSpace($Text[$end]) -and
            $Text[$end] -notin @('<', '>', '[', ']', '{', '}', '"', "'", '`')) {
            $end++
        }
        while ($end -gt ($start + $scheme.Length) -and
            '.,;:!?'.Contains([string]$Text[$end - 1])) { $end-- }
        while ($end -gt ($start + $scheme.Length) -and
            $Text[$end - 1] -ceq ')') {
            $candidate = $Text.Substring($start, $end - $start)
            $openCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq '('
            }).Count
            $closeCount = @($candidate.ToCharArray() | Where-Object {
                $_ -ceq ')'
            }).Count
            if ($closeCount -le $openCount) { break }
            $end--
        }
        $spans.Add([pscustomobject]@{
            Index = $start
            Length = $end - $start
            Value = $Text.Substring($start, $end - $start)
        })
    }
    return @($spans)
}

function Remove-MarkdownInlineHtmlTags {
    param([AllowEmptyString()][string]$Text)

    $result = [Text.StringBuilder]::new($Text.Length)
    for ($index = 0; $index -lt $Text.Length;) {
        if ($Text[$index] -cne '<') {
            [void]$result.Append($Text[$index])
            $index++
            continue
        }
        $cursor = $index + 1
        if ($cursor -lt $Text.Length -and $Text[$cursor] -ceq '/') {
            $cursor++
        }
        if ($cursor -ge $Text.Length -or
            -not [char]::IsLetter($Text[$cursor])) {
            [void]$result.Append('<')
            $index++
            continue
        }
        $cursor++
        while ($cursor -lt $Text.Length -and
            ([char]::IsLetterOrDigit($Text[$cursor]) -or
                $Text[$cursor] -ceq '-')) { $cursor++ }
        if ($cursor -ge $Text.Length -or
            (-not [char]::IsWhiteSpace($Text[$cursor]) -and
                $Text[$cursor] -cne '/' -and $Text[$cursor] -cne '>')) {
            [void]$result.Append('<')
            $index++
            continue
        }
        $quote = [char]0
        $tagEnd = -1
        for (; $cursor -lt $Text.Length; $cursor++) {
            $character = $Text[$cursor]
            if ($quote -ne [char]0) {
                if ($character -ceq $quote) { $quote = [char]0 }
                continue
            }
            if ($character -ceq '"' -or $character -ceq "'") {
                $quote = $character
                continue
            }
            if ($character -ceq '>') {
                $tagEnd = $cursor
                break
            }
        }
        if ($tagEnd -lt 0) {
            [void]$result.Append('<')
            $index++
            continue
        }
        $index = $tagEnd + 1
    }
    return $result.ToString()
}

function ConvertTo-MarkdownRenderedText {
    param([AllowEmptyString()][string]$Text)

    $decoded = [Net.WebUtility]::HtmlDecode([string]$Text)
    $decoded = [regex]::Replace($decoded, '(?s)<!--.*?(?:-->|\z)', '')
    $decoded = Remove-MarkdownInlineHtmlTags -Text $decoded
    $decoded = $decoded -replace '[*~`]', ''
    $decoded = [regex]::Replace(
        $decoded,
        '(?<![A-Za-z0-9])_+|_+(?![A-Za-z0-9])',
        ''
    )
    $rendered = [Text.StringBuilder]::new($decoded.Length)
    for ($index = 0; $index -lt $decoded.Length;) {
        if ($decoded[$index] -cne '\') {
            [void]$rendered.Append($decoded[$index])
            $index++
            continue
        }
        $runStart = $index
        while ($index -lt $decoded.Length -and $decoded[$index] -ceq '\') {
            $index++
        }
        $runLength = $index - $runStart
        for ($pair = 0; $pair -lt [Math]::Floor($runLength / 2); $pair++) {
            [void]$rendered.Append('\')
        }
        $hasOddEscape = ($runLength % 2) -eq 1
        $nextIsAsciiPunctuation = $false
        if ($index -lt $decoded.Length) {
            $characterCode = [int][char]$decoded[$index]
            $nextIsAsciiPunctuation =
                ($characterCode -ge 33 -and $characterCode -le 47) -or
                ($characterCode -ge 58 -and $characterCode -le 64) -or
                ($characterCode -ge 91 -and $characterCode -le 96) -or
                ($characterCode -ge 123 -and $characterCode -le 126)
        }
        if ($hasOddEscape -and $nextIsAsciiPunctuation) {
            [void]$rendered.Append($decoded[$index])
            $index++
        }
        elseif ($hasOddEscape) {
            [void]$rendered.Append('\')
        }
    }
    return $rendered.ToString()
}

function Get-GitHubShorthandReferences {
    param([AllowEmptyString()][string]$Text)

    $references = [System.Collections.Generic.List[object]]::new()
    foreach ($match in [regex]::Matches(
        [string]$Text,
        '(?i)(?<![A-Za-z0-9_])(?<kind>GH|PR|issue|comment|review)-(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
    )) {
        $references.Add([pscustomobject]@{
            Index = $match.Index
            Length = $match.Length
            Value = $match.Value
            Kind = $match.Groups['kind'].Value.ToLowerInvariant()
            Number = [long]$match.Groups['number'].Value
            Owner = ''
            RepositoryName = ''
        })
    }
    foreach ($match in [regex]::Matches(
        [string]$Text,
        '(?i)(?<![A-Za-z0-9_./-])(?:(?<owner>[A-Za-z0-9_.-]+)/)?(?<repository>[A-Za-z0-9_.-]{2,})#(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
    )) {
        if (Test-MarkdownSpanOverlap -Index $match.Index `
            -Length $match.Length -Spans @($references)) { continue }
        $references.Add([pscustomobject]@{
            Index = $match.Index
            Length = $match.Length
            Value = $match.Value
            Kind = 'repository'
            Number = [long]$match.Groups['number'].Value
            Owner = $match.Groups['owner'].Value
            RepositoryName = $match.Groups['repository'].Value
        })
    }
    return @($references | Sort-Object Index)
}

function Get-MarkdownLinkEvidence {
    param([AllowEmptyString()][string]$Markdown)

    $text = [string]$Markdown
    $definitions = [Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $codeSpans = @(Get-MarkdownCodeSpans -Markdown $text)
    $htmlCommentSpans = @(Get-MarkdownHtmlCommentSpans -Markdown $text)
    $nonRenderingHtmlSpans = @(
        Get-MarkdownNonRenderingHtmlSpans -Markdown $text | Where-Object {
            -not (Test-MarkdownSpanOverlap -Index $_.Index `
                -Length $_.Length `
                -Spans (@($codeSpans) + @($htmlCommentSpans)))
        }
    )
    $escapedLinkSpans = @(Get-MarkdownEscapedLinkSpans -Markdown $text)
    $ignoredSpans = @($codeSpans) + @($htmlCommentSpans) +
        @($nonRenderingHtmlSpans) + @($escapedLinkSpans)
    $definitionMatches = @([regex]::Matches(
        $text,
        '(?m)^[ \t]{0,3}\[(?<key>(?!\^)[^\]]+)\]:[ \t]*(?:<(?<angle>[^>]+)>|(?<plain>\S+))(?:[ \t]+(?:"[^"]*"|''[^'']*''|\([^)]*\)))?[ \t]*$'
    ) | Where-Object {
        -not (Test-MarkdownCharacterEscaped `
            -Text $text -Index ($_.Groups['key'].Index - 1)) -and
        -not (Test-MarkdownSpanOverlap -Index $_.Index -Length 1 `
            -Spans $ignoredSpans)
    })
    foreach ($definition in $definitionMatches) {
        $key = $definition.Groups['key'].Value.Trim()
        $target = if ($definition.Groups['angle'].Success) {
            $definition.Groups['angle'].Value
        } else { $definition.Groups['plain'].Value }
        $target = ConvertFrom-MarkdownLinkDestination -Destination $target
        if ([string]::IsNullOrWhiteSpace($key) -or
            [string]::IsNullOrWhiteSpace($target) -or
            $definitions.ContainsKey($key)) {
            throw 'TEST-0065 Markdown contains an empty or duplicate reference-link definition.'
        }
        $definitions.Add($key, [pscustomobject]@{
            Target = $target; Index = $definition.Index; Length = $definition.Length
        })
    }

    $links = [System.Collections.Generic.List[object]]::new()
    $unresolvedReferences = [System.Collections.Generic.List[object]]::new()
    $occupied = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in $definitionMatches) {
        $occupied.Add([pscustomobject]@{
            Index = $definition.Index; Length = $definition.Length
        })
    }
    foreach ($link in @(Get-MarkdownInlineLinkEvidence `
        -Markdown $text -ProtectedSpans $ignoredSpans)) {
        if (Test-MarkdownSpanOverlap -Index $link.Index `
            -Length $link.Length -Spans @($occupied)) { continue }
        $links.Add($link); $occupied.Add($link)
    }
    foreach ($match in [regex]::Matches(
        $text,
        '(?<!\!)\[(?<label>[^\]]+)\][ \t]*\[(?<key>[^\]]*)\]'
    )) {
        if (Test-MarkdownCharacterEscaped `
            -Text $text -Index $match.Index) { continue }
        if (Test-MarkdownSpanOverlap -Index $match.Index `
            -Length 1 -Spans $ignoredSpans) { continue }
        if (@($occupied | Where-Object {
            $match.Index -lt ($_.Index + $_.Length) -and
                ($match.Index + $match.Length) -gt $_.Index
        }).Count -ne 0) { continue }
        $key = $match.Groups['key'].Value.Trim()
        if ([string]::IsNullOrEmpty($key)) { $key = $match.Groups['label'].Value.Trim() }
        if (-not $definitions.ContainsKey($key)) {
            $unresolvedReferences.Add([pscustomobject]@{
                Label = $match.Groups['label'].Value
                Key = $key
            })
            $occupied.Add([pscustomobject]@{
                Index = $match.Index; Length = $match.Length
            })
            continue
        }
        $link = [pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Label = $match.Groups['label'].Value
            Target = [string]$definitions[$key].Target
            Style = 'Reference'; ReferenceKey = $key
        }
        $links.Add($link); $occupied.Add($link)
    }
    foreach ($match in [regex]::Matches($text, '(?<![!\]])\[(?<label>[^\]]+)\]')) {
        if (Test-MarkdownCharacterEscaped `
            -Text $text -Index $match.Index) { continue }
        if (Test-MarkdownSpanOverlap -Index $match.Index `
            -Length 1 -Spans $ignoredSpans) { continue }
        if (@($occupied | Where-Object {
            $match.Index -lt ($_.Index + $_.Length) -and
                ($match.Index + $match.Length) -gt $_.Index
        }).Count -ne 0) { continue }
        $key = $match.Groups['label'].Value.Trim()
        if (-not $definitions.ContainsKey($key)) { continue }
        $link = [pscustomobject]@{
            Index = $match.Index; Length = $match.Length
            Label = $match.Groups['label'].Value
            Target = [string]$definitions[$key].Target
            Style = 'Reference'; ReferenceKey = $key
        }
        $links.Add($link); $occupied.Add($link)
    }
    [pscustomobject]@{
        Links = @($links)
        Definitions = @($definitionMatches)
        Unresolved = @($unresolvedReferences)
        CodeSpans = @($codeSpans)
        HtmlComments = @($htmlCommentSpans)
        NonRenderingHtml = @($nonRenderingHtmlSpans)
        EscapedLinks = @($escapedLinkSpans)
    }
}

function Get-UnlinkedReferenceText {
    param(
        [AllowEmptyString()][string]$Markdown,
        $Evidence = $null
    )

    if ($null -eq $Evidence) {
        $Evidence = Get-MarkdownLinkEvidence -Markdown $Markdown
    }
    $remaining = [string]$Markdown
    $spans = @($Evidence.Links) + @($Evidence.Definitions | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    }) + @($Evidence.CodeSpans | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    }) + @($Evidence.HtmlComments | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    }) + @($Evidence.NonRenderingHtml | ForEach-Object {
        [pscustomobject]@{ Index = $_.Index; Length = $_.Length }
    })
    foreach ($span in @($spans | Sort-Object Index -Descending)) {
        $remaining = $remaining.Remove([int]$span.Index, [int]$span.Length).Insert(
            [int]$span.Index, (' ' * [int]$span.Length)
        )
    }
    $withoutUris = [regex]::Replace(
        $remaining,
        '(?:<)?https?://[^\s)>\uE000-\uE002]+(?:>)?',
        ''
    )
    return ConvertTo-MarkdownRenderedText -Text $withoutUris
}

function Get-MarkdownRenderedReferenceEvidence {
    param(
        [AllowEmptyString()][string]$Markdown,
        $Evidence = $null
    )

    if ($null -eq $Evidence) {
        $Evidence = Get-MarkdownLinkEvidence -Markdown $Markdown
    }
    $rendered = [string]$Markdown
    $replacementSpans = [System.Collections.Generic.List[object]]::new()
    for ($linkIndex = 0; $linkIndex -lt @($Evidence.Links).Count;
        $linkIndex++) {
        $link = @($Evidence.Links)[$linkIndex]
        $replacementSpans.Add([pscustomobject]@{
            Index = [int]$link.Index
            Length = [int]$link.Length
            Replacement = ([string][char]0xE000) + $linkIndex +
                ([string][char]0xE001) + [string]$link.Label +
                ([string][char]0xE002)
        })
    }
    foreach ($span in @($Evidence.Definitions) + @($Evidence.CodeSpans) +
        @($Evidence.HtmlComments) + @($Evidence.NonRenderingHtml)) {
        if (Test-MarkdownSpanOverlap -Index ([int]$span.Index) `
            -Length ([int]$span.Length) -Spans @($Evidence.Links)) {
            continue
        }
        $replacementSpans.Add([pscustomobject]@{
            Index = [int]$span.Index
            Length = [int]$span.Length
            Replacement = ''
        })
    }
    $bareUrlIgnoredSpans = @($Evidence.Links) + @($Evidence.Definitions) +
        @($Evidence.CodeSpans) + @($Evidence.HtmlComments) +
        @($Evidence.NonRenderingHtml)
    foreach ($bareUrl in @(Get-MarkdownHttpAutolinkSpans `
        -Markdown ([string]$Markdown))) {
        if (Test-MarkdownSpanOverlap -Index $bareUrl.Index `
            -Length $bareUrl.Length -Spans $bareUrlIgnoredSpans) { continue }
        $hasDecoratedNumericSegment = -not $bareUrl.IsAngle -and
            [regex]::IsMatch(
                [string]$bareUrl.RawValue,
                '(?:\*{1,3}[0-9]+\*{1,3}|~~[0-9]+~~|_{1,2}[0-9]+_{1,2})(?=$|[(/?#&.,;:!])'
            )
        if ($bareUrl.HasMarkupContinuation -or
            $hasDecoratedNumericSegment) { continue }
        $replacementSpans.Add([pscustomobject]@{
            Index = $bareUrl.Index
            Length = $bareUrl.Length
            Replacement = ''
        })
    }
    foreach ($span in @($replacementSpans | Sort-Object Index -Descending)) {
        $rendered = $rendered.Remove($span.Index, $span.Length).Insert(
            $span.Index,
            [string]$span.Replacement
        )
    }
    $rendered = ConvertTo-MarkdownRenderedText -Text $rendered

    $visible = [Text.StringBuilder]::new($rendered.Length)
    $linkSpans = [System.Collections.Generic.List[object]]::new()
    $activeLinkIndex = -1
    $activeStart = -1
    for ($index = 0; $index -lt $rendered.Length;) {
        if ([int][char]$rendered[$index] -eq 0xE000) {
            $markerEnd = $rendered.IndexOf([char]0xE001, $index + 1)
            if ($markerEnd -lt 0) {
                throw 'TEST-0065 rendered Markdown link marker is malformed.'
            }
            $activeLinkIndex = [int]$rendered.Substring(
                $index + 1,
                $markerEnd - $index - 1
            )
            $activeStart = $visible.Length
            $index = $markerEnd + 1
            continue
        }
        if ([int][char]$rendered[$index] -eq 0xE002) {
            if ($activeLinkIndex -lt 0) {
                throw 'TEST-0065 rendered Markdown link marker is unbalanced.'
            }
            $linkSpans.Add([pscustomobject]@{
                Index = $activeStart
                Length = $visible.Length - $activeStart
                Link = @($Evidence.Links)[$activeLinkIndex]
            })
            $activeLinkIndex = -1
            $activeStart = -1
            $index++
            continue
        }
        [void]$visible.Append($rendered[$index])
        $index++
    }
    if ($activeLinkIndex -ge 0) {
        throw 'TEST-0065 rendered Markdown link marker is unclosed.'
    }
    return [pscustomobject]@{
        Text = $visible.ToString()
        Links = @($linkSpans)
    }
}

function Test-RenderedReferenceCoveredByLink {
    param(
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][int]$Length,
        [Parameter(Mandatory)]$RenderedEvidence
    )

    return @($RenderedEvidence.Links | Where-Object {
        $Index -ge [int]$_.Index -and
            ($Index + $Length) -le ([int]$_.Index + [int]$_.Length)
    }).Count -eq 1
}

function Test-MarkdownCollectionContainsExactVisibleUri {
    param(
        [object[]]$MarkdownItems = @(),
        [Parameter(Mandatory)][string]$ExpectedUri
    )

    foreach ($item in $MarkdownItems) {
        $markdown = [string]$item
        $evidence = Get-MarkdownLinkEvidence -Markdown $markdown
        if (@($evidence.Links | Where-Object {
            ([string]$_.Target).Trim().Trim('<', '>') -ceq $ExpectedUri
        }).Count -gt 0) { return $true }
        $visible = $markdown
        $hiddenSpans = @($evidence.CodeSpans) +
            @($evidence.HtmlComments) + @($evidence.NonRenderingHtml) +
            @($evidence.Definitions) +
            @($evidence.Links) + @($evidence.EscapedLinks)
        foreach ($span in @($hiddenSpans | Sort-Object Index -Descending)) {
            $visible = $visible.Remove(
                [int]$span.Index, [int]$span.Length
            ).Insert([int]$span.Index, (' ' * [int]$span.Length))
        }
        foreach ($uriMatch in @(Get-MarkdownHttpAutolinkSpans `
            -Markdown $visible)) {
            $candidate = [string]$uriMatch.Value
            if ($candidate -ceq $ExpectedUri) { return $true }
        }
    }
    return $false
}

function Test-ContainsExactDocumentTitle {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Title
    )

    return [regex]::IsMatch(
        $Text,
        '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($Title) +
            '(?![A-Za-z0-9])'
    )
}

function Get-CanonicalDocumentTitles {
    param([Parameter(Mandatory)][string]$Markdown)

    $heading = [regex]::Match($Markdown, '(?m)^#\s+(?<title>.+?)\s*$')
    if (-not $heading.Success) { return @() }
    $titles = @($heading.Groups['title'].Value.Trim())
    $descriptive = [regex]::Match(
        $titles[0],
        '^(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}\s+-\s+(?<title>.+)$'
    )
    if ($descriptive.Success) {
        $titles += $descriptive.Groups['title'].Value.Trim()
    }
    return @($titles | Where-Object { $_.Length -ge 12 } | Select-Object -Unique)
}

function Get-CanonicalDocumentOwnedIds {
    param([Parameter(Mandatory)][string]$Markdown)

    $recordPattern = '(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}'
    $ownedIds = @()
    $headingIdentity = [regex]::Match(
        $Markdown,
        "(?m)^#\s+(?<id>$recordPattern)(?:\s+-|\s*$)"
    )
    if ($headingIdentity.Success) {
        $ownedIds += $headingIdentity.Groups['id'].Value
    }
    $ownedIds += @([regex]::Matches(
        $Markdown,
        "(?m)^\|\s*``(?<id>$recordPattern)``\s*\|"
    ) | ForEach-Object { $_.Groups['id'].Value })
    return @($ownedIds | Select-Object -Unique)
}

function Get-PrimarySurfaceRecordId {
    param([AllowEmptyString()][string]$Text)

    $match = [regex]::Match(
        $Text,
        '^\s*(?:\[(?<id>(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4})\]|(?<id>(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}))(?:\s|[-:])'
    )
    if ($match.Success) { return $match.Groups['id'].Value }
    return ''
}

function Get-OwnSurfaceTitles {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowEmptyString()][string]$PrimaryRecordId,
        [hashtable]$ExpectedRecordTitles
    )

    $subject = $Text.Trim()
    if (-not [string]::IsNullOrEmpty($PrimaryRecordId)) {
        $subject = [regex]::Replace(
            $subject,
            '^\s*(?:\[' + [regex]::Escape($PrimaryRecordId) + '\]|' +
                [regex]::Escape($PrimaryRecordId) + ')\s*(?:[-:]\s*)?',
            ''
        ).Trim()
    }
    return @($ExpectedRecordTitles.Keys | Where-Object {
        $subject -ieq [string]$_
    })
}

function Resolve-RepositoryDocumentPath {
    param(
        [AllowEmptyString()][string]$SourceRepositoryPath,
        [Parameter(Mandatory)][string]$Target
    )

    $cleanTarget = $Target.Trim().Trim('<', '>') -replace '[?#].*$', ''
    $absolute = [regex]::Match(
        $cleanTarget,
        '^https://github\.com/' + [regex]::Escape($Repository) +
            '/blob/' + [regex]::Escape($DefaultBranch) + '/(?<path>.+)$'
    )
    if ($absolute.Success) {
        return [uri]::UnescapeDataString($absolute.Groups['path'].Value).Replace('\', '/')
    }
    if ($cleanTarget -match '^https?://' -or
        [string]::IsNullOrEmpty($SourceRepositoryPath)) {
        return ''
    }
    if ($Target.Trim().StartsWith('#')) {
        return $SourceRepositoryPath
    }

    $sourceSegments = [Collections.Generic.List[string]]::new()
    $sourceDirectory = [IO.Path]::GetDirectoryName($SourceRepositoryPath)
    if (-not [string]::IsNullOrEmpty($sourceDirectory)) {
        foreach ($segment in $sourceDirectory.Replace('\', '/').Split('/')) {
            if (-not [string]::IsNullOrEmpty($segment)) { $sourceSegments.Add($segment) }
        }
    }
    foreach ($segment in ([uri]::UnescapeDataString($cleanTarget).Replace('\', '/').Split('/'))) {
        if ([string]::IsNullOrEmpty($segment) -or $segment -ceq '.') { continue }
        if ($segment -ceq '..') {
            if ($sourceSegments.Count -eq 0) { return '' }
            $sourceSegments.RemoveAt($sourceSegments.Count - 1)
            continue
        }
        $sourceSegments.Add($segment)
    }
    return $sourceSegments -join '/'
}

function Test-ExactCrossRecordTarget {
    param(
        [AllowEmptyString()][string]$SourceRepositoryPath,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$ExpectedTarget
    )

    $cleanTarget = $Target.Trim().Trim('<', '>')
    if ($cleanTarget -ceq $ExpectedTarget) { return $true }
    $expectedPath = Resolve-RepositoryDocumentPath `
        -SourceRepositoryPath '' -Target $ExpectedTarget
    if ([string]::IsNullOrEmpty($expectedPath)) { return $false }
    $actualPath = Resolve-RepositoryDocumentPath `
        -SourceRepositoryPath $SourceRepositoryPath -Target $cleanTarget
    return -not [string]::IsNullOrEmpty($actualPath) -and
        $actualPath -ceq $expectedPath
}

function Test-VisibleRepositoryPathMatchesLinkTarget {
    param(
        [AllowEmptyString()][string]$SourceRepositoryPath,
        [Parameter(Mandatory)][string]$VisiblePath,
        [Parameter(Mandatory)][string]$Target
    )

    $visibleTarget = $VisiblePath.Trim().Trim('<', '>')
    $actualTarget = $Target.Trim().Trim('<', '>')
    $visibleFragment = ''
    $actualFragment = ''
    if ($visibleTarget.Contains('#')) {
        $visibleFragment = '#' + ($visibleTarget -split '#', 2)[1]
    }
    if ($actualTarget.Contains('#')) {
        $actualFragment = '#' + ($actualTarget -split '#', 2)[1]
    }
    $visiblePath = Resolve-RepositoryDocumentPath `
        -SourceRepositoryPath $SourceRepositoryPath `
        -Target $visibleTarget
    if ([string]::IsNullOrEmpty($visiblePath) -and
        [string]::IsNullOrEmpty($SourceRepositoryPath) -and
        $visibleTarget -cnotmatch '^(?:\.\./|https?://)') {
        $visiblePath = ([uri]::UnescapeDataString(
            ($visibleTarget -replace '[?#].*$', '')
        )).Replace('\', '/').TrimStart('./')
    }
    $actualPath = Resolve-RepositoryDocumentPath `
        -SourceRepositoryPath $SourceRepositoryPath `
        -Target $actualTarget
    return -not [string]::IsNullOrEmpty($visiblePath) -and
        $actualPath -ceq $visiblePath -and
        ([string]::IsNullOrEmpty($visibleFragment) -or
            $actualFragment -ceq $visibleFragment)
}

function Test-ExactGitHubShorthandTarget {
    param(
        [Parameter(Mandatory)]$Reference,
        [Parameter(Mandatory)][string]$Target
    )

    $cleanTarget = $Target.Trim().Trim('<', '>')
    $repositoryParts = @($Repository.Split('/'))
    $currentOwner = $repositoryParts[0]
    $currentRepositoryName = $repositoryParts[1]
    if ([string]$Reference.Kind -in @('comment', 'review')) {
        $commentTarget = [regex]::Match(
            $cleanTarget,
            '^https://github\.com/(?<owner>[^/]+)/(?<repository>[^/]+)/(?:(?:issues|pull)/\d+#(?:(?:issuecomment|pullrequestreview)-(?<id>\d+)|discussion_r(?<id>\d+))|commit/[0-9a-f]{40}#commitcomment-(?<id>\d+)|discussions/\d+#discussioncomment-(?<id>\d+))$'
        )
        return $commentTarget.Success -and
            [long]$commentTarget.Groups['id'].Value -eq
                [long]$Reference.Number -and
            $commentTarget.Groups['owner'].Value -ieq $currentOwner -and
            $commentTarget.Groups['repository'].Value -ieq
                $currentRepositoryName
    }

    $artifactTarget = [regex]::Match(
        $cleanTarget,
        '^https://github\.com/(?<owner>[^/]+)/(?<repository>[^/]+)/(?<kind>issues|pull)/(?<number>[1-9][0-9]*)$'
    )
    if (-not $artifactTarget.Success -or
        [long]$artifactTarget.Groups['number'].Value -ne
            [long]$Reference.Number) {
        return $false
    }
    switch ([string]$Reference.Kind) {
        'pr' {
            return $artifactTarget.Groups['kind'].Value -ceq 'pull' -and
                $artifactTarget.Groups['owner'].Value -ieq $currentOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    $currentRepositoryName
        }
        'issue' {
            return $artifactTarget.Groups['kind'].Value -ceq 'issues' -and
                $artifactTarget.Groups['owner'].Value -ieq $currentOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    $currentRepositoryName
        }
        'repository' {
            $expectedOwner = if ([string]::IsNullOrEmpty(
                [string]$Reference.Owner
            )) { $currentOwner } else { [string]$Reference.Owner }
            return $artifactTarget.Groups['owner'].Value -ieq $expectedOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    [string]$Reference.RepositoryName
        }
        default {
            return $artifactTarget.Groups['owner'].Value -ieq $currentOwner -and
                $artifactTarget.Groups['repository'].Value -ieq
                    $currentRepositoryName
        }
    }
}

function Assert-NoCrossRecordReferenceInNonRenderingTitle {
    param(
        [AllowEmptyString()][string]$Title,
        [Parameter(Mandatory)][string]$Surface,
        [string[]]$AllowedRecordIds = @(),
        [string[]]$AllowedRecordTitles = @(),
        [hashtable]$ExpectedRecordTitles = @{},
        [ValidateSet('issue', 'pull')][string]$OwnGitHubIdentityKind,
        [Parameter(Mandatory)][long]$OwnGitHubIdentityNumber
    )

    $visible = ConvertTo-MarkdownRenderedText -Text $Title
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            $visible,
            '(?<!\\)\[[^\]]+\]\([^)]+\)'
        )) `
        "$Surface contains Markdown link syntax, but GitHub titles do not render clickable links."

    $remaining = $visible
    foreach ($allowedId in $AllowedRecordIds) {
        $remaining = [regex]::Replace(
            $remaining,
            '(?<![A-Za-z0-9_-])' + [regex]::Escape($allowedId) +
                '(?![A-Za-z0-9_-])',
            ''
        )
    }
    foreach ($allowedTitle in $AllowedRecordTitles) {
        $remaining = [regex]::Replace(
            $remaining,
            '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($allowedTitle) +
                '(?![A-Za-z0-9])',
            ''
        )
    }

    $ownNumber = [regex]::Escape([string]$OwnGitHubIdentityNumber)
    $ownIdentityPattern = if ($OwnGitHubIdentityKind -ceq 'issue') {
        '(?i)(?<![A-Za-z0-9_])(?:issue\s+#?' + $ownNumber +
            '|issue-' + $ownNumber + '|#' + $ownNumber +
            ')(?![A-Za-z0-9_-])'
    }
    else {
        '(?i)(?<![A-Za-z0-9_])(?:(?:PR|pull request)\s+#?' +
            $ownNumber + '|PR-' + $ownNumber + '|#' + $ownNumber +
            ')(?![A-Za-z0-9_-])'
    }
    $remaining = [regex]::Replace($remaining, $ownIdentityPattern, '')
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            $remaining,
            '(?<![A-Za-z0-9_-])(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}(?![A-Za-z0-9_-])'
        )) `
        "$Surface contains a cross-record identifier on a non-rendering title surface."
    foreach ($title in $ExpectedRecordTitles.Keys) {
        if ($AllowedRecordTitles -contains [string]$title) { continue }
        Assert-PostPublicationCondition `
            (-not (Test-ContainsExactDocumentTitle `
                -Text $remaining -Title ([string]$title))) `
            "$Surface contains a document-title reference on a non-rendering title surface."
    }
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            $remaining,
            '(?i)(?<![A-Za-z0-9_./-])(?:\.{0,2}/)?(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.md(?:#[A-Za-z0-9_.:-]+)?(?![A-Za-z0-9_.-])'
        )) `
        "$Surface contains a repository-document path on a non-rendering title surface."
    Assert-PostPublicationCondition `
        (@(Get-GitHubShorthandReferences -Text $remaining).Count -eq 0) `
        "$Surface contains a GitHub shorthand reference on a non-rendering title surface."
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            $remaining,
            '(?i)(?<![A-Za-z0-9_])(?:(?:issue|PR|pull request)\s+#?|#)[1-9][0-9]*(?![A-Za-z0-9_-])|\b(?:(?:issue|PR|pull request|commit|discussion)\s+)?comment\s+#?\d+\b|\breview\s+#?\d+\b'
        )) `
        "$Surface contains a GitHub record number on a non-rendering title surface."
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch($remaining, '(?i)https?://')) `
        "$Surface contains a URL on a non-rendering title surface."
}

function Assert-NoFreeTextCrossRecordReference {
    param(
        [AllowEmptyString()][string]$Markdown,
        [Parameter(Mandatory)][string]$Surface,
        [string[]]$ExpectedRepositoryPaths = @(),
        [string[]]$AllowedRecordIds = @(),
        [string[]]$AllowedRecordTitles = @(),
        [hashtable]$ExpectedRecordTargets = @{},
        [hashtable]$ExpectedRecordTitles = @{},
        [string]$SourceRepositoryPath = '',
        [switch]$RequireAbsoluteTargets,
        [ValidateSet('', 'issue', 'pull', 'comment')]
        [string]$OwnGitHubIdentityKind = '',
        [long]$OwnGitHubIdentityNumber = 0
    )

    $recordPattern = '(?<![A-Za-z0-9_-])(?:EPIC|FEAT|SUBF|TASK|BUG|FIND|DEC|TEST|RISK|IDEA|MIG)-\d{4}(?![A-Za-z0-9_-])'
    $documentPathPattern = '(?i)(?<![A-Za-z0-9_./-])(?:\.{0,2}/)?(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.md(?:#[A-Za-z0-9_.:-]+)?(?![A-Za-z0-9_.-])'
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            [string]$Markdown,
            '(?i)https?://[^\s\[\]<>()]*\[[^\]]+\](?:\([^)]+\)|[ \t]*\[[^\]]*\])[^\s<>()]*'
        )) `
        "$Surface composes a visible URL across a partial Markdown link."
    $linkEvidence = Get-MarkdownLinkEvidence -Markdown $Markdown
    foreach ($composedLink in @($linkEvidence.Links)) {
        $prefix = $Markdown.Substring(0, [int]$composedLink.Index)
        Assert-PostPublicationCondition `
            (-not [regex]::IsMatch(
                $prefix,
                '(?i)https?://[^\s<>()\[\]]*$'
            )) `
            "$Surface composes a visible URL across a partial Markdown link."
    }
    foreach ($definition in @($linkEvidence.Definitions)) {
        $definitionKey = $definition.Groups['key'].Value.Trim()
        $isUsed = @($linkEvidence.Links | Where-Object {
            $_.Style -ceq 'Reference' -and
                $_.ReferenceKey -ieq $definitionKey
        }).Count -gt 0
        if ($isUsed) { continue }
        $definitionText = ConvertTo-MarkdownRenderedText `
            -Text ([string]$definition.Value)
        Assert-PostPublicationCondition `
            (-not [regex]::IsMatch(
                $definitionText,
                $recordPattern + '|' + $documentPathPattern +
                    '|(?i:https?://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/[1-9][0-9]*|blob/[^<>\s]+))'
            ) -and
                @(Get-GitHubShorthandReferences `
                    -Text $definitionText).Count -eq 0) `
            "$Surface contains an unused reference-link definition with a non-clickable cross-record reference."
    }
    Assert-PostPublicationCondition `
        (@($linkEvidence.Unresolved).Count -eq 0) `
        "$Surface contains an unresolved reference-style link."
    foreach ($htmlComment in @($linkEvidence.HtmlComments)) {
        $commentContent = [regex]::Replace(
            [string]$htmlComment.Value,
            '(?s)^<!--|-->$',
            ''
        )
        $hiddenText = ConvertTo-MarkdownRenderedText `
            -Text $commentContent
        Assert-PostPublicationCondition `
            (-not [regex]::IsMatch(
                $hiddenText,
                $recordPattern + '|' + $documentPathPattern +
                    '|(?i:https?://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/[1-9][0-9]*|blob/[^<>\s]+))' +
                    '|(?i:(?<![A-Za-z0-9_])(?:issue|PR|pull request|comment|review)\s+#?[1-9][0-9]*)' +
                    '|(?i:(?<![A-Za-z0-9_])(?:GH|issue|pr|comment|review)-[1-9][0-9]*(?![A-Za-z0-9_-]))'
            ) -and
                @(Get-GitHubShorthandReferences -Text $hiddenText).Count -eq 0) `
            "$Surface hides a cross-record reference in a non-clickable HTML comment."
    }
    foreach ($htmlBlock in @($linkEvidence.NonRenderingHtml)) {
        $literalHtmlText = ConvertTo-MarkdownRenderedText `
            -Text ([string]$htmlBlock.Value)
        Assert-PostPublicationCondition `
            (-not [regex]::IsMatch(
                $literalHtmlText,
                $recordPattern + '|' + $documentPathPattern +
                    '|(?i:https?://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/[1-9][0-9]*|blob/[^<>\s]+))' +
                    '|(?i:(?<![A-Za-z0-9_])(?:issue|PR|pull request|comment|review)\s+#?[1-9][0-9]*)'
            ) -and
                @(Get-GitHubShorthandReferences `
                    -Text $literalHtmlText).Count -eq 0) `
            "$Surface contains a cross-record reference inside non-rendering HTML."
    }
    foreach ($codeMatch in @($linkEvidence.CodeSpans)) {
        $codeIsInsideClickableLink = @($linkEvidence.Links | Where-Object {
            $codeMatch.Index -ge $_.Index -and
                ($codeMatch.Index + $codeMatch.Length) -le
                    ($_.Index + $_.Length)
        }).Count -gt 0
        if ($codeIsInsideClickableLink) { continue }
        $codeText = [string]$codeMatch.Content
        $beforeStart = [Math]::Max(0, $codeMatch.Index - 80)
        $before = $Markdown.Substring(
            $beforeStart,
            $codeMatch.Index - $beforeStart
        )
        $afterStart = $codeMatch.Index + $codeMatch.Length
        $after = $Markdown.Substring(
            $afterStart,
            [Math]::Min(80, $Markdown.Length - $afterStart)
        )
        $codeDocumentReference = [regex]::IsMatch(
            $codeText, $documentPathPattern
        ) -and [regex]::IsMatch(
            $before,
            '(?i)\b(?:see|read|open|consult|reference(?:d)?(?:\s+to)?|recorded\s+in|documented\s+in|defined\s+in|described\s+in|according\s+to|details\s+in)\s*$'
        ) -or ([regex]::IsMatch($codeText, $documentPathPattern) -and
            [regex]::IsMatch(
                $after,
                '(?i)^\s+for\s+(?:details|context|more\s+information)\b'
            ))
        $codeMarkdownDocumentLink = [regex]::IsMatch(
            $codeText,
            '(?i)(?<![!\\])\[[^\]]+\]\((?:[^)\s]+\.md(?:#[A-Za-z0-9_.:-]+)?|https?://github\.com/[^/]+/[^/]+/blob/[^)\s]+)\)'
        )
        $codeReferenceText = $codeText
        foreach ($allowedId in $AllowedRecordIds) {
            $codeReferenceText = [regex]::Replace(
                $codeReferenceText,
                '(?<![A-Za-z0-9_-])' + [regex]::Escape($allowedId) +
                    '(?![A-Za-z0-9_-])',
                ''
            )
        }
        $codeTitleReference = $false
        foreach ($title in $ExpectedRecordTitles.Keys) {
            if ($AllowedRecordTitles -contains [string]$title) { continue }
            if ((Test-ContainsExactDocumentTitle `
                    -Text $codeText -Title ([string]$title)) -and
                ([regex]::IsMatch(
                    $codeText,
                    '(?i)(?<![!\\])\[[^\]]*' + [regex]::Escape([string]$title) +
                        '[^\]]*\]\([^)]+\)'
                ) -or [regex]::IsMatch(
                    $before,
                    '(?i)\b(?:see|read|open|consult|reference(?:d)?(?:\s+to)?|according\s+to|documented\s+in|described\s+in)\s*$'
                ) -or [regex]::IsMatch(
                    $after,
                    '(?i)^\s+(?:document|record|guide|is\s+authoritative|governs|defines|for\s+(?:details|context))\b'
                ))) {
                $codeTitleReference = $true
                break
            }
        }
        if ([regex]::IsMatch($codeReferenceText, $recordPattern) -or
            $codeDocumentReference -or
            $codeMarkdownDocumentLink -or
            $codeTitleReference -or
            @(Get-GitHubShorthandReferences `
                -Text $codeReferenceText).Count -gt 0 -or
            [regex]::IsMatch(
                $codeReferenceText,
                '(?i)https?://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/[1-9][0-9]*|blob/[^<>\s]+)|\b(?:issue|PR|pull request|comment)\s+#?\d+\b'
            )) {
            throw "TEST-0065 $Surface contains a code-formatted cross-record reference that is not clickable."
        }
    }

    foreach ($linkMatch in @($linkEvidence.Links)) {
        $label = ConvertTo-MarkdownRenderedText `
            -Text ([string]$linkMatch.Label)
        $target = [string]$linkMatch.Target
        foreach ($visibleUrl in @(Get-MarkdownVisibleHttpUrlSpans `
            -Text $label)) {
            $expectedUrl = [string]$visibleUrl.Value
            Assert-PostPublicationCondition `
                ($target.Trim().Trim('<', '>') -ceq $expectedUrl) `
                "$Surface links visible URL '$expectedUrl' to a different target."
        }
        foreach ($visiblePath in [regex]::Matches(
            $label,
            $documentPathPattern
        )) {
            Assert-PostPublicationCondition `
                (Test-VisibleRepositoryPathMatchesLinkTarget `
                    -SourceRepositoryPath $SourceRepositoryPath `
                    -VisiblePath ([string]$visiblePath.Value) `
                    -Target $target) `
                "$Surface links visible repository-document path '$($visiblePath.Value)' to a different target."
        }
        if ($RequireAbsoluteTargets) {
            $cleanTarget = $target.Trim().Trim('<', '>')
            Assert-PostPublicationCondition `
                ($cleanTarget -cmatch '^(?:https?://|mailto:|tel:|#)') `
                "$Surface contains a relative repository-document link instead of an absolute or same-artifact exact target."
        }
        $isCommentReference = [regex]::IsMatch(
            $target,
            '^https://github\.com/[^/]+/[^/]+/(?:(?:issues|pull)/\d+#(?:(?:issuecomment|pullrequestreview)-\d+|discussion_r\d+)|commit/[0-9a-f]{40}#commitcomment-\d+|discussions/\d+#discussioncomment-\d+)$'
        ) -or [regex]::IsMatch(
            $label,
            '(?i)\b(?:comment|review)\s+#?\d+\b'
        ) -or ([regex]::IsMatch(
            $target,
            '^https://github\.com/[^/]+/[^/]+/(?:issues|pull|commit|discussions)/'
        ) -and [regex]::IsMatch(
            $label,
            '(?i)\bcomment\b|\b(?:submitted|inline)\s+review\b'
        ))
        if ($isCommentReference) {
            $commentTarget = [regex]::Match(
                $target,
                '^https://github\.com/[^/]+/[^/]+/(?:(?<parentKind>issues|pull)/(?<parentNumber>\d+)#(?:(?:issuecomment|pullrequestreview)-(?<id>\d+)|discussion_r(?<id>\d+))|commit/[0-9a-f]{40}#commitcomment-(?<id>\d+)|discussions/\d+#discussioncomment-(?<id>\d+))$'
            )
            Assert-PostPublicationCondition $commentTarget.Success `
                "$Surface contains a comment link that is not an exact GitHub comment permalink."
            $labelId = [regex]::Match(
                $label,
                '(?i)\b(?:comment|review)\s+#?(?<id>\d+)\b'
            )
            Assert-PostPublicationCondition `
                (-not $labelId.Success -or
                    $labelId.Groups['id'].Value -ceq $commentTarget.Groups['id'].Value) `
                "$Surface contains a comment label that does not match its permalink target."
            $parentLabel = [regex]::Match(
                $label,
                '(?i)\b(?<kind>issue|PR|pull request)\s+#?(?<number>\d+)\s+(?:comment|(?:submitted|inline)\s+review)\b'
            )
            if ($parentLabel.Success) {
                $expectedParentKind = if (
                    $parentLabel.Groups['kind'].Value -ieq 'issue'
                ) { 'issues' } else { 'pull' }
                Assert-PostPublicationCondition `
                    ($commentTarget.Groups['parentKind'].Value -ceq
                        $expectedParentKind -and
                        $commentTarget.Groups['parentNumber'].Value -ceq
                            $parentLabel.Groups['number'].Value) `
                    "$Surface contains a comment parent label that does not match its permalink target."
            }
            $numericArtifactOrBareLabel = [regex]::Match(
                $label,
                '(?i)(?<![A-Za-z0-9_])(?:(?:issue|PR|pull request)\s+#?|#)[1-9][0-9]*(?![A-Za-z0-9_-])'
            )
            Assert-PostPublicationCondition `
                (-not $numericArtifactOrBareLabel.Success -or
                    $parentLabel.Success -or $labelId.Success) `
                "$Surface uses an issue, pull-request, or bare numeric label for a comment target."
        }
        else {
            $numericLabels = @([regex]::Matches(
                $label,
                '(?i)(?<![A-Za-z0-9_])(?:(?<kind>issue|PR|pull request)\s+#?|#)(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
            ))
            if ($numericLabels.Count -eq 0) {
                $numberOnlyLabel = [regex]::Match(
                    $label.Trim(), '^(?<number>[1-9][0-9]*)$'
                )
                if ($numberOnlyLabel.Success -and [regex]::IsMatch(
                    $target,
                    '^https://github\.com/[^/]+/[^/]+/(?:issues|pull)/[1-9][0-9]*$'
                )) {
                    $numericLabels = @($numberOnlyLabel)
                }
            }
            Assert-PostPublicationCondition ($numericLabels.Count -le 1) `
                "$Surface combines multiple numeric record references in one link."
            foreach ($numericLabel in $numericLabels) {
                $numericTarget = [regex]::Match(
                    $target,
                    '^https://github\.com/[^/]+/[^/]+/(?<kind>issues|pull)/(?<number>[1-9][0-9]*)$'
                )
                Assert-PostPublicationCondition `
                    ($numericTarget.Success -and
                        $numericLabel.Groups['number'].Value -ceq
                            $numericTarget.Groups['number'].Value) `
                    "$Surface contains a numeric link label that does not match its exact issue or pull-request target."
                $declaredKind = $numericLabel.Groups['kind'].Value
                if (-not [string]::IsNullOrEmpty($declaredKind)) {
                    $expectedKind = if ($declaredKind -ieq 'issue') { 'issues' } else { 'pull' }
                    Assert-PostPublicationCondition `
                        ($numericTarget.Groups['kind'].Value -ceq $expectedKind) `
                        "$Surface contains a numeric link label whose issue or pull-request kind does not match its target."
                }
            }
        }
        foreach ($idMatch in [regex]::Matches($label, $recordPattern)) {
            $recordId = $idMatch.Value
            if ($ExpectedRecordTargets.ContainsKey($recordId)) {
                $expectedTarget = [string]$ExpectedRecordTargets[$recordId]
                Assert-PostPublicationCondition `
                    (Test-ExactCrossRecordTarget `
                        -SourceRepositoryPath $SourceRepositoryPath `
                        -Target $target -ExpectedTarget $expectedTarget) `
                "$Surface links $recordId to a target other than its exact canonical target."
            }
        }
        foreach ($title in $ExpectedRecordTitles.Keys) {
            if (Test-ContainsExactDocumentTitle -Text $label -Title $title) {
                Assert-PostPublicationCondition `
                    (Test-ExactCrossRecordTarget `
                        -SourceRepositoryPath $SourceRepositoryPath `
                        -Target $target `
                        -ExpectedTarget ([string]$ExpectedRecordTitles[$title])) `
                    "$Surface links document title '$title' to a target other than its exact canonical target."
                }
        }
        $shorthandReferences = @(
            Get-GitHubShorthandReferences -Text $label
        )
        Assert-PostPublicationCondition ($shorthandReferences.Count -le 1) `
            "$Surface combines multiple GitHub shorthand references in one link."
        foreach ($shorthandReference in $shorthandReferences) {
            Assert-PostPublicationCondition `
                (Test-ExactGitHubShorthandTarget `
                    -Reference $shorthandReference -Target $target) `
                "$Surface links GitHub shorthand '$($shorthandReference.Value)' to a target other than its exact GitHub record."
        }
    }

    $unlinked = Get-UnlinkedReferenceText -Markdown $Markdown -Evidence $linkEvidence
    $numericRemaining = $unlinked
    if ($OwnGitHubIdentityNumber -gt 0) {
        $ownNumber = [regex]::Escape([string]$OwnGitHubIdentityNumber)
        $ownPattern = switch ($OwnGitHubIdentityKind) {
            'issue' {
                '(?i)(?<![A-Za-z0-9_])issue\s+#?' + $ownNumber +
                    '(?![A-Za-z0-9_-])'
            }
            'pull' {
                '(?i)(?<![A-Za-z0-9_])(?:PR|pull request)\s+#?' +
                    $ownNumber + '(?![A-Za-z0-9_-])'
            }
            'comment' {
                '(?i)(?<![A-Za-z0-9_])(?:comment|review)\s+#?' + $ownNumber +
                    '(?![A-Za-z0-9_-])'
            }
            default { '(?!)' }
        }
        $numericRemaining = [regex]::Replace(
            $numericRemaining,
            $ownPattern,
            ''
        )
    }
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            $numericRemaining,
            '(?i)\b(?:(?:issue|PR|pull request|commit|discussion)\s+)?comment\s+#?\d+\b|\b(?:submitted|inline)\s+review\s+#?\d+\b|\breview\s+#?\d+\b'
        )) `
        "$Surface contains a free-text comment reference without an exact permalink."
    foreach ($numericReference in [regex]::Matches(
        $numericRemaining,
        '(?i)(?<![A-Za-z0-9_])(?:(?<kind>issue|PR|pull request)\s+#?|#)(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
    )) {
        $declaredKind = [string]$numericReference.Groups['kind'].Value
        $matchesOwnIdentity = $OwnGitHubIdentityNumber -gt 0 -and
            [long]$numericReference.Groups['number'].Value -eq
                $OwnGitHubIdentityNumber -and
            ([string]::IsNullOrEmpty($declaredKind) -or
                ($OwnGitHubIdentityKind -ceq 'issue' -and
                    $declaredKind -ieq 'issue') -or
                ($OwnGitHubIdentityKind -ceq 'pull' -and
                    $declaredKind -imatch '^(?:PR|pull request)$'))
        Assert-PostPublicationCondition $matchesOwnIdentity `
            "$Surface contains a free-text cross-record reference by number."
    }
    foreach ($shorthandReference in @(
        Get-GitHubShorthandReferences -Text $numericRemaining
    )) {
        $matchesOwnIdentity =
            $OwnGitHubIdentityNumber -gt 0 -and
            [long]$shorthandReference.Number -eq $OwnGitHubIdentityNumber -and
            (($OwnGitHubIdentityKind -ceq 'issue' -and
                [string]$shorthandReference.Kind -ceq 'issue') -or
                ($OwnGitHubIdentityKind -ceq 'pull' -and
                    [string]$shorthandReference.Kind -ceq 'pr') -or
                ($OwnGitHubIdentityKind -ceq 'comment' -and
                    [string]$shorthandReference.Kind -in
                        @('comment', 'review')))
        Assert-PostPublicationCondition $matchesOwnIdentity `
            "$Surface contains a free-text GitHub shorthand reference."
    }
    $remaining = $numericRemaining
    foreach ($allowedId in $AllowedRecordIds) {
        $remaining = [regex]::Replace(
            $remaining,
            '(?<![A-Za-z0-9_-])' + [regex]::Escape($allowedId) +
                '(?![A-Za-z0-9_-])',
            ''
        )
    }
    $freeIds = @([regex]::Matches($remaining, $recordPattern) |
        ForEach-Object { $_.Value } | Select-Object -Unique)
    Assert-PostPublicationCondition ($freeIds.Count -eq 0) `
        "$Surface contains a free-text cross-record reference: $($freeIds -join ', ')."
    foreach ($title in $ExpectedRecordTitles.Keys) {
        if ($AllowedRecordTitles -contains [string]$title) { continue }
        Assert-PostPublicationCondition `
            (-not (Test-ContainsExactDocumentTitle `
                -Text $remaining -Title $title)) `
            "$Surface contains a free-text document-title reference '$title'."
    }

    foreach ($repositoryPath in $ExpectedRepositoryPaths) {
        Assert-PostPublicationCondition (-not $remaining.Contains($repositoryPath)) `
            "$Surface contains a free-text cross-record reference to '$repositoryPath'."
    }
    $proseRemaining = [regex]::Replace(
        $remaining,
        '(?ms)^```[^\r\n]*\r?\n.*?^```\s*$|(?<!`)`[^`\r\n]+`(?!`)',
        ''
    )
    Assert-PostPublicationCondition `
        (-not [regex]::IsMatch(
            $proseRemaining,
            $documentPathPattern
        )) `
        "$Surface contains a free-text repository document path."

    $renderedEvidence = Get-MarkdownRenderedReferenceEvidence `
        -Markdown $Markdown -Evidence $linkEvidence
    foreach ($renderedUrl in [regex]::Matches(
        [string]$renderedEvidence.Text,
        '(?i)https?://[^\s<>()\[\]{}"''`]+'
    )) {
        $urlLength = ([string]$renderedUrl.Value).TrimEnd(
            [char[]]'.,;:!?'
        ).Length
        Assert-PostPublicationCondition `
            (Test-RenderedReferenceCoveredByLink `
                -Index $renderedUrl.Index -Length $urlLength `
                -RenderedEvidence $renderedEvidence) `
            "$Surface contains a visible URL that is not wholly covered by one clickable link."
    }
    foreach ($renderedId in [regex]::Matches(
        [string]$renderedEvidence.Text,
        $recordPattern
    )) {
        if ($AllowedRecordIds -contains [string]$renderedId.Value) { continue }
        Assert-PostPublicationCondition `
            (Test-RenderedReferenceCoveredByLink `
                -Index $renderedId.Index -Length $renderedId.Length `
                -RenderedEvidence $renderedEvidence) `
            "$Surface contains a visible cross-record identifier that is not wholly covered by one clickable link."
    }
    foreach ($renderedNumeric in [regex]::Matches(
        [string]$renderedEvidence.Text,
        '(?i)(?<![A-Za-z0-9_])(?:(?<kind>issue|PR|pull request)\s+#?|#)(?<number>[1-9][0-9]*)(?![A-Za-z0-9_-])'
    )) {
        if (Test-RenderedReferenceCoveredByLink `
            -Index $renderedNumeric.Index -Length $renderedNumeric.Length `
            -RenderedEvidence $renderedEvidence) { continue }
        $declaredKind = [string]$renderedNumeric.Groups['kind'].Value
        $matchesOwnIdentity = $OwnGitHubIdentityNumber -gt 0 -and
            [long]$renderedNumeric.Groups['number'].Value -eq
                $OwnGitHubIdentityNumber -and
            ([string]::IsNullOrEmpty($declaredKind) -or
                ($OwnGitHubIdentityKind -ceq 'issue' -and
                    $declaredKind -ieq 'issue') -or
                ($OwnGitHubIdentityKind -ceq 'pull' -and
                    $declaredKind -imatch '^(?:PR|pull request)$'))
        Assert-PostPublicationCondition $matchesOwnIdentity `
            "$Surface contains a visible GitHub record number that is not wholly covered by one clickable link."
    }
    foreach ($renderedComment in [regex]::Matches(
        [string]$renderedEvidence.Text,
        '(?i)\b(?:comment|review)\s+#?(?<number>[1-9][0-9]*)\b'
    )) {
        if (Test-RenderedReferenceCoveredByLink `
            -Index $renderedComment.Index -Length $renderedComment.Length `
            -RenderedEvidence $renderedEvidence) { continue }
        $matchesOwnComment = $OwnGitHubIdentityKind -ceq 'comment' -and
            $OwnGitHubIdentityNumber -gt 0 -and
            [long]$renderedComment.Groups['number'].Value -eq
                $OwnGitHubIdentityNumber
        Assert-PostPublicationCondition $matchesOwnComment `
            "$Surface contains a visible GitHub comment reference that is not wholly covered by one clickable link."
    }
    foreach ($renderedShorthand in @(
        Get-GitHubShorthandReferences -Text ([string]$renderedEvidence.Text)
    )) {
        if (Test-RenderedReferenceCoveredByLink `
            -Index $renderedShorthand.Index `
            -Length $renderedShorthand.Length `
            -RenderedEvidence $renderedEvidence) { continue }
        $matchesOwnIdentity =
            $OwnGitHubIdentityNumber -gt 0 -and
            [long]$renderedShorthand.Number -eq $OwnGitHubIdentityNumber -and
            (($OwnGitHubIdentityKind -ceq 'issue' -and
                [string]$renderedShorthand.Kind -ceq 'issue') -or
                ($OwnGitHubIdentityKind -ceq 'pull' -and
                    [string]$renderedShorthand.Kind -ceq 'pr') -or
                ($OwnGitHubIdentityKind -ceq 'comment' -and
                    [string]$renderedShorthand.Kind -in
                        @('comment', 'review')))
        Assert-PostPublicationCondition $matchesOwnIdentity `
            "$Surface contains a visible GitHub shorthand that is not wholly covered by one clickable link."
    }
    foreach ($title in $ExpectedRecordTitles.Keys) {
        if ($AllowedRecordTitles -contains [string]$title) { continue }
        foreach ($titlePattern in @(
            '(?i)\b(?:see|read|open|consult|reference(?:d)?(?:\s+to)?|according\s+to|described\s+in|documented\s+in)\s+(?:(?:the|a)\s+)?(?<title>' +
                [regex]::Escape([string]$title) + ')(?![A-Za-z0-9])',
            '(?i)(?<![A-Za-z0-9])(?:(?:the|a)\s+)?(?<title>' +
                [regex]::Escape([string]$title) +
                ')\s+(?:guide|document|record|for\s+(?:details|context)|is\s+authoritative|governs|defines)\b'
        )) {
            foreach ($renderedTitle in [regex]::Matches(
                [string]$renderedEvidence.Text,
                $titlePattern
            )) {
                $titleGroup = $renderedTitle.Groups['title']
                Assert-PostPublicationCondition `
                    (Test-RenderedReferenceCoveredByLink `
                        -Index $titleGroup.Index -Length $titleGroup.Length `
                        -RenderedEvidence $renderedEvidence) `
                    "$Surface contains a visible document-title reference that is not wholly covered by one clickable link."
            }
        }
    }
    foreach ($renderedPath in [regex]::Matches(
        [string]$renderedEvidence.Text,
        $documentPathPattern
    )) {
        $resolvedRenderedPath = Resolve-RepositoryDocumentPath `
            -SourceRepositoryPath $SourceRepositoryPath `
            -Target ([string]$renderedPath.Value)
        if (-not [string]::IsNullOrEmpty($SourceRepositoryPath) -and
            $resolvedRenderedPath -ceq $SourceRepositoryPath) { continue }
        Assert-PostPublicationCondition `
            (Test-RenderedReferenceCoveredByLink `
                -Index $renderedPath.Index -Length $renderedPath.Length `
                -RenderedEvidence $renderedEvidence) `
            "$Surface contains a visible repository-document path that is not wholly covered by one clickable link."
    }
}

Assert-PostPublicationCondition ($Repository -cmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') `
    'repository must be an exact owner/name identity.'
Assert-PostPublicationCondition ($Tag -cmatch '^v(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)$') `
    'release tag must be canonical.'
Assert-PostPublicationCondition ($ExpectedCommit -cmatch '^[0-9a-f]{40}$') `
    'expected commit must be a full lowercase SHA.'
Assert-PostPublicationCondition ($DefaultBranch -cmatch '^[A-Za-z0-9._/-]+$') `
    'default branch contains unsupported characters.'
Assert-PostPublicationCondition ($OwnedBranch -cmatch '^[A-Za-z0-9._/-]+$') `
    'owned branch contains unsupported characters.'
Assert-PostPublicationCondition `
    ($FeaturePath -cmatch '^docs/features/FEAT-\d{4}-[A-Za-z0-9._-]+/README\.md$') `
    'feature path must identify one canonical feature record.'
Assert-PostPublicationCondition (-not [string]::IsNullOrWhiteSpace($Token)) `
    'GitHub API token is required for authoritative post-publication evidence.'

$expectedAssetNames = @($ExpectedReleaseAssetNames)
Assert-PostPublicationCondition ($expectedAssetNames.Count -le 16) `
    'expected release asset inventory exceeds the bounded 16-asset limit.'
$expectedAssetSet = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
foreach ($assetName in $expectedAssetNames) {
    Assert-PostPublicationCondition `
        (-not [string]::IsNullOrWhiteSpace($assetName) -and
            $assetName -cmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -and
            $expectedAssetSet.Add($assetName)) `
        "expected release asset name '$assetName' is unsafe or duplicated."
}
if ($expectedAssetSet.Contains($ExpectedLauncherAssetName)) {
    Assert-PostPublicationCondition `
        ($ExpectedLauncherSourcePath -cmatch
            '^(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -and
            -not $ExpectedLauncherSourcePath.Contains('..') -and
            -not $ExpectedLauncherSourcePath.Contains('\')) `
        'expected launcher source path is unsafe.'
}
if (-not [string]::IsNullOrEmpty($ExpectedBundleAssetName)) {
    Assert-PostPublicationCondition `
        ($expectedAssetSet.Contains($ExpectedBundleAssetName)) `
        'expected bundle asset must be present in the expected release asset inventory.'
    Assert-PostPublicationCondition `
        ($ExpectedBundleSourceInventoryPath -cmatch
            '^(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -and
            -not $ExpectedBundleSourceInventoryPath.Contains('..') -and
            -not $ExpectedBundleSourceInventoryPath.Contains('\')) `
        'expected bundle source inventory path is unsafe.'
}

$headers = @{
    Accept = 'application/vnd.github+json'
    Authorization = "Bearer $Token"
    'User-Agent' = 'meAndAI-post-publication-verifier'
    'X-GitHub-Api-Version' = '2026-03-10'
}
$apiRoot = $ApiBaseUri.TrimEnd('/')
$repositoryApi = "$apiRoot/repos/$Repository"

function Invoke-GitHubGet {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    $uri = if ([string]::IsNullOrEmpty($Path)) {
        $repositoryApi
    }
    else {
        "$repositoryApi/$Path"
    }
    return Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
}

function Invoke-GitHubPagedGet {
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateRange(1, 100)][int]$MaximumPages = 100
    )

    $results = [System.Collections.Generic.List[object]]::new()
    for ($page = 1; $page -le $MaximumPages; $page++) {
        $items = @(Invoke-GitHubGet "$Path`?per_page=100&page=$page")
        foreach ($item in $items) {
            if ($null -ne $item) {
                $results.Add($item)
            }
        }
        if ($items.Count -lt 100) {
            return @($results)
        }
    }
    throw "TEST-0065 GitHub pagination exceeded the bounded $MaximumPages-page evidence limit."
}

function Get-Sha256Hex {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($Bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-GitHubContentBytes {
    param([Parameter(Mandatory)][string]$RepositoryPath)

    $encodedPath = ConvertTo-ApiPath $RepositoryPath
    $contentRecord = Invoke-GitHubGet "contents/$encodedPath`?ref=$ExpectedCommit"
    Assert-PostPublicationCondition ($contentRecord.encoding -ceq 'base64') `
        "released source '$RepositoryPath' was not returned as base64 content."
    try {
        return [Convert]::FromBase64String(
            ([string]$contentRecord.content -replace '\s', '')
        )
    }
    catch {
        throw "TEST-0065 released source '$RepositoryPath' contains invalid base64 content."
    }
}

function Read-ZipEntryBytes {
    param(
        [Parameter(Mandatory)][IO.Compression.ZipArchiveEntry]$Entry,
        [ValidateRange(0, 67108864)][long]$MaximumLength = 16777216
    )

    Assert-PostPublicationCondition ($Entry.Length -le $MaximumLength) `
        "bundle entry '$($Entry.FullName)' exceeds the bounded size limit."
    $stream = $Entry.Open()
    $memory = [IO.MemoryStream]::new()
    try {
        $buffer = [byte[]]::new(81920)
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            Assert-PostPublicationCondition `
                (($memory.Length + $read) -le $MaximumLength) `
                "bundle entry '$($Entry.FullName)' exceeded its bounded read limit."
            $memory.Write($buffer, 0, $read)
        }
        Assert-PostPublicationCondition ($memory.Length -eq $Entry.Length) `
            "bundle entry '$($Entry.FullName)' decompressed to an unexpected length."
        return $memory.ToArray()
    }
    finally {
        $memory.Dispose()
        $stream.Dispose()
    }
}

function Assert-QuickAdoptionBundle {
    param([Parameter(Mandatory)][string]$BundlePath)

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $fileStream = [IO.File]::Open(
        $BundlePath, [IO.FileMode]::Open, [IO.FileAccess]::Read,
        [IO.FileShare]::Read
    )
    $archive = $null
    try {
        $archive = [IO.Compression.ZipArchive]::new(
            $fileStream, [IO.Compression.ZipArchiveMode]::Read, $false,
            [Text.Encoding]::UTF8
        )
        $entries = @($archive.Entries)
        Assert-PostPublicationCondition `
            ($entries.Count -ge 2 -and $entries.Count -le 65) `
            'bundle archive has an invalid bounded entry count.'
        $entryNames = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        $entryByName = [Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        $totalLength = [long]0
        foreach ($entry in $entries) {
            $name = [string]$entry.FullName
            $unsafeComponent = @($name.Split('/') | Where-Object {
                $_.EndsWith('.', [StringComparison]::Ordinal) -or
                [regex]::IsMatch(
                    $_,
                    '^(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
                    [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                        [Text.RegularExpressions.RegexOptions]::CultureInvariant
                )
            }).Count -ne 0
            $unixKind = ([int64]$entry.ExternalAttributes -shr 16) -band 0xF000
            Assert-PostPublicationCondition `
                ($name -cmatch '^(?:manifest\.json|MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+)$' -and
                    -not $name.Contains('\') -and
                    -not $name.StartsWith('/') -and
                    $name -cnotmatch '(^|/)(?:\.|\.\.)(?:/|$)' -and
                    $name -cnotmatch '^[A-Za-z]:' -and
                    -not $unsafeComponent -and
                    $entryNames.Add($name) -and
                    $unixKind -in @(0, 0x8000)) `
                "bundle archive entry '$name' is unsafe, duplicated, or not one regular file."
            $totalLength += [long]$entry.Length
            Assert-PostPublicationCondition ($totalLength -le 67108864) `
                'bundle archive exceeds the bounded decompressed size limit.'
            $entryByName.Add($name, $entry)
        }
        Assert-PostPublicationCondition ($entryByName.ContainsKey('manifest.json')) `
            'bundle archive does not contain its canonical manifest.'

        $manifestBytes = Read-ZipEntryBytes -Entry $entryByName['manifest.json'] `
            -MaximumLength 1048576
        Assert-PostPublicationCondition `
            (-not ($manifestBytes.Length -ge 3 -and
                $manifestBytes[0] -eq 0xEF -and $manifestBytes[1] -eq 0xBB -and
                $manifestBytes[2] -eq 0xBF)) `
            'bundle manifest must be UTF-8 without a byte-order mark.'
        try {
            $manifestText = [Text.UTF8Encoding]::new($false, $true).GetString(
                $manifestBytes
            )
            $manifest = $manifestText | ConvertFrom-Json
        }
        catch {
            throw 'TEST-0065 bundle manifest is not strict UTF-8 JSON.'
        }
        $manifestProperties = @($manifest.PSObject.Properties | ForEach-Object {
            [string]$_.Name
        })
        Assert-PostPublicationCondition `
            (($manifestProperties -join ',') -ceq
                'schema,kind,runtimeRepository,runtimeReleaseTag,sourceCommit,entryPoint,minimumPowerShellVersion,payload') `
            'bundle manifest has an unsupported shape.'
        Assert-PostPublicationCondition `
            (($manifest.schema -is [int] -or $manifest.schema -is [long]) -and
                [long]$manifest.schema -eq 1 -and
                [string]$manifest.kind -ceq 'meandai.quick-adoption.module-bundle' -and
                [string]$manifest.runtimeRepository -ceq $Repository -and
                [string]$manifest.runtimeReleaseTag -ceq $Tag) `
            'bundle manifest identity does not match the immutable release.'
        Assert-PostPublicationCondition `
            ([string]$manifest.sourceCommit -ceq $ExpectedCommit) `
            'bundle manifest source commit does not match the immutable release commit.'
        Assert-PostPublicationCondition `
            ([string]$manifest.minimumPowerShellVersion -ceq '5.1') `
            'bundle manifest minimum PowerShell version is unsupported.'

        $payload = @($manifest.payload)
        Assert-PostPublicationCondition `
            ($payload.Count -ge 1 -and $payload.Count -le 64) `
            'bundle manifest payload inventory is empty or unbounded.'
        $payloadPaths = [Collections.Generic.List[string]]::new()
        $payloadSet = [Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        $payloadByPath = [Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        $payloadDeclaredLength = [long]0
        foreach ($payloadEntry in $payload) {
            $properties = @($payloadEntry.PSObject.Properties | ForEach-Object {
                [string]$_.Name
            })
            $path = [string]$payloadEntry.path
            Assert-PostPublicationCondition `
                (($properties -join ',') -ceq 'path,length,sha256' -and
                    $path -cmatch '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -and
                    $payloadSet.Add($path) -and
                    ($payloadEntry.length -is [int] -or $payloadEntry.length -is [long]) -and
                    [long]$payloadEntry.length -ge 0 -and
                    [string]$payloadEntry.sha256 -cmatch '^[0-9a-f]{64}$') `
                "bundle manifest payload entry '$path' is malformed or duplicated."
            Assert-PostPublicationCondition ($entryByName.ContainsKey($path)) `
                "bundle archive is missing manifest payload '$path'."
            $payloadDeclaredLength += [long]$payloadEntry.length
            Assert-PostPublicationCondition ($payloadDeclaredLength -le 67108864) `
                'bundle manifest payload exceeds the bounded decompressed size limit.'
            $bytes = Read-ZipEntryBytes -Entry $entryByName[$path] `
                -MaximumLength ([long]$payloadEntry.length)
            Assert-PostPublicationCondition `
                ($bytes.LongLength -eq [long]$payloadEntry.length -and
                    (Get-Sha256Hex -Bytes $bytes) -ceq [string]$payloadEntry.sha256) `
                "bundle payload '$path' does not match its manifest digest and length."
            $payloadPaths.Add($path)
            $payloadByPath.Add($path, $payloadEntry)
        }
        Assert-PostPublicationCondition `
            ($entryByName.Count -eq ($payload.Count + 1)) `
            'bundle archive contains entries outside its manifest payload inventory.'
        Assert-PostPublicationCondition `
            ([string]$manifest.entryPoint -cmatch
                '^MeAndAI\.QuickAdoption/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.psd1$' -and
                $payloadSet.Contains([string]$manifest.entryPoint)) `
            'bundle manifest entry point is absent from its payload inventory.'
        $expectedEntryOrder = @('manifest.json') + @($payloadPaths)
        $actualEntryOrder = @($entries | ForEach-Object { [string]$_.FullName })
        Assert-PostPublicationCondition `
            (($actualEntryOrder -join "`n") -ceq ($expectedEntryOrder -join "`n")) `
            'bundle archive entry order differs from its canonical manifest inventory.'

        $inventoryBytes = Get-GitHubContentBytes `
            -RepositoryPath $ExpectedBundleSourceInventoryPath
        try {
            $inventory = [Text.UTF8Encoding]::new($false, $true).GetString(
                $inventoryBytes
            ) | ConvertFrom-Json
        }
        catch {
            throw 'TEST-0065 released bundle source inventory is not strict UTF-8 JSON.'
        }
        $inventoryProperties = @($inventory.PSObject.Properties | ForEach-Object {
            [string]$_.Name
        })
        $inventorySources = @($inventory.sources | ForEach-Object { [string]$_ })
        Assert-PostPublicationCondition `
            (($inventoryProperties -join ',') -ceq 'schema,kind,entryPoint,sources' -and
                ($inventory.schema -is [int] -or $inventory.schema -is [long]) -and
                [long]$inventory.schema -eq 1 -and
                [string]$inventory.kind -ceq 'meandai.quick-adoption.bundle-sources' -and
                [string]$inventory.entryPoint -ceq [string]$manifest.entryPoint -and
                ($inventorySources -join "`n") -ceq (@($payloadPaths) -join "`n")) `
            'bundle manifest payload inventory does not match the released source inventory.'

        foreach ($path in $payloadPaths) {
            $repositoryPath = 'scripts/quick-adoption/' +
                $path.Substring('MeAndAI.QuickAdoption/'.Length)
            $sourceBytes = Get-GitHubContentBytes -RepositoryPath $repositoryPath
            $payloadEntry = $payloadByPath[$path]
            Assert-PostPublicationCondition `
                ($sourceBytes.LongLength -eq [long]$payloadEntry.length -and
                    (Get-Sha256Hex -Bytes $sourceBytes) -ceq [string]$payloadEntry.sha256) `
                "bundle payload '$path' does not match the released source commit."
        }
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
        $fileStream.Dispose()
    }
}

function Assert-ExpectedReleaseAssets {
    param([Parameter(Mandatory)][object]$Release)

    if ($expectedAssetNames.Count -eq 0) {
        return
    }
    $releaseAssets = @($Release.assets)
    Assert-PostPublicationCondition `
        ($releaseAssets.Count -eq $expectedAssetNames.Count) `
        'release does not contain the exact expected asset inventory.'
    $releaseAssetNames = @($releaseAssets | ForEach-Object { [string]$_.name })
    foreach ($name in $expectedAssetNames) {
        Assert-PostPublicationCondition `
            (@($releaseAssetNames | Where-Object { $_ -ceq $name }).Count -eq 1) `
            'release does not contain the exact expected asset inventory.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        ('meandai-post-publication-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $temporaryRoot)
    try {
        for ($index = 0; $index -lt $expectedAssetNames.Count; $index++) {
            $name = $expectedAssetNames[$index]
            $asset = @($releaseAssets | Where-Object {
                [string]$_.name -ceq $name
            })[0]
            $assetId = [string]$asset.id
            $assetDigest = [string]$asset.digest
            $assetUrl = [string]$asset.url
            $maximumAssetBytes = if ($name -ceq $ExpectedLauncherAssetName) {
                1048576
            }
            elseif ($name -ceq $ExpectedBundleAssetName) { 67108864 }
            else { 67108864 }
            Assert-PostPublicationCondition `
                ($asset.state -ceq 'uploaded' -and
                    $assetId -cmatch '^[1-9][0-9]*$' -and
                    ($asset.size -is [int] -or $asset.size -is [long]) -and
                    [long]$asset.size -gt 0 -and
                    [long]$asset.size -le $maximumAssetBytes -and
                    $assetDigest -cmatch '^sha256:[0-9a-f]{64}$' -and
                    $assetUrl -ceq "$repositoryApi/releases/assets/$assetId") `
                "release asset '$name' is missing canonical API digest, bounded size, or identity metadata."
            $downloadPath = Join-Path $temporaryRoot ("asset-$index.bin")
            $downloadHeaders = @{}
            foreach ($header in $headers.GetEnumerator()) {
                $downloadHeaders[$header.Key] = $header.Value
            }
            $downloadHeaders.Accept = 'application/octet-stream'
            Invoke-RestMethod -Method Get -Uri $assetUrl -Headers $downloadHeaders `
                -OutFile $downloadPath
            $downloadItem = Get-Item -LiteralPath $downloadPath -Force
            Assert-PostPublicationCondition `
                (-not $downloadItem.PSIsContainer -and
                    (($downloadItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) -and
                    [long]$downloadItem.Length -eq [long]$asset.size) `
                "release asset '$name' downloaded size does not match API metadata."
            $downloadDigest = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
            Assert-PostPublicationCondition `
                ($downloadDigest -ceq $assetDigest.Substring('sha256:'.Length)) `
                "release asset '$name' downloaded digest does not match API metadata."
            if ($name -ceq $ExpectedLauncherAssetName) {
                $launcherSourceBytes = Get-GitHubContentBytes `
                    -RepositoryPath $ExpectedLauncherSourcePath
                Assert-PostPublicationCondition `
                    ($launcherSourceBytes.LongLength -eq $downloadItem.Length -and
                        (Get-Sha256Hex -Bytes $launcherSourceBytes) -ceq $downloadDigest) `
                    "release launcher asset '$name' does not match its released source commit."
            }
            elseif ($name -ceq $ExpectedBundleAssetName) {
                Assert-QuickAdoptionBundle -BundlePath $downloadPath
            }
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
}

$encodedTag = ConvertTo-ApiPath $Tag
$encodedDefaultBranch = ConvertTo-ApiPath $DefaultBranch
$encodedOwnedBranch = ConvertTo-ApiPath $OwnedBranch
$encodedFeaturePath = ConvertTo-ApiPath $FeaturePath

$repositoryState = Invoke-GitHubGet ''
Assert-PostPublicationCondition ($repositoryState.default_branch -ceq $DefaultBranch) `
    "repository default branch is not '$DefaultBranch'."

$release = Invoke-GitHubGet "releases/tags/$encodedTag"
Assert-PostPublicationCondition ($release.tag_name -ceq $Tag) `
    'release tag identity does not match the requested tag.'
Assert-PostPublicationCondition (-not [bool]$release.draft) `
    'release is still a draft.'
Assert-PostPublicationCondition (-not [bool]$release.prerelease) `
    'release is marked as a prerelease.'
Assert-PostPublicationCondition ($null -ne $release.published_at) `
    'release has no publication timestamp.'
Assert-PostPublicationCondition `
    ($null -ne $release.PSObject.Properties['immutable'] -and [bool]$release.immutable) `
    'release is not immutable.'
Assert-PostPublicationCondition ($release.target_commitish -ceq $ExpectedCommit) `
    'release target is not the exact expected commit.'

$tagReference = Invoke-GitHubGet "git/ref/tags/$encodedTag"
$tagObject = $tagReference.object
for ($depth = 0; $tagObject.type -ceq 'tag' -and $depth -lt 5; $depth++) {
    $annotatedTag = Invoke-GitHubGet "git/tags/$($tagObject.sha)"
    $tagObject = $annotatedTag.object
}
Assert-PostPublicationCondition ($tagObject.type -ceq 'commit') `
    'tag does not resolve to a commit within the bounded peel depth.'
Assert-PostPublicationCondition ($tagObject.sha -ceq $ExpectedCommit) `
    'release tag does not resolve to the expected commit.'

$defaultBranchComparison = Invoke-GitHubGet "compare/$ExpectedCommit...$encodedDefaultBranch"
Assert-PostPublicationCondition `
    (@('identical', 'ahead') -ccontains $defaultBranchComparison.status -and
        $defaultBranchComparison.merge_base_commit.sha -ceq $ExpectedCommit) `
    'released commit is not the default-branch head or one of its ancestors.'

$matchingBranches = @(Invoke-GitHubGet "git/matching-refs/heads/$encodedOwnedBranch")
$ownedReference = "refs/heads/$OwnedBranch"
Assert-PostPublicationCondition `
    (@($matchingBranches | Where-Object { $_.ref -ceq $ownedReference }).Count -eq 0) `
    'owned working branch still exists after publication.'

$issue = Invoke-GitHubGet "issues/$IssueNumber"
Assert-PostPublicationCondition ($issue.state -ceq 'closed') `
    'canonical delivery issue is not closed.'
Assert-PostPublicationCondition ($null -eq $issue.PSObject.Properties['pull_request']) `
    'canonical delivery authority resolves to a pull request instead of an issue.'
$comments = @(Invoke-GitHubPagedGet "issues/$IssueNumber/comments")
$issueCommentBodies = @($comments | ForEach-Object { [string]$_.body })

$pullRequest = Invoke-GitHubGet "pulls/$PullRequestNumber"
Assert-PostPublicationCondition `
    ($pullRequest.state -ceq 'closed' -and $null -ne $pullRequest.merged_at) `
    'delivery pull request is not merged.'
Assert-PostPublicationCondition ($pullRequest.merge_commit_sha -ceq $ExpectedCommit) `
    'delivery pull request does not resolve to the exact released commit.'
Assert-PostPublicationCondition ($pullRequest.base.ref -ceq $DefaultBranch) `
    'delivery pull request does not target the default branch.'
$pullConversationComments = @(
    Invoke-GitHubPagedGet "issues/$PullRequestNumber/comments"
)
$pullReviews = @(Invoke-GitHubPagedGet "pulls/$PullRequestNumber/reviews")
$inlineReviewComments = @(
    Invoke-GitHubPagedGet "pulls/$PullRequestNumber/comments"
)
$commitComments = @(
    Invoke-GitHubPagedGet "commits/$ExpectedCommit/comments"
)

$featureRecord = Invoke-GitHubGet "contents/$encodedFeaturePath`?ref=$ExpectedCommit"
Assert-PostPublicationCondition ($featureRecord.encoding -ceq 'base64') `
    'canonical feature record was not returned as base64 content.'
$featureBytes = [Convert]::FromBase64String(($featureRecord.content -replace '\s', ''))
$featureContent = [Text.Encoding]::UTF8.GetString($featureBytes)
$featureLinkEvidence = Get-MarkdownLinkEvidence -Markdown $featureContent
$decisionRow = [regex]::Match(
    $featureContent,
    '(?m)^\|\s*Decisions?\s*\|(?<value>.*?)\|\s*$'
)
Assert-PostPublicationCondition $decisionRow.Success `
    'canonical feature record has no Decisions field.'
$decisionPaths = [System.Collections.Generic.List[string]]::new()
foreach ($link in @($featureLinkEvidence.Links | Where-Object {
    $_.Index -ge $decisionRow.Index -and
        $_.Index -lt ($decisionRow.Index + $decisionRow.Length) -and
        [regex]::IsMatch([string]$_.Label, '(?<![A-Za-z0-9_-])DEC-\d{4}(?![A-Za-z0-9_-])')
})) {
    $idMatch = [regex]::Match(
        [string]$link.Label,
        '(?<![A-Za-z0-9_-])(?<id>DEC-\d{4})(?![A-Za-z0-9_-])'
    )
    $target = [string]$link.Target -replace '#.*$', ''
    $pathMatch = [regex]::Match(
        $target,
        '(?:^|/)decisions/(?<file>DEC-\d{4}-[A-Za-z0-9._-]+\.md)$'
    )
    Assert-PostPublicationCondition $pathMatch.Success `
        "canonical feature decision link '$target' does not identify a decision document."
    Assert-PostPublicationCondition `
        ($pathMatch.Groups['file'].Value.StartsWith(
            $idMatch.Groups['id'].Value + '-',
            [StringComparison]::Ordinal
        )) `
        "canonical feature decision label does not match its linked decision document."
    $decisionPath = "docs/decisions/$($pathMatch.Groups['file'].Value)"
    if (-not $decisionPaths.Contains($decisionPath)) {
        $decisionPaths.Add($decisionPath)
    }
}
$decisionField = $decisionRow.Groups['value'].Value.Trim()
Assert-PostPublicationCondition `
    ($decisionPaths.Count -gt 0 -or $decisionField -cmatch '^N/A(?:\s+-.*)?$') `
    'canonical feature Decisions field must link its decisions or state N/A.'

$webRoot = "https://github.com/$Repository"
$issueUrl = "$webRoot/issues/$IssueNumber"
$pullRequestUrl = "$webRoot/pull/$PullRequestNumber"
$releaseUrl = "$webRoot/releases/tag/$Tag"
$commitUrl = "$webRoot/commit/$ExpectedCommit"
$featureUrl = "$webRoot/blob/$DefaultBranch/$FeaturePath"
$decisionUrls = @($decisionPaths | ForEach-Object {
    "$webRoot/blob/$DefaultBranch/$_"
})
$decisionContents = @{}
foreach ($decisionPath in $decisionPaths) {
    $encodedDecisionPath = ConvertTo-ApiPath $decisionPath
    $decisionRecord = Invoke-GitHubGet `
        "contents/$encodedDecisionPath`?ref=$ExpectedCommit"
    Assert-PostPublicationCondition ($decisionRecord.encoding -ceq 'base64') `
        "canonical decision '$decisionPath' was not returned as base64 content."
    $decisionBytes = [Convert]::FromBase64String(
        ([string]$decisionRecord.content -replace '\s', '')
    )
    $decisionContents[$decisionPath] = [Text.Encoding]::UTF8.GetString(
        $decisionBytes
    )
}
$titleTargetCandidates = @{}
$documentTitleSources = @(
    [pscustomobject]@{ Content = $featureContent; Target = $featureUrl }
) + @(for ($index = 0; $index -lt $decisionPaths.Count; $index++) {
    [pscustomobject]@{
        Content = [string]$decisionContents[$decisionPaths[$index]]
        Target = $decisionUrls[$index]
    }
})
foreach ($source in $documentTitleSources) {
    foreach ($title in Get-CanonicalDocumentTitles `
        -Markdown ([string]$source.Content)) {
        if (-not $titleTargetCandidates.ContainsKey($title)) {
            $titleTargetCandidates[$title] = [Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal
            )
        }
        [void]$titleTargetCandidates[$title].Add([string]$source.Target)
    }
}
$expectedRecordTitles = @{}
foreach ($title in $titleTargetCandidates.Keys) {
    if ($titleTargetCandidates[$title].Count -eq 1) {
        $expectedRecordTitles[$title] = @($titleTargetCandidates[$title])[0]
    }
}
$featureId = [regex]::Match($FeaturePath, '(?:^|/)(?<id>FEAT-\d{4})-').Groups['id'].Value
$featureOwnedIds = @(Get-CanonicalDocumentOwnedIds -Markdown $featureContent)
$issuePrimaryId = Get-PrimarySurfaceRecordId -Text ([string]$issue.title)
$issueOwnIds = @($issuePrimaryId | Where-Object {
    -not [string]::IsNullOrEmpty($_)
})
$pullRequestPrimaryId = Get-PrimarySurfaceRecordId `
    -Text ([string]$pullRequest.title)
$pullRequestOwnIds = @($pullRequestPrimaryId | Where-Object {
    -not [string]::IsNullOrEmpty($_)
})
$expectedRecordTargets = @{
    $featureId = $featureUrl
}
foreach ($ownedId in $featureOwnedIds) {
    if (-not $expectedRecordTargets.ContainsKey($ownedId)) {
        $expectedRecordTargets[$ownedId] = $featureUrl
    }
}
foreach ($index in 0..($decisionPaths.Count - 1)) {
    if ($decisionPaths.Count -eq 0) { break }
    foreach ($decisionOwnedId in Get-CanonicalDocumentOwnedIds `
        -Markdown ([string]$decisionContents[$decisionPaths[$index]])) {
        Assert-PostPublicationCondition `
            (-not $expectedRecordTargets.ContainsKey($decisionOwnedId) -or
                [string]$expectedRecordTargets[$decisionOwnedId] -ceq
                    $decisionUrls[$index]) `
            "canonical record identity $decisionOwnedId has conflicting document targets."
        $expectedRecordTargets[$decisionOwnedId] = $decisionUrls[$index]
    }
}
if (-not [string]::IsNullOrEmpty($issuePrimaryId) -and
    -not $expectedRecordTargets.ContainsKey($issuePrimaryId)) {
    $expectedRecordTargets[$issuePrimaryId] = $issueUrl
}
$testRow = [regex]::Match(
    $featureContent,
    '(?m)^\|\s*Tests?\s*\|(?<value>.*?)\|\s*$'
)
if ($testRow.Success) {
    $featureDirectory = $FeaturePath.Substring(
        0,
        $FeaturePath.LastIndexOf('/') + 1
    )
    $featureTestUrl =
        "$webRoot/blob/$DefaultBranch/${featureDirectory}test-cases.md"
    foreach ($testLink in @($featureLinkEvidence.Links | Where-Object {
        $_.Index -ge $testRow.Index -and
            $_.Index -lt ($testRow.Index + $testRow.Length)
    })) {
        foreach ($testId in @([regex]::Matches(
            [string]$testLink.Label,
            '(?<![A-Za-z0-9_-])TEST-\d{4}(?![A-Za-z0-9_-])'
        ) | ForEach-Object { $_.Value } | Select-Object -Unique)) {
            $expectedRecordTargets[$testId] = $featureTestUrl
        }
    }
}
$issueOwnTitles = @(Get-OwnSurfaceTitles `
    -Text ([string]$issue.title) -PrimaryRecordId $issuePrimaryId `
    -ExpectedRecordTitles $expectedRecordTitles)
$pullRequestOwnTitles = @(Get-OwnSurfaceTitles `
    -Text ([string]$pullRequest.title) `
    -PrimaryRecordId $pullRequestPrimaryId `
    -ExpectedRecordTitles $expectedRecordTitles)

Assert-PostPublicationCondition `
    ([regex]::IsMatch($featureContent, '(?m)^\|\s*Status\s*\|\s*Complete\s*\|\s*$')) `
    'canonical feature record is not complete.'
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems @($featureContent) -ExpectedUri $issueUrl) `
    'canonical feature record does not link its delivery issue.'
$featureExpectedTitles = @{}
foreach ($title in $expectedRecordTitles.Keys) {
    if ([string]$expectedRecordTitles[$title] -cne $featureUrl) {
        $featureExpectedTitles[$title] = $expectedRecordTitles[$title]
    }
}
Assert-NoFreeTextCrossRecordReference `
    -Markdown $featureContent -Surface 'canonical feature document' `
    -ExpectedRepositoryPaths (@($FeaturePath) + @($decisionPaths)) `
    -AllowedRecordIds $featureOwnedIds `
    -ExpectedRecordTargets $expectedRecordTargets `
    -ExpectedRecordTitles $featureExpectedTitles `
    -SourceRepositoryPath $FeaturePath

$issueMarkdownBodies = @([string]$issue.body) + @($issueCommentBodies)
$pullRequestBodies = @(
    [string]$pullRequest.body
    @($pullConversationComments | ForEach-Object { [string]$_.body })
    @($pullReviews | ForEach-Object { [string]$_.body })
    @($inlineReviewComments | ForEach-Object { [string]$_.body })
)
$referencePaths = @($FeaturePath) + @($decisionPaths)
Assert-NoFreeTextCrossRecordReference `
    -Markdown ([string]$issue.body) -Surface 'delivery issue body' `
    -ExpectedRepositoryPaths $referencePaths `
    -AllowedRecordIds $issueOwnIds `
    -ExpectedRecordTargets $expectedRecordTargets `
    -ExpectedRecordTitles $expectedRecordTitles `
    -OwnGitHubIdentityKind issue -OwnGitHubIdentityNumber $IssueNumber `
    -RequireAbsoluteTargets
Assert-NoCrossRecordReferenceInNonRenderingTitle `
    -Title ([string]$issue.title) -Surface 'delivery issue title' `
    -AllowedRecordIds $issueOwnIds `
    -AllowedRecordTitles $issueOwnTitles `
    -ExpectedRecordTitles $expectedRecordTitles `
    -OwnGitHubIdentityKind issue -OwnGitHubIdentityNumber $IssueNumber
for ($index = 0; $index -lt $comments.Count; $index++) {
    Assert-NoFreeTextCrossRecordReference `
        -Markdown ([string]$comments[$index].body) `
        -Surface "delivery issue comment $($index + 1)" `
        -ExpectedRepositoryPaths $referencePaths `
        -ExpectedRecordTargets $expectedRecordTargets `
        -ExpectedRecordTitles $expectedRecordTitles `
        -OwnGitHubIdentityKind comment `
        -OwnGitHubIdentityNumber ([long]$comments[$index].id) `
        -RequireAbsoluteTargets
}
Assert-NoCrossRecordReferenceInNonRenderingTitle `
    -Title ([string]$pullRequest.title) `
    -Surface 'delivery pull-request title' `
    -AllowedRecordIds $pullRequestOwnIds `
    -AllowedRecordTitles $pullRequestOwnTitles `
    -ExpectedRecordTitles $expectedRecordTitles `
    -OwnGitHubIdentityKind pull `
    -OwnGitHubIdentityNumber $PullRequestNumber
Assert-NoFreeTextCrossRecordReference `
    -Markdown ([string]$pullRequest.body) `
    -Surface 'delivery pull-request body' `
    -ExpectedRepositoryPaths $referencePaths `
    -AllowedRecordIds $pullRequestOwnIds `
    -ExpectedRecordTargets $expectedRecordTargets `
    -ExpectedRecordTitles $expectedRecordTitles `
    -OwnGitHubIdentityKind pull `
    -OwnGitHubIdentityNumber $PullRequestNumber `
    -RequireAbsoluteTargets
foreach ($pullSurface in @(
    [pscustomobject]@{
        Name = 'conversation comment'
        Items = @($pullConversationComments)
    },
    [pscustomobject]@{
        Name = 'submitted review'
        Items = @($pullReviews)
    },
    [pscustomobject]@{
        Name = 'inline review comment'
        Items = @($inlineReviewComments)
    }
)) {
    for ($index = 0; $index -lt $pullSurface.Items.Count; $index++) {
        Assert-NoFreeTextCrossRecordReference `
            -Markdown ([string]$pullSurface.Items[$index].body) `
            -Surface "delivery pull-request $($pullSurface.Name) $($index + 1)" `
            -ExpectedRepositoryPaths $referencePaths `
            -ExpectedRecordTargets $expectedRecordTargets `
            -ExpectedRecordTitles $expectedRecordTitles `
            -OwnGitHubIdentityKind comment `
            -OwnGitHubIdentityNumber ([long]$pullSurface.Items[$index].id) `
            -RequireAbsoluteTargets
    }
}
for ($index = 0; $index -lt $commitComments.Count; $index++) {
    Assert-NoFreeTextCrossRecordReference `
        -Markdown ([string]$commitComments[$index].body) `
        -Surface "released-commit comment $($index + 1)" `
        -ExpectedRepositoryPaths $referencePaths `
        -ExpectedRecordTargets $expectedRecordTargets `
        -ExpectedRecordTitles $expectedRecordTitles `
        -OwnGitHubIdentityKind comment `
        -OwnGitHubIdentityNumber ([long]$commitComments[$index].id) `
        -RequireAbsoluteTargets
}
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems $issueMarkdownBodies -ExpectedUri $featureUrl) `
    'delivery issue does not link the canonical feature record on the default branch.'
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems $issueMarkdownBodies `
        -ExpectedUri $pullRequestUrl) `
    'delivery issue does not link the delivery pull request.'
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems $pullRequestBodies -ExpectedUri $issueUrl) `
    'delivery pull request does not link its delivery issue.'
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems $pullRequestBodies -ExpectedUri $featureUrl) `
    'delivery pull request does not link the canonical feature record on the default branch.'
foreach ($index in 0..($decisionPaths.Count - 1)) {
    if ($decisionPaths.Count -eq 0) { break }
    $decisionPath = $decisionPaths[$index]
    $decisionUrl = $decisionUrls[$index]
    $decisionContent = [string]$decisionContents[$decisionPath]
    $decisionId = [regex]::Match(
        $decisionPath,
        '(?:^|/)(?<id>DEC-\d{4})-'
    ).Groups['id'].Value
    $decisionExpectedTitles = @{}
    foreach ($title in $expectedRecordTitles.Keys) {
        if ([string]$expectedRecordTitles[$title] -cne $decisionUrl) {
            $decisionExpectedTitles[$title] = $expectedRecordTitles[$title]
        }
    }
    $decisionOwnedIds = @(Get-CanonicalDocumentOwnedIds `
        -Markdown $decisionContent)
    Assert-NoFreeTextCrossRecordReference `
        -Markdown $decisionContent `
        -Surface "canonical decision document '$decisionPath'" `
        -ExpectedRepositoryPaths @($referencePaths | Where-Object {
            $_ -cne $decisionPath
        }) `
        -AllowedRecordIds $decisionOwnedIds `
        -ExpectedRecordTargets $expectedRecordTargets `
        -ExpectedRecordTitles $decisionExpectedTitles `
        -SourceRepositoryPath $decisionPath
    Assert-PostPublicationCondition `
        (Test-MarkdownCollectionContainsExactVisibleUri `
            -MarkdownItems $issueMarkdownBodies `
            -ExpectedUri $decisionUrl) `
        "delivery issue does not link canonical decision '$decisionPath'."
    Assert-PostPublicationCondition `
        (Test-MarkdownCollectionContainsExactVisibleUri `
            -MarkdownItems $pullRequestBodies `
            -ExpectedUri $decisionUrl) `
        "delivery pull request does not link canonical decision '$decisionPath'."
}
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems $issueCommentBodies -ExpectedUri $releaseUrl) `
    'delivery issue does not contain the immutable release link.'
Assert-PostPublicationCondition `
    (Test-MarkdownCollectionContainsExactVisibleUri `
        -MarkdownItems $issueCommentBodies -ExpectedUri $commitUrl) `
    'delivery issue does not contain the exact released commit link.'

# Keep the larger asset downloads last so inexpensive metadata and governance
# failures stop before consuming release bandwidth.
Assert-ExpectedReleaseAssets -Release $release

Write-Host "TEST-0065 post-publication evidence verified for $Repository $Tag at $ExpectedCommit." `
    -ForegroundColor Green
}
finally {
    [Threading.Thread]::CurrentThread.CurrentCulture =
        $originalValidationCulture
}
