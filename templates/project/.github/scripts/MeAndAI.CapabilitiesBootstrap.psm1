Set-StrictMode -Version Latest

$script:MeAndAIAdoptionManifestPath = '.ai/adoption/meandai-capabilities.json'
$script:MeAndAISeedWorkflowPath = '.github/workflows/meandai-protocol-update.yml'
$script:MeAndAIAdoptionTargetPaths = @(
    '.gitmodules', '.ai/protocol', '.ai/meandai-update-state.json', 'AGENTS.md',
    '.ai/memory/README.md', '.ai/memory/project.md',
    '.ai/memory/log/README.md', 'docs/ideas/README.md',
    '.github/ISSUE_TEMPLATE/bug.yml',
    '.github/ISSUE_TEMPLATE/epic.yml',
    '.github/ISSUE_TEMPLATE/feature.yml',
    '.github/ISSUE_TEMPLATE/finding.yml',
    '.github/ISSUE_TEMPLATE/subfeature.yml',
    '.github/ISSUE_TEMPLATE/task.yml',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)
$script:MeAndAIAdoptionProposedPaths = @(
    $script:MeAndAISeedWorkflowPath
) + @($script:MeAndAIAdoptionTargetPaths)
$script:MeAndAIRequiredAdoptionTasks = @(
    'Create or reconcile the repository labels required by the protocol.',
    'Create project-owned feature and decision records for adoption.',
    'Apply the manifest-selected adoption strategy; do not infer or change it.',
    'Tailor project-local memory without importing protocol-repository facts.',
    'Resolve every collision through semantic review; do not overwrite blindly.',
    'Create and run the project test evidence required by DoR and DoD.',
    'Verify all documentation links and traceability references.',
    'Remove the manifest before marking the pull request ready or merging it.'
)
$script:MeAndAIProtocolSurfaceFiles = @(
    'AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'PROTOCOL.md', 'CONTRIBUTING.md',
    '.cursorrules', '.windsurfrules', '.github/copilot-instructions.md',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1',
    '.ai/protocol', '.ai/meandai-update-state.json',
    'FEATURE_BACKLOG.md', 'ACTIVE_FINDINGS.md', 'DECISIONS.md',
    'WORK_INDEX.md', 'SESSION_HANDOFF.md', 'PROJECT_STATE.md',
    'PROJECT_METRICS.md', 'RELEASES.md',
    'ai/FEATURE_BACKLOG.md', 'ai/ACTIVE_FINDINGS.md', 'ai/DECISIONS.md',
    'ai/WORK_INDEX.md', 'ai/SESSION_HANDOFF.md', 'ai/PROJECT_STATE.md',
    'ai/PROJECT_METRICS.md', 'ai/RELEASES.md'
)
$script:MeAndAIProtocolSurfaceRoots = @(
    '.ai/protocol/', '.ai/memory/', '.cursor/rules/', '.windsurf/rules/',
    '.github/instructions/',
    'docs/features/', 'docs/decisions/', 'docs/findings/',
    'docs/governance/', 'docs/ideas/', 'docs/agent-prompts/'
)
$script:MeAndAILegacyCommonAuthorityFiles = @(
    'AGENTS.md', 'CLAUDE.md', 'GEMINI.md', 'PROTOCOL.md',
    '.cursorrules', '.windsurfrules', '.github/copilot-instructions.md'
)
$script:MeAndAILegacyAiGovernanceFiles = @(
    'ai/FEATURE_BACKLOG.md', 'ai/ACTIVE_FINDINGS.md', 'ai/DECISIONS.md',
    'ai/WORK_INDEX.md', 'ai/SESSION_HANDOFF.md', 'ai/PROJECT_STATE.md',
    'ai/PROJECT_METRICS.md', 'ai/RELEASES.md'
)
$script:MeAndAILegacyCommonAuthorityRoots = @(
    '.cursor/rules/', '.windsurf/rules/', '.github/instructions/'
)
$script:MeAndAILegacyGovernanceRoots = @(
    '.ai/protocol/', '.ai/memory/', '.cursor/rules/', '.windsurf/rules/',
    '.github/instructions/',
    'docs/governance/', 'docs/agent-prompts/'
)
$script:MeAndAIResolvedAdoptionStrategies = @(
    'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart'
)
$script:MeAndAIProtocolSurfaceMaximumCount = 256
$script:MeAndAIProtocolSurfaceMaximumUtf8Bytes = 16384
$script:MeAndAIInstructionGraphSchema = 2
$script:MeAndAIInstructionGraphMaximumTreeEntries = 65536
$script:MeAndAIInstructionGraphMaximumTreePathUtf8Bytes = 4194304
$script:MeAndAIInstructionGraphMaximumNodes = 512
$script:MeAndAIInstructionGraphMaximumEdges = 8192
$script:MeAndAIInstructionGraphMaximumDepth = 32
$script:MeAndAIInstructionGraphMaximumBlobBytes = 524288
$script:MeAndAIInstructionGraphMaximumAggregateBlobBytes = 8388608
$script:MeAndAIInstructionGraphMaximumPathUtf8Bytes = 32768
$script:MeAndAIInstructionGraphRepeatedHashPathPattern =
    '^(?<path>(?:\./|\.\./)?(?:[^/?#]+/)*[^/?#]*#{2,}' +
    '[^/?#]*\.[^/?#\s]+)(?:[?#].*)?$'
$script:MeAndAIGenericInstructionRootFiles = @(
    'CLAUDE.md', 'GEMINI.md', 'PROTOCOL.md', '.cursorrules',
    '.windsurfrules', '.github/copilot-instructions.md'
)
$script:MeAndAIGenericInstructionRootRoots = @(
    '.github/instructions/', '.cursor/rules/', '.windsurf/rules/'
)
$script:MeAndAIInstructionGraphTextExtensions = @(
    '', '.md', '.markdown', '.txt', '.rst', '.org', '.adoc', '.asciidoc',
    '.json', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf',
    '.rules', '.mdc'
)
$script:MeAndAIInstructionGraphProtectedExtensions = @(
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.odt', '.ods', '.odp',
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.tif', '.tiff',
    '.ico', '.svg', '.avif',
    '.mp3', '.wav', '.flac', '.ogg', '.m4a',
    '.mp4', '.mov', '.avi', '.mkv', '.webm',
    '.zip', '.7z', '.rar', '.tar', '.gz', '.bz2', '.xz', '.zst',
    '.exe', '.dll', '.so', '.dylib', '.bin', '.dat', '.db', '.sqlite',
    '.sqlite3', '.wasm', '.class', '.jar', '.pdb',
    '.ps1', '.psm1', '.psd1', '.sh', '.bash', '.zsh', '.fish', '.bat',
    '.cmd', '.cs', '.fs', '.fsx', '.vb', '.java', '.kt', '.kts', '.c',
    '.h', '.cc', '.cpp', '.cxx', '.hpp', '.go', '.rs', '.py', '.pyi',
    '.js', '.jsx', '.ts', '.tsx', '.mjs', '.cjs', '.vue', '.svelte',
    '.php', '.rb', '.swift', '.m', '.mm', '.scala', '.clj', '.cljs',
    '.ex', '.exs', '.erl', '.hrl', '.lua', '.r', '.dart', '.sol', '.asm',
    '.s', '.mq5', '.mqh', '.mqproj', '.ipynb', '.proto', '.graphql', '.gql',
    '.html', '.htm', '.xml', '.xsd', '.css', '.scss', '.sass', '.less',
    '.tf', '.tfvars', '.hcl', '.sln', '.csproj', '.fsproj', '.vbproj',
    '.props', '.targets', '.gradle', '.csv', '.tsv', '.parquet',
    '.feather', '.lock', '.log'
)
$script:MeAndAISourceEnforcedRequiredPaths = @(
    '.ai/meandai-update-state.json',
    '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
    '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
)

function Test-MeAndAIExactOrdinalSequence {
    param(
        [AllowEmptyCollection()][object[]]$Actual,
        [AllowEmptyCollection()][object[]]$Expected
    )

    $actualValues = @($Actual | ForEach-Object { [string]$_ })
    $expectedValues = @($Expected | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $expectedValues.Count) {
        return $false
    }
    for ($index = 0; $index -lt $actualValues.Count; $index++) {
        if ($actualValues[$index] -cne $expectedValues[$index]) {
            return $false
        }
    }
    return $true
}

function Test-MeAndAIExactObjectProperties {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$Names
    )

    if ($null -eq $Object -or $Object -is [array]) { return $false }
    $actual = @($Object.PSObject.Properties | ForEach-Object { $_.Name })
    return $actual.Count -eq $Names.Count -and
        @($Names | Where-Object { $actual -cnotcontains $_ }).Count -eq 0
}

function Test-MeAndAIUniqueCanonicalPaths {
    param([AllowEmptyCollection()][object[]]$Paths)

    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($value in @($Paths)) {
        $path = [string]$value
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            -not $seen.Add($path)) {
            return $false
        }
    }
    return $true
}

function Test-MeAndAIExactCanonicalSurfaceSequence {
    param(
        [AllowEmptyCollection()][object[]]$Actual,
        [AllowEmptyCollection()][object[]]$Expected
    )

    $actualValues = @($Actual)
    $expectedValues = @($Expected | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $expectedValues.Count) {
        return $false
    }
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    for ($index = 0; $index -lt $actualValues.Count; $index++) {
        $value = $actualValues[$index]
        if ($value -isnot [string] -or
            -not (Test-MeAndAICanonicalRepositoryPath -Path $value) -or
            -not $seen.Add($value) -or
            $value -cne $expectedValues[$index]) {
            return $false
        }
    }
    return $true
}

function Get-MeAndAIRequiredAdoptionTasks {
    return @($script:MeAndAIRequiredAdoptionTasks)
}

function Get-MeAndAIAdoptionTargetPaths {
    return @($script:MeAndAIAdoptionTargetPaths)
}

function Get-MeAndAIAdoptionProposedPaths {
    return @($script:MeAndAIAdoptionProposedPaths)
}

function Get-MeAndAIProtocolAssessmentLimits {
    return [pscustomobject]@{
        MaximumSurfaceCount = [int]$script:MeAndAIProtocolSurfaceMaximumCount
        MaximumSurfaceUtf8Bytes =
            [int]$script:MeAndAIProtocolSurfaceMaximumUtf8Bytes
    }
}

function Test-MeAndAICanonicalRepositoryPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or
        $Path.StartsWith('/', [StringComparison]::Ordinal) -or
        $Path -match '^[A-Za-z]:' -or
        $Path.Contains('\') -or
        $Path -match '[\x00-\x1f]') {
        return $false
    }
    $segments = @($Path.Split('/'))
    return $segments.Count -gt 0 -and
        @($segments | Where-Object {
            $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..'
        }).Count -eq 0
}

function New-MeAndAIGitHubBlobLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$Path
    )

    if ($Repository -cnotmatch '^[^/\s]+/[^/\s]+$' -or
        $Commit -cnotmatch '^[0-9a-f]{40}$' -or
        -not (Test-MeAndAICanonicalRepositoryPath -Path $Path)) {
        throw "Cannot create an immutable GitHub blob link for '$Path'."
    }
    $encodedPath = (@($Path.Split('/') | ForEach-Object {
        [Uri]::EscapeDataString([string]$_)
    }) -join '/')
    return "[``$Path``](https://github.com/$Repository/blob/$Commit/$encodedPath)"
}

function Get-MeAndAILinkedPathIdentityDigest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Paths
    )

    if (-not (Test-MeAndAIExactCanonicalSurfaceSequence `
            -Actual @($Paths) -Expected @($Paths))) {
        throw 'Cannot derive a linked-path identity from invalid paths.'
    }
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append("schema=1`ncount=$(@($Paths).Count)`n")
    foreach ($pathValue in @($Paths)) {
        $path = [string]$pathValue
        $length = [Text.Encoding]::UTF8.GetByteCount($path)
        [void]$builder.Append("$length`:$path`n")
    }
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash(
            [Text.UTF8Encoding]::new($false).GetBytes($builder.ToString())
        ))).Replace('-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

function Test-MeAndAIExactLinkedPathSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [Parameter(Mandatory)][string]$Heading,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Paths
    )

    if (-not (Test-MeAndAIExactCanonicalSurfaceSequence `
            -Actual @($Paths) -Expected @($Paths))) {
        return $false
    }
    $lines = if (@($Paths).Count -eq 0) {
        @('- None')
    }
    else {
        @($Paths | ForEach-Object {
            '- ' + (New-MeAndAIGitHubBlobLink -Repository $Repository `
                -Commit $Commit -Path ([string]$_))
        })
    }
    $normalized = $Body.Replace("`r`n", "`n").Replace("`r", "`n")
    $expected = (@($Heading, '') + @($lines)) -join "`n"
    $headings = @([regex]::Matches(
        $normalized,
        '(?m)^' + [regex]::Escape($Heading) + '$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    ))
    if ($headings.Count -ne 1) {
        return $false
    }
    $start = [int]$headings[0].Index
    if ($start + $expected.Length -gt $normalized.Length -or
        $normalized.Substring($start, $expected.Length) -cne $expected) {
        return $false
    }
    $suffix = $normalized.Substring($start + $expected.Length)
    return $suffix.Length -eq 0 -or
        $suffix.StartsWith("`n`n", [StringComparison]::Ordinal)
}

function Assert-MeAndAIProtocolAssessmentPathCasing {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $actualSegments = @($Path.Split('/'))
    $canonicalPaths = @(
        $script:MeAndAIAdoptionManifestPath
    ) + @($script:MeAndAIAdoptionProposedPaths)
    foreach ($canonicalPath in $canonicalPaths) {
        $canonicalSegments = @(([string]$canonicalPath).Split('/'))
        $sharedLength = [Math]::Min(
            $actualSegments.Count,
            $canonicalSegments.Count
        )
        for ($index = 0; $index -lt $sharedLength; $index++) {
            if (-not $actualSegments[$index].Equals(
                    $canonicalSegments[$index],
                    [StringComparison]::OrdinalIgnoreCase)) {
                break
            }
            if ($actualSegments[$index] -cne $canonicalSegments[$index]) {
                throw "Repository path '$Path' uses noncanonical casing for adoption path '$canonicalPath'."
            }
        }
    }
}

function Test-MeAndAIProtocolSurfacePath {
    param([Parameter(Mandatory)][string]$Path)

    if ($Path.Equals('AGENTS.md', [StringComparison]::OrdinalIgnoreCase) -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    foreach ($candidate in $script:MeAndAIProtocolSurfaceFiles) {
        if ($Path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    foreach ($root in $script:MeAndAIProtocolSurfaceRoots) {
        if ($Path.Equals($root.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAIProtocolAssessmentRelevantPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetPaths
    )

    if ($Path.Equals(
            $script:MeAndAIAdoptionManifestPath,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $Path.Equals(
            $script:MeAndAISeedWorkflowPath,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        (Test-MeAndAIProtocolSurfacePath -Path $Path)) {
        return $true
    }
    foreach ($value in @($TargetPaths)) {
        $target = [string]$value
        if ($Path.Equals($target, [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith("$target/", [StringComparison]::OrdinalIgnoreCase) -or
            $target.StartsWith("$Path/", [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Get-MeAndAIProtocolSurfaceInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Paths = @()
    )

    $seenPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $surfaces = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    [object[]]$pathValues = @()
    if ($null -ne $Paths) {
        $pathValues = [object[]]@($Paths)
    }
    if ($pathValues.Count -eq 1 -and $null -eq $pathValues[0]) {
        $pathValues = [object[]]@()
    }
    foreach ($value in $pathValues) {
        $path = [string]$value
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            -not $seenPaths.Add($path)) {
            throw "Protocol inventory path '$path' is invalid or case-ambiguous."
        }
        if ((Test-MeAndAIProtocolSurfacePath -Path $path) -and
            $surfaces.Add($path) -and
            ($surfaces.Count -gt $script:MeAndAIProtocolSurfaceMaximumCount -or
             [Text.Encoding]::UTF8.GetByteCount((@($surfaces) -join "`n")) -gt
                $script:MeAndAIProtocolSurfaceMaximumUtf8Bytes)) {
            throw 'Protocol inventory exceeds the bounded assessment budget; maintainer review is required.'
        }
    }
    $result = @($surfaces)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    if ($result.Count -gt $script:MeAndAIProtocolSurfaceMaximumCount -or
        [Text.Encoding]::UTF8.GetByteCount(($result -join "`n")) -gt
            $script:MeAndAIProtocolSurfaceMaximumUtf8Bytes) {
        throw 'Protocol inventory exceeds the bounded assessment budget; maintainer review is required.'
    }
    return @($result)
}

function Get-MeAndAIInstructionGraphLimits {
    return [pscustomobject][ordered]@{
        MaximumTreeEntries =
            [int]$script:MeAndAIInstructionGraphMaximumTreeEntries
        MaximumTreePathUtf8Bytes =
            [int]$script:MeAndAIInstructionGraphMaximumTreePathUtf8Bytes
        MaximumNodes = [int]$script:MeAndAIInstructionGraphMaximumNodes
        MaximumEdges = [int]$script:MeAndAIInstructionGraphMaximumEdges
        MaximumDepth = [int]$script:MeAndAIInstructionGraphMaximumDepth
        MaximumBlobBytes =
            [int]$script:MeAndAIInstructionGraphMaximumBlobBytes
        MaximumAggregateBlobBytes =
            [int]$script:MeAndAIInstructionGraphMaximumAggregateBlobBytes
        MaximumPathUtf8Bytes =
            [int]$script:MeAndAIInstructionGraphMaximumPathUtf8Bytes
    }
}

function Get-MeAndAIGitPathLeafName {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    $separator = $Path.LastIndexOf('/')
    if ($separator -lt 0) { return $Path }
    return $Path.Substring($separator + 1)
}

function Get-MeAndAIGitPathDirectoryName {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    $separator = $Path.LastIndexOf('/')
    if ($separator -lt 0) { return '' }
    return $Path.Substring(0, $separator)
}

function Get-MeAndAIGitPathExtension {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    $leaf = Get-MeAndAIGitPathLeafName -Path $Path
    $dot = $leaf.LastIndexOf('.')
    if ($dot -le 0 -or $dot -eq ($leaf.Length - 1)) { return '' }
    return $leaf.Substring($dot)
}

function Test-MeAndAIInvariantRegex {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$InputText,
        [Parameter(Mandatory)][string]$Pattern
    )

    $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    return [regex]::IsMatch($InputText, $Pattern, $options)
}

function Test-MeAndAIInstructionGraphNumericDottedToken {
    param([Parameter(Mandatory)][string]$Value)

    return [regex]::IsMatch(
        $Value,
        '^[vV]?[0-9]+(?:\.[0-9]+){1,}(?:[-+][A-Za-z0-9.-]+)?$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
}

function Test-MeAndAIInstructionGraphCommandCodeSpan {
    param([Parameter(Mandatory)][string]$Value)

    return Test-MeAndAIInvariantRegex -InputText $Value -Pattern (
        '^(?:&\s+|\.\s+)?(?:cat|type|more|less|head|tail|get-content|gc|' +
        'select-string|sls|open|start|start-process|invoke-item|ii|code|' +
        'vim|vi|nano|notepad(?:\.exe)?|pwsh(?:\.exe)?|' +
        'powershell(?:\.exe)?|cmd(?:\.exe)?|bash|sh|zsh|fish|' +
        'python(?:3)?(?:\.exe)?|py|node(?:\.exe)?|deno|bun|ruby|perl|' +
        'java|dotnet|git|gh|npm|npx|pnpm|yarn|make|cmake|msbuild|' +
        'cargo|go|docker|podman|kubectl|helm|terraform|ansible|curl|' +
        'wget|invoke-webrequest|iwr|sed|awk|grep|rg|find|findstr|' +
        'copy|xcopy|robocopy|cp|move|mv|remove-item|rm|del|erase)\s+'
    )
}

function Test-MeAndAIExternalInstructionReference {
    param([Parameter(Mandatory)][string]$Target)

    if ($Target.StartsWith('//', [StringComparison]::Ordinal)) { return $true }
    if (-not [regex]::IsMatch(
            $Target,
            '^[A-Za-z][A-Za-z0-9+.-]*:',
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )) {
        return $false
    }
    if ($Target.Length -ge 2 -and $Target[1] -ceq ':') { return $false }
    return -not $Target.StartsWith('file:', [StringComparison]::OrdinalIgnoreCase)
}

function Get-MeAndAIGitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash($payload)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Test-MeAndAIInstructionRootPath {
    param([Parameter(Mandatory)][string]$Path)

    if ($Path -ceq 'AGENTS.md' -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)) {
        return $true
    }
    foreach ($candidate in $script:MeAndAIGenericInstructionRootFiles) {
        if ($Path -ceq $candidate) { return $true }
    }
    foreach ($root in $script:MeAndAIGenericInstructionRootRoots) {
        if ($Path.StartsWith($root, [StringComparison]::Ordinal) -and
            (Get-MeAndAIGitPathExtension -Path $Path).ToLowerInvariant() -cin
                $script:MeAndAIInstructionGraphTextExtensions) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAIInstructionGraphTextPath {
    param([Parameter(Mandatory)][string]$Path)

    if (Test-MeAndAIInstructionRootPath -Path $Path) { return $true }
    $extension = (Get-MeAndAIGitPathExtension -Path $Path).ToLowerInvariant()
    return $extension -cin $script:MeAndAIInstructionGraphTextExtensions
}

function Test-MeAndAIInstructionGraphProtectedPath {
    param([Parameter(Mandatory)][string]$Path)

    $extension = (Get-MeAndAIGitPathExtension -Path $Path).ToLowerInvariant()
    return $extension -cin $script:MeAndAIInstructionGraphProtectedExtensions
}

function Test-MeAndAIReservedProtocolNamespacePath {
    param([Parameter(Mandatory)][string]$Path)

    return $Path -ceq '.ai/protocol' -or
        $Path.StartsWith('.ai/protocol/', [StringComparison]::Ordinal)
}

function Test-MeAndAICanonicalProtocolAuthorityTarget {
    param([Parameter(Mandatory)][string]$Path)

    return $Path -cin @(
        '.ai/protocol/PROTOCOL.md', '.ai/protocol/VERSION'
    )
}

function ConvertTo-MeAndAIInstructionReferenceLabel {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Label)

    return ([regex]::Replace($Label.Trim(), '\s+', ' ')).ToLowerInvariant()
}

function Get-MeAndAIInstructionSemanticLine {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Line
    )

    $extension =
        (Get-MeAndAIGitPathExtension -Path $SourcePath).ToLowerInvariant()
    if ($extension -cne '.json' -or
        (Test-MeAndAIInstructionRootPath -Path $SourcePath)) {
        return $Line
    }

    $characters = $Line.ToCharArray()
    $masked = [char[]]::new($characters.Length)
    $insideString = $false
    $escaped = $false
    for ($index = 0; $index -lt $characters.Length; $index++) {
        $character = $characters[$index]
        if ($insideString) {
            $masked[$index] = ' '
            if ([int]$character -lt 0x20) {
                throw "Instruction JSON string in '$SourcePath' contains an unescaped control character."
            }
            if ($escaped) {
                $escaped = $false
            }
            elseif ($character -ceq '\') {
                $escaped = $true
            }
            elseif ($character -ceq '"') {
                $insideString = $false
            }
            continue
        }

        if ($character -ceq '"') {
            $insideString = $true
            $masked[$index] = ' '
        }
        else {
            $masked[$index] = $character
        }
    }
    if ($insideString) {
        throw "Instruction JSON string in '$SourcePath' is unterminated."
    }
    return (-join $masked)
}

function Resolve-MeAndAIInstructionGraphPath {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][bool]$RelativeToSource
    )

    $candidate = $Target
    if ([string]::IsNullOrWhiteSpace($candidate) -or
        $candidate.Contains('\') -or
        $candidate.StartsWith('/', [StringComparison]::Ordinal) -or
        $candidate -match '^[A-Za-z]:') {
        throw "Instruction reference '$Target' from '$SourcePath' escapes the repository root."
    }
    $segments = [System.Collections.Generic.List[string]]::new()
    if ($RelativeToSource) {
        $sourceSegments = @($SourcePath.Split('/'))
        for ($index = 0; $index -lt ($sourceSegments.Count - 1); $index++) {
            $segments.Add($sourceSegments[$index])
        }
    }
    foreach ($segment in @($candidate.Split('/'))) {
        if ($segment -ceq '' -or $segment -ceq '.') { continue }
        if ($segment -ceq '..') {
            if ($segments.Count -eq 0) {
                throw "Instruction reference '$Target' from '$SourcePath' escapes the repository root."
            }
            $segments.RemoveAt($segments.Count - 1)
            continue
        }
        if ($segment -match '[\x00-\x1f]') {
            throw "Instruction reference '$Target' from '$SourcePath' is unsafe."
        }
        $segments.Add($segment)
    }
    if ($segments.Count -eq 0) {
        throw "Instruction reference '$Target' from '$SourcePath' is empty."
    }
    $resolved = @($segments) -join '/'
    if (-not (Test-MeAndAICanonicalRepositoryPath -Path $resolved)) {
        throw "Instruction reference '$Target' from '$SourcePath' is not canonical."
    }
    return $resolved
}

function Resolve-MeAndAIInstructionGraphLiteralPath {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][bool]$RelativeToSource
    )

    $firstDelimiter = $Target.IndexOfAny([char[]]@('?', '#'))
    if ($firstDelimiter -eq 0) { return $null }
    if ($firstDelimiter -lt 0) {
        return Resolve-MeAndAIInstructionGraphPath `
            -SourcePath $SourcePath -Target $Target `
            -RelativeToSource (
                $RelativeToSource -or $Target.StartsWith('./') -or
                $Target.StartsWith('../')
            )
    }

    $literalPrefix = $Target.Substring(0, $firstDelimiter)
    $literalSuffix = $Target.Substring($firstDelimiter)
    $literalPrefixResolved = Resolve-MeAndAIInstructionGraphPath `
        -SourcePath $SourcePath -Target $literalPrefix `
        -RelativeToSource (
            $RelativeToSource -or $literalPrefix.StartsWith('./') -or
            $literalPrefix.StartsWith('../')
        )
    $literalResolved = $literalPrefixResolved + $literalSuffix
    if (-not (Test-MeAndAICanonicalRepositoryPath -Path $literalResolved)) {
        return $null
    }
    return $literalResolved
}

function Resolve-MeAndAIInstructionGraphReferenceTarget {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][bool]$RelativeToSource,
        [Parameter(Mandatory)]$RepositoryPathInventory
    )

    try {
        $decodedTarget = [uri]::UnescapeDataString($Target)
    }
    catch {
        throw "Instruction reference '$Target' from '$SourcePath' has invalid escaping."
    }
    if ($decodedTarget.StartsWith(
            'file:', [StringComparison]::OrdinalIgnoreCase
        ) -or ($decodedTarget.Length -ge 2 -and
               $decodedTarget[1] -ceq ':')) {
        throw "Instruction reference '$Target' from '$SourcePath' escapes the repository root."
    }
    if (Test-MeAndAIExternalInstructionReference -Target $decodedTarget) {
        return [pscustomobject][ordered]@{
            Target = $decodedTarget
            Resolved = $null
            External = $true
            ExistsInInventory = $false
            RepeatedHashPlaceholder = $false
        }
    }

    # A literal hash can be part of a tracked Git path. Prefer the longest exact
    # inventory prefix before interpreting a later hash or query as URI syntax.
    for ($index = $decodedTarget.Length - 1; $index -ge 0; $index--) {
        if ($decodedTarget[$index] -cne '#' -and
            $decodedTarget[$index] -cne '?') {
            continue
        }
        if ($index -eq 0) { continue }
        $prefix = $decodedTarget.Substring(0, $index)
        $prefixResolved = Resolve-MeAndAIInstructionGraphLiteralPath `
            -SourcePath $SourcePath -Target $prefix `
            -RelativeToSource $RelativeToSource
        if ($null -ne $prefixResolved -and
            $RepositoryPathInventory.ContainsKey($prefixResolved)) {
            return [pscustomobject][ordered]@{
                Target = $decodedTarget
                Resolved = $prefixResolved
                External = $false
                ExistsInInventory = $true
                RepeatedHashPlaceholder = $false
            }
        }
    }

    # Preserve an exact literal-hash Git path without allowing query/fragment
    # text to participate in dot-segment normalization. Delimiter suffixes are
    # opaque here; only an already-canonical exact-tree identity can retain one.
    $literalResolved = Resolve-MeAndAIInstructionGraphLiteralPath `
        -SourcePath $SourcePath -Target $decodedTarget `
        -RelativeToSource $RelativeToSource
    if ($null -ne $literalResolved -and
        $RepositoryPathInventory.ContainsKey($literalResolved)) {
        return [pscustomobject][ordered]@{
            Target = $decodedTarget
            Resolved = $literalResolved
            External = $false
            ExistsInInventory = $true
            RepeatedHashPlaceholder = $false
        }
    }

    $hashMatch = [regex]::Match(
        $decodedTarget,
        $script:MeAndAIInstructionGraphRepeatedHashPathPattern,
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $pathTarget = if ($hashMatch.Success) {
        [string]$hashMatch.Groups['path'].Value
    }
    else {
        $delimiter = $decodedTarget.IndexOfAny([char[]]@('?', '#'))
        if ($delimiter -ge 0) {
            $decodedTarget.Substring(0, $delimiter)
        }
        else { $decodedTarget }
    }
    $resolved = Resolve-MeAndAIInstructionGraphPath `
        -SourcePath $SourcePath -Target $pathTarget `
        -RelativeToSource (
            $RelativeToSource -or $pathTarget.StartsWith('./') -or
            $pathTarget.StartsWith('../')
        )
    $existsInInventory = $RepositoryPathInventory.ContainsKey($resolved)
    return [pscustomobject][ordered]@{
        Target = $decodedTarget
        Resolved = $resolved
        External = $false
        ExistsInInventory = [bool]$existsInInventory
        RepeatedHashPlaceholder =
            [bool]($hashMatch.Success -and -not $existsInInventory)
    }
}

function Get-MeAndAIInstructionGraphReferences {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)]$RepositoryPathInventory
    )

    $references = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $repeatedHashPathPattern =
        $script:MeAndAIInstructionGraphRepeatedHashPathPattern
    $referenceDefinitions =
        [System.Collections.Generic.Dictionary[string, string]]::new(
            [StringComparer]::Ordinal
        )
    if ($Text.Length -gt 0 -and $Text[0] -ceq [char]0xFEFF) {
        $Text = $Text.Substring(1)
    }
    $lines = @([regex]::Split($Text, '\r\n|\n|\r'))
    $insideFence = $false
    $fenceCharacter = ''
    $fenceLength = 0
    $requiredReadingContext = $false
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $line = [string]$lines[$lineIndex]
        $fence = [regex]::Match(
            $line, '^ {0,3}(?<marker>`{3,}|~{3,})(?<trailing>.*)$'
        )
        if ($fence.Success) {
            $marker = [string]$fence.Groups['marker'].Value
            $trailing = [string]$fence.Groups['trailing'].Value
            if (-not $insideFence) {
                $candidateCharacter = $marker.Substring(0, 1)
                if ($candidateCharacter -cne '`' -or
                    -not $trailing.Contains('`')) {
                    $insideFence = $true
                    $fenceCharacter = $candidateCharacter
                    $fenceLength = $marker.Length
                    continue
                }
            }
            elseif ($marker.StartsWith(
                    $fenceCharacter, [StringComparison]::Ordinal
                ) -and $marker.Length -ge $fenceLength -and
                [string]::IsNullOrWhiteSpace($trailing)) {
                $insideFence = $false
                $fenceCharacter = ''
                $fenceLength = 0
            }
            if ($insideFence -or [string]::IsNullOrWhiteSpace($trailing)) {
                continue
            }
        }
        if ($insideFence) { continue }
        $definitionLine = Get-MeAndAIInstructionSemanticLine `
            -SourcePath $SourcePath -Line $line
        $definitionLine = [regex]::Replace(
            $definitionLine, '`[^`\r\n]+`', ' '
        )
        $definition = [regex]::Match(
            $definitionLine,
            '^\s*\[(?<id>[^\]]+)\]:\s*(?<target><[^>]+>|\S+)'
        )
        if ($definition.Success) {
            $id = ConvertTo-MeAndAIInstructionReferenceLabel `
                -Label ([string]$definition.Groups['id'].Value)
            $target = [string]$definition.Groups['target'].Value
            if ([string]::IsNullOrWhiteSpace($id)) {
                throw "Instruction reference definition in '$SourcePath' has an empty label."
            }
            if ($referenceDefinitions.ContainsKey($id)) {
                if ([string]$referenceDefinitions[$id] -cne $target) {
                    throw "Instruction reference label '$id' in '$SourcePath' is ambiguous."
                }
            }
            else {
                $referenceDefinitions.Add($id, $target)
            }
        }
    }

    $insideFence = $false
    $fenceCharacter = ''
    $fenceLength = 0
    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
        $line = [string]$lines[$lineIndex]
        $fence = [regex]::Match(
            $line, '^ {0,3}(?<marker>`{3,}|~{3,})(?<trailing>.*)$'
        )
        if ($fence.Success) {
            $marker = [string]$fence.Groups['marker'].Value
            $trailing = [string]$fence.Groups['trailing'].Value
            if (-not $insideFence) {
                $candidateCharacter = $marker.Substring(0, 1)
                if ($candidateCharacter -cne '`' -or
                    -not $trailing.Contains('`')) {
                    $insideFence = $true
                    $fenceCharacter = $candidateCharacter
                    $fenceLength = $marker.Length
                    continue
                }
            }
            elseif ($marker.StartsWith(
                    $fenceCharacter, [StringComparison]::Ordinal
                ) -and $marker.Length -ge $fenceLength -and
                [string]::IsNullOrWhiteSpace($trailing)) {
                $insideFence = $false
                $fenceCharacter = ''
                $fenceLength = 0
            }
            if ($insideFence -or [string]::IsNullOrWhiteSpace($trailing)) {
                continue
            }
        }
        if ($insideFence) { continue }

        $semanticLine = Get-MeAndAIInstructionSemanticLine `
            -SourcePath $SourcePath -Line $line

        $isMarkdownTableRow = [regex]::IsMatch(
            $semanticLine, '^\s*\|',
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        $negatedInstructionLeadIn = Test-MeAndAIInvariantRegex `
            -InputText $semanticLine `
            -Pattern '\b(?:do\s+not|must\s+not|never)\b[^\r\n]*\b(?:read|load|consult|open)\b'
        $imperativeReadingLeadIn =
            (Test-MeAndAIInstructionRootPath -Path $SourcePath) -and
            -not $isMarkdownTableRow -and
            -not $negatedInstructionLeadIn -and
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*(?:[-*+]\s+)?' +
                '(?:(?:before|then|next|first|please|always|' +
                'for\s+(?:each|every))\b[^:\r\n]{0,160}\s+)?' +
                '(?:(?:you\s+)?must\s+)?(?:always\s+)?' +
                '(?:read|load|consult|open)\b[^:\r\n]{0,160}' +
                '\b(?:files?|documents?|routing|memory)\b[^:\r\n]*:\s*$'
            ))
        $declaresRequiredReadingContext = -not $isMarkdownTableRow -and
            ((Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '\bread\s+in\s+this\s+order\b|' +
                '\brequired\s+reading(?:\s+order)?(?=\s*(?::|$))'
            )) -or $imperativeReadingLeadIn)
        $requiredReadingItem = $requiredReadingContext -and
            $semanticLine -match '^\s*(?:[-*+]\s+|[0-9]+[.)]\s+)'
        if ($declaresRequiredReadingContext) {
            $requiredReadingContext = $true
        }
        elseif ($requiredReadingContext -and
            -not [string]::IsNullOrWhiteSpace($semanticLine) -and
            -not $requiredReadingItem) {
            $requiredReadingContext = $false
        }

        $authorityLabelDeclaration =
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                 '^\s*(?:[-*+]\s+|[0-9]+[.)]\s+)?' +
                '(?:canonical\s+(?:source|authority)|source[- ]of[- ]truth|' +
                'authoritative(?:\s+(?:source|authority))?|' +
                '(?:(?:project|product|feature|decision|test|work|memory|' +
                'protocol)\s+){1,3}authoritative\s+(?:source|authority))\s*:'
            ))
        $authorityTableDeclaration =
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*\|\s*(?:canonical\s+(?:source|authority)|' +
                'source[- ]of[- ]truth|authoritative(?:\s+(?:source|' +
                'authority))?)\s*\|'
            ))
        $authorityDesignationPattern =
            '(?:canonical\s+(?:source|authority)|' +
            'source[- ]of[- ]truth|' +
            'authoritative(?:\s+(?:source|authority))?|' +
            'single\s+canonical' +
            '(?:\s+[a-z][a-z0-9_-]{0,31}){0,6}\s+' +
            '(?:source|authority))'
        $authorityNegationPattern =
            '\b(?:(?:(?:do(?:es)?|did)\s+not|don''t|doesn''t|didn''t)\s+' +
            '(?:remain|serve)(?:s)?' +
            '(?:\s+as)?|never\s+(?:remains?|serves?(?:\s+as)?)|' +
            '(?:is|are|was|were)\s+not|' +
            '(?:cannot|can''t|(?:could|must|should|may|might|will|would|' +
            'shall)\s+not)\s+' +
            '(?:remain|serve)(?:s)?(?:\s+as)?|' +
            'no\s+longer\s+(?:remains?|serves?(?:\s+as)?))\s+' +
            '(?:the\s+)?' + $authorityDesignationPattern + '\b'
        $reverseAuthorityNegationPattern =
            '\b(?:canonical\s+(?:source|authority)|' +
            'source[- ]of[- ]truth)' +
            '(?:\s+(?:for|of)\s+[^.;:,\r\n]{1,128})?\s+' +
            '(?:(?:is|are|was|were|remains?)\s+' +
            '(?:not|never|no\s+longer)|' +
            '(?:(?:do(?:es)?|did)\s+not|don''t|doesn''t|didn''t)\s+' +
            'remain|' +
            '(?:cannot|can''t|(?:could|must|should|may|might|will|would|' +
            'shall)\s+not)\s+remain)\b'
        $authoritySentenceText = [regex]::Replace(
            $semanticLine,
            $authorityNegationPattern,
            ' ',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        $authoritySentenceText = [regex]::Replace(
            $authoritySentenceText,
            $reverseAuthorityNegationPattern,
            ' ',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        $authoritySentenceDeclaration =
            (Test-MeAndAIInvariantRegex `
                -InputText $authoritySentenceText -Pattern (
                    '\b(?:is|are|remains?|serves?\s+as)\s+(?:the\s+)?' +
                    '(?:canonical\s+(?:source|authority)|' +
                    'source[- ]of[- ]truth|' +
                    'authoritative(?:\s+(?:source|authority))?|' +
                    'single\s+canonical' +
                    '(?:\s+[a-z][a-z0-9_-]{0,31}){0,6}\s+' +
                    '(?:source|authority))\b'
                )) -or
            (Test-MeAndAIInvariantRegex `
                -InputText $authoritySentenceText -Pattern (
                    '\b(?:canonical\s+(?:source|authority)|' +
                    'source[- ]of[- ]truth)' +
                    '(?:\s+(?:for|of)\s+[^.;:\r\n]{1,128})?\s+' +
                    '(?:is|are|remains?)\b'
                ))
        $declaresAuthority = $authorityLabelDeclaration -or
            $authorityTableDeclaration -or
            (-not $isMarkdownTableRow -and $authoritySentenceDeclaration)
        $declaresIndex =
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*(?:[-*+]\s+)?(?:(?:canonical|authoritative)\s+)?' +
                '(?:(?:project|product|feature|decision|test|work)\s+)?' +
                '(?:index|catalog|tracker)(?:\s+(?:authority|source))?\s*:'
            )) -or
            (-not $isMarkdownTableRow -and
             (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '\b(?:is|are|remains?|serves?\s+as)\s+(?:the\s+)?' +
                 '(?:canonical|authoritative)\s+' +
                 '(?:(?:project|product|feature|decision|test|work)\s+)?' +
                 '(?:index|catalog|tracker)\b'
             ))) -or
            (-not $isMarkdownTableRow -and
             (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '\b(?:canonical|authoritative)\s+' +
                '(?:(?:project|product|feature|decision|test|work)\s+)?' +
                '(?:index|catalog|tracker)' +
                '(?:\s+(?:authority|source))?' +
                '(?:\s+(?:for|of)\s+[^.;:\r\n]{1,128})?\s+' +
                '(?:is|are|remains?)\b'
             ))) -or
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*\|\s*(?:(?:canonical|authoritative)\s+)?' +
                '(?:(?:project|product|feature|decision|test|work)\s+)?' +
                '(?:index|catalog|tracker)\s*\|'
            ))
        $requiresReading =
            (-not $isMarkdownTableRow -and
             (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '\brequired\s+reading(?:\s+order)?(?=\s*(?::|$))|' +
                '\bmust\s+(?:read|load|consult)\b|' +
                '^\s*(?:[-*+]\s+|[0-9]+[.)]\s+)?' +
                '(?:(?:then|next|first|please|always)\s+)?' +
                '(?:load|consult)\b(?=\s+(?:' +
                '`[^`\r\n]+`|' +
                '(?<!!)\[[^\]\r\n]+\](?:\([^\r\n]+\)|\[[^\]\r\n]*\])?|' +
                '(?:[A-Za-z]:[\\/]|[\\/]+|\.\.?[\\/])?' +
                '[^\s`/\\]+(?:[\\/][^\s`]+|\.[^\s`]+)' +
                '))'
            ))) -or
            ((Test-MeAndAIInstructionRootPath -Path $SourcePath) -and
             -not $isMarkdownTableRow -and
             (Test-MeAndAIInvariantRegex -InputText $semanticLine `
                -Pattern '\bread(?:\s+and\s+follow)?\b')) -or
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*\|\s*(?:required\s+reading(?:\s+order)?|' +
                'must\s+read|load|consult|read(?:\s+and\s+follow)?)\s*\|'
            ))
        $negatesReading = Test-MeAndAIInvariantRegex -InputText $semanticLine `
            -Pattern '\b(do\s+not|must\s+not|never)\b[^\r\n]*\b(read|load|consult)\b'

        $lineKind = if ($declaresAuthority) {
            'DeclaresAuthority'
        }
        elseif ($declaresIndex) {
            'Indexes'
        }
        elseif ($requiredReadingItem -or
            ($requiresReading -and -not $negatesReading)) {
            'RequiresRead'
        }
        else { 'References' }
        $required = $lineKind -cin @(
            'RequiresRead', 'DeclaresAuthority', 'Indexes'
        )
        $lineNumber = $lineIndex + 1
        $acceptRepositoryPathTokens =
            (Test-MeAndAIInstructionRootPath -Path $SourcePath) -or
            $lineKind -cin @('RequiresRead', 'DeclaresAuthority', 'Indexes')
        $acceptFlatExtensionlessCodeSpan =
            $declaresRequiredReadingContext -or $requiredReadingItem -or
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*(?:[-*+]\s+|[0-9]+[.)]\s+)?' +
                '(?:(?:canonical\s+(?:source|authority)|source[- ]of[- ]truth|' +
                'authoritative(?:\s+(?:source|authority))?|' +
                '(?:(?:project|product|feature|decision|test|work|memory|' +
                'protocol)\s+){1,3}authoritative\s+(?:source|authority))|' +
                '(?:(?:canonical|authoritative)\s+)?' +
                '(?:(?:project|product|feature|decision|test|work)\s+)?' +
                '(?:index|catalog|tracker)(?:\s+(?:authority|source))?)\s*:'
            )) -or
            (Test-MeAndAIInvariantRegex -InputText $semanticLine -Pattern (
                '^\s*(?:[-*+]\s+|[0-9]+[.)]\s+)?' +
                '(?:must\s+read|load|consult|read(?:\s+and\s+follow)?)\b'
            ))

        $tokens = [System.Collections.Generic.List[object]]::new()
        $markdownSyntaxLine = [regex]::Replace(
            $semanticLine, '`[^`\r\n]+`', ' '
        )
        foreach ($match in [regex]::Matches(
            $markdownSyntaxLine,
            '(?<!!)\[[^\]]+\]\((?<target><[^>]+>|[^)\s]+)(?:\s+["''][^"'']*["''])?\)'
        )) {
            $tokens.Add([pscustomobject]@{
                Target = [string]$match.Groups['target'].Value
                RelativeToSource = $true
                Reason = 'MarkdownLink'
            })
        }
        foreach ($match in [regex]::Matches(
            $markdownSyntaxLine,
            '(?<!!)\[(?<text>[^\]]+)\]\[(?<id>[^\]]*)\]'
        )) {
            $id = [string]$match.Groups['id'].Value
            if ([string]::IsNullOrWhiteSpace($id)) {
                $id = [string]$match.Groups['text'].Value
            }
            $id = ConvertTo-MeAndAIInstructionReferenceLabel -Label $id
            if ($referenceDefinitions.ContainsKey($id)) {
                $tokens.Add([pscustomobject]@{
                    Target = [string]$referenceDefinitions[$id]
                    RelativeToSource = $true
                    Reason = 'MarkdownReferenceLink'
                })
            }
        }
        $shortcutReferenceLine = [regex]::Replace(
            $markdownSyntaxLine,
            '!?\[[^\]]+\]\((?:<[^>]+>|[^)\s]+)(?:\s+["''][^"'']*["''])?\)',
            ' '
        )
        $shortcutReferenceLine = [regex]::Replace(
            $shortcutReferenceLine,
            '(?<!!)\[[^\]]+\]\[[^\]]*\]',
            ' '
        )
        foreach ($match in [regex]::Matches(
            $shortcutReferenceLine,
            '(?<!!)\[(?<id>[^\]]+)\](?!\s*[:\[(])'
        )) {
            $id = ConvertTo-MeAndAIInstructionReferenceLabel `
                -Label ([string]$match.Groups['id'].Value)
            if ($referenceDefinitions.ContainsKey($id)) {
                $tokens.Add([pscustomobject]@{
                    Target = [string]$referenceDefinitions[$id]
                    RelativeToSource = $true
                    Reason = 'MarkdownReferenceLink'
                })
            }
        }
        foreach ($match in [regex]::Matches(
            $semanticLine,
            '`(?<target>[^`\r\n]+)`'
        )) {
            if (-not $acceptRepositoryPathTokens) { continue }
            $value = ([string]$match.Groups['target'].Value).Trim()
            if ([string]::IsNullOrWhiteSpace($value)) { continue }
            if ([regex]::IsMatch(
                    $value, '^!?\[[^\]\r\n]+\]\([^\r\n]+\)$',
                    [Text.RegularExpressions.RegexOptions]::CultureInvariant
                ) -or [regex]::IsMatch(
                    $value, '^!?\[[^\]\r\n]+\]\[[^\]\r\n]*\]$',
                    [Text.RegularExpressions.RegexOptions]::CultureInvariant
                )) {
                continue
            }
            # A fragment-only directive is not a repository target. Repeated
            # hashes are classified in the common token path below, after
            # external/escape handling and before placeholder suppression.
            if ($value.StartsWith('#', [StringComparison]::Ordinal)) {
                continue
            }
            $relativeToSource = $value.StartsWith('./') -or
                $value.StartsWith('../')
            # All-numeric slash tokens commonly encode ratios, dates, and test
            # results. They remain concrete only when the exact resolved path
            # exists in the committed tree, so a real numeric path is retained
            # without turning evidence such as 24/24 into a missing target.
            if ([regex]::IsMatch(
                    $value, '^(?:(?:\.\.?/)+)?[0-9]+(?:/[0-9]+)+$',
                    [Text.RegularExpressions.RegexOptions]::CultureInvariant
                )) {
                $numericSlashPath = Resolve-MeAndAIInstructionGraphPath `
                    -SourcePath $SourcePath -Target $value `
                    -RelativeToSource $relativeToSource
                if (-not $RepositoryPathInventory.ContainsKey(
                        $numericSlashPath)) {
                    continue
                }
            }
            try {
                $classificationValue = [uri]::UnescapeDataString($value)
            }
            catch {
                throw "Instruction reference '$value' from '$SourcePath' has invalid escaping."
            }
            if ($classificationValue.StartsWith(
                    'file:', [StringComparison]::OrdinalIgnoreCase
                ) -or ($classificationValue.Length -ge 2 -and
                       $classificationValue[1] -ceq ':')) {
                throw "Instruction reference '$value' from '$SourcePath' escapes the repository root."
            }
            $externalCandidate =
                Test-MeAndAIExternalInstructionReference `
                    -Target $classificationValue
            $classificationHashMatch = [regex]::Match(
                $value, $repeatedHashPathPattern,
                [Text.RegularExpressions.RegexOptions]::CultureInvariant
            )
            if ($classificationHashMatch.Success) {
                $classificationValue =
                    [string]$classificationHashMatch.Groups['path'].Value
            }
            $extension = Get-MeAndAIGitPathExtension `
                -Path $classificationValue
            $whitespaceMatches = [regex]::Matches($value, '\s')
            $hasWhitespace = $whitespaceMatches.Count -gt 0
            if ($hasWhitespace -and -not $externalCandidate) {
                if ((Test-MeAndAIInstructionGraphCommandCodeSpan `
                        -Value $value) -or $extension -match '\s' -or
                    [regex]::IsMatch(
                        $value, '(?:^|\s)--?[A-Za-z][A-Za-z0-9-]*\b',
                        [Text.RegularExpressions.RegexOptions]::CultureInvariant
                    )) {
                    continue
                }
                $membership = Resolve-MeAndAIInstructionGraphReferenceTarget `
                    -SourcePath $SourcePath -Target $value `
                    -RelativeToSource $relativeToSource `
                    -RepositoryPathInventory $RepositoryPathInventory
                if ($lineKind -ceq 'References' -and
                    -not [bool]$membership.External -and
                    -not [bool]$membership.ExistsInInventory) {
                    continue
                }
            }
            $canonicalExtensionlessPath = $extension -ceq '' -and
                ($classificationValue.Contains('/') -or
                    $acceptFlatExtensionlessCodeSpan) -and
                (Test-MeAndAICanonicalRepositoryPath -Path $classificationValue)
            $canonicalDottedPath = $extension -cne '' -and
                ((Test-MeAndAIInstructionGraphTextPath `
                    -Path $classificationValue) -or
                 (Test-MeAndAIInstructionGraphProtectedPath `
                    -Path $classificationValue) -or
                 -not (Test-MeAndAIInstructionGraphNumericDottedToken `
                    -Value $classificationValue))
            if ($canonicalDottedPath -or $canonicalExtensionlessPath -or
                (Test-MeAndAIInstructionRootPath -Path $value) -or
                $externalCandidate) {
                $tokens.Add([pscustomobject]@{
                    Target = $value
                    RelativeToSource = $relativeToSource
                    Reason = 'RepositoryPathToken'
                })
            }
        }
        # Raw repository-path tokens are a separate grammar production. Strip
        # syntax-owned spans first so a relative Markdown target is not also
        # reinterpreted as a root-relative raw token on the same line.
        $rawTokenLine = [regex]::Replace(
            $semanticLine,
            '!?\[[^\]]+\]\((?:<[^>]+>|[^)\s]+)(?:\s+["''][^"'']*["''])?\)',
            ' '
        )
        $rawTokenLine = [regex]::Replace(
            $rawTokenLine, '`[^`\r\n]+`', ' '
        )
        $rawTokenLine = [regex]::Replace(
            $rawTokenLine, '^\s*\[[^\]]+\]:\s*(?:<[^>]+>|\S+)', ' '
        )
        foreach ($match in [regex]::Matches(
            $rawTokenLine,
            '(?<![\p{L}\p{M}\p{N}_.:/\\|+@~-])' +
            '(?<target>(?:(?:[A-Za-z]:[\\/]|[\\/]+)|(?:\.\.?[\\/])*)?' +
            '(?:[\p{L}\p{M}\p{N}_.|+@~-]+[\\/])*' +
            '(?:[\p{L}\p{M}\p{N}_.|+@~-]+\.[\p{L}\p{M}\p{N}_|+@~-]+))' +
            '(?![\p{L}\p{M}\p{N}_/\\|+@~-])'
        )) {
            if (-not $acceptRepositoryPathTokens) { continue }
            $value = [string]$match.Groups['target'].Value
            if (-not (Test-MeAndAIInstructionGraphTextPath -Path $value) -and
                -not (Test-MeAndAIInstructionGraphProtectedPath -Path $value) -and
                (Test-MeAndAIInstructionGraphNumericDottedToken `
                    -Value $value)) {
                continue
            }
            $tokens.Add([pscustomobject]@{
                Target = $value
                RelativeToSource = $value.StartsWith('./') -or
                    $value.StartsWith('../')
                Reason = 'RepositoryPathToken'
            })
        }

        foreach ($token in $tokens) {
            $target = ([string]$token.Target).Trim()
            if ($target.StartsWith('<') -and $target.EndsWith('>')) {
                $target = $target.Substring(1, $target.Length - 2)
            }
            if ([string]::IsNullOrWhiteSpace($target) -or
                $target.StartsWith('#')) {
                continue
            }
            $classification = Resolve-MeAndAIInstructionGraphReferenceTarget `
                -SourcePath $SourcePath -Target $target `
                -RelativeToSource ([bool]$token.RelativeToSource) `
                -RepositoryPathInventory $RepositoryPathInventory
            if ([bool]$classification.External) {
                $externalTarget = [string]$classification.Target
                $key = "external`0$externalTarget`0$lineKind`0$lineNumber"
                if ($seen.Add($key)) {
                    $references.Add([pscustomobject][ordered]@{
                        target = $externalTarget
                        kind = $lineKind
                        anchor = "L$lineNumber"
                        reason = [string]$token.Reason
                        required = [bool]$required
                        external = $true
                    })
                }
                continue
            }
            if ([bool]$classification.RepeatedHashPlaceholder) {
                continue
            }
            $resolved = [string]$classification.Resolved
            $key = "local`0$resolved`0$lineKind`0$lineNumber"
            if ($seen.Add($key)) {
                $references.Add([pscustomobject][ordered]@{
                    target = $resolved
                    kind = $lineKind
                    anchor = "L$lineNumber"
                    reason = [string]$token.Reason
                    required = [bool]$required
                    external = $false
                })
            }
        }
    }
    return @($references)
}

function Add-MeAndAIInstructionGraphNode {
    param(
        [Parameter(Mandatory)]$NodeStates,
        [Parameter(Mandatory)]$Entry,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Scope,
        [Parameter(Mandatory)][string]$Role,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)]$Limits
    )

    $path = [string]$Entry.Path
    if ($NodeStates.ContainsKey($path)) {
        $state = $NodeStates[$path]
        [void]$state.Reasons.Add($Reason)
        $precedence = @{
            UnlinkedKnownSurfaceCandidate = 0
            ProtectedNonText = 1
            ReferencedText = 2
            InstructionRoot = 3
        }
        if ([int]$precedence[$Role] -gt [int]$precedence[[string]$state.Role]) {
            $state.Role = $Role
            $state.Scope = $Scope
        }
        return $state
    }
    if ($NodeStates.Count -ge [int]$Limits.MaximumNodes) {
        throw 'Instruction graph exceeds the node budget; maintainer review is required.'
    }
    $state = [pscustomobject]@{
        Path = $path
        Mode = [string]$Entry.Mode
        Type = [string]$Entry.Type
        BlobSha = [string]$Entry.Sha
        Scope = $Scope
        Role = $Role
        Reasons = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::Ordinal
        )
    }
    [void]$state.Reasons.Add($Reason)
    $NodeStates.Add($path, $state)
    return $state
}

function Add-MeAndAIInstructionGraphEdge {
    param(
        [Parameter(Mandatory)]$EdgeStates,
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Anchor,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][bool]$External,
        [Parameter(Mandatory)]$Limits
    )

    # The graph models one directed semantic relationship, not every textual
    # repetition of that relationship. Retain the first exact anchor/reason in
    # deterministic source order so large indexes cannot inflate equivalent
    # edges while the closure topology remains unchanged.
    $key = "$Source`0$Target`0$Kind`0$External"
    if ($EdgeStates.ContainsKey($key)) { return }
    if ($EdgeStates.Count -ge [int]$Limits.MaximumEdges) {
        throw 'Instruction graph exceeds the edge budget; maintainer review is required.'
    }
    $EdgeStates.Add($key, [pscustomobject][ordered]@{
        source = $Source
        target = $Target
        kind = $Kind
        anchor = $Anchor
        reason = $Reason
        external = $External
    })
}

function Add-MeAndAIInstructionGraphCanonicalValue {
    param(
        [Parameter(Mandatory)][IO.MemoryStream]$Stream,
        [AllowEmptyString()][string]$Value = ''
    )

    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Value)
    $prefix = [Text.Encoding]::ASCII.GetBytes("$($bytes.Length):")
    $Stream.Write($prefix, 0, $prefix.Length)
    $Stream.Write($bytes, 0, $bytes.Length)
    $Stream.WriteByte(10)
}

function Get-MeAndAIInstructionGraphDigest {
    param([Parameter(Mandatory)]$Graph)

    $stream = [IO.MemoryStream]::new()
    try {
        foreach ($value in @(
            'schema', [string]$Graph.schema,
            'baseHead', [string]$Graph.baseHead,
            'maximumTreeEntries', [string]$Graph.limits.maximumTreeEntries,
            'maximumTreePathUtf8Bytes',
                [string]$Graph.limits.maximumTreePathUtf8Bytes,
            'maximumNodes', [string]$Graph.limits.maximumNodes,
            'maximumEdges', [string]$Graph.limits.maximumEdges,
            'maximumDepth', [string]$Graph.limits.maximumDepth,
            'maximumBlobBytes', [string]$Graph.limits.maximumBlobBytes,
            'maximumAggregateBlobBytes',
                [string]$Graph.limits.maximumAggregateBlobBytes,
            'maximumPathUtf8Bytes', [string]$Graph.limits.maximumPathUtf8Bytes
        )) {
            Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                -Value ([string]$value)
        }
        foreach ($root in @($Graph.roots)) {
            foreach ($value in @('root', [string]$root.path, [string]$root.kind)) {
                Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                    -Value ([string]$value)
            }
        }
        foreach ($node in @($Graph.nodes)) {
            foreach ($value in @(
                'node', [string]$node.path, [string]$node.mode,
                [string]$node.type, [string]$node.blobSha,
                [string]$node.scope, [string]$node.role
            )) {
                Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                    -Value ([string]$value)
            }
            foreach ($reason in @($node.reasons)) {
                Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                    -Value 'reason'
                Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                    -Value ([string]$reason)
            }
        }
        foreach ($edge in @($Graph.edges)) {
            foreach ($value in @(
                'edge', [string]$edge.source, [string]$edge.target,
                [string]$edge.kind, [string]$edge.anchor,
                [string]$edge.reason, ([string][bool]$edge.external)
            )) {
                Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                    -Value ([string]$value)
            }
        }
        foreach ($candidate in @($Graph.candidates)) {
            Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                -Value 'candidate'
            Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                -Value ([string]$candidate)
        }
        foreach ($surface in @($Graph.protocolSurfaces)) {
            Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                -Value 'surface'
            Add-MeAndAIInstructionGraphCanonicalValue -Stream $stream `
                -Value ([string]$surface)
        }
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            return ([BitConverter]::ToString(
                $sha.ComputeHash($stream.ToArray())
            )).Replace('-', '').ToLowerInvariant()
        }
        finally { $sha.Dispose() }
    }
    finally { $stream.Dispose() }
}

function New-MeAndAIInstructionGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BaseHead,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TreeEntries,
        [Parameter(Mandatory)][scriptblock]$ReadBlob
    )

    if ($BaseHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Instruction graph requires one canonical lowercase base commit.'
    }
    $limits = Get-MeAndAIInstructionGraphLimits
    $entryValues = @($TreeEntries)
    if ($entryValues.Count -gt [int]$limits.MaximumTreeEntries) {
        throw 'Instruction graph exceeds the tracked-tree budget; maintainer review is required.'
    }
    $entryByPath = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $entryByInsensitivePath =
        [System.Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
    $normalizedPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $entryByNormalizedPath =
        [System.Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
    [long]$treePathUtf8Bytes = 0
    foreach ($entry in $entryValues) {
        foreach ($property in @('Path', 'Mode', 'Type', 'Sha')) {
            if ($null -eq $entry -or $null -eq $entry.PSObject.Properties[$property]) {
                throw "Instruction graph tree entry is missing '$property'."
            }
        }
        $path = [string]$entry.Path
        $entryMode = [string]$entry.Mode
        $entryType = [string]$entry.Type
        $validModeType =
            ($entryMode -cin @('100644', '100755', '120000') -and
             $entryType -ceq 'blob') -or
            ($entryMode -ceq '040000' -and $entryType -ceq 'tree') -or
            ($entryMode -ceq '160000' -and $entryType -ceq 'commit')
        $entryPathUtf8Bytes = [Text.Encoding]::UTF8.GetByteCount($path)
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            $entryPathUtf8Bytes -gt [int]$limits.MaximumPathUtf8Bytes -or
            $entryMode -cnotmatch '^[0-9]{6}$' -or
            $entryType -cnotin @('blob', 'tree', 'commit') -or
            -not $validModeType -or
            [string]$entry.Sha -cnotmatch '^[0-9a-f]{40}$' -or
            $entryByInsensitivePath.ContainsKey($path)) {
            throw "Instruction graph tree path '$path' is invalid or case-ambiguous."
        }
        if ($treePathUtf8Bytes -gt
            ([long]$limits.MaximumTreePathUtf8Bytes - $entryPathUtf8Bytes)) {
            throw 'Instruction graph exceeds the tracked-tree path budget; maintainer review is required.'
        }
        $treePathUtf8Bytes += $entryPathUtf8Bytes
        $normalized = $path.Normalize([Text.NormalizationForm]::FormC)
        if (-not $normalizedPaths.Add($normalized)) {
            throw "Instruction graph tree path '$path' is Unicode-ambiguous."
        }
        $entryByPath.Add($path, $entry)
        $entryByInsensitivePath.Add($path, $entry)
        $entryByNormalizedPath.Add($normalized, $entry)
    }

    $seedStates = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $instructionRoots = [System.Collections.Generic.List[string]]::new()
    foreach ($path in @($entryByPath.Keys)) {
        $isInstructionRoot = Test-MeAndAIInstructionRootPath -Path $path
        if ([string]$entryByPath[$path].Type -ceq 'tree') {
            $isInstructionRoot = $false
        }
        # Intermediate trees are present so a referenced directory can be
        # distinguished from a missing path, but the pre-graph compatibility
        # projection was leaf/gitlink based. Do not manufacture new directory
        # surfaces merely because exact acquisition now uses ls-tree -t.
        $isCompatibility = [string]$entryByPath[$path].Type -cne 'tree' -and
            (Test-MeAndAIProtocolSurfacePath -Path $path)
        if (-not $isInstructionRoot -and -not $isCompatibility) { continue }
        $kind = if ($isInstructionRoot) {
            if ($path -ceq 'AGENTS.md' -or
                $path.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)) {
                'ScopedAgents'
            }
            else { 'GenericInstructionRoot' }
        }
        elseif ($path -ceq '.ai/protocol' -or
            $path -ceq '.ai/meandai-update-state.json' -or
            $path.StartsWith('.github/scripts/MeAndAI.',
                [StringComparison]::Ordinal)) {
            'ReservedIntegrationAuthority'
        }
        else { 'KnownSurfaceCompatibility' }
        $seedStates.Add($path, [pscustomobject][ordered]@{
            path = $path
            kind = $kind
        })
        if ($isInstructionRoot) { $instructionRoots.Add($path) }
    }

    $nodeStates = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $edgeStates = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $queue = [System.Collections.Generic.Queue[object]]::new()
    $reachable = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $visited = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $sortedRootPaths = @($instructionRoots)
    [Array]::Sort($sortedRootPaths, [StringComparer]::Ordinal)
    foreach ($path in $sortedRootPaths) {
        $entry = $entryByPath[$path]
        if ([string]$entry.Mode -cnotin @('100644', '100755') -or
            [string]$entry.Type -cne 'blob') {
            throw "Instruction root '$path' is not one regular blob."
        }
        [void]$reachable.Add($path)
        [void](Add-MeAndAIInstructionGraphNode -NodeStates $nodeStates `
            -Entry $entry -Scope $path -Role 'InstructionRoot' `
            -Reason 'InstructionRootSeed' -Limits $limits)
        $queue.Enqueue([pscustomobject]@{
            Path = $path
            Depth = 0
            Scope = $path
        })
    }
    foreach ($path in @($seedStates.Keys)) {
        if ($reachable.Contains($path)) { continue }
        $entry = $entryByPath[$path]
        [void](Add-MeAndAIInstructionGraphNode -NodeStates $nodeStates `
            -Entry $entry -Scope '' -Role 'UnlinkedKnownSurfaceCandidate' `
            -Reason ([string]$seedStates[$path].kind) -Limits $limits)
    }

    $agentsRootPaths = @($sortedRootPaths | Where-Object {
        $_ -ceq 'AGENTS.md' -or
        $_.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)
    })
    foreach ($nestedPath in @($agentsRootPaths | Where-Object {
        $_.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)
    })) {
        $parents = @($agentsRootPaths | Where-Object {
            $_ -cne $nestedPath -and
                ($_ -ceq 'AGENTS.md' -or
                 ((Get-MeAndAIGitPathDirectoryName -Path $_) -cne '' -and
                  $nestedPath.StartsWith(
                    ((Get-MeAndAIGitPathDirectoryName -Path $_) + '/'),
                    [StringComparison]::Ordinal
                  )))
        } | Sort-Object { $_.Split('/').Count } -Descending)
        if ($parents.Count -gt 0) {
            Add-MeAndAIInstructionGraphEdge -EdgeStates $edgeStates `
                -Source ([string]$parents[0]) -Target $nestedPath `
                -Kind 'Scopes' -Anchor 'scope' -Reason 'NestedInstructionScope' `
                -External $false -Limits $limits
        }
    }

    [long]$aggregateBlobBytes = 0
    [int]$parsedBlobCount = 0
    $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        $path = [string]$current.Path
        if (-not $visited.Add($path)) { continue }
        if ([int]$current.Depth -gt [int]$limits.MaximumDepth) {
            throw 'Instruction graph exceeds the traversal-depth budget; maintainer review is required.'
        }
        $entry = $entryByPath[$path]
        [object]$raw = & $ReadBlob $entry
        [byte[]]$bytes = if ($raw -is [byte[]]) {
            [byte[]]$raw
        }
        elseif ($raw -is [array] -and @($raw).Count -eq 1 -and
            @($raw)[0] -is [byte[]]) {
            [byte[]]@($raw)[0]
        }
        else { [byte[]]@($raw) }
        if ($bytes.Length -gt [int]$limits.MaximumBlobBytes) {
            throw "Instruction blob '$path' exceeds the per-blob budget."
        }
        if ($aggregateBlobBytes -gt
            ([long]$limits.MaximumAggregateBlobBytes - $bytes.Length)) {
            throw 'Instruction graph exceeds the aggregate parsed-blob budget; maintainer review is required.'
        }
        $aggregateBlobBytes += $bytes.Length
        $parsedBlobCount++
        if ((Get-MeAndAIGitBlobSha -Bytes $bytes) -cne [string]$entry.Sha) {
            throw "Instruction blob '$path' does not match its exact tree identity."
        }
        try { $text = $strictUtf8.GetString($bytes) }
        catch {
            throw "Instruction blob '$path' is not valid UTF-8."
        }
        foreach ($reference in @(Get-MeAndAIInstructionGraphReferences `
            -SourcePath $path -Text $text `
            -RepositoryPathInventory $entryByPath)) {
            if ([bool]$reference.external) {
                Add-MeAndAIInstructionGraphEdge -EdgeStates $edgeStates `
                    -Source $path -Target ([string]$reference.target) `
                    -Kind ([string]$reference.kind) `
                    -Anchor ([string]$reference.anchor) `
                    -Reason ([string]$reference.reason) -External $true `
                    -Limits $limits
                continue
            }
            $target = [string]$reference.target
            $reservedProtocolTerminal =
                Test-MeAndAIReservedProtocolNamespacePath -Path $target
            $reservedProtocolGitlink = $reservedProtocolTerminal -and
                $entryByPath.ContainsKey('.ai/protocol') -and
                [string]$entryByPath['.ai/protocol'].Mode -ceq '160000' -and
                [string]$entryByPath['.ai/protocol'].Type -ceq 'commit'
            if ($reservedProtocolGitlink) {
                $terminalEntry = $entryByPath['.ai/protocol']
                if ([bool]$reference.required -and
                    -not (Test-MeAndAICanonicalProtocolAuthorityTarget `
                        -Path $target)) {
                    throw "Required reserved protocol target '$target' is not a canonical protocol authority."
                }
                if (-not $reachable.Contains($target) -and
                    ([int]$current.Depth + 1) -gt
                        [int]$limits.MaximumDepth) {
                    throw 'Instruction graph exceeds the traversal-depth budget; maintainer review is required.'
                }
                Add-MeAndAIInstructionGraphEdge -EdgeStates $edgeStates `
                    -Source $path -Target $target -Kind ([string]$reference.kind) `
                    -Anchor ([string]$reference.anchor) `
                    -Reason ([string]$reference.reason) -External $false `
                    -Limits $limits
                [void]$reachable.Add($target)
                [void]$reachable.Add('.ai/protocol')
                [void](Add-MeAndAIInstructionGraphNode -NodeStates $nodeStates `
                    -Entry $terminalEntry -Scope ([string]$current.Scope) `
                    -Role 'ProtectedNonText' `
                    -Reason 'ReservedIntegrationTerminal' -Limits $limits)
                continue
            }
            if (-not $entryByPath.ContainsKey($target)) {
                if ($entryByInsensitivePath.ContainsKey($target)) {
                    throw "Instruction target '$target' uses noncanonical path casing."
                }
                $normalizedTarget = $target.Normalize(
                    [Text.NormalizationForm]::FormC
                )
                if ($entryByNormalizedPath.ContainsKey($normalizedTarget)) {
                    throw "Instruction target '$target' uses noncanonical Unicode normalization."
                }
                if ([bool]$reference.required) {
                    throw "A required instruction target '$target' referenced by '$path' is missing."
                }
                continue
            }
            $targetEntry = $entryByPath[$target]
            if (-not $reachable.Contains($target) -and
                ([int]$current.Depth + 1) -gt [int]$limits.MaximumDepth) {
                throw 'Instruction graph exceeds the traversal-depth budget; maintainer review is required.'
            }
            Add-MeAndAIInstructionGraphEdge -EdgeStates $edgeStates `
                -Source $path -Target $target -Kind ([string]$reference.kind) `
                -Anchor ([string]$reference.anchor) `
                -Reason ([string]$reference.reason) -External $false `
                -Limits $limits
            if ([string]$targetEntry.Mode -cnotin @('100644', '100755') -or
                [string]$targetEntry.Type -cne 'blob') {
                if ([bool]$reference.required) {
                    throw "A required non-regular instruction target '$target' referenced by '$path' as '$([string]$reference.kind)' cannot be traversed."
                }
                [void](Add-MeAndAIInstructionGraphNode -NodeStates $nodeStates `
                    -Entry $targetEntry -Scope ([string]$current.Scope) `
                    -Role 'ProtectedNonText' -Reason 'ReferencedProtectedEvidence' `
                    -Limits $limits)
                continue
            }
            $isText = Test-MeAndAIInstructionGraphTextPath -Path $target
            $isProtected = Test-MeAndAIInstructionGraphProtectedPath -Path $target
            if (-not $isText -and -not $isProtected) {
                throw "An unsupported regular instruction text target '$target' requires maintainer review."
            }
            if ($isProtected -and [string]$reference.kind -cin @(
                    'RequiresRead', 'DeclaresAuthority', 'Indexes'
                )) {
                throw "A protected source or binary target '$target' is used as live instruction authority; maintainer review is required."
            }
            $role = if ($isText) { 'ReferencedText' } else { 'ProtectedNonText' }
            [void]$reachable.Add($target)
            [void](Add-MeAndAIInstructionGraphNode -NodeStates $nodeStates `
                -Entry $targetEntry -Scope ([string]$current.Scope) -Role $role `
                -Reason ([string]$reference.kind) -Limits $limits)
            if ($isText -and -not $visited.Contains($target)) {
                $queue.Enqueue([pscustomobject]@{
                    Path = $target
                    Depth = ([int]$current.Depth + 1)
                    Scope = [string]$current.Scope
                })
            }
        }
    }

    $orderedNodePaths = @($nodeStates.Keys)
    [Array]::Sort($orderedNodePaths, [StringComparer]::Ordinal)
    $nodes = @($orderedNodePaths | ForEach-Object {
        $nodeState = $nodeStates[[string]$_]
        $reasons = @($nodeState.Reasons)
        [Array]::Sort($reasons, [StringComparer]::Ordinal)
        [pscustomobject][ordered]@{
            path = [string]$nodeState.Path
            mode = [string]$nodeState.Mode
            type = [string]$nodeState.Type
            blobSha = [string]$nodeState.BlobSha
            scope = [string]$nodeState.Scope
            role = [string]$nodeState.Role
            reasons = @($reasons)
        }
    })
    $pathUtf8Bytes = [Text.Encoding]::UTF8.GetByteCount(
        (@($nodes | ForEach-Object { [string]$_.path }) -join "`n")
    )
    if ($pathUtf8Bytes -gt [int]$limits.MaximumPathUtf8Bytes) {
        throw 'Instruction graph exceeds the path-inventory budget; maintainer review is required.'
    }
    $orderedEdgeKeys = @($edgeStates.Keys)
    [Array]::Sort($orderedEdgeKeys, [StringComparer]::Ordinal)
    $edges = @($orderedEdgeKeys | ForEach-Object {
        $edgeStates[[string]$_]
    })
    $orderedSeedPaths = @($seedStates.Keys)
    [Array]::Sort($orderedSeedPaths, [StringComparer]::Ordinal)
    $roots = @($orderedSeedPaths | ForEach-Object {
        $seedStates[[string]$_]
    })
    $candidates = @($nodes | Where-Object {
        $_.role -ceq 'UnlinkedKnownSurfaceCandidate'
    } | ForEach-Object { [string]$_.path })
    $surfaceSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($root in $roots) { [void]$surfaceSet.Add([string]$root.path) }
    foreach ($node in $nodes) {
        if ([string]$node.role -cne 'ProtectedNonText') {
            [void]$surfaceSet.Add([string]$node.path)
        }
    }
    $surfaces = @($surfaceSet)
    [Array]::Sort($candidates, [StringComparer]::Ordinal)
    [Array]::Sort($surfaces, [StringComparer]::Ordinal)
    $graph = [pscustomobject][ordered]@{
        schema = [int]$script:MeAndAIInstructionGraphSchema
        baseHead = $BaseHead
        limits = [pscustomobject][ordered]@{
            maximumTreeEntries = [int]$limits.MaximumTreeEntries
            maximumTreePathUtf8Bytes =
                [int]$limits.MaximumTreePathUtf8Bytes
            maximumNodes = [int]$limits.MaximumNodes
            maximumEdges = [int]$limits.MaximumEdges
            maximumDepth = [int]$limits.MaximumDepth
            maximumBlobBytes = [int]$limits.MaximumBlobBytes
            maximumAggregateBlobBytes =
                [int]$limits.MaximumAggregateBlobBytes
            maximumPathUtf8Bytes = [int]$limits.MaximumPathUtf8Bytes
        }
        roots = @($roots)
        nodes = @($nodes)
        edges = @($edges)
        candidates = @($candidates)
        protocolSurfaces = @($surfaces)
        counts = [pscustomobject][ordered]@{
            treeEntries = [int]$entryValues.Count
            treePathUtf8Bytes = [long]$treePathUtf8Bytes
            roots = [int]$roots.Count
            nodes = [int]$nodes.Count
            edges = [int]$edges.Count
            candidates = [int]$candidates.Count
            protocolSurfaces = [int]$surfaces.Count
            parsedBlobs = [int]$parsedBlobCount
            parsedBlobBytes = [long]$aggregateBlobBytes
            pathInventoryUtf8Bytes = [int]$pathUtf8Bytes
        }
        digest = ''
    }
    $graph.digest = Get-MeAndAIInstructionGraphDigest -Graph $graph
    return $graph
}

function Test-MeAndAIExactInstructionGraph {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)

    try {
        if (-not (Test-MeAndAIExactObjectProperties -Object $Graph -Names @(
                'schema', 'baseHead', 'limits', 'roots', 'nodes', 'edges',
                'candidates', 'protocolSurfaces', 'counts', 'digest'
            )) -or
            ($Graph.schema -isnot [int] -and $Graph.schema -isnot [long]) -or
            [long]$Graph.schema -ne $script:MeAndAIInstructionGraphSchema -or
            [string]$Graph.baseHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$Graph.digest -cnotmatch '^[0-9a-f]{64}$' -or
            $Graph.roots -isnot [array] -or $Graph.nodes -isnot [array] -or
            $Graph.edges -isnot [array] -or $Graph.candidates -isnot [array] -or
            $Graph.protocolSurfaces -isnot [array] -or $null -eq $Graph.counts) {
            return $false
        }
        $limits = Get-MeAndAIInstructionGraphLimits
        [long]$nodePathUtf8Bytes = 0
        foreach ($node in @($Graph.nodes)) {
            $nodePathUtf8Bytes +=
                [Text.Encoding]::UTF8.GetByteCount([string]$node.path)
        }
        if (-not (Test-MeAndAIExactObjectProperties `
                -Object $Graph.limits -Names @(
                    'maximumTreeEntries', 'maximumTreePathUtf8Bytes',
                    'maximumNodes', 'maximumEdges',
                    'maximumDepth', 'maximumBlobBytes',
                    'maximumAggregateBlobBytes', 'maximumPathUtf8Bytes'
                )) -or
            -not (Test-MeAndAIExactObjectProperties `
                -Object $Graph.counts -Names @(
                    'treeEntries', 'treePathUtf8Bytes', 'roots', 'nodes',
                    'edges', 'candidates',
                    'protocolSurfaces', 'parsedBlobs', 'parsedBlobBytes',
                    'pathInventoryUtf8Bytes'
                ))) {
            return $false
        }
        foreach ($numericValue in @(
            $Graph.limits.maximumTreeEntries,
            $Graph.limits.maximumTreePathUtf8Bytes,
            $Graph.limits.maximumNodes,
            $Graph.limits.maximumEdges,
            $Graph.limits.maximumDepth,
            $Graph.limits.maximumBlobBytes,
            $Graph.limits.maximumAggregateBlobBytes,
            $Graph.limits.maximumPathUtf8Bytes,
            $Graph.counts.treeEntries,
            $Graph.counts.treePathUtf8Bytes,
            $Graph.counts.roots,
            $Graph.counts.nodes,
            $Graph.counts.edges,
            $Graph.counts.candidates,
            $Graph.counts.protocolSurfaces,
            $Graph.counts.parsedBlobs,
            $Graph.counts.parsedBlobBytes,
            $Graph.counts.pathInventoryUtf8Bytes
        )) {
            if ($numericValue -isnot [int] -and
                $numericValue -isnot [long]) {
                return $false
            }
        }
        if (
            [long]$Graph.limits.maximumTreeEntries -ne
                [long]$limits.MaximumTreeEntries -or
            [long]$Graph.limits.maximumTreePathUtf8Bytes -ne
                [long]$limits.MaximumTreePathUtf8Bytes -or
            [long]$Graph.limits.maximumNodes -ne [long]$limits.MaximumNodes -or
            [long]$Graph.limits.maximumEdges -ne [long]$limits.MaximumEdges -or
            [long]$Graph.limits.maximumDepth -ne [long]$limits.MaximumDepth -or
            [long]$Graph.limits.maximumBlobBytes -ne
                [long]$limits.MaximumBlobBytes -or
            [long]$Graph.limits.maximumAggregateBlobBytes -ne
                [long]$limits.MaximumAggregateBlobBytes -or
            [long]$Graph.limits.maximumPathUtf8Bytes -ne
                [long]$limits.MaximumPathUtf8Bytes -or
            @($Graph.nodes).Count -gt [int]$limits.MaximumNodes -or
            @($Graph.edges).Count -gt [int]$limits.MaximumEdges -or
            [long]$Graph.counts.treeEntries -gt
                [long]$limits.MaximumTreeEntries -or
            [long]$Graph.counts.treeEntries -lt @($Graph.nodes).Count -or
            [long]$Graph.counts.treePathUtf8Bytes -lt $nodePathUtf8Bytes -or
            [long]$Graph.counts.treePathUtf8Bytes -gt
                [long]$limits.MaximumTreePathUtf8Bytes -or
            [long]$Graph.counts.roots -ne @($Graph.roots).Count -or
            [long]$Graph.counts.nodes -ne @($Graph.nodes).Count -or
            [long]$Graph.counts.edges -ne @($Graph.edges).Count -or
            [long]$Graph.counts.candidates -ne @($Graph.candidates).Count -or
            [long]$Graph.counts.protocolSurfaces -ne
                @($Graph.protocolSurfaces).Count -or
            [long]$Graph.counts.parsedBlobs -lt 0 -or
            [long]$Graph.counts.parsedBlobBytes -lt 0 -or
            [long]$Graph.counts.parsedBlobBytes -gt
                [long]$limits.MaximumAggregateBlobBytes -or
            [long]$Graph.counts.pathInventoryUtf8Bytes -ne
                [Text.Encoding]::UTF8.GetByteCount(
                    (@($Graph.nodes | ForEach-Object {
                        [string]$_.path
                    }) -join "`n")
                ) -or
            [long]$Graph.counts.pathInventoryUtf8Bytes -gt
                [long]$limits.MaximumPathUtf8Bytes) {
            return $false
        }
        $rootPaths = @($Graph.roots | ForEach-Object { [string]$_.path })
        $sortedRootPaths = @($rootPaths)
        [Array]::Sort($sortedRootPaths, [StringComparer]::Ordinal)
        if (-not (Test-MeAndAIExactOrdinalSequence -Actual $rootPaths `
                -Expected $sortedRootPaths) -or
            -not (Test-MeAndAIUniqueCanonicalPaths -Paths $rootPaths)) {
            return $false
        }
        $compatibilityRootKinds =
            [System.Collections.Generic.Dictionary[string, string]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($root in @($Graph.roots)) {
            $rootPath = [string]$root.path
            $rootKind = [string]$root.kind
            $isAgentsRoot = $rootPath -ceq 'AGENTS.md' -or
                $rootPath.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)
            $isInstructionRoot = Test-MeAndAIInstructionRootPath `
                -Path $rootPath
            $isReservedRoot = $rootPath -ceq '.ai/protocol' -or
                $rootPath -ceq '.ai/meandai-update-state.json' -or
                $rootPath.StartsWith(
                    '.github/scripts/MeAndAI.', [StringComparison]::Ordinal
                )
            if (-not (Test-MeAndAIExactObjectProperties -Object $root `
                    -Names @('path', 'kind')) -or
                $rootKind -cnotin @(
                    'ScopedAgents', 'GenericInstructionRoot',
                    'KnownSurfaceCompatibility',
                    'ReservedIntegrationAuthority'
                ) -or
                ($rootKind -ceq 'ScopedAgents' -and -not $isAgentsRoot) -or
                ($rootKind -ceq 'GenericInstructionRoot' -and
                 (-not $isInstructionRoot -or $isAgentsRoot)) -or
                ($rootKind -ceq 'ReservedIntegrationAuthority' -and
                 -not $isReservedRoot) -or
                ($rootKind -ceq 'KnownSurfaceCompatibility' -and
                 ($isInstructionRoot -or $isReservedRoot -or
                 -not (Test-MeAndAIProtocolSurfacePath -Path $rootPath)))) {
                return $false
            }
            if ($rootKind -cin @(
                'KnownSurfaceCompatibility', 'ReservedIntegrationAuthority'
            )) {
                $compatibilityRootKinds.Add($rootPath, $rootKind)
            }
        }
        $nodePaths = @($Graph.nodes | ForEach-Object { [string]$_.path })
        $sortedNodePaths = @($nodePaths)
        [Array]::Sort($sortedNodePaths, [StringComparer]::Ordinal)
        if (-not (Test-MeAndAIExactOrdinalSequence -Actual $nodePaths `
            -Expected $sortedNodePaths) -or
            -not (Test-MeAndAIUniqueCanonicalPaths -Paths $nodePaths) -or
            -not (Test-MeAndAIExactCanonicalSurfaceSequence `
                -Actual @($Graph.protocolSurfaces) `
                -Expected @($Graph.protocolSurfaces))) {
            return $false
        }
        $nodeMap = [System.Collections.Generic.Dictionary[string, object]]::new(
            [StringComparer]::Ordinal
        )
        $instructionRootSet =
            [System.Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($root in @($Graph.roots | Where-Object {
            [string]$_.kind -cin @(
                'ScopedAgents', 'GenericInstructionRoot'
            )
        })) {
            [void]$instructionRootSet.Add([string]$root.path)
        }
        foreach ($node in @($Graph.nodes)) {
            if (-not (Test-MeAndAIExactObjectProperties -Object $node `
                    -Names @(
                        'path', 'mode', 'type', 'blobSha', 'scope', 'role',
                        'reasons'
                    )) -or
                [string]$node.mode -cnotmatch '^[0-9]{6}$' -or
                [string]$node.type -cnotin @('blob', 'tree', 'commit') -or
                [string]$node.blobSha -cnotmatch '^[0-9a-f]{40}$' -or
                [string]$node.role -cnotin @(
                    'InstructionRoot', 'ReferencedText', 'ProtectedNonText',
                    'UnlinkedKnownSurfaceCandidate'
                ) -or $node.reasons -isnot [array]) {
                return $false
            }
            $nodePath = [string]$node.path
            $nodeScope = [string]$node.scope
            $nodeRole = [string]$node.role
            $nodeMode = [string]$node.mode
            $nodeType = [string]$node.type
            $regularBlob = $nodeMode -cin @('100644', '100755') -and
                $nodeType -ceq 'blob'
            $validModeType = $regularBlob -or
                ($nodeMode -ceq '120000' -and $nodeType -ceq 'blob') -or
                ($nodeMode -ceq '040000' -and $nodeType -ceq 'tree') -or
                ($nodeMode -ceq '160000' -and $nodeType -ceq 'commit')
            if (-not $validModeType -or
                ($nodeRole -ceq 'InstructionRoot' -and -not $regularBlob) -or
                ($nodeRole -ceq 'ReferencedText' -and
                 (-not $regularBlob -or
                  -not (Test-MeAndAIInstructionGraphTextPath `
                    -Path $nodePath))) -or
                ($nodeRole -ceq 'ProtectedNonText' -and $regularBlob -and
                 -not (Test-MeAndAIInstructionGraphProtectedPath `
                    -Path $nodePath)) -or
                ($nodeRole -ceq 'UnlinkedKnownSurfaceCandidate' -and
                 ($nodeScope -cne '' -or
                  -not $compatibilityRootKinds.ContainsKey($nodePath))) -or
                ($nodeRole -cne 'UnlinkedKnownSurfaceCandidate' -and
                 (-not (Test-MeAndAICanonicalRepositoryPath -Path $nodeScope) -or
                  -not $instructionRootSet.Contains($nodeScope))) -or
                ($nodeRole -ceq 'InstructionRoot' -and
                 ($nodeScope -cne $nodePath -or
                  -not $instructionRootSet.Contains($nodePath)))) {
                return $false
            }
            $reasons = @($node.reasons | ForEach-Object { [string]$_ })
            $sortedReasons = @($reasons)
            [Array]::Sort($sortedReasons, [StringComparer]::Ordinal)
            if (-not (Test-MeAndAIExactOrdinalSequence -Actual $reasons `
                    -Expected $sortedReasons) -or
                @($reasons | Select-Object -Unique).Count -ne $reasons.Count) {
                return $false
            }
            $nodeMap.Add($nodePath, $node)
        }
        foreach ($root in @($Graph.roots)) {
            $rootPath = [string]$root.path
            if (-not $nodeMap.ContainsKey($rootPath) -or
                ([string]$root.kind -cin @(
                    'ScopedAgents', 'GenericInstructionRoot'
                ) -and
                 [string]$nodeMap[$rootPath].role -cne 'InstructionRoot') -or
                ([string]$root.kind -cnotin @(
                    'ScopedAgents', 'GenericInstructionRoot'
                ) -and
                 [string]$nodeMap[$rootPath].role -ceq 'InstructionRoot')) {
                return $false
            }
        }
        $expectedNodeReasons =
            [System.Collections.Generic.Dictionary[string, object]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($nodePath in @($nodeMap.Keys)) {
            $expectedNodeReasons.Add(
                $nodePath,
                [System.Collections.Generic.HashSet[string]]::new(
                    [StringComparer]::Ordinal
                )
            )
        }
        foreach ($root in @($Graph.roots)) {
            $rootPath = [string]$root.path
            $rootReason = if ([string]$root.kind -cin @(
                'ScopedAgents', 'GenericInstructionRoot'
            )) { 'InstructionRootSeed' } else { [string]$root.kind }
            [void]$expectedNodeReasons[$rootPath].Add($rootReason)
        }
        $semanticEdgeKeys = [System.Collections.Generic.List[string]]::new()
        $seenSemanticEdges = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::Ordinal
        )
        $incomingLocalNodeSet =
            [System.Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($edge in @($Graph.edges)) {
            if (-not (Test-MeAndAIExactObjectProperties -Object $edge `
                    -Names @(
                        'source', 'target', 'kind', 'anchor', 'reason',
                        'external'
                    )) -or
                [string]$edge.kind -cnotin @(
                    'Scopes', 'RequiresRead', 'DeclaresAuthority', 'Indexes',
                    'References'
                ) -or $edge.external -isnot [bool] -or
                -not (Test-MeAndAICanonicalRepositoryPath `
                    -Path ([string]$edge.source)) -or
                (-not [bool]$edge.external -and
                 -not (Test-MeAndAICanonicalRepositoryPath `
                    -Path ([string]$edge.target)))) {
                return $false
            }
            $source = [string]$edge.source
            $target = [string]$edge.target
            $kind = [string]$edge.kind
            $anchor = [string]$edge.anchor
            $reason = [string]$edge.reason
            $external = [bool]$edge.external
            $reservedTerminal = -not $external -and
                (Test-MeAndAIReservedProtocolNamespacePath -Path $target) -and
                $nodeMap.ContainsKey('.ai/protocol') -and
                [string]$nodeMap['.ai/protocol'].mode -ceq '160000' -and
                [string]$nodeMap['.ai/protocol'].type -ceq 'commit'
            if (-not $nodeMap.ContainsKey($source) -or
                [string]$nodeMap[$source].role -cnotin @(
                    'InstructionRoot', 'ReferencedText'
                ) -or
                ($external -and
                 -not (Test-MeAndAIExternalInstructionReference `
                    -Target $target)) -or
                (-not $external -and -not $nodeMap.ContainsKey($target) -and
                 -not $reservedTerminal) -or
                (-not $external -and -not $reservedTerminal -and
                 $kind -cin @(
                    'RequiresRead', 'DeclaresAuthority', 'Indexes'
                 ) -and $nodeMap.ContainsKey($target) -and
                 [string]$nodeMap[$target].role -ceq 'ProtectedNonText') -or
                ($reservedTerminal -and
                 $kind -cin @('RequiresRead', 'DeclaresAuthority', 'Indexes') -and
                 -not (Test-MeAndAICanonicalProtocolAuthorityTarget `
                    -Path $target)) -or
                ($kind -ceq 'Scopes' -and
                 ($external -or $anchor -cne 'scope' -or
                  $reason -cne 'NestedInstructionScope' -or
                  -not $instructionRootSet.Contains($source) -or
                  -not $instructionRootSet.Contains($target))) -or
                ($kind -cne 'Scopes' -and
                 ($anchor -cnotmatch '^L[1-9][0-9]*$' -or
                  $reason -cnotin @(
                    'MarkdownLink', 'MarkdownReferenceLink',
                    'RepositoryPathToken'
                  )))) {
                return $false
            }
            $semanticKey = "$source`0$target`0$kind`0$external"
            if (-not $seenSemanticEdges.Add($semanticKey)) { return $false }
            $semanticEdgeKeys.Add($semanticKey)
            if (-not $external -and $nodeMap.ContainsKey($target)) {
                [void]$incomingLocalNodeSet.Add($target)
            }
            if (-not $external -and $kind -cne 'Scopes') {
                $reasonNodePath = $null
                $expectedReason = $null
                if ($reservedTerminal) {
                    $reasonNodePath = '.ai/protocol'
                    $expectedReason = 'ReservedIntegrationTerminal'
                }
                elseif ($nodeMap.ContainsKey($target)) {
                    $reasonNodePath = $target
                    $targetNode = $nodeMap[$target]
                    $expectedReason = if (
                        [string]$targetNode.mode -cin @('100644', '100755') -and
                        [string]$targetNode.type -ceq 'blob'
                    ) { $kind } else { 'ReferencedProtectedEvidence' }
                }
                if ($null -ne $reasonNodePath) {
                    [void]$expectedNodeReasons[$reasonNodePath].Add(
                        $expectedReason
                    )
                }
            }
        }
        $sortedEdgeKeys = @($semanticEdgeKeys)
        [Array]::Sort($sortedEdgeKeys, [StringComparer]::Ordinal)
        if (-not (Test-MeAndAIExactOrdinalSequence `
                -Actual @($semanticEdgeKeys) -Expected $sortedEdgeKeys)) {
            return $false
        }
        $adjacency =
            [System.Collections.Generic.Dictionary[string, object]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($edge in @($Graph.edges | Where-Object {
            -not [bool]$_.external
        })) {
            $source = [string]$edge.source
            if (-not $adjacency.ContainsKey($source)) {
                $adjacency.Add(
                    $source,
                    [System.Collections.Generic.List[string]]::new()
                )
            }
            $adjacency[$source].Add([string]$edge.target)
        }
        $depthByPath = [System.Collections.Generic.Dictionary[string, int]]::new(
            [StringComparer]::Ordinal
        )
        $depthQueue = [System.Collections.Generic.Queue[string]]::new()
        foreach ($rootPath in @($instructionRootSet)) {
            $depthByPath.Add($rootPath, 0)
            $depthQueue.Enqueue($rootPath)
        }
        while ($depthQueue.Count -gt 0) {
            $source = $depthQueue.Dequeue()
            if (-not $adjacency.ContainsKey($source)) { continue }
            $nextDepth = [int]$depthByPath[$source] + 1
            foreach ($target in @($adjacency[$source])) {
                if ($depthByPath.ContainsKey($target)) { continue }
                if ($nextDepth -gt [int]$limits.MaximumDepth) {
                    return $false
                }
                $depthByPath.Add($target, $nextDepth)
                $depthQueue.Enqueue($target)
            }
        }
        foreach ($edge in @($Graph.edges)) {
            if (-not $depthByPath.ContainsKey([string]$edge.source)) {
                return $false
            }
        }
        foreach ($node in @($Graph.nodes | Where-Object {
            [string]$_.role -cin @('InstructionRoot', 'ReferencedText')
        })) {
            if (-not $depthByPath.ContainsKey([string]$node.path)) {
                return $false
            }
        }
        foreach ($node in @($Graph.nodes)) {
            $nodePath = [string]$node.path
            if (-not $instructionRootSet.Contains($nodePath) -and
                -not $compatibilityRootKinds.ContainsKey($nodePath) -and
                -not $incomingLocalNodeSet.Contains($nodePath)) {
                return $false
            }
            $expectedReasons = @($expectedNodeReasons[$nodePath])
            [Array]::Sort($expectedReasons, [StringComparer]::Ordinal)
            if (-not (Test-MeAndAIExactOrdinalSequence `
                -Actual @($node.reasons) -Expected $expectedReasons)) {
                return $false
            }
        }
        $expectedCandidates = @($Graph.nodes | Where-Object {
            [string]$_.role -ceq 'UnlinkedKnownSurfaceCandidate'
        } | ForEach-Object { [string]$_.path })
        if (-not (Test-MeAndAIExactOrdinalSequence `
            -Actual @($Graph.candidates) -Expected $expectedCandidates)) {
            return $false
        }
        $expectedSurfaceSet =
            [System.Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($root in @($Graph.roots)) {
            [void]$expectedSurfaceSet.Add([string]$root.path)
        }
        foreach ($node in @($Graph.nodes | Where-Object {
            [string]$_.role -cne 'ProtectedNonText'
        })) {
            [void]$expectedSurfaceSet.Add([string]$node.path)
        }
        $expectedSurfaces = @($expectedSurfaceSet)
        [Array]::Sort($expectedSurfaces, [StringComparer]::Ordinal)
        if (-not (Test-MeAndAIExactCanonicalSurfaceSequence `
            -Actual @($Graph.protocolSurfaces) -Expected $expectedSurfaces)) {
            return $false
        }
        $parseableNodeCount = @($Graph.nodes | Where-Object {
            [string]$_.role -cin @('InstructionRoot', 'ReferencedText')
        }).Count
        $instructionRootCount = @($Graph.nodes | Where-Object {
            [string]$_.role -ceq 'InstructionRoot'
        }).Count
        if ([long]$Graph.counts.parsedBlobs -lt $instructionRootCount -or
            [long]$Graph.counts.parsedBlobs -gt $parseableNodeCount) {
            return $false
        }
        return [string]$Graph.digest -ceq
            (Get-MeAndAIInstructionGraphDigest -Graph $Graph)
    }
    catch { return $false }
}

function ConvertTo-MeAndAIInstructionGraphRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)

    if (-not (Test-MeAndAIExactInstructionGraph -Graph $Graph)) {
        throw 'Instruction graph is not an exact canonical graph record.'
    }
    return [pscustomobject][ordered]@{
        schema = [int]$Graph.schema
        baseHead = [string]$Graph.baseHead
        limits = [pscustomobject][ordered]@{
            maximumTreeEntries = [int]$Graph.limits.maximumTreeEntries
            maximumTreePathUtf8Bytes =
                [int]$Graph.limits.maximumTreePathUtf8Bytes
            maximumNodes = [int]$Graph.limits.maximumNodes
            maximumEdges = [int]$Graph.limits.maximumEdges
            maximumDepth = [int]$Graph.limits.maximumDepth
            maximumBlobBytes = [int]$Graph.limits.maximumBlobBytes
            maximumAggregateBlobBytes =
                [int]$Graph.limits.maximumAggregateBlobBytes
            maximumPathUtf8Bytes = [int]$Graph.limits.maximumPathUtf8Bytes
        }
        roots = @($Graph.roots | ForEach-Object {
            [pscustomobject][ordered]@{
                path = [string]$_.path
                kind = [string]$_.kind
            }
        })
        nodes = @($Graph.nodes | ForEach-Object {
            [pscustomobject][ordered]@{
                path = [string]$_.path
                mode = [string]$_.mode
                type = [string]$_.type
                blobSha = [string]$_.blobSha
                scope = [string]$_.scope
                role = [string]$_.role
                reasons = @($_.reasons | ForEach-Object { [string]$_ })
            }
        })
        edges = @($Graph.edges | ForEach-Object {
            [pscustomobject][ordered]@{
                source = [string]$_.source
                target = [string]$_.target
                kind = [string]$_.kind
                anchor = [string]$_.anchor
                reason = [string]$_.reason
                external = [bool]$_.external
            }
        })
        candidates = @($Graph.candidates | ForEach-Object { [string]$_ })
        protocolSurfaces = @(
            $Graph.protocolSurfaces | ForEach-Object { [string]$_ }
        )
        counts = [pscustomobject][ordered]@{
            treeEntries = [int]$Graph.counts.treeEntries
            treePathUtf8Bytes = [long]$Graph.counts.treePathUtf8Bytes
            roots = [int]$Graph.counts.roots
            nodes = [int]$Graph.counts.nodes
            edges = [int]$Graph.counts.edges
            candidates = [int]$Graph.counts.candidates
            protocolSurfaces = [int]$Graph.counts.protocolSurfaces
            parsedBlobs = [int]$Graph.counts.parsedBlobs
            parsedBlobBytes = [long]$Graph.counts.parsedBlobBytes
            pathInventoryUtf8Bytes =
                [int]$Graph.counts.pathInventoryUtf8Bytes
        }
        digest = [string]$Graph.digest
    }
}

function Get-MeAndAIInstructionGraphIdentity {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Graph)

    $record = ConvertTo-MeAndAIInstructionGraphRecord -Graph $Graph
    return [pscustomobject][ordered]@{
        schema = [int]$record.schema
        graphBase = [string]$record.baseHead
        graphDigest = [string]$record.digest
        graphCounts = $record.counts
        graphLimits = $record.limits
        protocolSurfaces = @($record.protocolSurfaces)
    }
}

function Test-MeAndAIExactInstructionGraphIdentityRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Identity)

    try {
        if (-not (Test-MeAndAIExactObjectProperties -Object $Identity -Names @(
                'schema', 'graphBase', 'graphDigest', 'graphCounts',
                'graphLimits', 'protocolSurfaces'
            )) -or
            [long]$Identity.schema -ne $script:MeAndAIInstructionGraphSchema -or
            [string]$Identity.graphBase -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$Identity.graphDigest -cnotmatch '^[0-9a-f]{64}$' -or
            -not (Test-MeAndAIExactObjectProperties `
                -Object $Identity.graphCounts -Names @(
                    'treeEntries', 'treePathUtf8Bytes', 'roots', 'nodes',
                    'edges', 'candidates',
                    'protocolSurfaces', 'parsedBlobs', 'parsedBlobBytes',
                    'pathInventoryUtf8Bytes'
                )) -or
            -not (Test-MeAndAIExactObjectProperties `
                -Object $Identity.graphLimits -Names @(
                    'maximumTreeEntries', 'maximumTreePathUtf8Bytes',
                    'maximumNodes', 'maximumEdges',
                    'maximumDepth', 'maximumBlobBytes',
                    'maximumAggregateBlobBytes', 'maximumPathUtf8Bytes'
                )) -or
            $Identity.protocolSurfaces -isnot [array] -or
            -not (Test-MeAndAIExactCanonicalSurfaceSequence `
                -Actual @($Identity.protocolSurfaces) `
                -Expected @($Identity.protocolSurfaces))) {
            return $false
        }
        $limits = Get-MeAndAIInstructionGraphLimits
        foreach ($pair in @(
            @('maximumTreeEntries', 'MaximumTreeEntries'),
            @('maximumTreePathUtf8Bytes', 'MaximumTreePathUtf8Bytes'),
            @('maximumNodes', 'MaximumNodes'),
            @('maximumEdges', 'MaximumEdges'),
            @('maximumDepth', 'MaximumDepth'),
            @('maximumBlobBytes', 'MaximumBlobBytes'),
            @('maximumAggregateBlobBytes', 'MaximumAggregateBlobBytes'),
            @('maximumPathUtf8Bytes', 'MaximumPathUtf8Bytes')
        )) {
            if ([long]$Identity.graphLimits.([string]$pair[0]) -ne
                [long]$limits.([string]$pair[1])) {
                return $false
            }
        }
        foreach ($name in @(
            'treeEntries', 'treePathUtf8Bytes', 'roots', 'nodes', 'edges',
            'candidates',
            'protocolSurfaces', 'parsedBlobs', 'parsedBlobBytes',
            'pathInventoryUtf8Bytes'
        )) {
            if ([long]$Identity.graphCounts.$name -lt 0) { return $false }
        }
        return [long]$Identity.graphCounts.treeEntries -le
                [long]$limits.MaximumTreeEntries -and
            [long]$Identity.graphCounts.treePathUtf8Bytes -le
                [long]$limits.MaximumTreePathUtf8Bytes -and
            [long]$Identity.graphCounts.nodes -le [long]$limits.MaximumNodes -and
            [long]$Identity.graphCounts.edges -le [long]$limits.MaximumEdges -and
            [long]$Identity.graphCounts.protocolSurfaces -eq
                @($Identity.protocolSurfaces).Count -and
            [long]$Identity.graphCounts.parsedBlobBytes -le
                [long]$limits.MaximumAggregateBlobBytes -and
            [long]$Identity.graphCounts.pathInventoryUtf8Bytes -le
                [long]$limits.MaximumPathUtf8Bytes
    }
    catch { return $false }
}

function Test-MeAndAIInstructionGraphIdentityEqual {
    param(
        [Parameter(Mandatory)]$Actual,
        [Parameter(Mandatory)]$Expected
    )

    if (-not (Test-MeAndAIExactInstructionGraphIdentityRecord `
            -Identity $Actual) -or
        -not (Test-MeAndAIExactInstructionGraphIdentityRecord `
            -Identity $Expected) -or
        [long]$Actual.schema -ne [long]$Expected.schema -or
        [string]$Actual.graphBase -cne [string]$Expected.graphBase -or
        [string]$Actual.graphDigest -cne [string]$Expected.graphDigest -or
        -not (Test-MeAndAIExactOrdinalSequence `
            -Actual @($Actual.protocolSurfaces) `
            -Expected @($Expected.protocolSurfaces))) {
        return $false
    }
    foreach ($name in @(
        'treeEntries', 'treePathUtf8Bytes', 'roots', 'nodes', 'edges',
        'candidates',
        'protocolSurfaces', 'parsedBlobs', 'parsedBlobBytes',
        'pathInventoryUtf8Bytes'
    )) {
        if ([long]$Actual.graphCounts.$name -ne
            [long]$Expected.graphCounts.$name) {
            return $false
        }
    }
    foreach ($name in @(
        'maximumTreeEntries', 'maximumTreePathUtf8Bytes', 'maximumNodes',
        'maximumEdges', 'maximumDepth',
        'maximumBlobBytes', 'maximumAggregateBlobBytes',
        'maximumPathUtf8Bytes'
    )) {
        if ([long]$Actual.graphLimits.$name -ne
            [long]$Expected.graphLimits.$name) {
            return $false
        }
    }
    return $true
}

function Test-MeAndAIExactInstructionGraphIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Identity,
        [Parameter(Mandatory)]$Graph
    )

    try {
        $expected = Get-MeAndAIInstructionGraphIdentity -Graph $Graph
        return Test-MeAndAIInstructionGraphIdentityEqual `
            -Actual $Identity -Expected $expected
    }
    catch { return $false }
}

function Test-MeAndAILegacyCommonAuthorityPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    foreach ($candidate in $script:MeAndAILegacyCommonAuthorityFiles) {
        if ($Path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    foreach ($root in $script:MeAndAILegacyCommonAuthorityRoots) {
        if ($Path.Equals($root.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAIConsumerGovernancePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ($Path -ceq 'AGENTS.md' -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::Ordinal)) {
        return $true
    }
    foreach ($root in @(
        '.ai/memory/',
        'docs/features/', 'docs/decisions/', 'docs/findings/',
        'docs/governance/', 'docs/ideas/', 'docs/agent-prompts/'
    )) {
        if ($Path.StartsWith($root, [StringComparison]::Ordinal) -and
            $Path.EndsWith('.md', [StringComparison]::Ordinal)) {
            return $true
        }
    }
    return $Path.StartsWith(
        'tests/meandai-adoption/',
        [StringComparison]::Ordinal
    )
}

function Test-MeAndAILegacyGovernancePath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ($Path.Equals('AGENTS.md', [StringComparison]::OrdinalIgnoreCase) -or
        $Path.EndsWith('/AGENTS.md', [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    foreach ($candidate in @(
        $script:MeAndAILegacyCommonAuthorityFiles +
        $script:MeAndAILegacyAiGovernanceFiles
    )) {
        if ($Path.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    foreach ($root in $script:MeAndAILegacyGovernanceRoots) {
        if ($Path.Equals($root.TrimEnd('/'), [StringComparison]::OrdinalIgnoreCase) -or
            $Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

function Test-MeAndAICleanStartSurfaceSupported {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (Test-MeAndAILegacyGovernancePath -Path $Path) { return $true }
    foreach ($targetPath in $script:MeAndAIAdoptionTargetPaths) {
        if ($Path -ceq [string]$targetPath) {
            return $true
        }
    }
    return $false
}

function Resolve-MeAndAIAdoptionStrategy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RequestedStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ProtocolSurfaces,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Collisions,
        [Parameter(Mandatory)][bool]$AcknowledgeProtocolRecordLoss
    )

    $allowed = @('Auto', 'FreshAdoption', 'FullMigration',
        'HybridReconciliation', 'CleanStart', 'Abort')
    $diagnostics = [System.Collections.Generic.List[string]]::new()
    if ($RequestedStrategy -cnotin $allowed) {
        $diagnostics.Add("Unsupported adoption strategy '$RequestedStrategy'.")
    }
    if (-not (Test-MeAndAIUniqueCanonicalPaths -Paths $ProtocolSurfaces) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths $Collisions)) {
        $diagnostics.Add('Protocol surfaces or collision paths are empty or ambiguous.')
    }
    $surfaceValues = @($ProtocolSurfaces | ForEach-Object { [string]$_ })
    $sortedSurfaces = @($surfaceValues)
    [Array]::Sort($sortedSurfaces, [StringComparer]::Ordinal)
    if (-not (Test-MeAndAIExactOrdinalSequence -Actual $surfaceValues `
        -Expected $sortedSurfaces)) {
        $diagnostics.Add('Protocol surfaces are not in canonical ordinal order.')
    }
    if ($diagnostics.Count -gt 0) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = ''
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @($diagnostics)
        }
    }

    if ($RequestedStrategy -ceq 'Abort') {
        return [pscustomobject]@{
            State = 'Aborted'
            AdoptionStrategy = 'Abort'
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('Initial adoption was aborted by the maintainer.')
        }
    }

    $hasEvidence = $surfaceValues.Count -gt 0
    if ($RequestedStrategy -ceq 'Auto' -and $hasEvidence) {
        return [pscustomobject]@{
            State = 'ProtocolMigrationReviewRequired'
            AdoptionStrategy = ''
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('Existing protocol or governance evidence requires an explicit adoption strategy.')
        }
    }
    $resolved = if ($RequestedStrategy -ceq 'Auto') {
        'FreshAdoption'
    }
    else { $RequestedStrategy }

    if (-not $hasEvidence -and $resolved -cin @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @("$resolved requires detected protocol or governance evidence; use FreshAdoption for an evidence-free repository.")
        }
    }
    if ($resolved -ceq 'FreshAdoption' -and $hasEvidence) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('FreshAdoption contradicts detected protocol or governance evidence.')
        }
    }
    if ($resolved -ceq 'CleanStart') {
        $unsupportedCleanStartSurfaces = @($surfaceValues | Where-Object {
            -not (Test-MeAndAICleanStartSurfaceSupported -Path ([string]$_))
        })
        if ($unsupportedCleanStartSurfaces.Count -gt 0) {
            return [pscustomobject]@{
                State = 'BlockedManualReview'
                AdoptionStrategy = $resolved
                ProtocolSurfaces = @($surfaceValues)
                ProtocolRecordLossAcknowledged = $false
                Diagnostics = @("CleanStart cannot safely classify detected paths as discardable governance records: $($unsupportedCleanStartSurfaces -join ', ').")
            }
        }
    }
    if ($resolved -ceq 'CleanStart' -and -not $AcknowledgeProtocolRecordLoss) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('CleanStart requires explicit acknowledgement of protocol record loss.')
        }
    }
    if ($resolved -cne 'CleanStart' -and $AcknowledgeProtocolRecordLoss) {
        return [pscustomobject]@{
            State = 'BlockedManualReview'
            AdoptionStrategy = $resolved
            ProtocolSurfaces = @($surfaceValues)
            ProtocolRecordLossAcknowledged = $false
            Diagnostics = @('Protocol record loss acknowledgement is valid only with CleanStart.')
        }
    }

    return [pscustomobject]@{
        State = 'Resolved'
        AdoptionStrategy = $resolved
        ProtocolSurfaces = @($surfaceValues)
        ProtocolRecordLossAcknowledged = ($resolved -ceq 'CleanStart')
        Diagnostics = @()
    }
}

function Test-MeAndAIExactAdoptionManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$ExpectedState,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedProtocolSurfaces,
        [Parameter(Mandatory)][bool]$ExpectedProtocolRecordLossAcknowledgement,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedCollisions,
        [AllowNull()]$ExpectedSourceGraph = $null
    )

    if ($null -eq $Manifest -or $Manifest -is [array]) {
        return $false
    }
    $graphAware = $null -ne $ExpectedSourceGraph
    if ($graphAware -and
        -not (Test-MeAndAIExactInstructionGraph -Graph $ExpectedSourceGraph)) {
        return $false
    }
    $manifestProperties = @(
        'schema', 'operation', 'state', 'repository', 'targetTag', 'protocolSha',
        'adoptionStrategy', 'protocolSurfaces',
        'protocolRecordLossAcknowledged', 'collisions', 'proposedPaths',
        'requiredTasks'
    )
    if ($graphAware) { $manifestProperties += 'sourceGraph' }
    $actualProperties = @($Manifest.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualProperties.Count -ne $manifestProperties.Count -or
        @($manifestProperties | Where-Object {
            $actualProperties -cnotcontains $_
        }).Count -ne 0) {
        return $false
    }

    if (($Manifest.schema -isnot [int] -and $Manifest.schema -isnot [long]) -or
        [long]$Manifest.schema -ne $(if ($graphAware) { 3 } else { 2 }) -or
        [string]$Manifest.operation -cne 'ai-capabilities-adoption' -or
        [string]$Manifest.state -cne $ExpectedState -or
        -not ([string]$Manifest.repository).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$Manifest.targetTag -cne $TargetTag -or
        [string]$Manifest.protocolSha -cne $ProtocolSha -or
        [string]$Manifest.adoptionStrategy -cne $ExpectedAdoptionStrategy -or
        [string]$Manifest.adoptionStrategy -cnotin $script:MeAndAIResolvedAdoptionStrategies -or
        $Manifest.protocolRecordLossAcknowledged -isnot [bool] -or
        [bool]$Manifest.protocolRecordLossAcknowledged -ne
            $ExpectedProtocolRecordLossAcknowledgement) {
        return $false
    }

    if ($Manifest.protocolSurfaces -isnot [array] -or
        $Manifest.collisions -isnot [array] -or
        $Manifest.proposedPaths -isnot [array] -or
        $Manifest.requiredTasks -isnot [array] -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.protocolSurfaces)) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.collisions)) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths @($Manifest.proposedPaths)) -or
        -not (Test-MeAndAIExactOrdinalSequence `
            -Actual @($Manifest.protocolSurfaces) `
            -Expected @($ExpectedProtocolSurfaces)) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual @($Manifest.collisions) `
            -Expected @($ExpectedCollisions)) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual @($Manifest.proposedPaths) `
            -Expected $script:MeAndAIAdoptionProposedPaths) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual @($Manifest.requiredTasks) `
            -Expected $script:MeAndAIRequiredAdoptionTasks)) {
        return $false
    }

    if ($graphAware -and
        (-not (Test-MeAndAIExactInstructionGraph -Graph $Manifest.sourceGraph) -or
         -not (Test-MeAndAIExactInstructionGraphIdentity `
            -Identity (Get-MeAndAIInstructionGraphIdentity `
                -Graph $Manifest.sourceGraph) `
            -Graph $ExpectedSourceGraph) -or
         -not (Test-MeAndAIExactOrdinalSequence `
            -Actual @($Manifest.protocolSurfaces) `
            -Expected @($Manifest.sourceGraph.protocolSurfaces)))) {
        return $false
    }

    return $true
}

function Test-MeAndAIExactAdoptionPullRequestMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$RemoteHead,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$TargetSha,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [Parameter(Mandatory)][string]$ExpectedState,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()]
        [object[]]$ExpectedProtocolSurfaces,
        [Parameter(Mandatory)][bool]$ExpectedProtocolRecordLossAcknowledgement,
        [AllowNull()]$ExpectedSourceGraph = $null,
        [AllowNull()]$ExpectedSourceGraphIdentity = $null,
        [ValidateSet('Proposed', 'Completed')]
        [string]$ExpectedPhase = 'Proposed'
    )

    foreach ($property in @(
        'number', 'url', 'headRefName', 'headRefOid', 'baseRefName',
        'headRepository', 'author', 'body', 'isDraft', 'state'
    )) {
        if ($null -eq $PullRequest.PSObject.Properties[$property]) {
            return $false
        }
    }
    $expectedDraft = $ExpectedPhase -ceq 'Proposed'
    if ([string]$PullRequest.state -cne 'OPEN' -or
        [string]$PullRequest.headRefName -cne $Branch -or
        [string]$PullRequest.headRefOid -cne $RemoteHead -or
        [string]$PullRequest.baseRefName -cne $BaseBranch -or
        $PullRequest.isDraft -isnot [bool] -or
        [bool]$PullRequest.isDraft -ne $expectedDraft -or
        [string]$PullRequest.number -cnotmatch '^[1-9][0-9]*$' -or
        [string]$PullRequest.url -cnotmatch
            "/pull/$([regex]::Escape([string]$PullRequest.number))/?$") {
        return $false
    }
    if ($null -eq $PullRequest.headRepository -or
        $null -eq $PullRequest.headRepository.PSObject.Properties['nameWithOwner'] -or
        -not ([string]$PullRequest.headRepository.nameWithOwner).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -or
        $null -eq $PullRequest.author -or
        $null -eq $PullRequest.author.PSObject.Properties['login'] -or
        -not ([string]$PullRequest.author.login).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        )) {
        return $false
    }

    $body = [string]$PullRequest.body
    $markerStarts = [regex]::Matches(
        $body, '<!--\s*meandai-capabilities-adoption:',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $markerMatches = [regex]::Matches(
        $body, '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($markerStarts.Count -ne 1 -or $markerMatches.Count -ne 1) {
        return $false
    }
    try {
        $marker = $markerMatches[0].Groups['json'].Value | ConvertFrom-Json
    }
    catch {
        return $false
    }
    $schemaProperty = $marker.PSObject.Properties['schema']
    if ($null -eq $schemaProperty -or
        ($schemaProperty.Value -isnot [int] -and
         $schemaProperty.Value -isnot [long])) {
        return $false
    }
    $schema = [long]$schemaProperty.Value
    $graphAware = $null -ne $ExpectedSourceGraph -or
        $null -ne $ExpectedSourceGraphIdentity
    if ($null -ne $ExpectedSourceGraph -and
        -not (Test-MeAndAIExactInstructionGraph -Graph $ExpectedSourceGraph)) {
        return $false
    }
    $expectedGraphIdentity = if ($null -ne $ExpectedSourceGraph) {
        Get-MeAndAIInstructionGraphIdentity -Graph $ExpectedSourceGraph
    }
    else { $ExpectedSourceGraphIdentity }
    if ($graphAware -and
        -not (Test-MeAndAIExactInstructionGraphIdentityRecord `
            -Identity $expectedGraphIdentity)) {
        return $false
    }
    $expectedProperties = if ($schema -eq 2 -and -not $graphAware) {
        @('schema', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 3 -and -not $graphAware) {
        @('schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'repository', 'actor')
    }
    elseif ($schema -eq 5 -and -not $graphAware) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'adoptionStrategy', 'protocolSurfaces',
            'protocolRecordLossAcknowledged', 'repository', 'actor'
        )
    }
    elseif ($schema -eq 7 -and $graphAware) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'branch', 'adoptionStrategy', 'protocolSurfaces',
            'protocolRecordLossAcknowledged', 'graphBase', 'graphDigest',
            'graphCounts', 'graphLimits', 'repository', 'actor'
        )
    }
    elseif ($schema -eq 9 -and $graphAware) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'branch', 'adoptionStrategy',
            'protocolRecordLossAcknowledged', 'graphBase', 'graphDigest',
            'graphCounts', 'graphLimits', 'repository', 'actor'
        )
    }
    elseif ($schema -eq 11 -and -not $graphAware) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'branch', 'adoptionStrategy', 'surfaceBase', 'surfaceDigest',
            'protocolRecordLossAcknowledged', 'repository', 'actor'
        )
    }
    else {
        return $false
    }
    $actualProperties = @($marker.PSObject.Properties | ForEach-Object {
        $_.Name
    })
    if ($actualProperties.Count -ne $expectedProperties.Count -or
        @($expectedProperties | Where-Object {
            $actualProperties -cnotcontains $_
        }).Count -ne 0) {
        return $false
    }
    $phase = if ($schema -eq 2) { 'Proposed' } else { [string]$marker.phase }
    $graphIdentityValid = $true
    if ($schema -in @(7, 9)) {
        $identitySurfaces = if ($schema -eq 7) {
            @($marker.protocolSurfaces)
        }
        else { @($ExpectedProtocolSurfaces) }
        $markerGraphIdentity = [pscustomobject][ordered]@{
                    schema = [int]$expectedGraphIdentity.schema
                    graphBase = [string]$marker.graphBase
                    graphDigest = [string]$marker.graphDigest
                    graphCounts = $marker.graphCounts
                    graphLimits = $marker.graphLimits
                    protocolSurfaces = @($identitySurfaces)
                }
        $graphIdentityValid = [string]$marker.branch -ceq $Branch -and
            (Test-MeAndAIInstructionGraphIdentityEqual `
                -Actual $markerGraphIdentity -Expected $expectedGraphIdentity)
        if ($schema -eq 9) {
            $graphIdentityValid = $graphIdentityValid -and
                (Test-MeAndAIExactLinkedPathSection -Body $body `
                    -Heading '### Detected protocol and governance surfaces' `
                    -Repository $Repository -Commit ([string]$marker.graphBase) `
                    -Paths @($identitySurfaces))
        }
    }
    $linkedSurfaceIdentityValid = $true
    if ($schema -eq 11) {
        $linkedSurfaceIdentityValid =
            (Test-MeAndAIExactCanonicalSurfaceSequence `
                -Actual @($ExpectedProtocolSurfaces) `
                -Expected @($ExpectedProtocolSurfaces)) -and
            [string]$marker.branch -ceq $Branch -and
            [string]$marker.surfaceBase -cmatch '^[0-9a-f]{40}$' -and
            [string]$marker.surfaceDigest -ceq
                (Get-MeAndAILinkedPathIdentityDigest `
                    -Paths @($ExpectedProtocolSurfaces)) -and
            (Test-MeAndAIExactLinkedPathSection -Body $body `
                -Heading '### Detected protocol and governance surfaces' `
                -Repository $Repository -Commit ([string]$marker.surfaceBase) `
                -Paths @($ExpectedProtocolSurfaces))
    }
    if (-not (
        $phase -ceq $ExpectedPhase -and
        ($ExpectedPhase -ceq 'Proposed' -or
         $schema -in @(3, 5, 7, 9, 11)) -and
        [string]$marker.state -ceq $ExpectedState -and
        [string]$marker.target -ceq $TargetTag -and
        [string]$marker.protocolSha -ceq $TargetSha -and
        [string]$marker.head -ceq $RemoteHead -and
        ([string]$marker.repository).Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        ) -and
        ([string]$marker.actor).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        ) -and
        (($schema -in @(2, 3) -and
          $ExpectedAdoptionStrategy -cin @('LegacyUnspecified', 'FreshAdoption') -and
          @($ExpectedProtocolSurfaces).Count -eq 0 -and
          -not $ExpectedProtocolRecordLossAcknowledgement) -or
         ($schema -eq 5 -and
          [string]$marker.adoptionStrategy -ceq $ExpectedAdoptionStrategy -and
          $marker.protocolSurfaces -is [array] -and
          (Test-MeAndAIExactCanonicalSurfaceSequence `
              -Actual @($marker.protocolSurfaces) `
              -Expected @($ExpectedProtocolSurfaces)) -and
          $marker.protocolRecordLossAcknowledged -is [bool] -and
          [bool]$marker.protocolRecordLossAcknowledged -eq
              $ExpectedProtocolRecordLossAcknowledgement) -or
         ($schema -eq 7 -and $graphIdentityValid -and
          [string]$marker.adoptionStrategy -ceq $ExpectedAdoptionStrategy -and
          (Test-MeAndAIExactCanonicalSurfaceSequence `
              -Actual @($marker.protocolSurfaces) `
              -Expected @($ExpectedProtocolSurfaces)) -and
          $marker.protocolRecordLossAcknowledged -is [bool] -and
          [bool]$marker.protocolRecordLossAcknowledged -eq
              $ExpectedProtocolRecordLossAcknowledgement) -or
         ($schema -eq 9 -and $graphIdentityValid -and
          [string]$marker.adoptionStrategy -ceq $ExpectedAdoptionStrategy -and
          $marker.protocolRecordLossAcknowledged -is [bool] -and
          [bool]$marker.protocolRecordLossAcknowledged -eq
              $ExpectedProtocolRecordLossAcknowledgement) -or
         ($schema -eq 11 -and $linkedSurfaceIdentityValid -and
          [string]$marker.adoptionStrategy -ceq $ExpectedAdoptionStrategy -and
          $marker.protocolRecordLossAcknowledged -is [bool] -and
          [bool]$marker.protocolRecordLossAcknowledged -eq
              $ExpectedProtocolRecordLossAcknowledgement))
    )) {
        return $false
    }
    return $true
}

function Test-MeAndAIReservedProtocolSubmoduleContract {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Rows,
        [Parameter(Mandatory)]$ProtocolEntry,
        [Parameter(Mandatory)][string]$ProtocolRepository
    )

    $normalizedRows = [System.Collections.Generic.List[string]]::new()
    foreach ($value in @($Rows)) {
        if ($value -isnot [string]) { return $false }
        $row = [string]$value
        $separator = $row.IndexOf("`n", [StringComparison]::Ordinal)
        if ($separator -le 0) {
            return $false
        }
        $normalizedRows.Add($row)
    }
    $sortedRows = [string[]]@($normalizedRows)
    [Array]::Sort($sortedRows, [StringComparer]::Ordinal)
    $protocolPrefix = 'submodule..ai/protocol.'
    $reservedRows = @($sortedRows | Where-Object {
        $row = [string]$_
        $separator = $row.IndexOf("`n", [StringComparison]::Ordinal)
        $key = $row.Substring(0, $separator)
        $value = $row.Substring($separator + 1)
        if ($key.StartsWith(
            $protocolPrefix, [StringComparison]::OrdinalIgnoreCase
        )) {
            return $true
        }
        if (-not [regex]::IsMatch(
            $key, '^submodule\..+\.path$',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        )) {
            return $false
        }
        $candidate = $value.Replace('\', '/').Trim('/')
        while ($candidate.StartsWith('./', [StringComparison]::Ordinal)) {
            $candidate = $candidate.Substring(2).TrimEnd('/')
        }
        return $candidate -and (
            $candidate.Equals(
                '.ai/protocol', [StringComparison]::OrdinalIgnoreCase
            ) -or
            $candidate.StartsWith(
                '.ai/protocol/', [StringComparison]::OrdinalIgnoreCase
            ) -or
            '.ai/protocol'.StartsWith(
                "$candidate/", [StringComparison]::OrdinalIgnoreCase
            )
        )
    })
    if ($reservedRows.Count -eq 0) { return $true }
    $expectedRows = [string[]]@(
        "submodule..ai/protocol.path`n.ai/protocol",
        "submodule..ai/protocol.url`nhttps://github.com/$ProtocolRepository.git"
    )
    [Array]::Sort($expectedRows, [StringComparer]::Ordinal)
    if (($reservedRows -join "`0") -cne ($expectedRows -join "`0")) {
        return $false
    }
    foreach ($property in @('Mode', 'Type', 'Path')) {
        if ($null -eq $ProtocolEntry.PSObject.Properties[$property]) {
            return $false
        }
    }
    return [string]$ProtocolEntry.Mode -ceq '160000' -and
        [string]$ProtocolEntry.Type -ceq 'commit' -and
        [string]$ProtocolEntry.Path -ceq '.ai/protocol'
}

function Test-MeAndAICompletedAdoptionChangeSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$Changes,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$ProtocolSurfaces,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$TargetPaths,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()]
        [object[]]$FinalEntries,
        [AllowNull()]$SourceGraph = $null
    )

    if ($null -eq $Changes) { $Changes = [object[]]::new(0) }
    if ($null -eq $ProtocolSurfaces) {
        $ProtocolSurfaces = [object[]]::new(0)
    }
    if ($null -eq $TargetPaths) { $TargetPaths = [object[]]::new(0) }
    if ($null -eq $FinalEntries) { $FinalEntries = [object[]]::new(0) }

    if ($ExpectedAdoptionStrategy -cnotin @(
        'LegacyUnspecified', 'FreshAdoption', 'FullMigration',
        'HybridReconciliation', 'CleanStart'
    ) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual $TargetPaths `
            -Expected $script:MeAndAIAdoptionTargetPaths) -or
        -not (Test-MeAndAIUniqueCanonicalPaths -Paths $ProtocolSurfaces) -or
        ($ExpectedAdoptionStrategy -ceq 'LegacyUnspecified' -and
         @($ProtocolSurfaces).Count -ne 0)) {
        return $false
    }
    $surfaceValues = @($ProtocolSurfaces | ForEach-Object { [string]$_ })
    $sortedSurfaces = @($surfaceValues)
    [Array]::Sort($sortedSurfaces, [StringComparer]::Ordinal)
    if (-not (Test-MeAndAIExactOrdinalSequence -Actual $surfaceValues `
        -Expected $sortedSurfaces)) {
        return $false
    }

    $sourceNodeMap = $null
    if ($null -ne $SourceGraph) {
        if (-not (Test-MeAndAIExactInstructionGraph -Graph $SourceGraph) -or
            (@($SourceGraph.protocolSurfaces) -join "`0") -cne
                (@($surfaceValues) -join "`0")) {
            return $false
        }
        $sourceNodeMap =
            [System.Collections.Generic.Dictionary[string, object]]::new(
                [StringComparer]::Ordinal
            )
        foreach ($node in @($SourceGraph.nodes)) {
            $sourceNodeMap.Add([string]$node.path, $node)
        }
    }

    $entryMap = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($entry in @($FinalEntries)) {
        if ($null -eq $entry -or
            $null -eq $entry.PSObject.Properties['Path'] -or
            $null -eq $entry.PSObject.Properties['Exists'] -or
            $null -eq $entry.PSObject.Properties['Mode'] -or
            $entry.Exists -isnot [bool]) {
            return $false
        }
        $path = [string]$entry.Path
        if (-not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            $entryMap.ContainsKey($path)) {
            return $false
        }
        $entryMap.Add($path, $entry)
    }

    $normalizedChanges = [System.Collections.Generic.List[object]]::new()
    $changedSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($change in @($Changes)) {
        if ($null -eq $change -or
            $null -eq $change.PSObject.Properties['Status'] -or
            $null -eq $change.PSObject.Properties['Path']) {
            return $false
        }
        $status = [string]$change.Status
        $path = [string]$change.Path
        if ($status -cnotin @('A', 'D', 'M', 'T') -or
            -not (Test-MeAndAICanonicalRepositoryPath -Path $path) -or
            -not $changedSet.Add($path)) {
            return $false
        }
        $normalizedChanges.Add([pscustomobject]@{
            Status = $status
            Path = $path
        })
    }
    if ($normalizedChanges.Count -eq 0) { return $false }
    if ($ExpectedAdoptionStrategy -ceq 'HybridReconciliation') {
        $decisionChanges = @($normalizedChanges | Where-Object {
            $path = [string]$_.Path
            [string]$_.Status -cin @('A', 'M') -and
            $path.StartsWith(
                'docs/decisions/', [StringComparison]::Ordinal
            ) -and
            $path.EndsWith(
                '.md', [StringComparison]::Ordinal
            )
        })
        if ($decisionChanges.Count -eq 0) { return $false }
    }

    $requiredSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $TargetPaths) { [void]$requiredSet.Add([string]$path) }
    $surfaceSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $surfaceValues) { [void]$surfaceSet.Add($path) }
    $sourceEnforcedRequired = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $script:MeAndAISourceEnforcedRequiredPaths) {
        [void]$sourceEnforcedRequired.Add([string]$path)
    }
    $migrationStrategy = $ExpectedAdoptionStrategy -cin @(
        'FullMigration', 'HybridReconciliation', 'CleanStart'
    )
    $manifestDeletions = @($normalizedChanges | Where-Object {
        [string]$_.Status -ceq 'D' -and
        [string]$_.Path -ceq $script:MeAndAIAdoptionManifestPath
    })
    if ($manifestDeletions.Count -ne 1) { return $false }

    foreach ($change in $normalizedChanges) {
        $status = [string]$change.Status
        $path = [string]$change.Path
        $basename = Get-MeAndAIGitPathLeafName -Path $path
        if ($basename.Equals('FG_PAT.txt', [StringComparison]::OrdinalIgnoreCase) -or
            $basename.Equals(
                'MEANDAI_RO_FG_PAT.txt', [StringComparison]::OrdinalIgnoreCase
            ) -or
            $path.Equals(
                $script:MeAndAISeedWorkflowPath,
                [StringComparison]::OrdinalIgnoreCase
            )) {
            return $false
        }
        if ($path -ceq $script:MeAndAIAdoptionManifestPath) {
            if ($status -cne 'D') { return $false }
            continue
        }
        if ($requiredSet.Contains($path)) {
            if ($status -ceq 'D') { return $false }
            continue
        }
        if ($status -ceq 'A') {
            if (-not (Test-MeAndAIConsumerGovernancePath -Path $path)) {
                return $false
            }
            continue
        }
        if ($null -ne $sourceNodeMap) {
            if (-not $sourceNodeMap.ContainsKey($path)) { return $false }
            $sourceNode = $sourceNodeMap[$path]
            $sourceRole = [string]$sourceNode.role
            $parsedInstructionText = $sourceRole -cin @(
                'InstructionRoot', 'ReferencedText'
            )
            $boundedCompatibilityText =
                $sourceRole -ceq 'UnlinkedKnownSurfaceCandidate' -and
                (Test-MeAndAIInstructionGraphTextPath -Path $path)
            $cleanStartGitlinkDeletion =
                $ExpectedAdoptionStrategy -ceq 'CleanStart' -and
                $status -ceq 'D' -and $surfaceSet.Contains($path) -and
                (Test-MeAndAICleanStartSurfaceSupported -Path $path) -and
                $sourceRole -cin @(
                    'ProtectedNonText', 'UnlinkedKnownSurfaceCandidate'
                ) -and
                [string]$sourceNode.mode -ceq '160000' -and
                [string]$sourceNode.type -ceq 'commit'
            if (-not $cleanStartGitlinkDeletion -and
                ([string]$sourceNode.mode -cnotin @('100644', '100755') -or
                 [string]$sourceNode.type -cne 'blob' -or
                 (-not $parsedInstructionText -and
                  -not $boundedCompatibilityText))) {
                return $false
            }
        }
        if ($path.StartsWith('.ai/protocol/', [StringComparison]::Ordinal)) {
            if (-not $migrationStrategy -or $status -cne 'D' -or
                -not $surfaceSet.Contains($path)) {
                return $false
            }
            continue
        }
        if ($status -cin @('M', 'D')) {
            if (-not $migrationStrategy -or -not $surfaceSet.Contains($path) -or
                -not (Test-MeAndAILegacyGovernancePath -Path $path)) {
                return $false
            }
            continue
        }
        return $false
    }

    foreach ($path in $TargetPaths) {
        $value = [string]$path
        if (-not $entryMap.ContainsKey($value)) { return $false }
        $entry = $entryMap[$value]
        $expectedMode = if ($value -ceq '.ai/protocol') {
            '160000'
        }
        else { '100644' }
        if (-not [bool]$entry.Exists -or
            [string]$entry.Mode -cne $expectedMode) {
            return $false
        }
    }
    foreach ($change in @($normalizedChanges | Where-Object {
        [string]$_.Status -cne 'D'
    })) {
        $path = [string]$change.Path
        if ($requiredSet.Contains($path)) { continue }
        if (-not $entryMap.ContainsKey($path)) { return $false }
        $entry = $entryMap[$path]
        $allowedModes = if ($path.StartsWith(
            'tests/meandai-adoption/', [StringComparison]::Ordinal
        )) { @('100644', '100755') } else { @('100644') }
        if (-not [bool]$entry.Exists -or
            [string]$entry.Mode -cnotin $allowedModes) {
            return $false
        }
    }

    foreach ($surface in $surfaceSet) {
        if ($requiredSet.Contains($surface)) {
            $mustChange =
                (Test-MeAndAILegacyCommonAuthorityPath -Path $surface) -or
                ($ExpectedAdoptionStrategy -ceq 'CleanStart' -and
                 -not $sourceEnforcedRequired.Contains($surface))
            if ($mustChange -and -not $changedSet.Contains($surface)) {
                return $false
            }
            continue
        }
        $exists = $entryMap.ContainsKey($surface) -and
            [bool]$entryMap[$surface].Exists
        if ($ExpectedAdoptionStrategy -ceq 'CleanStart' -and $exists -and
            (Test-MeAndAILegacyGovernancePath -Path $surface)) {
            return $false
        }
        if (Test-MeAndAILegacyCommonAuthorityPath -Path $surface) {
            if ($ExpectedAdoptionStrategy -ceq 'FullMigration' -and $exists) {
                return $false
            }
            if ($ExpectedAdoptionStrategy -ceq 'HybridReconciliation' -and
                $exists -and -not $changedSet.Contains($surface)) {
                return $false
            }
        }
    }
    return $true
}

function Resolve-MeAndAIInstructionGraphClosure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$SourceGraph,
        [Parameter(Mandatory)]$FinalGraph,
        [Parameter(Mandatory)][string]$ExpectedAdoptionStrategy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Changes,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TargetPaths
    )

    if (-not (Test-MeAndAIExactInstructionGraph -Graph $SourceGraph) -or
        -not (Test-MeAndAIExactInstructionGraph -Graph $FinalGraph) -or
        $ExpectedAdoptionStrategy -cnotin @(
            'FreshAdoption', 'FullMigration', 'HybridReconciliation',
            'CleanStart'
        ) -or
        -not (Test-MeAndAIExactOrdinalSequence -Actual $TargetPaths `
            -Expected $script:MeAndAIAdoptionTargetPaths)) {
        throw 'Instruction-graph closure received an invalid exact contract.'
    }

    $changeMap = [System.Collections.Generic.Dictionary[string, string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($change in @($Changes)) {
        if ($null -eq $change -or
            $null -eq $change.PSObject.Properties['Status'] -or
            $null -eq $change.PSObject.Properties['Path'] -or
            [string]$change.Status -cnotin @('A', 'D', 'M', 'T') -or
            -not (Test-MeAndAICanonicalRepositoryPath `
                -Path ([string]$change.Path)) -or
            $changeMap.ContainsKey([string]$change.Path)) {
            throw 'Instruction-graph closure received an invalid change set.'
        }
        $changeMap.Add([string]$change.Path, [string]$change.Status)
    }
    $hybridDecisionChanged = $ExpectedAdoptionStrategy -ceq
        'HybridReconciliation' -and @($Changes | Where-Object {
            [string]$_.Status -cin @('A', 'M') -and
            [string]$_.Path -clike 'docs/decisions/*.md'
        }).Count -gt 0

    $targetSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in @($TargetPaths)) { [void]$targetSet.Add([string]$path) }
    $unresolved = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $diagnostics = [System.Collections.Generic.List[string]]::new()

    $canonicalProtocolNode = @($FinalGraph.nodes | Where-Object {
        [string]$_.path -ceq '.ai/protocol' -and
        [string]$_.mode -ceq '160000' -and
        [string]$_.type -ceq 'commit' -and
        [string]$_.role -ceq 'ProtectedNonText'
    })
    $canonicalRootEdges = @($FinalGraph.edges | Where-Object {
        -not [bool]$_.external -and [string]$_.source -ceq 'AGENTS.md' -and
        [string]$_.target -ceq '.ai/protocol/PROTOCOL.md' -and
        [string]$_.kind -cin @('RequiresRead', 'DeclaresAuthority')
    })
    if ($canonicalProtocolNode.Count -ne 1 -or
        $canonicalRootEdges.Count -eq 0) {
        [void]$unresolved.Add('AGENTS.md')
        $diagnostics.Add(
            'The final root instruction adapter does not reach the canonical protocol gitlink.'
        )
    }

    $sourceNodeMap = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($node in @($SourceGraph.nodes)) {
        $sourceNodeMap.Add([string]$node.path, $node)
    }
    $sourceAuthorityPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $sourceGenericRootPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($root in @($SourceGraph.roots | Where-Object {
        [string]$_.kind -ceq 'GenericInstructionRoot'
    })) {
        [void]$sourceGenericRootPaths.Add([string]$root.path)
    }
    foreach ($edge in @($SourceGraph.edges)) {
        if ([bool]$edge.external -or
            [string]$edge.kind -cnotin @(
                'RequiresRead', 'DeclaresAuthority', 'Indexes'
            ) -or
            -not $sourceNodeMap.ContainsKey([string]$edge.target)) {
            continue
        }
        $node = $sourceNodeMap[[string]$edge.target]
        if ([string]$node.role -cne 'ProtectedNonText' -and
            -not $targetSet.Contains([string]$node.path) -and
            -not (Test-MeAndAIReservedProtocolNamespacePath `
                -Path ([string]$node.path))) {
            [void]$sourceAuthorityPaths.Add([string]$node.path)
        }
    }
    foreach ($root in @($SourceGraph.roots)) {
        $path = [string]$root.path
        if (-not $targetSet.Contains($path) -and
            (Test-MeAndAILegacyCommonAuthorityPath -Path $path)) {
            [void]$sourceAuthorityPaths.Add($path)
        }
    }

    $finalAuthorityPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($edge in @($FinalGraph.edges)) {
        if (-not [bool]$edge.external -and
            [string]$edge.kind -cin @(
                'RequiresRead', 'DeclaresAuthority', 'Indexes'
            )) {
            [void]$finalAuthorityPaths.Add([string]$edge.target)
        }
    }
    foreach ($path in @($sourceAuthorityPaths)) {
        $status = if ($changeMap.ContainsKey($path)) {
            [string]$changeMap[$path]
        }
        else { '' }
        $hybridRetainedRoot = $hybridDecisionChanged -and
            $sourceGenericRootPaths.Contains($path) -and $status -ceq 'M'
        if ($hybridRetainedRoot) { continue }
        if (-not $status -or
            ($status -cne 'D' -and $finalAuthorityPaths.Contains($path))) {
            [void]$unresolved.Add($path)
        }
    }

    foreach ($edge in @($FinalGraph.edges | Where-Object {
        -not [bool]$_.external -and
        [string]$_.kind -cin @(
            'RequiresRead', 'DeclaresAuthority', 'Indexes'
        )
    })) {
        $path = [string]$edge.target
        if (-not (Test-MeAndAIReservedProtocolNamespacePath -Path $path) -and
            -not $targetSet.Contains($path) -and
            -not $sourceAuthorityPaths.Contains($path)) {
            [void]$unresolved.Add($path)
        }
    }
    foreach ($root in @($FinalGraph.roots)) {
        $path = [string]$root.path
        if ([string]$root.kind -eq 'GenericInstructionRoot' -and
            -not $targetSet.Contains($path) -and
            -not ($hybridDecisionChanged -and
                $sourceGenericRootPaths.Contains($path) -and
                 $changeMap.ContainsKey($path) -and
                 [string]$changeMap[$path] -ceq 'M')) {
            [void]$unresolved.Add($path)
        }
    }

    $unresolvedPaths = @($unresolved)
    [Array]::Sort($unresolvedPaths, [StringComparer]::Ordinal)
    if ($unresolvedPaths.Count -gt 0) {
        $diagnostics.Add(
            "Unresolved instruction authority: $($unresolvedPaths -join ', ')."
        )
    }
    return [pscustomobject][ordered]@{
        State = if ($unresolvedPaths.Count -eq 0) { 'Ready' } else { 'Blocked' }
        UnresolvedPaths = @($unresolvedPaths)
        Diagnostics = @($diagnostics)
    }
}

function New-MeAndAICapabilitiesPlan {
    param(
        [string]$State,
        [string]$ProposalMode,
        [object[]]$Collisions,
        [object[]]$Diagnostics,
        [string]$AdoptionStrategy = '',
        [object[]]$ProtocolSurfaces = @(),
        [bool]$ProtocolRecordLossAcknowledged = $false,
        [AllowNull()]$SourceGraph = $null
    )

    $graphRecord = $null
    if ($null -ne $SourceGraph) {
        $graphRecord = ConvertTo-MeAndAIInstructionGraphRecord `
            -Graph $SourceGraph
        if (-not (Test-MeAndAIExactOrdinalSequence `
            -Actual @($ProtocolSurfaces) `
            -Expected @($graphRecord.protocolSurfaces))) {
            throw 'Lifecycle plan surfaces do not match the source graph.'
        }
    }
    $plan = [pscustomobject][ordered]@{
        SchemaVersion = if ($null -eq $graphRecord) { 2 } else { 3 }
        State = $State
        ProposalMode = $ProposalMode
        AdoptionStrategy = $AdoptionStrategy
        ProtocolSurfaces = @($ProtocolSurfaces | ForEach-Object { [string]$_ })
        ProtocolRecordLossAcknowledged = $ProtocolRecordLossAcknowledged
        Collisions = @($Collisions | ForEach-Object { [string]$_ })
        Diagnostics = @($Diagnostics | ForEach-Object { [string]$_ })
    }
    if ($null -ne $graphRecord) {
        $plan | Add-Member -NotePropertyName SourceGraph `
            -NotePropertyValue $graphRecord
    }
    return $plan
}

function Resolve-MeAndAICapabilitiesLifecycle {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Snapshot)

    $required = @(
        'SchemaVersion', 'LocalUpdaterState', 'SeedWorkflowState', 'Collisions',
        'ManifestExists', 'RemoteBranchExists', 'OpenPullRequestCount',
        'ExistingProposalValid', 'AdoptionStrategy', 'ProtocolSurfaces',
        'AcknowledgeProtocolRecordLoss'
    )
    $missing = @($required | Where-Object {
        $_ -notin $Snapshot.PSObject.Properties.Name
    })
    if ($missing.Count -gt 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @("Lifecycle snapshot is missing: $($missing -join ', ').")
    }

    if ($Snapshot.SchemaVersion -isnot [int] -and
        $Snapshot.SchemaVersion -isnot [long]) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('Lifecycle schema version must be an integer.')
    }
    $schemaVersion = [long]$Snapshot.SchemaVersion
    if ($schemaVersion -notin @(2, 3)) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @("Unsupported lifecycle schema '$($Snapshot.SchemaVersion)'.")
    }
    $sourceGraph = $null
    if ($schemaVersion -eq 3) {
        if ($null -eq $Snapshot.PSObject.Properties['SourceGraph'] -or
            -not (Test-MeAndAIExactInstructionGraph `
                -Graph $Snapshot.SourceGraph) -or
            -not (Test-MeAndAIExactOrdinalSequence `
                -Actual @($Snapshot.ProtocolSurfaces) `
                -Expected @($Snapshot.SourceGraph.protocolSurfaces))) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @() `
                -Diagnostics @('Lifecycle source graph is missing, invalid, or inconsistent with its derived surfaces.')
        }
        $sourceGraph = $Snapshot.SourceGraph
    }

    $localUpdaterState = [string]$Snapshot.LocalUpdaterState
    $seedWorkflowState = [string]$Snapshot.SeedWorkflowState
    $allowedUpdaterStates = @('Absent', 'Partial', 'Complete')
    $allowedSeedStates = @('Exact', 'Missing', 'Drifted')
    if ($localUpdaterState -cnotin $allowedUpdaterStates -or
        $seedWorkflowState -cnotin $allowedSeedStates) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('Lifecycle snapshot contains an unknown state.')
    }

    if ($Snapshot.ManifestExists -isnot [bool] -or
        $Snapshot.RemoteBranchExists -isnot [bool] -or
        $Snapshot.ExistingProposalValid -isnot [bool] -or
        ($Snapshot.OpenPullRequestCount -isnot [int] -and
         $Snapshot.OpenPullRequestCount -isnot [long]) -or
        [long]$Snapshot.OpenPullRequestCount -lt 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('Lifecycle snapshot contains invalid ownership values.')
    }

    $collisions = [System.Collections.Generic.List[string]]::new()
    $seenCollisions = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($value in @($Snapshot.Collisions)) {
        $path = [string]$value
        if ([string]::IsNullOrWhiteSpace($path) -or
            -not $seenCollisions.Add($path)) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @($collisions) `
                -Diagnostics @('Lifecycle collision paths are empty or ambiguous.')
        }
        $collisions.Add($path)
    }

    if ($Snapshot.ProtocolSurfaces -isnot [array] -or
        $Snapshot.AcknowledgeProtocolRecordLoss -isnot [bool]) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('Adoption strategy evidence has invalid types.')
    }
    $strategy = Resolve-MeAndAIAdoptionStrategy `
        -RequestedStrategy ([string]$Snapshot.AdoptionStrategy) `
        -ProtocolSurfaces @($Snapshot.ProtocolSurfaces) `
        -Collisions @($collisions) `
        -AcknowledgeProtocolRecordLoss ([bool]$Snapshot.AcknowledgeProtocolRecordLoss)

    if ($seedWorkflowState -cne 'Exact') {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('The committed seed workflow does not match the pinned release.')
    }
    if ([bool]$Snapshot.ManifestExists) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('The transient adoption manifest already exists.')
    }

    $branchExists = [bool]$Snapshot.RemoteBranchExists
    $pullRequestCount = [long]$Snapshot.OpenPullRequestCount
    if ($branchExists -and $pullRequestCount -eq 1) {
        if (-not [bool]$Snapshot.ExistingProposalValid) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @($collisions) `
                -Diagnostics @('The existing adoption proposal failed ownership validation.')
        }
        return New-MeAndAICapabilitiesPlan -State 'PendingAdoption' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('A deterministic adoption proposal already exists.') `
            -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
            -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
            -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged) `
            -SourceGraph $sourceGraph
    }
    if ([bool]$Snapshot.ExistingProposalValid) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('Ownership evidence exists without one deterministic proposal.')
    }
    if ($branchExists -or $pullRequestCount -ne 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @('Adoption branch and pull-request ownership are inconsistent.')
    }

    if ($localUpdaterState -ceq 'Complete') {
        if ($collisions.Count -ne 0) {
            return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
                -ProposalMode 'None' -Collisions @($collisions) `
                -Diagnostics @('A complete updater snapshot cannot contain adoption collisions.')
        }
        return New-MeAndAICapabilitiesPlan -State 'Update' `
            -ProposalMode 'None' -Collisions @() -Diagnostics @() `
            -AdoptionStrategy 'ExistingAdoption' `
            -ProtocolSurfaces @($Snapshot.ProtocolSurfaces) `
            -SourceGraph $sourceGraph
    }

    if ([string]$strategy.State -cne 'Resolved') {
        return New-MeAndAICapabilitiesPlan -State ([string]$strategy.State) `
            -ProposalMode 'None' -Collisions @($collisions) `
            -Diagnostics @($strategy.Diagnostics) `
            -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
            -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
            -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged) `
            -SourceGraph $sourceGraph
    }

    if ($localUpdaterState -ceq 'Partial' -and $collisions.Count -eq 0) {
        return New-MeAndAICapabilitiesPlan -State 'BlockedManualReview' `
            -ProposalMode 'None' -Collisions @() `
            -Diagnostics @('A partial updater snapshot must identify its colliding paths.')
    }
    if ($collisions.Count -gt 0) {
        return New-MeAndAICapabilitiesPlan -State 'AdoptionReviewRequired' `
            -ProposalMode 'ManifestOnly' -Collisions @($collisions) -Diagnostics @() `
            -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
            -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
            -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged) `
            -SourceGraph $sourceGraph
    }

    return New-MeAndAICapabilitiesPlan -State 'BootstrapReady' `
        -ProposalMode 'Full' -Collisions @() -Diagnostics @() `
        -AdoptionStrategy ([string]$strategy.AdoptionStrategy) `
        -ProtocolSurfaces @($strategy.ProtocolSurfaces) `
        -ProtocolRecordLossAcknowledged ([bool]$strategy.ProtocolRecordLossAcknowledged) `
        -SourceGraph $sourceGraph
}

Export-ModuleMember -Function @(
    'Assert-MeAndAIProtocolAssessmentPathCasing',
    'ConvertTo-MeAndAIInstructionGraphRecord',
    'Get-MeAndAIAdoptionProposedPaths',
    'Get-MeAndAIAdoptionTargetPaths',
    'Get-MeAndAIInstructionGraphIdentity',
    'Get-MeAndAIInstructionGraphLimits',
    'Get-MeAndAILinkedPathIdentityDigest',
    'New-MeAndAIGitHubBlobLink',
    'Get-MeAndAIProtocolAssessmentLimits',
    'Get-MeAndAIProtocolSurfaceInventory',
    'Get-MeAndAIRequiredAdoptionTasks',
    'Resolve-MeAndAIAdoptionStrategy',
    'Resolve-MeAndAICapabilitiesLifecycle',
    'Resolve-MeAndAIInstructionGraphClosure',
    'New-MeAndAIInstructionGraph',
    'Test-MeAndAICompletedAdoptionChangeSet',
    'Test-MeAndAICanonicalRepositoryPath',
    'Test-MeAndAICleanStartSurfaceSupported',
    'Test-MeAndAIConsumerGovernancePath',
    'Test-MeAndAIExactAdoptionPullRequestMarker',
    'Test-MeAndAIExactLinkedPathSection',
    'Test-MeAndAILegacyCommonAuthorityPath',
    'Test-MeAndAILegacyGovernancePath',
    'Test-MeAndAIProtocolAssessmentRelevantPath',
    'Test-MeAndAIExactAdoptionManifest',
    'Test-MeAndAIExactInstructionGraph',
    'Test-MeAndAIExactInstructionGraphIdentity',
    'Test-MeAndAIExactInstructionGraphIdentityRecord',
    'Test-MeAndAIReservedProtocolSubmoduleContract'
)
