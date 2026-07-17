[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.10.0',
    [string]$RemoteName = 'origin',
    [ValidateRange(1, 60)]
    [int]$WorkflowTimeoutMinutes = 15,
    [ValidateRange(1, 120)]
    [int]$CodexTimeoutMinutes = 30,
    [ValidateRange(0, 7200)]
    [int]$CodexTimeoutSeconds = 0,
    [switch]$SkipLifecycleDispatch,
    [Alias('SkipCodexDelegation')]
    [switch]$SkipLocalCodex,
    [switch]$NoProgress,
    [string]$CodexCommand = '',
    [string]$TemporaryCodexVersion = '0.144.4'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$minimumGitHubCliVersion = '2.82.1'
$workflowSourcePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
$workflowTargetPath = '.github/workflows/meandai-protocol-update.yml'
$adoptionManifestPath = '.ai/adoption/meandai-capabilities.json'
$adoptionAssets = @(
    [pscustomobject]@{
        ConsumerPath = 'AGENTS.md'
        TemplatePath = 'templates/project/AGENTS.submodule.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/README.md'
        TemplatePath = 'templates/project/.ai/memory/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/project.md'
        TemplatePath = 'templates/project/.ai/memory/project.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/log/README.md'
        TemplatePath = 'templates/project/.ai/memory/log/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = 'docs/ideas/README.md'
        TemplatePath = 'templates/project/docs/ideas/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/bug.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/bug.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/epic.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/epic.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/feature.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/feature.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/finding.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/finding.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/subfeature.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/subfeature.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/task.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/task.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/PULL_REQUEST_TEMPLATE.md'
        TemplatePath = '.github/PULL_REQUEST_TEMPLATE.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
        TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    }
)
$adoptionUpdaterAssets = @($adoptionAssets | Where-Object {
    [string]$_.ConsumerPath -cin @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    )
})
$managedUpdaterAssets = @(
    [pscustomobject]@{
        ConsumerPath = $workflowTargetPath
        TemplatePath = $workflowSourcePath
    }
) + @($adoptionUpdaterAssets)
$secretLockLabel = 'meandai:secret-reconciliation-lock'
$tokenMappings = [ordered]@{
    'FG_PAT.txt' = 'MEANDAI_UPDATER_TOKEN'
    'MEANDAI_RO_FG_PAT.txt' = 'MEANDAI_PROTOCOL_TOKEN'
}
$adoptionLabels = @(
    [pscustomobject]@{ Name = 'type:epic'; Color = '5319e7'; Description = 'Agile epic' },
    [pscustomobject]@{ Name = 'type:feature'; Color = '1d76db'; Description = 'User-facing feature' },
    [pscustomobject]@{ Name = 'type:subfeature'; Color = '0e8a16'; Description = 'Independently testable feature slice' },
    [pscustomobject]@{ Name = 'type:task'; Color = 'd4c5f9'; Description = 'Implementation or maintenance task' },
    [pscustomobject]@{ Name = 'type:bug'; Color = 'd73a4a'; Description = 'Defect' },
    [pscustomobject]@{ Name = 'type:finding'; Color = 'fbca04'; Description = 'Review or scan finding' },
    [pscustomobject]@{ Name = 'priority:p0'; Color = 'b60205'; Description = 'Critical priority' },
    [pscustomobject]@{ Name = 'priority:p1'; Color = 'd93f0b'; Description = 'High priority' },
    [pscustomobject]@{ Name = 'priority:p2'; Color = 'fbca04'; Description = 'Normal priority' },
    [pscustomobject]@{ Name = 'priority:p3'; Color = '0e8a16'; Description = 'Low priority' },
    [pscustomobject]@{ Name = 'status:blocked'; Color = 'b60205'; Description = 'Blocked by an unresolved dependency' },
    [pscustomobject]@{ Name = 'status:in-progress'; Color = '1d76db'; Description = 'Implementation in progress' },
    [pscustomobject]@{ Name = 'status:needs-review'; Color = '5319e7'; Description = 'Ready for maintainer review' }
)

$script:QuickAdoptionProgressEnabled = -not $NoProgress
$script:QuickAdoptionLastProgressKey = ''
$script:QuickAdoptionLastChildKey = ''
$script:ValidatedProtocolReleases = [System.Collections.Generic.Dictionary[string, object]]::new(
    [StringComparer]::Ordinal
)
$script:CanonicalProtocolAssets = [System.Collections.Generic.Dictionary[string, object]]::new(
    [StringComparer]::Ordinal
)

function ConvertTo-QuickAdoptionDisplayText {
    param(
        [AllowEmptyString()][string]$Value,
        [ValidateRange(1, 1000)][int]$MaximumLength = 180
    )

    if ([string]::IsNullOrEmpty($Value)) {
        return ''
    }
    $withoutAnsi = [regex]::Replace(
        $Value,
        "`e\[[0-?]*[ -/]*[@-~]",
        ''
    )
    $singleLine = [regex]::Replace($withoutAnsi, '[\p{Cc}\p{Cf}]+', ' ')
    $singleLine = [regex]::Replace($singleLine, '\s+', ' ').Trim()
    if ($singleLine.Length -gt $MaximumLength) {
        if ($MaximumLength -le 3) {
            return $singleLine.Substring(0, $MaximumLength)
        }
        return $singleLine.Substring(0, $MaximumLength - 3) + '...'
    }
    return $singleLine
}

function Write-QuickAdoptionLine {
    param(
        [Parameter(Mandatory)][ValidateSet('Phase', 'Child')][string]$Channel,
        [Parameter(Mandatory)][string]$Text
    )

    if (-not $script:QuickAdoptionProgressEnabled) {
        return
    }
    $display = ConvertTo-QuickAdoptionDisplayText -Value $Text -MaximumLength 240
    if (-not $display) {
        return
    }
    $keyVariable = if ($Channel -ceq 'Phase') {
        'QuickAdoptionLastProgressKey'
    }
    else { 'QuickAdoptionLastChildKey' }
    if ((Get-Variable -Scope Script -Name $keyVariable -ValueOnly) -ceq $display) {
        return
    }
    Set-Variable -Scope Script -Name $keyVariable -Value $display
    Write-Host $display
}

function Set-QuickAdoptionProgress {
    param(
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][ValidateRange(0, 100)][int]$PercentComplete
    )

    if (-not $script:QuickAdoptionProgressEnabled) {
        return
    }
    $width = 20
    $filled = [int][Math]::Floor(($PercentComplete * $width) / 100.0)
    $bar = ('#' * $filled) + ('-' * ($width - $filled))
    $displayStatus = ConvertTo-QuickAdoptionDisplayText -Value $Status
    Write-QuickAdoptionLine -Channel Phase `
        -Text ('meAndAI [{0}] {1,3}% {2}' -f $bar, $PercentComplete, $displayStatus)
}

function Set-QuickAdoptionChildProgress {
    param(
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][string]$Status
    )

    if (-not $script:QuickAdoptionProgressEnabled) {
        return
    }
    $label = if ($Activity -ceq 'Running local Codex') {
        'Codex'
    }
    else {
        ConvertTo-QuickAdoptionDisplayText -Value $Activity -MaximumLength 60
    }
    $displayStatus = ConvertTo-QuickAdoptionDisplayText -Value $Status
    Write-QuickAdoptionLine -Channel Child -Text "$label | $displayStatus"
}

function Complete-QuickAdoptionChildProgress {
    $script:QuickAdoptionLastChildKey = ''
}

function Complete-QuickAdoptionProgress {
    $script:QuickAdoptionLastProgressKey = ''
    $script:QuickAdoptionLastChildKey = ''
}

function Get-QuickAdoptionObjectProperty {
    param(
        $InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Get-QuickAdoptionCommandIdentity {
    param([AllowEmptyString()][string]$Command)

    $normalized = ConvertTo-QuickAdoptionDisplayText -Value $Command -MaximumLength 200
    if (-not $normalized) {
        return 'repository command'
    }
    $match = [regex]::Match(
        $normalized,
        '^(?:"(?<double>[^"]+)"|''(?<single>[^'']+)''|(?<plain>[^\s]+))'
    )
    if (-not $match.Success) {
        return 'repository command'
    }
    $token = @(
        $match.Groups['double'].Value,
        $match.Groups['single'].Value,
        $match.Groups['plain'].Value
    ) | Where-Object { $_ } | Select-Object -First 1
    if (-not $token) {
        return 'repository command'
    }
    $identity = [IO.Path]::GetFileName([string]$token)
    if ($identity -cnotmatch '^[A-Za-z0-9._+-]{1,64}$') {
        return 'repository command'
    }
    return $identity
}

function Write-LocalCodexEvent {
    param([AllowEmptyString()][string]$Line)

    if (-not $script:QuickAdoptionProgressEnabled -or
        [string]::IsNullOrWhiteSpace($Line)) {
        return
    }
    try {
        $event = $Line | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
            -Status 'Received unstructured CLI output'
        return
    }

    $eventType = [string](Get-QuickAdoptionObjectProperty `
        -InputObject $event -Name 'type')
    switch -CaseSensitive ($eventType) {
        'thread.started' {
            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                -Status 'Session started'
        }
        'turn.started' {
            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                -Status 'Working'
        }
        'turn.completed' {
            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                -Status 'Completed'
        }
        'turn.failed' {
            $errorValue = Get-QuickAdoptionObjectProperty -InputObject $event -Name 'error'
            $message = if ($errorValue -is [string]) {
                [string]$errorValue
            }
            else {
                [string](Get-QuickAdoptionObjectProperty `
                    -InputObject $errorValue -Name 'message')
            }
            $message = ConvertTo-QuickAdoptionDisplayText -Value $message
            if (-not $message) { $message = 'Turn failed' }
            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                -Status "Failed: $message"
        }
        'error' {
            $message = [string](Get-QuickAdoptionObjectProperty `
                -InputObject $event -Name 'message')
            $message = ConvertTo-QuickAdoptionDisplayText -Value $message
            if (-not $message) { $message = 'CLI error' }
            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                -Status "Error: $message"
        }
        { @('item.started', 'item.updated', 'item.completed') -ccontains $_ } {
            $item = Get-QuickAdoptionObjectProperty -InputObject $event -Name 'item'
            $itemType = [string](Get-QuickAdoptionObjectProperty `
                -InputObject $item -Name 'type')
            switch -CaseSensitive ($itemType) {
                'reasoning' {
                    if ($eventType -ceq 'item.started') {
                        Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                            -Status 'Analyzing repository'
                    }
                }
                'command_execution' {
                    if ($eventType -ceq 'item.started') {
                        $command = [string](Get-QuickAdoptionObjectProperty `
                            -InputObject $item -Name 'command')
                        $identity = Get-QuickAdoptionCommandIdentity -Command $command
                        Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                            -Status "Running command: $identity"
                    }
                }
                'agent_message' {
                    if ($eventType -ceq 'item.completed') {
                        $message = [string](Get-QuickAdoptionObjectProperty `
                            -InputObject $item -Name 'text')
                        $message = ConvertTo-QuickAdoptionDisplayText `
                            -Value $message -MaximumLength 220
                        if ($message) {
                            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                                -Status $message
                        }
                    }
                }
                'file_change' {
                    if ($eventType -ceq 'item.completed') {
                        $changes = @(Get-QuickAdoptionObjectProperty `
                            -InputObject $item -Name 'changes')
                        $paths = @($changes | ForEach-Object {
                            [string](Get-QuickAdoptionObjectProperty `
                                -InputObject $_ -Name 'path')
                        } | Where-Object { $_ } | Select-Object -First 3)
                        if ($paths.Count -eq 0) {
                            $path = [string](Get-QuickAdoptionObjectProperty `
                                -InputObject $item -Name 'path')
                            if ($path) { $paths = @($path) }
                        }
                        $safePaths = @($paths | ForEach-Object {
                            ConvertTo-QuickAdoptionDisplayText -Value $_ -MaximumLength 120
                        })
                        if ($safePaths.Count -eq 1) {
                            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                                -Status "Changed file: $($safePaths[0])"
                        }
                        elseif ($safePaths.Count -gt 1) {
                            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                                -Status "Changed files: $($safePaths -join ', ')"
                        }
                    }
                }
                'plan_update' {
                    Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                        -Status 'Plan updated'
                }
                'mcp_tool_call' {
                    if ($eventType -ceq 'item.started') {
                        Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                            -Status 'Using configured tool'
                    }
                }
                'web_search' {
                    if ($eventType -ceq 'item.started') {
                        Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                            -Status 'Searching documentation'
                    }
                }
            }
        }
        default {
            Set-QuickAdoptionChildProgress -Activity 'Running local Codex' `
                -Status 'Received CLI event'
        }
    }
}

function Invoke-External {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        [AllowNull()][string]$InputText = $null,
        [switch]$AllowFailure
    )

    $previousPreference = $ErrorActionPreference
    $previousGitHubHost = [Environment]::GetEnvironmentVariable('GH_HOST', 'Process')
    $ErrorActionPreference = 'Continue'
    try {
        if ($Command -ceq 'gh') {
            [Environment]::SetEnvironmentVariable('GH_HOST', 'github.com', 'Process')
        }
        $global:LASTEXITCODE = 0
        $output = if ($PSBoundParameters.ContainsKey('InputText')) {
            @($InputText | & $Command @Arguments 2>&1)
        }
        else {
            @(& $Command @Arguments 2>&1)
        }
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) {
            $exitCode = 0
        }
    }
    finally {
        if ($Command -ceq 'gh') {
            [Environment]::SetEnvironmentVariable(
                'GH_HOST', $previousGitHubHost, 'Process'
            )
        }
        $ErrorActionPreference = $previousPreference
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = (@($output) -join [Environment]::NewLine).Trim()
        if ($detail) {
            throw "$Command failed with exit code ${exitCode}: $detail"
        }
        throw "$Command failed with exit code $exitCode."
    }

    return [pscustomobject]@{
        ExitCode = [int]$exitCode
        Output = @($output)
    }
}

function Compare-CanonicalDecimalComponent {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return [Math]::Sign($Left.Length - $Right.Length)
    }
    return [Math]::Sign([string]::CompareOrdinal($Left, $Right))
}

function Assert-MinimumGitHubCliVersion {
    $versionResult = Invoke-External -Command 'gh' -Arguments @('--version')
    $versionPattern = '\Agh version (?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<revision>0|[1-9][0-9]*)(?: \([^()\r\n]+\))?\z'
    $parsedVersions = [System.Collections.Generic.List[object]]::new()
    foreach ($outputLine in @($versionResult.Output)) {
        $match = [regex]::Match(
            [string]$outputLine,
            $versionPattern,
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if ($match.Success) {
            [void]$parsedVersions.Add([pscustomobject]@{
                Text = "$($match.Groups['major'].Value).$($match.Groups['minor'].Value).$($match.Groups['revision'].Value)"
                Parts = @(
                    $match.Groups['major'].Value,
                    $match.Groups['minor'].Value,
                    $match.Groups['revision'].Value
                )
            })
        }
    }

    $upgradeGuidance = 'Upgrade GitHub CLI before rerunning quick adoption: https://cli.github.com/'
    if ($parsedVersions.Count -ne 1) {
        throw "Unable to determine a single canonical GitHub CLI version. GitHub CLI $minimumGitHubCliVersion or newer is required. $upgradeGuidance"
    }

    $detected = $parsedVersions[0]
    $minimumParts = @($minimumGitHubCliVersion.Split('.'))
    for ($index = 0; $index -lt $minimumParts.Count; $index++) {
        $comparison = Compare-CanonicalDecimalComponent `
            -Left ([string]$detected.Parts[$index]) `
            -Right ([string]$minimumParts[$index])
        if ($comparison -lt 0) {
            throw "GitHub CLI $minimumGitHubCliVersion or newer is required; detected $($detected.Text). $upgradeGuidance"
        }
        if ($comparison -gt 0) {
            return
        }
    }
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $allArguments = @('-C', $Repository) + $Arguments
    return Invoke-External -Command 'git' -Arguments $allArguments -AllowFailure:$AllowFailure
}

function Get-NormalizedPath {
    param([Parameter(Mandatory)][string]$Path)

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Assert-ContainedManagedDestination {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$RelativePath
    )

    if ([IO.Path]::IsPathRooted($RelativePath)) {
        throw "Managed destination '$RelativePath' must be relative to the repository root."
    }
    $segments = @($RelativePath -split '[\\/]')
    if ($segments.Count -eq 0 -or
        @($segments | Where-Object { $_ -ceq '' -or $_ -ceq '.' -or $_ -ceq '..' }).Count -gt 0) {
        throw "Managed destination '$RelativePath' is not a canonical repository-relative path."
    }

    $rootPath = [IO.Path]::GetFullPath($Root)
    $relativePlatformPath = $segments -join [IO.Path]::DirectorySeparatorChar
    $destination = [IO.Path]::GetFullPath((Join-Path $rootPath $relativePlatformPath))
    $comparison = if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        [StringComparison]::OrdinalIgnoreCase
    }
    else { [StringComparison]::Ordinal }
    $rootPrefix = if ($rootPath.EndsWith([string][IO.Path]::DirectorySeparatorChar) -or
        $rootPath.EndsWith([string][IO.Path]::AltDirectorySeparatorChar)) {
        $rootPath
    }
    else { $rootPath + [IO.Path]::DirectorySeparatorChar }
    if (-not $destination.StartsWith($rootPrefix, $comparison)) {
        throw "Managed destination '$RelativePath' escapes the repository root."
    }

    $current = $rootPath
    for ($index = 0; $index -lt $segments.Count; $index++) {
        $current = Join-Path $current $segments[$index]
        try {
            $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            continue
        }
        catch {
            throw "Managed destination '$RelativePath' could not be inspected safely: $($_.Exception.Message)"
        }

        $linkTypeProperty = $item.PSObject.Properties['LinkType']
        $isLink = $null -ne $linkTypeProperty -and
            -not [string]::IsNullOrEmpty([string]$linkTypeProperty.Value)
        $isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if ($isLink -or $isReparsePoint) {
            $component = @($segments[0..$index]) -join '/'
            throw "Managed destination '$RelativePath' traverses linked or reparse-point path '$component'."
        }
        if ($index -lt ($segments.Count - 1) -and -not $item.PSIsContainer) {
            $component = @($segments[0..$index]) -join '/'
            throw "Managed destination '$RelativePath' traverses non-directory path '$component'."
        }
    }

    return $destination
}

function Get-GitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $sha = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Test-ByteArrayEqual {
    param(
        [Parameter(Mandatory)][byte[]]$Left,
        [Parameter(Mandatory)][byte[]]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }
    return $true
}

function Get-AdoptionTreeEntry {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Path,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one adoption tree source must be selected.'
    }
    $result = if ($UseIndex) {
        Invoke-Git -Repository $Repository -Arguments @('ls-files', '--stage', '--', $Path)
    }
    else {
        Invoke-Git -Repository $Repository -Arguments @('ls-tree', $Commit, '--', $Path)
    }
    $lines = @($result.Output | Where-Object { $_ })
    $empty = [pscustomobject]@{ Mode = ''; Type = ''; Sha = ''; Path = '' }
    if ($lines.Count -ne 1) {
        return $empty
    }
    $pattern = if ($UseIndex) {
        '^(?<mode>[0-9]{6})\s+(?<sha>[0-9a-f]{40})\s+0\t(?<path>.+)$'
    }
    else {
        '^(?<mode>[0-9]{6})\s+(?<type>[^\s]+)\s+(?<sha>[0-9a-f]{40})\t(?<path>.+)$'
    }
    $match = [regex]::Match([string]$lines[0], $pattern)
    if (-not $match.Success -or [string]$match.Groups['path'].Value -cne $Path) {
        return $empty
    }
    return [pscustomobject]@{
        Mode = [string]$match.Groups['mode'].Value
        Type = if ($UseIndex) { 'blob' } else { [string]$match.Groups['type'].Value }
        Sha = [string]$match.Groups['sha'].Value
        Path = [string]$match.Groups['path'].Value
    }
}

function Get-SingleCommitParent {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    $line = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-list', '--parents', '-n', '1', $Commit
    )).Output -join '').Trim())
    $parts = @($line -split ' ' | Where-Object { $_ })
    if ($parts.Count -ne 2 -or $parts[0] -cne $Commit -or
        $parts[1] -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption proposal must contain one exact parent commit.'
    }
    return $parts[1]
}

function Get-ExpectedAdoptionManifestContract {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string[]]$TargetPaths
    )

    $baseHead = Get-SingleCommitParent -Repository $Repository -Commit $ProposalHead
    $basePaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'ls-tree', '-r', '--name-only', $baseHead
    )).Output | ForEach-Object { [string]$_ })
    $pathLookup = [System.Collections.Generic.Dictionary[string, string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($path in $basePaths) {
        if ([string]::IsNullOrWhiteSpace($path) -or $pathLookup.ContainsKey($path)) {
            throw "The adoption proposal parent contains an empty or case-ambiguous path '$path'."
        }
        $pathLookup.Add($path, $path)
    }
    if ($pathLookup.ContainsKey($adoptionManifestPath)) {
        throw 'The adoption proposal parent already contains the transient adoption manifest.'
    }

    $collisions = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $TargetPaths) {
        if ($pathLookup.ContainsKey($path)) {
            $collisions.Add([string]$pathLookup[$path])
        }
    }
    $updaterCount = @($adoptionUpdaterAssets | Where-Object {
        $pathLookup.ContainsKey([string]$_.ConsumerPath)
    }).Count
    return [pscustomobject]@{
        BaseHead = $baseHead
        LocalUpdaterState = if ($updaterCount -eq 0) {
            'Absent'
        }
        elseif ($updaterCount -eq $adoptionUpdaterAssets.Count) { 'Complete' }
        else { 'Partial' }
        Collisions = @($collisions)
    }
}

function Get-ExactProtocolSourceBlobSha {
    param(
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$TemplatePath
    )

    $sourcePath = Join-Path $ProtocolSource `
        ($TemplatePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Exact protocol source is missing asset '$TemplatePath'."
    }
    if (Test-Path -LiteralPath (Join-Path $ProtocolSource '.git')) {
        $sourceEntry = Get-AdoptionTreeEntry -Repository $ProtocolSource `
            -Commit $ProtocolSha -Path $TemplatePath
        if ($sourceEntry.Mode -cne '100644' -or $sourceEntry.Type -cne 'blob') {
            throw "Exact protocol source asset '$TemplatePath' is not a regular blob."
        }
        return [string]$sourceEntry.Sha
    }
    return Get-GitBlobSha -Bytes ([IO.File]::ReadAllBytes($sourcePath))
}

function Assert-AdoptionUpdaterAssetsExact {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one updater validation tree source must be selected.'
    }
    foreach ($asset in $adoptionUpdaterAssets) {
        $sourceSha = Get-ExactProtocolSourceBlobSha -ProtocolSource $ProtocolSource `
            -ProtocolSha $ProtocolSha -TemplatePath ([string]$asset.TemplatePath)
        $consumerEntry = if ($UseIndex) {
            Get-AdoptionTreeEntry -Repository $Repository -Path ([string]$asset.ConsumerPath) `
                -UseIndex
        }
        else {
            Get-AdoptionTreeEntry -Repository $Repository -Path ([string]$asset.ConsumerPath) `
                -Commit $Commit
        }
        if ($consumerEntry.Mode -cne '100644' -or $consumerEntry.Type -cne 'blob' -or
            $consumerEntry.Sha -cne $sourceSha) {
            throw "Consumer updater asset '$($asset.ConsumerPath)' does not match the exact protocol source."
        }
    }
}

function Test-ExactOrdinalPathSet {
    param(
        [Parameter(Mandatory)][object[]]$Actual,
        [Parameter(Mandatory)][object[]]$Expected
    )

    if ($Actual.Count -ne $Expected.Count) {
        return $false
    }
    $remaining = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in $Expected) {
        if (-not $remaining.Add([string]$path)) {
            return $false
        }
    }
    foreach ($path in $Actual) {
        if (-not $remaining.Remove([string]$path)) {
            return $false
        }
    }
    return $remaining.Count -eq 0
}

function Assert-ExactAdoptionProposal {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
        [Parameter(Mandatory)][ValidateSet('Full', 'ManifestOnly')]
        [string]$ProposalMode,
        [Parameter(Mandatory)][string[]]$TargetPaths,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    if ($CanonicalBaseHead -cnotmatch '^[0-9a-f]{40}$' -or
        $ProtocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The exact adoption proposal received an invalid base or protocol commit.'
    }
    $proposalParent = Get-SingleCommitParent -Repository $Repository `
        -Commit $ProposalHead
    if ($proposalParent -cne $CanonicalBaseHead) {
        throw 'The adoption proposal is not based on the canonical consumer head.'
    }

    $mappedTargetPaths = @('.gitmodules', '.ai/protocol') + @(
        $adoptionAssets | ForEach-Object { [string]$_.ConsumerPath }
    )
    if (-not (Test-ExactOrdinalPathSet -Actual @($TargetPaths) `
        -Expected $mappedTargetPaths)) {
        throw 'The exact protocol target paths do not match the launcher asset mapping.'
    }
    $expectedChangedPaths = if ($ProposalMode -ceq 'Full') {
        @($TargetPaths) + @($adoptionManifestPath)
    }
    else {
        @($adoptionManifestPath)
    }
    Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--check', $CanonicalBaseHead, $ProposalHead, '--'
    ) | Out-Null
    $actualChangedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--no-renames', '--name-only', '--diff-filter=ACMRTD',
        $CanonicalBaseHead, $ProposalHead, '--'
    )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if (-not (Test-ExactOrdinalPathSet -Actual $actualChangedPaths `
        -Expected $expectedChangedPaths)) {
        throw 'The adoption proposal does not contain the exact lifecycle change set.'
    }

    if ($ProposalMode -ceq 'ManifestOnly') {
        return
    }

    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path '.ai/protocol'
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cne $ProtocolSha) {
        throw 'The exact adoption proposal protocol reference is not the pinned gitlink.'
    }

    $gitmodulesText = @(
        '[submodule ".ai/protocol"]',
        "`tpath = .ai/protocol",
        "`turl = https://github.com/$ProtocolRepository.git",
        ''
    ) -join "`n"
    $gitmodulesSha = Get-GitBlobSha -Bytes (
        [Text.UTF8Encoding]::new($false).GetBytes($gitmodulesText)
    )
    $gitmodulesEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $ProposalHead -Path '.gitmodules'
    if ($gitmodulesEntry.Mode -cne '100644' -or
        $gitmodulesEntry.Type -cne 'blob' -or
        $gitmodulesEntry.Sha -cne $gitmodulesSha) {
        throw 'The exact adoption proposal submodule metadata is not canonical.'
    }

    foreach ($asset in $adoptionAssets) {
        $sourceSha = Get-ExactProtocolSourceBlobSha `
            -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha `
            -TemplatePath ([string]$asset.TemplatePath)
        $proposalEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $ProposalHead -Path ([string]$asset.ConsumerPath)
        if ($proposalEntry.Mode -cne '100644' -or
            $proposalEntry.Type -cne 'blob' -or
            $proposalEntry.Sha -cne $sourceSha) {
            throw "Adoption proposal asset '$($asset.ConsumerPath)' does not match the exact protocol source."
        }
    }
}

function Get-GitHubSlugFromRemote {
    param([Parameter(Mandatory)][string]$RemoteUrl)

    $candidate = $RemoteUrl.Trim()
    $path = $null
    if ($candidate -match '^https://github\.com/(?<path>[^?#]+)$') {
        $path = $Matches.path
    }
    elseif ($candidate -match '^git@github\.com:(?<path>.+)$') {
        $path = $Matches.path
    }
    elseif ($candidate -match '^ssh://git@github\.com/(?<path>.+)$') {
        $path = $Matches.path
    }

    if (-not $path) {
        throw "Remote '$RemoteName' must be an unambiguous GitHub HTTPS or SSH URL."
    }

    $path = $path.Trim('/')
    if ($path.EndsWith('.git', [StringComparison]::OrdinalIgnoreCase)) {
        $path = $path.Substring(0, $path.Length - 4)
    }
    $parts = @($path.Split('/'))
    if ($parts.Count -ne 2 -or -not $parts[0] -or -not $parts[1]) {
        throw "Remote '$RemoteName' does not identify exactly one GitHub owner/repository."
    }
    return "$($parts[0])/$($parts[1])"
}

function Add-LocalTokenExcludes {
    param([Parameter(Mandatory)][string]$Repository)

    $result = Invoke-Git -Repository $Repository -Arguments @('rev-parse', '--git-path', 'info/exclude')
    $excludePath = (@($result.Output) -join '').Trim()
    if (-not [IO.Path]::IsPathRooted($excludePath)) {
        $excludePath = Join-Path $Repository $excludePath
    }
    $excludePath = [IO.Path]::GetFullPath($excludePath)
    $excludeDirectory = Split-Path -Parent $excludePath
    [IO.Directory]::CreateDirectory($excludeDirectory) | Out-Null

    $existing = if (Test-Path -LiteralPath $excludePath -PathType Leaf) {
        @([IO.File]::ReadAllLines($excludePath))
    }
    else {
        @()
    }
    $updated = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $existing) {
        $updated.Add($line)
    }
    foreach ($name in $tokenMappings.Keys) {
        if ($updated -cnotcontains $name) {
            $updated.Add($name)
        }
    }
    [IO.File]::WriteAllLines($excludePath, $updated, [Text.UTF8Encoding]::new($false))
}

function Assert-TokenFilesAreLocalOnly {
    param([Parameter(Mandatory)][string]$Repository)

    $head = Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', '--verify', 'HEAD'
    ) -AllowFailure
    $hasHead = $head.ExitCode -eq 0
    if ($hasHead) {
        $shallow = Invoke-Git -Repository $Repository -Arguments @(
            'rev-parse', '--is-shallow-repository'
        ) -AllowFailure
        $shallowText = ((@($shallow.Output) -join '').Trim())
        if ($shallow.ExitCode -ne 0 -or $shallowText -cnotin @('true', 'false')) {
            throw 'The launcher could not determine whether repository history is complete.'
        }
        if ($shallowText -ceq 'true') {
            throw 'Credential-history validation requires a non-shallow repository. Fetch complete history before rerunning.'
        }
    }

    foreach ($name in $tokenMappings.Keys) {
        $tracked = Invoke-Git -Repository $Repository -Arguments @(
            'ls-files', '--error-unmatch', '--', $name
        ) -AllowFailure
        if ($tracked.ExitCode -eq 0) {
            throw "Credential file '$name' is tracked or staged. Remove it from Git, rotate that token, and rerun."
        }

        if ($hasHead) {
            $history = Invoke-Git -Repository $Repository -Arguments @(
                'log', '--all', '--reflog', '--format=%H', '--', $name
            ) -AllowFailure
            if ($history.ExitCode -ne 0) {
                throw "Credential history for '$name' could not be inspected."
            }
            if ((@($history.Output) -join '').Trim()) {
                throw "Credential file '$name' appears in locally reachable ref or reflog history. Rotate that token and clean the history before rerunning."
            }
        }

    }
}

function Read-LocalToken {
    param([Parameter(Mandatory)][string]$Path)

    $value = [IO.File]::ReadAllText($Path).Trim()
    if (-not $value -or $value -match '\s') {
        throw "Credential file '$([IO.Path]::GetFileName($Path))' must contain exactly one non-whitespace token value."
    }
    return $value
}

function Invoke-GitHubApi {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Token
    )

    $headers = @{
        Accept = 'application/vnd.github+json'
        Authorization = "Bearer $Token"
        'X-GitHub-Api-Version' = '2026-03-10'
        'User-Agent' = 'meAndAI-quick-adoption'
    }
    try {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
    }
    catch {
        throw "GitHub API access failed for the requested repository resource. Verify token scope and repository access, then rerun."
    }
}

function Get-ValidatedImmutableProtocolRelease {
    param(
        [string]$ProtocolToken = '',
        [string]$Tag = $ProtocolTag
    )

    if ($Tag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$') {
        throw "Protocol tag '$Tag' must use the canonical vM.m.rev form."
    }
    if ($script:ValidatedProtocolReleases.ContainsKey($Tag)) {
        return $script:ValidatedProtocolReleases[$Tag]
    }

    $escapedTag = [Uri]::EscapeDataString($Tag)
    $endpoint = "repos/$ProtocolRepository/releases/tags/$escapedTag"
    if ($ProtocolToken) {
        $release = Invoke-GitHubApi `
            -Uri "https://api.github.com/$endpoint" -Token $ProtocolToken
    }
    else {
        try {
            $result = Invoke-External -Command 'gh' -Arguments @(
                'api',
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2026-03-10',
                $endpoint
            )
            $release = ((@($result.Output) -join [Environment]::NewLine) |
                ConvertFrom-Json)
        }
        catch {
            throw "Unable to verify the published immutable GitHub Release '$Tag' through the authenticated local GitHub CLI."
        }
    }

    $requiredProperties = @('tag_name', 'draft', 'prerelease', 'immutable', 'published_at')
    foreach ($property in $requiredProperties) {
        if ($null -eq $release -or $null -eq $release.PSObject.Properties[$property]) {
            throw "The published immutable GitHub Release response is missing '$property'."
        }
    }
    $publishedAt = [DateTimeOffset]::MinValue
    if ([string]$release.tag_name -cne $Tag -or
        $release.draft -isnot [bool] -or $release.draft -or
        $release.prerelease -isnot [bool] -or $release.prerelease -or
        $release.immutable -isnot [bool] -or -not $release.immutable -or
        -not [DateTimeOffset]::TryParse([string]$release.published_at, [ref]$publishedAt)) {
        throw "Protocol source '$Tag' is not an exact published immutable GitHub Release."
    }

    $commitEndpoint = "repos/$ProtocolRepository/commits/$escapedTag"
    if ($ProtocolToken) {
        $commit = Invoke-GitHubApi `
            -Uri "https://api.github.com/$commitEndpoint" -Token $ProtocolToken
    }
    else {
        try {
            $commitResult = Invoke-External -Command 'gh' -Arguments @(
                'api',
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2026-03-10',
                $commitEndpoint
            )
            $commit = ((@($commitResult.Output) -join [Environment]::NewLine) |
                ConvertFrom-Json)
        }
        catch {
            throw "Unable to resolve immutable protocol release '$Tag' to one commit through the authenticated local GitHub CLI."
        }
    }
    if ($null -eq $commit -or $null -eq $commit.PSObject.Properties['sha'] -or
        [string]$commit.sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Immutable protocol release '$Tag' did not resolve to one canonical commit."
    }

    $evidence = [pscustomobject]@{
        Tag = $Tag
        CommitSha = [string]$commit.sha
        Release = $release
    }
    $script:ValidatedProtocolReleases.Add($Tag, $evidence)
    return $evidence
}

function Get-CanonicalProtocolAsset {
    param(
        [Parameter(Mandatory)][string]$Tag,
        [Parameter(Mandatory)][string]$TemplatePath,
        [string]$ProtocolToken = ''
    )

    if ($ProtocolRepository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw "ProtocolRepository '$ProtocolRepository' must use the owner/repository form."
    }
    if ($TemplatePath -cnotmatch '^[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*$') {
        throw "Protocol asset path '$TemplatePath' is not canonical."
    }

    [void](Get-ValidatedImmutableProtocolRelease `
        -ProtocolToken $ProtocolToken -Tag $Tag)
    $cacheKey = "$Tag`n$TemplatePath"
    if ($script:CanonicalProtocolAssets.ContainsKey($cacheKey)) {
        return $script:CanonicalProtocolAssets[$cacheKey]
    }

    $escapedRef = [Uri]::EscapeDataString($Tag)
    $uri = "https://api.github.com/repos/$ProtocolRepository/contents/$TemplatePath`?ref=$escapedRef"
    if ($ProtocolToken) {
        $response = Invoke-GitHubApi -Uri $uri -Token $ProtocolToken
    }
    else {
        $endpoint = "repos/$ProtocolRepository/contents/$TemplatePath`?ref=$escapedRef"
        try {
            $result = Invoke-External -Command 'gh' -Arguments @(
                'api',
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2026-03-10',
                $endpoint
            )
            $response = ((@($result.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        }
        catch {
            throw "Unable to retrieve canonical protocol asset '$TemplatePath' at '$Tag' through the authenticated local GitHub CLI. Verify local gh access to '$ProtocolRepository', then rerun."
        }
    }
    if ($response.encoding -cne 'base64' -or -not $response.content -or -not $response.sha) {
        throw "Canonical protocol asset '$TemplatePath' is incomplete or uses an unsupported encoding."
    }

    try {
        $bytes = [Convert]::FromBase64String(([string]$response.content))
    }
    catch {
        throw "Canonical protocol asset '$TemplatePath' contains invalid base64 content."
    }
    $actualSha = Get-GitBlobSha -Bytes $bytes
    if ($actualSha -cne ([string]$response.sha).ToLowerInvariant()) {
        throw "Canonical protocol asset '$TemplatePath' failed Git blob verification."
    }
    $asset = [pscustomobject]@{
        Tag = $Tag
        TemplatePath = $TemplatePath
        Bytes = [byte[]]$bytes
        Sha = $actualSha
    }
    $script:CanonicalProtocolAssets.Add($cacheKey, $asset)
    return $asset
}

function Get-CanonicalWorkflow {
    param([string]$ProtocolToken = '')

    $asset = Get-CanonicalProtocolAsset -Tag $ProtocolTag `
        -TemplatePath $workflowSourcePath -ProtocolToken $ProtocolToken
    return [byte[]]$asset.Bytes
}

function ConvertTo-CanonicalProtocolVersionRecord {
    param([Parameter(Mandatory)][string]$Tag)

    $match = [regex]::Match(
        $Tag,
        '^v(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<revision>0|[1-9][0-9]*)$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if (-not $match.Success) {
        throw "Protocol tag '$Tag' must use the canonical vM.m.rev form."
    }
    return [pscustomobject]@{
        Tag = $Tag
        Parts = @(
            [string]$match.Groups['major'].Value,
            [string]$match.Groups['minor'].Value,
            [string]$match.Groups['revision'].Value
        )
    }
}

function Compare-CanonicalProtocolVersion {
    param(
        [Parameter(Mandatory)]$Left,
        [Parameter(Mandatory)]$Right
    )

    for ($index = 0; $index -lt 3; $index++) {
        $comparison = Compare-CanonicalDecimalComponent `
            -Left ([string]$Left.Parts[$index]) `
            -Right ([string]$Right.Parts[$index])
        if ($comparison -ne 0) {
            return $comparison
        }
    }
    return 0
}

function Assert-CanonicalProtocolSubmoduleMetadata {
    param([Parameter(Mandatory)][string]$Repository)

    $pathResult = Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', '.gitmodules', '--get-regexp', '^submodule\..*\.path$'
    ) -AllowFailure
    if ($pathResult.ExitCode -ne 0) {
        throw "Installed protocol metadata has no canonical '$('.ai/protocol')' entry."
    }
    $matches = @($pathResult.Output | Where-Object {
        [string]$_ -match '^submodule\.\.ai/protocol\.path\s+\.ai/protocol$'
    })
    if ($matches.Count -ne 1) {
        throw "Installed protocol metadata must contain one canonical '.ai/protocol' path entry."
    }
    $urlResult = Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', '.gitmodules', '--get-all', 'submodule..ai/protocol.url'
    ) -AllowFailure
    $urls = @($urlResult.Output | Where-Object { $_ })
    $expectedUrl = "https://github.com/$ProtocolRepository.git"
    if ($urlResult.ExitCode -ne 0 -or $urls.Count -ne 1 -or
        [string]$urls[0] -cne $expectedUrl) {
        throw "Installed protocol metadata must use canonical URL '$expectedUrl'."
    }
}

function Get-ExistingAdoptionRoute {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [string]$HeadSha = '',
        [string]$ProtocolToken = ''
    )

    if (-not $HeadSha) {
        return [pscustomobject]@{
            State = 'InitialAdoption'; InstalledTag = ''; InstalledProtocolSha = ''
        }
    }
    if ($HeadSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'Existing adoption routing received an invalid default-branch head.'
    }

    $manifestEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path $adoptionManifestPath
    if ($manifestEntry.Path) {
        throw 'The transient adoption manifest exists on the default branch; managed routing is ambiguous.'
    }
    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path '.ai/protocol'
    if (-not $protocolEntry.Path) {
        $partialManagedPaths = @('.gitmodules') + @($adoptionUpdaterAssets | ForEach-Object {
            [string]$_.ConsumerPath
        })
        foreach ($partialManagedPath in $partialManagedPaths) {
            $partialManagedEntry = Get-AdoptionTreeEntry -Repository $Repository `
                -Commit $HeadSha -Path $partialManagedPath
            if ($partialManagedEntry.Path) {
                throw "Managed adoption footprint '$partialManagedPath' exists without the protocol gitlink."
            }
        }
        return [pscustomobject]@{
            State = 'InitialAdoption'; InstalledTag = ''; InstalledProtocolSha = ''
        }
    }
    if ($protocolEntry.Mode -cne '160000' -or
        $protocolEntry.Type -cne 'commit' -or
        $protocolEntry.Sha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Existing '.ai/protocol' is not one canonical protocol gitlink."
    }

    $workingChanges = @((Invoke-Git -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ })
    if ($workingChanges.Count -ne 0) {
        throw 'A completed adoption must be clean before current/update routing.'
    }
    $gitmodulesEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $HeadSha -Path '.gitmodules'
    if ($gitmodulesEntry.Mode -cne '100644' -or $gitmodulesEntry.Type -cne 'blob') {
        throw "Installed protocol gitlink has no canonical '.gitmodules' blob."
    }
    Assert-CanonicalProtocolSubmoduleMetadata -Repository $Repository

    foreach ($asset in $managedUpdaterAssets) {
        $consumerEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $HeadSha -Path ([string]$asset.ConsumerPath)
        if ($consumerEntry.Mode -cne '100644' -or $consumerEntry.Type -cne 'blob') {
            throw "Installed updater asset '$($asset.ConsumerPath)' is absent or partial."
        }
    }

    $workflowText = (@(Invoke-Git -Repository $Repository -Arguments @(
        'show', "${HeadSha}:$workflowTargetPath"
    )).Output -join "`n")
    $declarations = [regex]::Matches(
        $workflowText,
        '(?m)^[ \t]*BOOTSTRAP_PROTOCOL_TAG[ \t]*:.*$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $canonicalDeclarations = [regex]::Matches(
        $workflowText,
        '(?m)^  BOOTSTRAP_PROTOCOL_TAG: (?<tag>v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*))$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($declarations.Count -ne 1 -or $canonicalDeclarations.Count -ne 1) {
        throw 'Installed updater workflow has no single canonical bootstrap protocol tag.'
    }
    $installedTag = [string]$canonicalDeclarations[0].Groups['tag'].Value
    $installedVersion = ConvertTo-CanonicalProtocolVersionRecord -Tag $installedTag
    $targetVersion = ConvertTo-CanonicalProtocolVersionRecord -Tag $ProtocolTag
    if ([string]$installedVersion.Parts[0] -cne [string]$targetVersion.Parts[0]) {
        throw "Installed protocol '$installedTag' and requested '$ProtocolTag' cross a major-version boundary; use a reviewed migration."
    }

    $installedRelease = Get-ValidatedImmutableProtocolRelease `
        -ProtocolToken $ProtocolToken -Tag $installedTag
    if ([string]$installedRelease.CommitSha -cne [string]$protocolEntry.Sha) {
        throw "Installed protocol gitlink does not match immutable release '$installedTag'."
    }
    foreach ($asset in $managedUpdaterAssets) {
        $sourceAsset = Get-CanonicalProtocolAsset -Tag $installedTag `
            -TemplatePath ([string]$asset.TemplatePath) `
            -ProtocolToken $ProtocolToken
        $consumerEntry = Get-AdoptionTreeEntry -Repository $Repository `
            -Commit $HeadSha -Path ([string]$asset.ConsumerPath)
        if ([string]$consumerEntry.Sha -cne [string]$sourceAsset.Sha) {
            throw "Installed updater asset '$($asset.ConsumerPath)' drifted from immutable release '$installedTag'."
        }
    }

    $comparison = Compare-CanonicalProtocolVersion `
        -Left $installedVersion -Right $targetVersion
    if ($comparison -gt 0) {
        throw "Installed protocol '$installedTag' is newer than requested launcher target '$ProtocolTag'; downgrade is prohibited."
    }
    return [pscustomobject]@{
        State = if ($comparison -eq 0) { 'AlreadyCurrent' } else { 'CompatibleUpdate' }
        InstalledTag = $installedTag
        InstalledProtocolSha = [string]$protocolEntry.Sha
    }
}

function Set-RepositorySecret {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    # gh secret set reads the value from stdin when no body argument is used.
    try {
        Invoke-External -Command 'gh' -Arguments @(
            'secret', 'set', $Name, '--repo', $Repository
        ) -InputText $Value | Out-Null
    }
    catch {
        throw "Unable to store repository Actions secret '$Name'."
    }
}

function Get-RepositorySecretNames {
    param([Parameter(Mandatory)][string]$Repository)

    # gh secret list exposes repository secret names, never their stored values.
    $listed = Invoke-External -Command 'gh' -Arguments @(
        'secret', 'list', '--repo', $Repository, '--json', 'name'
    )
    try {
        $items = @(((@($listed.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
    }
    catch {
        throw 'GitHub CLI returned invalid repository Actions secret metadata.'
    }

    $names = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $items) {
        if ($null -eq $item -or $null -eq $item.PSObject.Properties['name']) {
            throw 'GitHub CLI returned incomplete repository Actions secret metadata.'
        }
        $name = ([string]$item.name).Trim()
        if (-not $name) {
            throw 'GitHub CLI returned an empty repository Actions secret name.'
        }
        if ($names -notcontains $name) {
            $names.Add($name)
        }
    }
    return @($names)
}

function Get-RepositoryLabelRecord {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Name
    )

    $encodedName = [Uri]::EscapeDataString($Name)
    $view = Invoke-External -Command 'gh' -Arguments @(
        'api',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10',
        "repos/$Repository/labels/$encodedName"
    )
    try {
        $label = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
    }
    catch {
        throw "GitHub CLI returned invalid metadata for repository label '$Name'."
    }
    if ($null -eq $label -or $null -eq $label.PSObject.Properties['name'] -or
        $null -eq $label.PSObject.Properties['description'] -or
        [string]$label.name -cne $Name) {
        throw "Repository label '$Name' has incomplete or mismatched identity metadata."
    }
    return $label
}

function Enter-RepositorySecretReconciliationLock {
    param([Parameter(Mandatory)][string]$Repository)

    $nonce = [guid]::NewGuid().ToString('N')
    $description = "meAndAI secret reconciliation lock session $nonce"
    $created = Invoke-External -Command 'gh' -Arguments @(
        'label', 'create', $secretLockLabel, '--repo', $Repository,
        '--color', 'ededed', '--description', $description
    ) -AllowFailure
    if ($created.ExitCode -ne 0) {
        throw "Repository secret reconciliation is already locked or a stale '$secretLockLabel' label exists. Inspect the label and resolve ownership manually before rerunning."
    }

    $observed = Get-RepositoryLabelRecord -Repository $Repository -Name $secretLockLabel
    if ([string]$observed.description -cne $description) {
        throw 'The repository secret-reconciliation lock could not be verified after creation.'
    }
    return [pscustomobject]@{
        Name = $secretLockLabel
        Description = $description
    }
}

function Exit-RepositorySecretReconciliationLock {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Lock
    )

    $observed = Get-RepositoryLabelRecord -Repository $Repository -Name ([string]$Lock.Name)
    if ([string]$observed.description -cne [string]$Lock.Description) {
        throw 'The repository secret-reconciliation lock ownership changed; the launcher did not remove it.'
    }
    $encodedName = [Uri]::EscapeDataString([string]$Lock.Name)
    Invoke-External -Command 'gh' -Arguments @(
        'api', '--method', 'DELETE',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2026-03-10',
        "repos/$Repository/labels/$encodedName"
    ) | Out-Null
}

function Write-CanonicalWorkflow {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][byte[]]$Bytes
    )

    $directory = Split-Path -Parent $Path
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $current = [IO.File]::ReadAllBytes($Path)
        if (-not (Test-ByteArrayEqual -Left $current -Right $Bytes)) {
            throw "The existing '$workflowTargetPath' differs from the canonical $ProtocolTag seed; it was not overwritten."
        }
        return $false
    }

    $temporaryPath = Join-Path $directory ".meandai-seed-$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
    return $true
}

function Invoke-LifecycleWorkflow {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$HeadSha
    )

    $workflowName = [IO.Path]::GetFileName($workflowTargetPath)
    $correlationId = [guid]::NewGuid().ToString('N')
    $expectedRunTitle = "meAndAI AI capabilities lifecycle [$correlationId]"
    $registered = $false
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        $view = Invoke-External -Command 'gh' -Arguments @(
            'workflow', 'view', $workflowName, '--repo', $Repository,
            '--ref', $Branch, '--yaml'
        ) -AllowFailure
        if ($view.ExitCode -eq 0) {
            $registered = $true
            break
        }
        if ($attempt -lt 6) {
            Start-Sleep -Seconds 5
        }
    }
    if (-not $registered) {
        throw 'The lifecycle workflow was published but did not become discoverable after six bounded attempts.'
    }

    $listArguments = @(
        'run', 'list', '--repo', $Repository, '--workflow', $workflowName,
        '--event', 'workflow_dispatch', '--branch', $Branch, '--commit', $HeadSha,
        '--limit', '100', '--json', 'databaseId,createdAt,displayTitle,headSha,status,conclusion,url'
    )
    $baselineResult = Invoke-External -Command 'gh' -Arguments $listArguments
    try {
        $baselineRuns = @(((@($baselineResult.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
    }
    catch {
        throw 'GitHub CLI returned invalid baseline workflow-run metadata.'
    }
    $baselineIds = [System.Collections.Generic.HashSet[long]]::new()
    foreach ($run in $baselineRuns) {
        if ($null -eq $run.PSObject.Properties['databaseId'] -or
            [string]$run.databaseId -cnotmatch '^[1-9][0-9]*$') {
            throw 'GitHub CLI returned an invalid baseline workflow-run identity.'
        }
        [void]$baselineIds.Add([long]$run.databaseId)
    }

    $dispatchStarted = [DateTimeOffset]::UtcNow.AddSeconds(-5)
    Invoke-External -Command 'gh' -Arguments @(
        'workflow', 'run', $workflowName, '--repo', $Repository, '--ref', $Branch,
        '--field', "correlation_id=$correlationId"
    ) | Out-Null

    $deadline = [DateTimeOffset]::UtcNow.AddMinutes($WorkflowTimeoutMinutes)
    $observedRunId = $null
    while ([DateTimeOffset]::UtcNow -lt $deadline) {
        if ($null -eq $observedRunId) {
            $list = Invoke-External -Command 'gh' -Arguments $listArguments
            try {
                $runs = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
            }
            catch {
                throw 'GitHub CLI returned invalid workflow-run metadata.'
            }
            $candidates = [System.Collections.Generic.List[object]]::new()
            foreach ($run in $runs) {
                if ($null -eq $run.PSObject.Properties['databaseId'] -or
                    [string]$run.databaseId -cnotmatch '^[1-9][0-9]*$' -or
                    $null -eq $run.PSObject.Properties['createdAt'] -or
                    $null -eq $run.PSObject.Properties['displayTitle'] -or
                    $null -eq $run.PSObject.Properties['headSha']) {
                    throw 'GitHub CLI returned incomplete workflow-run metadata.'
                }
                try {
                    $createdAt = [DateTimeOffset]::Parse([string]$run.createdAt)
                }
                catch {
                    throw 'GitHub CLI returned an invalid workflow-run timestamp.'
                }
                if (-not $baselineIds.Contains([long]$run.databaseId) -and
                    [string]$run.headSha -ceq $HeadSha -and
                    [string]$run.displayTitle -ceq $expectedRunTitle -and
                    $createdAt -ge $dispatchStarted) {
                    $candidates.Add($run)
                }
            }
            if ($candidates.Count -gt 1) {
                throw 'More than one unseen lifecycle workflow run matches this dispatch.'
            }
            if ($candidates.Count -eq 1) {
                $observedRunId = [long]$candidates[0].databaseId
            }
        }
        if ($null -ne $observedRunId) {
            $view = Invoke-External -Command 'gh' -Arguments @(
                'run', 'view', [string]$observedRunId, '--repo', $Repository,
                '--json', 'databaseId,displayTitle,headSha,status,conclusion,url'
            )
            try {
                $run = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
            }
            catch {
                throw 'GitHub CLI returned invalid workflow-run detail metadata.'
            }
            if ([long]$run.databaseId -ne [long]$observedRunId -or
                [string]$run.headSha -cne $HeadSha -or
                [string]$run.displayTitle -cne $expectedRunTitle) {
                throw 'The observed lifecycle workflow run no longer matches its dispatch identity.'
            }
            if ([string]$run.status -ceq 'completed') {
                if ([string]$run.conclusion -cne 'success') {
                    throw "The lifecycle workflow completed with '$($run.conclusion)': $($run.url)"
                }
                return $run
            }
        }
        Start-Sleep -Seconds 5
    }

    throw "The lifecycle workflow did not complete within $WorkflowTimeoutMinutes minute(s)."
}

function Get-ValidatedAdoptionMarker {
    param(
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [string]$ExpectedMarkerHead = ''
    )

    $requiredProperties = @(
        'number', 'url', 'isDraft', 'state', 'baseRefName', 'headRefName',
        'headRefOid', 'headRepository', 'headRepositoryOwner',
        'isCrossRepository', 'author', 'body'
    )
    foreach ($property in $requiredProperties) {
        if ($null -eq $PullRequest.PSObject.Properties[$property]) {
            throw "The deterministic adoption pull request is missing '$property' metadata."
        }
    }
    if ([string]$PullRequest.state -cne 'OPEN' -or
        [string]$PullRequest.baseRefName -cne $BaseBranch -or
        [string]$PullRequest.headRefName -cne $Branch -or
        [string]$PullRequest.headRefOid -cnotmatch '^[0-9a-f]{40}$' -or
        $PullRequest.isDraft -isnot [bool]) {
        throw 'The deterministic adoption pull request has invalid lifecycle metadata.'
    }
    $headRepositoryNameProperty = if ($null -ne $PullRequest.headRepository) {
        $PullRequest.headRepository.PSObject.Properties['name']
    }
    else { $null }
    $headRepositoryOwnerLoginProperty = if ($null -ne $PullRequest.headRepositoryOwner) {
        $PullRequest.headRepositoryOwner.PSObject.Properties['login']
    }
    else { $null }
    if ($PullRequest.isCrossRepository -isnot [bool] -or
        [bool]$PullRequest.isCrossRepository -or
        $null -eq $headRepositoryNameProperty -or
        $headRepositoryNameProperty.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$headRepositoryNameProperty.Value) -or
        $null -eq $headRepositoryOwnerLoginProperty -or
        $headRepositoryOwnerLoginProperty.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$headRepositoryOwnerLoginProperty.Value) -or
        -not ("$($headRepositoryOwnerLoginProperty.Value)/$($headRepositoryNameProperty.Value)").Equals(
            $Repository, [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The deterministic adoption pull request does not originate in the target repository.'
    }
    if ($null -eq $PullRequest.author -or
        $null -eq $PullRequest.author.PSObject.Properties['login'] -or
        -not ([string]$PullRequest.author.login).Equals(
            $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The deterministic adoption pull request author does not match the authenticated maintainer.'
    }
    if ([string]$PullRequest.number -cnotmatch '^[1-9][0-9]*$' -or
        [string]$PullRequest.url -cnotmatch "/pull/$([regex]::Escape([string]$PullRequest.number))/?$") {
        throw 'The deterministic adoption pull request has invalid identity metadata.'
    }

    $body = [string]$PullRequest.body
    $markerStarts = [regex]::Matches(
        $body, '<!--\s*meandai-capabilities-adoption:',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    $markerMatches = [regex]::Matches(
        $body, '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($markerStarts.Count -ne 1 -or $markerMatches.Count -ne 1) {
        throw 'The deterministic adoption pull request does not contain one canonical ownership marker.'
    }
    try {
        $marker = $markerMatches[0].Groups['json'].Value | ConvertFrom-Json
    }
    catch {
        throw 'The deterministic adoption pull request ownership marker is invalid JSON.'
    }
    $schemaProperty = $marker.PSObject.Properties['schema']
    if ($null -eq $schemaProperty -or
        ($schemaProperty.Value -isnot [int] -and
         $schemaProperty.Value -isnot [long])) {
        throw 'The deterministic adoption pull request ownership marker has an invalid schema type.'
    }
    $schema = [long]$schemaProperty.Value
    $expectedMarkerProperties = if ($schema -eq 2) {
        @('schema', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 3) {
        @('schema', 'phase', 'state', 'target', 'protocolSha', 'head', 'repository', 'actor')
    }
    elseif ($schema -eq 4) {
        @(
            'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
            'previousHead', 'plannedHead', 'repository', 'actor'
        )
    }
    else {
        throw 'The deterministic adoption pull request ownership marker uses an unsupported schema.'
    }
    $actualMarkerProperties = @($marker.PSObject.Properties | ForEach-Object { $_.Name })
    if ($actualMarkerProperties.Count -ne $expectedMarkerProperties.Count -or
        @($expectedMarkerProperties | Where-Object { $actualMarkerProperties -cnotcontains $_ }).Count -ne 0) {
        throw 'The deterministic adoption pull request ownership marker has an unexpected schema.'
    }
    $phase = if ($schema -eq 2) { 'Proposed' } else { [string]$marker.phase }
    if ($phase -cnotin @('Proposed', 'Publishing', 'Completed') -or
        [string]$marker.state -cnotin @('BootstrapReady', 'AdoptionReviewRequired') -or
        [string]$marker.target -cne $ProtocolTag -or
        [string]$marker.protocolSha -cnotmatch '^[0-9a-f]{40}$' -or
        -not ([string]$marker.repository).Equals($Repository, [StringComparison]::OrdinalIgnoreCase) -or
        -not ([string]$marker.actor).Equals($ExpectedActor, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The deterministic adoption pull request ownership marker does not match its live identity.'
    }
    if ($phase -ceq 'Publishing') {
        if ($schema -ne 4 -or
            [string]$marker.previousHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.plannedHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.previousHead -ceq [string]$marker.plannedHead -or
            [string]$marker.head -cne [string]$marker.previousHead -or
            ([string]$PullRequest.headRefOid -cne [string]$marker.previousHead -and
             [string]$PullRequest.headRefOid -cne [string]$marker.plannedHead) -or
            ($ExpectedMarkerHead -and
             [string]$marker.previousHead -cne $ExpectedMarkerHead)) {
            throw 'The deterministic adoption pull request publishing marker is inconsistent with its live transition.'
        }
    }
    else {
        if ($schema -eq 4) {
            throw 'The deterministic adoption pull request uses the publishing schema outside its publishing phase.'
        }
        $requiredMarkerHead = if ($ExpectedMarkerHead) {
            $ExpectedMarkerHead
        }
        else {
            [string]$PullRequest.headRefOid
        }
        if ($requiredMarkerHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.head -cne $requiredMarkerHead) {
            throw 'The deterministic adoption pull request marker head does not match the expected transition state.'
        }
    }
    if ($schema -eq 2) {
        $marker | Add-Member -NotePropertyName phase -NotePropertyValue 'Proposed' -Force
    }
    return $marker
}

function Get-AdoptionPullRequest {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$BaseBranch,
        [Parameter(Mandatory)][string]$ExpectedActor,
        [ValidateRange(1, 6)][int]$MaxAttempts = 6,
        [string]$ExpectedNumber = '',
        [string]$ExpectedUrl = '',
        [string]$ExpectedLiveHead = '',
        [string]$ExpectedMarkerHead = '',
        [string]$ExpectedBody,
        [object]$ExpectedDraft = $null
    )

    $branch = "automation/meandai-capabilities-$ProtocolTag"
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $list = Invoke-External -Command 'gh' -Arguments @(
            'pr', 'list', '--repo', $Repository, '--state', 'open', '--head', $branch,
            '--limit', '10', '--json',
            'number,url,isDraft,state,baseRefName,headRefName,headRefOid,headRepository,headRepositoryOwner,isCrossRepository,author,body'
        )
        try {
            $pullRequests = @(((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json))
        }
        catch {
            throw 'GitHub CLI returned invalid adoption pull-request metadata.'
        }
        $matchingPullRequests = @($pullRequests | Where-Object { $_.headRefName -ceq $branch })
        if ($matchingPullRequests.Count -eq 1) {
            $marker = Get-ValidatedAdoptionMarker -PullRequest $matchingPullRequests[0] `
                -Repository $Repository -Branch $branch -BaseBranch $BaseBranch `
                -ExpectedActor $ExpectedActor -ExpectedMarkerHead $ExpectedMarkerHead
            $pullRequest = $matchingPullRequests[0]
            if (($ExpectedNumber -and [string]$pullRequest.number -cne $ExpectedNumber) -or
                ($ExpectedUrl -and [string]$pullRequest.url -cne $ExpectedUrl) -or
                ($ExpectedLiveHead -and [string]$pullRequest.headRefOid -cne $ExpectedLiveHead) -or
                ($PSBoundParameters.ContainsKey('ExpectedBody') -and
                    [string]$pullRequest.body -cne $ExpectedBody) -or
                ($null -ne $ExpectedDraft -and
                    ($ExpectedDraft -isnot [bool] -or [bool]$pullRequest.isDraft -ne [bool]$ExpectedDraft))) {
                throw 'The deterministic adoption pull request changed outside the expected state transition.'
            }
            $pullRequest | Add-Member -NotePropertyName meAndAIMarker `
                -NotePropertyValue $marker -Force
            return $pullRequest
        }
        if ($matchingPullRequests.Count -gt 1) {
            throw 'More than one open deterministic adoption pull request was found.'
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds 5
        }
    }

    return $null
}

function Get-AdoptionPullRequestTrackingBody {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$IssueNumber
    )

    $trackingLine = "Tracking issue: #$IssueNumber"
    $trackingStarts = [regex]::Matches(
        $Body, '^[ \t]*Tracking[ \t]+issue[ \t]*:',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [Text.RegularExpressions.RegexOptions]::Multiline -bor
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $exactTrackingLines = [regex]::Matches(
        $Body, "^$([regex]::Escape($trackingLine))`r?$",
        [Text.RegularExpressions.RegexOptions]::Multiline -bor
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $closingReference = [regex]::Matches(
        $Body,
        '\b(?:close(?:s|d)?|fix(?:es|ed)?|resolve(?:s|d)?)\b[^\r\n]*#[1-9][0-9]*\b',
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($closingReference.Count -ne 0) {
        throw 'The adoption pull request contains a native issue-closing reference.'
    }
    if ($trackingStarts.Count -eq 1 -and $exactTrackingLines.Count -eq 1) {
        return [pscustomobject]@{ Body = $Body; Changed = $false }
    }
    if ($trackingStarts.Count -ne 0 -or $exactTrackingLines.Count -ne 0) {
        throw 'The adoption pull request contains duplicate or conflicting tracking-issue lines.'
    }

    $separator = if ([string]::IsNullOrEmpty($Body) -or
        $Body.EndsWith("`r`n`r`n", [StringComparison]::Ordinal) -or
        $Body.EndsWith("`n`n", [StringComparison]::Ordinal)) {
        ''
    }
    elseif ($Body.EndsWith("`n", [StringComparison]::Ordinal)) {
        [Environment]::NewLine
    }
    else {
        [Environment]::NewLine + [Environment]::NewLine
    }
    return [pscustomobject]@{
        Body = $Body + $separator + $trackingLine
        Changed = $true
    }
}

function Set-AdoptionPullRequestBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)][string]$FileName
    )

    $bodyPath = Join-Path $TemporaryDirectory $FileName
    [IO.File]::WriteAllText(
        $bodyPath, $Body, [Text.UTF8Encoding]::new($false)
    )
    Invoke-External -Command 'gh' -Arguments @(
        'pr', 'edit', [string]$PullRequest.number, '--repo', $Repository,
        '--body-file', $bodyPath
    ) | Out-Null
    return $Body
}

function Set-AdoptionPullRequestMarkerBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$MarkerJson,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)][string]$FileName,
        [ValidateRange(0, 2147483647)][int]$TrackingIssueNumber = 0
    )

    $body = [string]$PullRequest.body
    $matches = [regex]::Matches(
        $body, '<!-- meandai-capabilities-adoption:(?<json>\{[^\r\n]*\}) -->',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if ($matches.Count -ne 1) {
        throw 'The adoption marker cannot be updated because its canonical source is missing or ambiguous.'
    }
    $match = $matches[0]
    $replacement = "<!-- meandai-capabilities-adoption:$MarkerJson -->"
    $updatedBody = $body.Substring(0, $match.Index) + $replacement +
        $body.Substring($match.Index + $match.Length)
    if ($TrackingIssueNumber -gt 0) {
        $tracking = Get-AdoptionPullRequestTrackingBody -Body $updatedBody `
            -IssueNumber $TrackingIssueNumber
        $updatedBody = [string]$tracking.Body
    }
    return Set-AdoptionPullRequestBody -Repository $Repository `
        -PullRequest $PullRequest -Body $updatedBody `
        -TemporaryDirectory $TemporaryDirectory -FileName $FileName
}

function Set-AdoptionPullRequestPublishingMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$PlannedHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    if ($PreviousHead -cnotmatch '^[0-9a-f]{40}$' -or
        $PlannedHead -cnotmatch '^[0-9a-f]{40}$' -or
        $PreviousHead -ceq $PlannedHead) {
        throw 'The adoption publishing transition has invalid commit identities.'
    }
    $marker = $PullRequest.meAndAIMarker
    $publishingMarker = [ordered]@{
        schema = 4
        phase = 'Publishing'
        state = [string]$marker.state
        target = [string]$marker.target
        protocolSha = [string]$marker.protocolSha
        head = $PreviousHead
        previousHead = $PreviousHead
        plannedHead = $PlannedHead
        repository = [string]$marker.repository
        actor = [string]$marker.actor
    } | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $publishingMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'publishing-adoption-pr.md'
}

function Set-AdoptionPullRequestProposedMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    if ($PreviousHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The restored adoption proposal head is invalid.'
    }
    $marker = $PullRequest.meAndAIMarker
    $proposedMarker = [ordered]@{
        schema = 3
        phase = 'Proposed'
        state = [string]$marker.state
        target = [string]$marker.target
        protocolSha = [string]$marker.protocolSha
        head = $PreviousHead
        repository = [string]$marker.repository
        actor = [string]$marker.actor
    } | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $proposedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'proposed-adoption-pr.md'
}

function Set-AdoptionPullRequestCompletedMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PublishedHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$IssueNumber
    )

    if ($PublishedHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The completed adoption head is invalid.'
    }
    $marker = $PullRequest.meAndAIMarker
    $completedMarker = [ordered]@{
        schema = 3
        phase = 'Completed'
        state = [string]$marker.state
        target = [string]$marker.target
        protocolSha = [string]$marker.protocolSha
        head = $PublishedHead
        repository = [string]$marker.repository
        actor = [string]$marker.actor
    } | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $completedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'completed-adoption-pr.md' `
        -TrackingIssueNumber $IssueNumber
}

function Get-RevalidatedAdoptionPullRequest {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$OriginalPullRequest,
        [Parameter(Mandatory)][string]$LiveHead,
        [Parameter(Mandatory)][string]$MarkerHead,
        [Parameter(Mandatory)][string]$Body,
        [Parameter(Mandatory)][bool]$Draft
    )

    return Get-AdoptionPullRequest -Repository $Repository `
        -BaseBranch ([string]$OriginalPullRequest.baseRefName) `
        -ExpectedActor ([string]$OriginalPullRequest.meAndAIMarker.actor) `
        -MaxAttempts 1 -ExpectedNumber ([string]$OriginalPullRequest.number) `
        -ExpectedUrl ([string]$OriginalPullRequest.url) -ExpectedLiveHead $LiveHead `
        -ExpectedMarkerHead $MarkerHead -ExpectedBody $Body -ExpectedDraft $Draft
}

function Complete-AdoptionReviewTransition {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$PublishedHead,
        [Parameter(Mandatory)][string]$ExpectedMarkerHead,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)]$Issue,
        [switch]$PersistCompletedMarker
    )

    $issueNumberProperty = if ($null -ne $Issue) {
        $Issue.PSObject.Properties['number']
    }
    else { $null }
    if ($null -eq $issueNumberProperty -or
        [string]$issueNumberProperty.Value -cnotmatch '^[1-9][0-9]*$' -or
        [long]$issueNumberProperty.Value -gt [int]::MaxValue) {
        throw 'The canonical adoption issue has invalid identity metadata.'
    }
    $issueNumber = [int]$issueNumberProperty.Value
    $body = [string]$PullRequest.body
    $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
        -OriginalPullRequest $PullRequest -LiveHead $PublishedHead `
        -MarkerHead $ExpectedMarkerHead -Body $body `
        -Draft ([bool]$PullRequest.isDraft)
    if ($PersistCompletedMarker) {
        if (-not [bool]$current.isDraft) {
            throw 'The adoption proposal became ready before its completed marker was persisted.'
        }
        $body = Set-AdoptionPullRequestCompletedMarker -Repository $Repository `
            -PullRequest $current -PublishedHead $PublishedHead `
            -TemporaryDirectory $TemporaryDirectory -IssueNumber $issueNumber
        $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $current -LiveHead $PublishedHead `
            -MarkerHead $PublishedHead -Body $body -Draft $true
    }
    $tracking = Get-AdoptionPullRequestTrackingBody -Body $body `
        -IssueNumber $issueNumber
    if ([bool]$tracking.Changed) {
        $body = Set-AdoptionPullRequestBody -Repository $Repository `
            -PullRequest $current -Body ([string]$tracking.Body) `
            -TemporaryDirectory $TemporaryDirectory `
            -FileName 'tracked-adoption-pr.md'
        $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $current -LiveHead $PublishedHead `
            -MarkerHead $PublishedHead -Body $body `
            -Draft ([bool]$current.isDraft)
    }
    if ([bool]$current.isDraft) {
        Invoke-External -Command 'gh' -Arguments @(
            'pr', 'ready', [string]$current.number, '--repo', $Repository
        ) | Out-Null
        $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $current -LiveHead $PublishedHead `
            -MarkerHead $PublishedHead -Body $body -Draft $false
    }
    Set-AdoptionIssueReadyForReview -Repository $Repository -Issue $Issue
    return $current
}

function Ensure-AdoptionLabels {
    param([Parameter(Mandatory)][string]$Repository)

    $list = Invoke-External -Command 'gh' -Arguments @(
        'label', 'list', '--repo', $Repository, '--limit', '1000', '--json', 'name'
    )
    try {
        $parsed = ((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        $existing = @($parsed | Where-Object { $null -ne $_ })
    }
    catch {
        throw 'GitHub CLI returned invalid repository-label metadata.'
    }

    $names = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($label in $existing) {
        if ($null -eq $label.PSObject.Properties['name'] -or
            [string]::IsNullOrWhiteSpace([string]$label.name)) {
            throw 'GitHub CLI returned an invalid repository label.'
        }
        [void]$names.Add([string]$label.name)
    }

    foreach ($label in $adoptionLabels) {
        if ($names.Contains([string]$label.Name)) {
            continue
        }
        Invoke-External -Command 'gh' -Arguments @(
            'label', 'create', [string]$label.Name, '--repo', $Repository,
            '--color', [string]$label.Color, '--description', [string]$label.Description
        ) | Out-Null
        [void]$names.Add([string]$label.Name)
    }
}

function Get-AdoptionIssueInventory {
    param([Parameter(Mandatory)][string]$Repository)

    $list = Invoke-External -Command 'gh' -Arguments @(
        'issue', 'list', '--repo', $Repository, '--state', 'all', '--limit', '1000',
        '--json', 'number,url,title,body,state'
    )
    try {
        $parsed = ((@($list.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        return @($parsed | Where-Object { $null -ne $_ })
    }
    catch {
        throw 'GitHub CLI returned invalid adoption-issue metadata.'
    }
}

function Get-MarkedAdoptionIssues {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Issues,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$ExpectedTitle,
        [Parameter(Mandatory)][string]$ExpectedBody
    )

    $numbers = [System.Collections.Generic.HashSet[int]]::new()
    $canonicalMarkerPattern = '\A' + [regex]::Escape($Marker) + '(?:\r?\n|\z)'
    $ownershipPrefix = $Marker.Substring(0, $Marker.Length - ' -->'.Length)
    $matching = [System.Collections.Generic.List[object]]::new()
    $normalizedExpectedBody = $ExpectedBody.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    foreach ($issue in $Issues) {
        if ($null -eq $issue.PSObject.Properties['body']) {
            continue
        }
        $body = [string]$issue.body
        $hasOwnedPrefix = $body.StartsWith(
            $ownershipPrefix, [StringComparison]::OrdinalIgnoreCase
        )
        $canonicalLines = [regex]::Matches(
            $body,
            '(?m)^' + [regex]::Escape($Marker) + '\r?$'
        )
        if (-not [regex]::IsMatch($body, $canonicalMarkerPattern)) {
            if ($hasOwnedPrefix) {
                throw 'A project-owned adoption issue contains a malformed ownership marker; manual review is required.'
            }
            continue
        }
        foreach ($property in @('number', 'url', 'title', 'body', 'state')) {
            if ($null -eq $issue.PSObject.Properties[$property]) {
                throw 'A project-owned adoption issue has incomplete identity metadata.'
            }
        }
        $normalizedBody = $body.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
        if ($canonicalLines.Count -ne 1 -or
            [string]$issue.title -cne $ExpectedTitle -or
            $normalizedBody -cne $normalizedExpectedBody) {
            throw 'A canonically marked adoption issue has drifted from its exact owned record; manual review is required.'
        }
        if ([string]$issue.number -cnotmatch '^[1-9][0-9]*$' -or
            [string]$issue.url -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$' -or
            [string]$issue.state -cnotin @('OPEN', 'CLOSED') -or
            -not $numbers.Add([int]$issue.number)) {
            throw 'A project-owned adoption issue has invalid or duplicate identity metadata.'
        }
        $matching.Add($issue)
    }
    return @($matching | Sort-Object { [int]$_.number })
}

function Ensure-AdoptionIssue {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    $marker = '<!-- meandai-local-adoption:{0}:pr-{1} -->' -f `
        $ProtocolTag, [string]$PullRequest.number
    $issueTitle = "Track meAndAI AI capabilities adoption from $ProtocolTag"
    $issueBody = @(
        $marker,
        '## AI capabilities adoption tracking',
        '',
        "- Protocol release: ``$ProtocolTag``",
        "- Adoption draft: $($PullRequest.url)",
        '',
        'This issue tracks the project-owned feature and decision records, local memory, tests, evidence, links, and maintainer review required to complete the transient adoption manifest.',
        '',
        'The launcher may prepare the draft and mark it ready after bounded local validation; only the maintainer may merge it.'
    ) -join [Environment]::NewLine
    $completed = [string]$PullRequest.meAndAIMarker.phase -ceq 'Completed'
    $desiredStatusLabel = if ($completed) {
        'status:needs-review'
    }
    else { 'status:in-progress' }
    $supersededStatusLabel = if ($completed) {
        'status:in-progress'
    }
    else { 'status:needs-review' }
    $matchingIssues = @(Get-MarkedAdoptionIssues `
        -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody)

    if ($matchingIssues.Count -eq 0) {
        $bodyPath = Join-Path $TemporaryDirectory 'adoption-issue.md'
        [IO.File]::WriteAllText(
            $bodyPath, $issueBody + [Environment]::NewLine,
            [Text.UTF8Encoding]::new($false)
        )
        $created = Invoke-External -Command 'gh' -Arguments @(
            'issue', 'create', '--repo', $Repository,
            '--title', $issueTitle,
            '--body-file', $bodyPath,
            '--label', 'type:feature', '--label', 'priority:p1',
            '--label', $desiredStatusLabel
        )
        $createdUrl = ((@($created.Output) -join [Environment]::NewLine).Trim())
        if ($createdUrl -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$') {
            throw 'Created adoption issue returned an unrecognized URL.'
        }
        $matchingIssues = @(Get-MarkedAdoptionIssues `
            -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
            -ExpectedTitle $issueTitle -ExpectedBody $issueBody)
    }

    if ($matchingIssues.Count -eq 0) {
        throw 'The created adoption issue was not observable during convergence.'
    }
    $canonicalNumber = [int]$matchingIssues[0].number
    if ([string]$matchingIssues[0].state -ceq 'CLOSED') {
        Invoke-External -Command 'gh' -Arguments @(
            'issue', 'reopen', [string]$canonicalNumber, '--repo', $Repository
        ) | Out-Null
    }
    foreach ($duplicate in @($matchingIssues | Select-Object -Skip 1)) {
        if ([string]$duplicate.state -ceq 'OPEN') {
            Invoke-External -Command 'gh' -Arguments @(
                'issue', 'close', [string]$duplicate.number, '--repo', $Repository
            ) | Out-Null
        }
    }

    $converged = @(Get-MarkedAdoptionIssues `
        -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody |
        Where-Object { [string]$_.state -ceq 'OPEN' })
    if ($converged.Count -ne 1 -or [int]$converged[0].number -ne $canonicalNumber) {
        throw 'Project-owned adoption issues did not converge to one canonical open identity.'
    }
    Invoke-External -Command 'gh' -Arguments @(
        'issue', 'edit', [string]$canonicalNumber, '--repo', $Repository,
        '--add-label', 'type:feature', '--add-label', 'priority:p1',
        '--add-label', $desiredStatusLabel,
        '--remove-label', $supersededStatusLabel
    ) | Out-Null
    return $converged[0]
}

function Set-AdoptionIssueReadyForReview {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Issue
    )

    Invoke-External -Command 'gh' -Arguments @(
        'issue', 'edit', [string]$Issue.number, '--repo', $Repository,
        '--remove-label', 'status:in-progress',
        '--add-label', 'status:needs-review'
    ) | Out-Null
}

function ConvertTo-ProcessArgument {
    param([AllowEmptyString()][Parameter(Mandatory)][string]$Value)

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }
    $builder = [Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            [void]$builder.Append(('\' * (($backslashes * 2) + 1)))
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void]$builder.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashes -gt 0) {
        [void]$builder.Append(('\' * ($backslashes * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function New-ExternalProcessRunner {
    param(
        [Parameter(Mandatory)]$CommandInfo,
        [string[]]$PrefixArguments = @(),
        [Parameter(Mandatory)][string]$Description
    )

    if ($CommandInfo.CommandType -eq [Management.Automation.CommandTypes]::Application) {
        $extension = [IO.Path]::GetExtension([string]$CommandInfo.Source)
        if ($extension -in @('.cmd', '.bat')) {
            if ($env:OS -cne 'Windows_NT' -or -not $env:ComSpec) {
                throw "The $Description resolved to a Windows command wrapper on a non-Windows host."
            }
            return [pscustomobject]@{
                Command = [string]$env:ComSpec
                PrefixArguments = @('/d', '/c', 'call', [string]$CommandInfo.Source) + @($PrefixArguments)
                Description = $Description
            }
        }
        return [pscustomobject]@{
            Command = [string]$CommandInfo.Source
            PrefixArguments = @($PrefixArguments)
            Description = $Description
        }
    }
    throw "The $Description must resolve to a native executable or command wrapper."
}

function Resolve-LocalCodexRunner {
    param(
        [string]$ExplicitCommand,
        [Parameter(Mandatory)][string]$FallbackVersion
    )

    if ($FallbackVersion -cnotmatch '^\d+\.\d+\.\d+$') {
        throw 'TemporaryCodexVersion must use the M.m.rev form.'
    }

    $installedName = if ($ExplicitCommand) { $ExplicitCommand } else { 'codex' }
    $installed = @(Get-Command $installedName -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq [Management.Automation.CommandTypes]::Application } |
        Select-Object -First 1)
    if ($installed.Count -eq 1) {
        return New-ExternalProcessRunner -CommandInfo $installed[0] `
            -Description 'installed local Codex CLI'
    }

    if ($ExplicitCommand) {
        throw "The explicitly selected Codex command '$ExplicitCommand' is not available."
    }

    $npxCandidates = @(Get-Command 'npx' -All -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandType -eq [Management.Automation.CommandTypes]::Application })
    $npx = if ($env:OS -eq 'Windows_NT') {
        @($npxCandidates | Where-Object { [IO.Path]::GetExtension([string]$_.Source) -ieq '.cmd' } |
            Select-Object -First 1)
    }
    else {
        @($npxCandidates | Select-Object -First 1)
    }
    if ($npx.Count -eq 1) {
        return New-ExternalProcessRunner -CommandInfo $npx[0] `
            -PrefixArguments @('-y', "@openai/codex@$FallbackVersion") `
            -Description "temporary @openai/codex@$FallbackVersion through npx"
    }

    throw 'Codex CLI is not installed and npx is unavailable for the pinned temporary fallback.'
}

function New-ExternalProcessContainment {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    if ($env:OS -cne 'Windows_NT') {
        return $null
    }
    $typeName = 'MeAndAI.QuickAdoption.ProcessJob'
    if ($null -eq ($typeName -as [type])) {
        try {
            Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace MeAndAI.QuickAdoption
{
    public sealed class ProcessJob : IDisposable
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct BasicLimits
        {
            public long PerProcessUserTimeLimit;
            public long PerJobUserTimeLimit;
            public uint LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public uint ActiveProcessLimit;
            public UIntPtr Affinity;
            public uint PriorityClass;
            public uint SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IoCounters
        {
            public ulong ReadOperationCount;
            public ulong WriteOperationCount;
            public ulong OtherOperationCount;
            public ulong ReadTransferCount;
            public ulong WriteTransferCount;
            public ulong OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct ExtendedLimits
        {
            public BasicLimits BasicLimitInformation;
            public IoCounters IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        private static extern IntPtr CreateJobObject(IntPtr attributes, string name);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetInformationJobObject(
            IntPtr job, int informationClass, IntPtr information, uint length);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);

        [DllImport("kernel32.dll")]
        private static extern bool CloseHandle(IntPtr handle);

        private IntPtr handle;

        private ProcessJob(IntPtr jobHandle)
        {
            handle = jobHandle;
        }

        public static ProcessJob TryCreate(Process process)
        {
            const uint KillOnJobClose = 0x00002000;
            const int ExtendedLimitInformation = 9;
            IntPtr job = CreateJobObject(IntPtr.Zero, null);
            if (job == IntPtr.Zero) return null;

            ExtendedLimits limits = new ExtendedLimits();
            limits.BasicLimitInformation.LimitFlags = KillOnJobClose;
            int size = Marshal.SizeOf(typeof(ExtendedLimits));
            IntPtr buffer = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(limits, buffer, false);
                if (!SetInformationJobObject(job, ExtendedLimitInformation, buffer, (uint)size) ||
                    !AssignProcessToJobObject(job, process.Handle))
                {
                    CloseHandle(job);
                    return null;
                }
                return new ProcessJob(job);
            }
            finally
            {
                Marshal.FreeHGlobal(buffer);
            }
        }

        public void Dispose()
        {
            IntPtr owned = handle;
            handle = IntPtr.Zero;
            if (owned != IntPtr.Zero) CloseHandle(owned);
        }
    }
}
'@ -ErrorAction Stop
        }
        catch {
            return $null
        }
    }
    try {
        return [MeAndAI.QuickAdoption.ProcessJob]::TryCreate($Process)
    }
    catch {
        return $null
    }
}

function Stop-ExternalProcessTree {
    param([Parameter(Mandatory)][Diagnostics.Process]$Process)

    try {
        if ($Process.HasExited) {
            return $true
        }
    }
    catch {
        return $false
    }

    $killTreeMethod = $Process.GetType().GetMethod(
        'Kill',
        [type[]]@([bool])
    )
    if ($null -ne $killTreeMethod) {
        try {
            [void]$killTreeMethod.Invoke($Process, [object[]]@($true))
        }
        catch { }
    }
    else {
        $descendants = [System.Collections.Generic.List[Diagnostics.Process]]::new()
        if ($env:OS -ceq 'Windows_NT') {
            $searcher = $null
            $records = $null
            try {
                $searcher = [System.Management.ManagementObjectSearcher]::new(
                    'SELECT ProcessId, ParentProcessId FROM Win32_Process'
                )
                $records = $searcher.Get()
                $childrenByParent = @{}
                foreach ($record in $records) {
                    $parentId = [int][uint32]$record.ParentProcessId
                    $processId = [int][uint32]$record.ProcessId
                    if (-not $childrenByParent.ContainsKey($parentId)) {
                        $childrenByParent[$parentId] = `
                            [System.Collections.Generic.List[int]]::new()
                    }
                    $childrenByParent[$parentId].Add($processId)
                }
                $pending = [System.Collections.Generic.Stack[int]]::new()
                $visited = [System.Collections.Generic.HashSet[int]]::new()
                $pending.Push($Process.Id)
                [void]$visited.Add($Process.Id)
                while ($pending.Count -gt 0) {
                    $parentId = $pending.Pop()
                    if (-not $childrenByParent.ContainsKey($parentId)) {
                        continue
                    }
                    foreach ($childId in $childrenByParent[$parentId]) {
                        if (-not $visited.Add($childId)) {
                            continue
                        }
                        try {
                            $child = [Diagnostics.Process]::GetProcessById($childId)
                            $descendants.Add($child)
                            $pending.Push($childId)
                        }
                        catch { }
                    }
                }
            }
            catch { }
            finally {
                if ($null -ne $records) { $records.Dispose() }
                if ($null -ne $searcher) { $searcher.Dispose() }
            }
        }

        try { $Process.Kill() } catch { }
        for ($index = $descendants.Count - 1; $index -ge 0; $index--) {
            try {
                if (-not $descendants[$index].HasExited) {
                    $descendants[$index].Kill()
                }
            }
            catch { }
        }
        foreach ($descendant in $descendants) {
            try { [void]$descendant.WaitForExit(5000) } catch { }
            finally { $descendant.Dispose() }
        }
    }

    try {
        [void]$Process.WaitForExit(5000)
        return $Process.HasExited
    }
    catch {
        return $false
    }
}

function Invoke-BoundedProcess {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string[]]$Arguments,
        [AllowEmptyString()][string]$StandardInput = '',
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription,
        [Parameter(Mandatory)][string]$Operation,
        [string]$ProgressActivity = '',
        [scriptblock]$OutputLineHandler = $null,
        [switch]$RequireProcessTreeContainment
    )

    $allArguments = @($Runner.PrefixArguments) + @($Arguments)
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$Runner.Command
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $argumentListProperty = $startInfo.GetType().GetProperty('ArgumentList')
    if ($null -ne $argumentListProperty) {
        $nativeArgumentList = $argumentListProperty.GetValue($startInfo, $null)
        foreach ($argument in $allArguments) {
            [void]$nativeArgumentList.Add([string]$argument)
        }
    }
    else {
        $startInfo.Arguments = (@($allArguments | ForEach-Object {
            ConvertTo-ProcessArgument -Value ([string]$_)
        }) -join ' ')
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $processStarted = $false
    $processContainment = $null
    try {
        if (-not $process.Start()) {
            throw "Unable to start $Operation."
        }
        $processStarted = $true
        $processContainment = New-ExternalProcessContainment -Process $process
        if ($RequireProcessTreeContainment -and $env:OS -ceq 'Windows_NT' -and
            $null -eq $processContainment) {
            [void](Stop-ExternalProcessTree -Process $process)
            throw "Unable to establish kill-on-close process-tree containment for $Operation."
        }
        $stdoutLines = [System.Collections.Generic.List[string]]::new()
        $stdoutReadTask = $process.StandardOutput.ReadLineAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if ($StandardInput) {
            $process.StandardInput.Write($StandardInput)
        }
        $process.StandardInput.Close()
        $completed = $false
        $stopwatch = [Diagnostics.Stopwatch]::StartNew()
        $nextHeartbeatMilliseconds = 15000
        while (-not $completed -and $stopwatch.ElapsedMilliseconds -lt $TimeoutMilliseconds) {
            while ($null -ne $stdoutReadTask -and $stdoutReadTask.IsCompleted) {
                $line = $stdoutReadTask.GetAwaiter().GetResult()
                if ($null -eq $line) {
                    $stdoutReadTask = $null
                    break
                }
                $stdoutLines.Add([string]$line)
                if ($null -ne $OutputLineHandler) {
                    [void](& $OutputLineHandler ([string]$line))
                }
                $stdoutReadTask = $process.StandardOutput.ReadLineAsync()
            }
            $remaining = [int][Math]::Max(
                1,
                [Math]::Min(200, $TimeoutMilliseconds - $stopwatch.ElapsedMilliseconds)
            )
            $completed = $process.WaitForExit($remaining)
            if (-not $completed -and $ProgressActivity -and
                $stopwatch.ElapsedMilliseconds -ge $nextHeartbeatMilliseconds) {
                $elapsed = [Math]::Floor($stopwatch.Elapsed.TotalSeconds)
                Set-QuickAdoptionChildProgress -Activity $ProgressActivity `
                    -Status "Elapsed: $elapsed second(s); limit: $TimeoutDescription"
                $nextHeartbeatMilliseconds += 15000
            }
        }
        $stopwatch.Stop()
        if (-not $completed) {
            $terminationConfirmed = Stop-ExternalProcessTree -Process $process
            if (-not $terminationConfirmed) {
                throw "$Operation exceeded the $TimeoutDescription limit, and process-tree termination could not be confirmed."
            }
            throw "$Operation exceeded the $TimeoutDescription limit and was terminated."
        }
        $process.WaitForExit()
        while ($null -ne $stdoutReadTask) {
            $line = $stdoutReadTask.GetAwaiter().GetResult()
            if ($null -eq $line) {
                $stdoutReadTask = $null
                break
            }
            $stdoutLines.Add([string]$line)
            if ($null -ne $OutputLineHandler) {
                [void](& $OutputLineHandler ([string]$line))
            }
            $stdoutReadTask = $process.StandardOutput.ReadLineAsync()
        }
        return [pscustomobject]@{
            ExitCode = [int]$process.ExitCode
            StdOut = [string](@($stdoutLines) -join [Environment]::NewLine)
            StdErr = [string]$stderrTask.GetAwaiter().GetResult()
        }
    }
    finally {
        if ($null -ne $processContainment) {
            try { $processContainment.Dispose() } catch { }
            $processContainment = $null
        }
        if ($processStarted) {
            $stillRunning = $false
            try { $stillRunning = -not $process.HasExited } catch { }
            if ($stillRunning -and
                -not (Stop-ExternalProcessTree -Process $process)) {
                Write-Warning "$Operation was interrupted, but child-process-tree termination could not be confirmed."
            }
        }
        if ($ProgressActivity) {
            Complete-QuickAdoptionChildProgress
        }
        $process.Dispose()
    }
}

function Get-ProcessFailureDetail {
    param([Parameter(Mandatory)]$Result)

    $detail = (@($Result.StdOut, $Result.StdErr) -join [Environment]::NewLine).Trim()
    if ($detail.Length -gt 1200) {
        $detail = $detail.Substring(0, 1200) + '...'
    }
    return $detail
}

function Get-LocalCodexFailureDetail {
    param([Parameter(Mandatory)]$Result)

    $details = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($line in @([string]$Result.StdOut -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        try { $event = $line | ConvertFrom-Json -ErrorAction Stop }
        catch { continue }
        $eventType = [string](Get-QuickAdoptionObjectProperty `
            -InputObject $event -Name 'type')
        $message = ''
        if ($eventType -ceq 'error') {
            $message = [string](Get-QuickAdoptionObjectProperty `
                -InputObject $event -Name 'message')
        }
        elseif ($eventType -ceq 'turn.failed') {
            $errorValue = Get-QuickAdoptionObjectProperty -InputObject $event -Name 'error'
            $message = if ($errorValue -is [string]) {
                [string]$errorValue
            }
            else {
                [string](Get-QuickAdoptionObjectProperty `
                    -InputObject $errorValue -Name 'message')
            }
        }
        elseif ($eventType -ceq 'item.completed') {
            $item = Get-QuickAdoptionObjectProperty -InputObject $event -Name 'item'
            if ([string](Get-QuickAdoptionObjectProperty `
                -InputObject $item -Name 'type') -ceq 'agent_message') {
                $message = [string](Get-QuickAdoptionObjectProperty `
                    -InputObject $item -Name 'text')
            }
        }
        $message = ConvertTo-QuickAdoptionDisplayText -Value $message -MaximumLength 300
        if ($message -and $seen.Add($message)) {
            $details.Add($message)
        }
    }

    $stderr = ConvertTo-QuickAdoptionDisplayText `
        -Value ([string]$Result.StdErr) -MaximumLength 600
    if ($stderr -and $seen.Add($stderr)) {
        $details.Add($stderr)
    }
    $detail = (@($details) -join ' | ').Trim()
    if (-not $detail) {
        return 'No structured error detail was emitted.'
    }
    if ($detail.Length -gt 1200) {
        return $detail.Substring(0, 1197) + '...'
    }
    return $detail
}

function Assert-LocalCodexLogin {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments @('login', 'status') `
        -TimeoutMilliseconds $TimeoutMilliseconds `
        -TimeoutDescription $TimeoutDescription `
        -Operation 'Local Codex authentication check'
    if ($result.ExitCode -ne 0) {
        $detail = Get-ProcessFailureDetail -Result $result
        throw "Local Codex authentication check failed with code $($result.ExitCode). $detail"
    }
}

function Get-ConfiguredWindowsSandboxMode {
    if ($env:OS -cne 'Windows_NT') {
        return ''
    }

    $codexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
    if ([string]::IsNullOrWhiteSpace($codexHome)) {
        $userProfile = [Environment]::GetFolderPath(
            [Environment+SpecialFolder]::UserProfile
        )
        $codexHome = Join-Path $userProfile '.codex'
    }
    $configPath = Join-Path $codexHome 'config.toml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return 'elevated'
    }

    $insideWindowsSection = $false
    $values = [System.Collections.Generic.List[string]]::new()
    foreach ($rawLine in [IO.File]::ReadAllLines($configPath)) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#', [StringComparison]::Ordinal)) {
            continue
        }
        $section = [regex]::Match($line, '^\[(?<name>[^\]]+)\]\s*(?:#.*)?$')
        if ($section.Success) {
            $insideWindowsSection = $section.Groups['name'].Value.Trim() -ceq 'windows'
            continue
        }
        if (-not $insideWindowsSection) {
            continue
        }
        $sandbox = [regex]::Match(
            $line,
            '^sandbox\s*=\s*[\"''](?<value>[^\"'']+)[\"'']\s*(?:#.*)?$'
        )
        if ($sandbox.Success) {
            $values.Add($sandbox.Groups['value'].Value)
            continue
        }
        if ($line -match '^sandbox\s*=') {
            throw "Codex config '$configPath' contains an invalid [windows].sandbox value."
        }
    }

    if ($values.Count -eq 0) {
        return 'elevated'
    }
    if ($values.Count -ne 1 -or $values[0] -cnotin @('elevated', 'unelevated')) {
        throw "Codex config '$configPath' must contain at most one supported [windows].sandbox value."
    }
    return $values[0]
}

function Assert-LocalCodexWorkspaceWrite {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds
    )

    if ($env:OS -cne 'Windows_NT') {
        return ''
    }

    $preferredMode = Get-ConfiguredWindowsSandboxMode
    $candidateModes = if ($preferredMode -ceq 'elevated') {
        @('elevated', 'unelevated')
    }
    else {
        @('unelevated')
    }
    $probeTimeout = [int][Math]::Min($TimeoutMilliseconds, 60000)
    $probeTimeoutDescription = "$([Math]::Ceiling($probeTimeout / 1000.0)) second(s)"
    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($mode in $candidateModes) {
        $probeName = ".meandai-codex-sandbox-probe-$([guid]::NewGuid().ToString('N')).tmp"
        $probePath = Join-Path $WorkingDirectory $probeName
        $probeScript = @(
            '$ErrorActionPreference = ''Stop'''
            '$probe = Join-Path (Get-Location).Path ''__MEANDAI_PROBE_NAME__'''
            '[IO.File]::WriteAllText($probe, ''meandai-workspace-write-probe'', [Text.UTF8Encoding]::new($false))'
            'if ([IO.File]::ReadAllText($probe) -cne ''meandai-workspace-write-probe'') { throw ''probe verification failed'' }'
            '[IO.File]::Delete($probe)'
        ) -join '; '
        $probeScript = $probeScript.Replace('__MEANDAI_PROBE_NAME__', $probeName)
        $result = $null
        try {
            $result = Invoke-BoundedProcess -Runner $Runner -Arguments @(
                'sandbox', '--config', "windows.sandbox=`"$mode`"",
                '-P', ':workspace', '-C', $WorkingDirectory,
                'powershell.exe', '-NoProfile', '-NonInteractive',
                '-Command', $probeScript
            ) -TimeoutMilliseconds $probeTimeout `
                -TimeoutDescription $probeTimeoutDescription `
                -Operation "Local Codex $mode Windows sandbox workspace-write preflight"
        }
        catch {
            $failures.Add("${mode}: $($_.Exception.Message)")
        }

        $residue = Test-Path -LiteralPath $probePath
        if ($residue) {
            Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
        }
        if ($null -ne $result -and $result.ExitCode -eq 0 -and -not $residue) {
            if ($mode -cne $preferredMode) {
                Write-Warning "Local Codex '$preferredMode' Windows sandbox failed its token-free workspace-write preflight; using '$mode' for this run."
            }
            Write-Host "Local Codex sandbox preflight succeeded with Windows '$mode' mode."
            return $mode
        }
        if ($null -ne $result) {
            $detail = Get-ProcessFailureDetail -Result $result
            if ($residue) {
                $detail = "Sandbox left its probe file behind. $detail".Trim()
            }
            $failures.Add("${mode}: exit $($result.ExitCode). $detail".Trim())
        }
    }

    $failureText = (@($failures) -join ' | ')
    throw "Local Codex cannot write inside its native Windows workspace sandbox; semantic adoption was not started. Verify the Codex [windows].sandbox configuration or run Codex sandbox setup, then rerun. $failureText"
}

function Invoke-LocalCodexExec {
    param(
        [Parameter(Mandatory)]$Runner,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][int]$TimeoutMilliseconds,
        [Parameter(Mandatory)][string]$TimeoutDescription,
        [string]$WindowsSandboxMode = ''
    )

    # codex exec receives the scoped prompt through stdin and is bounded by the launcher.
    $arguments = @(
        'exec',
        '--ephemeral',
        '--ignore-user-config',
        '--sandbox', 'workspace-write',
        '--config', 'approval_policy="never"',
        '--config', 'sandbox_workspace_write.network_access=false',
        '--config', 'shell_environment_policy.inherit="core"'
    )
    if ($WindowsSandboxMode) {
        $arguments += @('--config', "windows.sandbox=`"$WindowsSandboxMode`"")
    }
    $arguments += @(
        '--cd', $WorkingDirectory,
        '--json',
        '--output-last-message', $OutputPath,
        '-'
    )

    $result = Invoke-BoundedProcess -Runner $Runner -Arguments $arguments `
        -StandardInput $Prompt -TimeoutMilliseconds $TimeoutMilliseconds `
        -TimeoutDescription $TimeoutDescription `
        -Operation 'Local Codex adoption execution' `
        -ProgressActivity 'Running local Codex' `
        -RequireProcessTreeContainment `
        -OutputLineHandler {
            param([string]$Line)
            Write-LocalCodexEvent -Line $Line
        }
    if ($result.ExitCode -ne 0) {
        $detail = Get-LocalCodexFailureDetail -Result $result
        throw "Local Codex exited with code $($result.ExitCode). $detail"
    }
}

function Get-ProtocolSourceSnapshot {
    param(
        [string]$Token = '',
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][string]$Destination
    )

    if ($Commit -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest contains an invalid protocol commit.'
    }
    $sourceRoot = $null
    if ($Token) {
        $archivePath = Join-Path $Destination 'protocol-source.zip'
        $extractPath = Join-Path $Destination 'protocol-source'
        [IO.Directory]::CreateDirectory($extractPath) | Out-Null
        $headers = @{
            Accept = 'application/vnd.github+json'
            Authorization = "Bearer $Token"
            'X-GitHub-Api-Version' = '2026-03-10'
            'User-Agent' = 'meAndAI-quick-adoption'
        }
        $uri = "https://api.github.com/repos/$ProtocolRepository/zipball/$Commit"
        try {
            Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers $headers -OutFile $archivePath
            Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force
        }
        catch {
            throw 'Unable to download the exact protocol source snapshot required for semantic adoption.'
        }

        $roots = @(Get-ChildItem -LiteralPath $extractPath -Directory)
        if ($roots.Count -eq 1) {
            $sourceRoot = $roots[0].FullName
        }
    }
    else {
        $sourceRoot = Join-Path $Destination 'protocol-source'
        try {
            Invoke-External -Command 'gh' -Arguments @(
                'repo', 'clone', $ProtocolRepository, $sourceRoot, '--',
                '--branch', $ProtocolTag, '--single-branch', '--depth', '1'
            ) | Out-Null
            $resolvedCommit = ((@(Invoke-Git -Repository $sourceRoot -Arguments @(
                'rev-parse', 'HEAD'
            )).Output -join '').Trim())
        }
        catch {
            throw 'Unable to clone the exact protocol source snapshot through the authenticated local GitHub CLI.'
        }
        if ($resolvedCommit -cne $Commit) {
            throw 'The authenticated protocol source snapshot does not match the adoption manifest commit.'
        }
    }

    if (-not $sourceRoot -or
        -not (Test-Path -LiteralPath (Join-Path $sourceRoot 'PROTOCOL.md') -PathType Leaf)) {
        throw 'The exact protocol source snapshot has an unexpected structure.'
    }
    $versionPath = Join-Path $sourceRoot 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf) -or
        [IO.File]::ReadAllText($versionPath).Trim() -cne $ProtocolTag.Substring(1)) {
        throw 'The protocol source snapshot version does not match the requested tag.'
    }
    return $sourceRoot
}

function Assert-CredentialFilesAbsent {
    param([Parameter(Mandatory)][string]$Repository)

    $files = @(Get-ChildItem -LiteralPath $Repository -Recurse -Force -File)
    foreach ($name in $tokenMappings.Keys) {
        $matches = @($files | Where-Object {
            ([string]$_.Name).Equals($name, [StringComparison]::OrdinalIgnoreCase)
        })
        if ($matches.Count -gt 0) {
            throw "Credential file '$name' must not exist in the isolated Codex clone."
        }
    }
}

function Assert-AdoptionProtocolReference {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    $protocolIndex = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'ls-files', '--stage', '--', '.ai/protocol'
    )).Output -join '').Trim())
    $expectedProtocolIndex = "160000 $ProtocolSha 0`t.ai/protocol"
    if ($protocolIndex -cne $expectedProtocolIndex) {
        throw 'The completed protocol reference is not the exact manifest gitlink.'
    }

    $gitmodulesPath = Join-Path $Repository '.gitmodules'
    $protocolModulePath = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.path'
    )).Output -join '').Trim())
    $protocolModuleUrl = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.url'
    )).Output -join '').Trim())
    if ($protocolModulePath -cne '.ai/protocol' -or
        $protocolModuleUrl -cne "https://github.com/$ProtocolRepository.git") {
        throw 'The completed protocol submodule metadata is not canonical.'
    }
}

function Get-ValidatedAdoptionManifest {
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProposalRepository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string]$CanonicalBaseHead
    )

    try {
        $manifest = [IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json
    }
    catch {
        throw 'The adoption manifest is not valid JSON.'
    }
    if ([string]$PullRequest.meAndAIMarker.protocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest does not match the pull-request ownership marker.'
    }

    $modulePath = Join-Path $ProtocolSource `
        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw 'The exact protocol source is missing its capabilities contract module.'
    }
    $modules = @(Import-Module -Name $modulePath -Force -PassThru)
    if ($modules.Count -ne 1) {
        throw 'The exact protocol capabilities contract module could not be loaded unambiguously.'
    }
    $module = $modules[0]
    try {
        $validators = @(Get-Command -Name 'Test-MeAndAIExactAdoptionManifest' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $resolvers = @(Get-Command -Name 'Resolve-MeAndAICapabilitiesLifecycle' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $targetPathGetters = @(Get-Command -Name 'Get-MeAndAIAdoptionTargetPaths' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        if ($validators.Count -ne 1 -or $resolvers.Count -ne 1 -or
            $targetPathGetters.Count -ne 1) {
            throw 'The exact protocol capabilities contract does not export one path getter, resolver, and manifest validator.'
        }
        $targetPathGetter = $targetPathGetters[0]
        $targetPaths = @(& $targetPathGetter)
        $contract = Get-ExpectedAdoptionManifestContract `
            -Repository $ProposalRepository -ProposalHead $ProposalHead `
            -TargetPaths $targetPaths
        if ($null -eq $workflowBytes) {
            throw 'The independently verified canonical seed workflow bytes are unavailable.'
        }
        $sourceWorkflowSha = Get-GitBlobSha -Bytes ([byte[]]$workflowBytes)
        $baseWorkflowEntry = Get-AdoptionTreeEntry -Repository $ProposalRepository `
            -Commit ([string]$contract.BaseHead) -Path $workflowTargetPath
        $seedWorkflowState = if ($baseWorkflowEntry.Mode -ceq '100644' -and
            $baseWorkflowEntry.Type -ceq 'blob' -and
            $baseWorkflowEntry.Sha -ceq $sourceWorkflowSha) {
            'Exact'
        }
        elseif (-not $baseWorkflowEntry.Path) { 'Missing' }
        else { 'Drifted' }
        $resolver = $resolvers[0]
        $plan = & $resolver -Snapshot ([pscustomobject]@{
            SchemaVersion = 1
            LocalUpdaterState = [string]$contract.LocalUpdaterState
            SeedWorkflowState = $seedWorkflowState
            Collisions = @($contract.Collisions)
            ManifestExists = $false
            RemoteBranchExists = $false
            OpenPullRequestCount = 0
            ExistingProposalValid = $false
        })
        if ($null -eq $plan -or
            [string]$plan.State -cnotin @('BootstrapReady', 'AdoptionReviewRequired') -or
            [string]$PullRequest.meAndAIMarker.state -cne [string]$plan.State) {
            throw 'The adoption proposal is not permitted by the independently derived lifecycle contract.'
        }
        $validator = $validators[0]
        $valid = & $validator -Manifest $manifest -Repository $Repository `
            -TargetTag $ProtocolTag `
            -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
            -ExpectedState ([string]$plan.State) `
            -ExpectedCollisions @($contract.Collisions)
    }
    finally {
        Remove-Module -Name ([string]$module.Name) -Force -ErrorAction SilentlyContinue
    }
    if ($valid -isnot [bool] -or -not $valid) {
        throw 'The adoption manifest does not exactly match the independently derived protocol contract.'
    }
    Assert-ExactAdoptionProposal -Repository $ProposalRepository `
        -ProposalHead $ProposalHead -CanonicalBaseHead $CanonicalBaseHead `
        -ProposalMode ([string]$plan.ProposalMode) -TargetPaths $targetPaths `
        -ProtocolSource $ProtocolSource `
        -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha)
    return $manifest
}

function Get-ValidatedAdoptionChangeSet {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Manifest
    )

    Assert-CredentialFilesAbsent -Repository $Repository
    Invoke-Git -Repository $Repository -Arguments @('diff', '--check') | Out-Null
    Invoke-Git -Repository $Repository -Arguments @(
        'add', '-A', '--', '.', ':(exclude).ai/protocol'
    ) | Out-Null
    $changedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--cached', '--name-only', '--diff-filter=ACMRTD'
    )).Output | Where-Object { $_ })
    if ($changedPaths.Count -eq 0) {
        throw 'Local Codex produced no reviewable adoption change.'
    }
    foreach ($forbiddenPath in @($workflowTargetPath) + @($tokenMappings.Keys)) {
        $protectedDiff = Invoke-Git -Repository $Repository -Arguments @(
            'diff', '--cached', '--quiet', '--exit-code', '--', $forbiddenPath
        ) -AllowFailure
        if ($protectedDiff.ExitCode -eq 1) {
            throw "Local Codex changed protected adoption path '$forbiddenPath'."
        }
        if ($protectedDiff.ExitCode -ne 0) {
            throw "Protected adoption path '$forbiddenPath' could not be validated."
        }
    }
    if (@($changedPaths | Where-Object { $_ -clike '.ai/protocol/*' }).Count -gt 0) {
        throw 'Local Codex changed files inside the protocol reference instead of preserving one gitlink.'
    }
    Assert-AdoptionProtocolReference -Repository $Repository `
        -ProtocolSha ([string]$Manifest.protocolSha)
    Invoke-Git -Repository $Repository -Arguments @('diff', '--cached', '--check') | Out-Null
    return $changedPaths
}

function Assert-RecoverablePublishedAdoption {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$PlannedHead,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$ProtocolSource
    )

    $head = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    if ($head -cne $PlannedHead -or
        (Get-SingleCommitParent -Repository $Repository -Commit $PlannedHead) -cne $PreviousHead) {
        throw 'The published adoption recovery commit does not match its persisted transition.'
    }
    $status = @((Invoke-Git -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ })
    if ($status.Count -ne 0) {
        throw 'The published adoption recovery clone is not clean.'
    }
    Assert-CredentialFilesAbsent -Repository $Repository
    $manifestPath = Join-Path $Repository `
        ($adoptionManifestPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $manifestPath) {
        throw 'The published adoption recovery commit still contains the transient manifest.'
    }
    Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--check', $PreviousHead, $PlannedHead, '--'
    ) | Out-Null
    $changedPaths = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--no-renames', '--name-only', '--diff-filter=ACMRTD',
        $PreviousHead, $PlannedHead, '--'
    )).Output | Where-Object { $_ })
    if ($changedPaths.Count -eq 0) {
        throw 'The published adoption recovery commit contains no reviewable change.'
    }
    foreach ($path in @($workflowTargetPath) + @($tokenMappings.Keys)) {
        if ($changedPaths -ccontains $path) {
            throw "The published adoption recovery commit changed protected path '$path'."
        }
    }
    if (@($changedPaths | Where-Object { $_ -clike '.ai/protocol/*' }).Count -gt 0) {
        throw 'The published adoption recovery commit changed content inside the protocol gitlink.'
    }
    Assert-AdoptionProtocolReference -Repository $Repository -ProtocolSha $ProtocolSha
    Assert-AdoptionUpdaterAssetsExact -Repository $Repository `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha -Commit $PlannedHead
}

function Get-RemoteBranchHead {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Remote,
        [Parameter(Mandatory)][string]$Branch,
        [switch]$AllowMissing
    )

    $result = Invoke-Git -Repository $Repository -Arguments @(
        'ls-remote', '--heads', $Remote, "refs/heads/$Branch"
    )
    $lines = @($result.Output | Where-Object { $_ })
    if ($AllowMissing -and $lines.Count -eq 0) {
        return $null
    }
    if ($lines.Count -ne 1) {
        throw 'The deterministic adoption branch is missing or ambiguous on the remote.'
    }
    $parts = ([string]$lines[0]).Split("`t")
    if ($parts.Count -ne 2 -or $parts[0] -cnotmatch '^[0-9a-f]{40}$' -or
        $parts[1] -cne "refs/heads/$Branch") {
        throw 'The deterministic adoption branch returned invalid remote metadata.'
    }
    return $parts[0]
}

function Invoke-AdoptionCodexCompletion {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ClonePath,
        [Parameter(Mandatory)][string]$TemporaryRoot,
        [Parameter(Mandatory)]$AdoptionIssue
    )

    $runner = Resolve-LocalCodexRunner -ExplicitCommand $CodexCommand `
        -FallbackVersion $TemporaryCodexVersion
    $timeoutMilliseconds = if ($CodexTimeoutSeconds -gt 0) {
        [int][Math]::Min(
            [int]::MaxValue, [TimeSpan]::FromSeconds($CodexTimeoutSeconds).TotalMilliseconds
        )
    }
    else {
        [int][Math]::Min(
            [int]::MaxValue, [TimeSpan]::FromMinutes($CodexTimeoutMinutes).TotalMilliseconds
        )
    }
    $timeoutDescription = if ($CodexTimeoutSeconds -gt 0) {
        "$CodexTimeoutSeconds second(s)"
    }
    else { "$CodexTimeoutMinutes minute(s)" }
    Assert-LocalCodexLogin -Runner $runner `
        -TimeoutMilliseconds $timeoutMilliseconds `
        -TimeoutDescription $timeoutDescription
    $windowsSandboxMode = Assert-LocalCodexWorkspaceWrite -Runner $runner `
        -WorkingDirectory $ClonePath `
        -TimeoutMilliseconds $timeoutMilliseconds
    $resultPath = Join-Path $TemporaryRoot 'codex-result.txt'
    $prompt = @"
Complete the meAndAI AI-capabilities adoption for $Repository pull request #$($PullRequest.number) in this isolated temporary clone.

Read the manifest at .ai/adoption/meandai-capabilities.json, the exact protocol source at $ProtocolSource, every applicable AGENTS.md, and the consumer's existing project files before editing. Resolve collisions semantically; create or reconcile the project-owned feature and decision records, local memory, tests, evidence, and clickable links required by the protocol. The launcher already reconciled the required Agile labels and project-owned adoption issue $($AdoptionIssue.url); reference that issue from the local feature record. Do not invent project facts. If the consumer has no application source or product documentation yet, that absence is not a blocker to protocol adoption: record product purpose, runtime/stack, architecture, build command, and product test command as 'Not yet established', and use structural adoption checks without inventing product behavior. If other required facts are unavailable, state the precise blocker. If the .ai/protocol gitlink is absent, create it from $ProtocolRepository at exactly $($Manifest.protocolSha); never substitute a moving ref.

Secret provisioning is already complete: FG_PAT.txt maps to MEANDAI_UPDATER_TOKEN and MEANDAI_RO_FG_PAT.txt maps to MEANDAI_PROTOCOL_TOKEN. Those source files are intentionally absent. Do not search for, request, print, recreate, or modify credential values or repository secrets.

Work only in this clone. Spawned-command network access is disabled: do not invoke gh, GitHub APIs, remote Git operations, or any other external service. Preserve any existing pinned protocol gitlink and do not change the lifecycle workflow. Do not commit, push, approve, mark the pull request ready, merge, close, delete, or alter branches. The launcher owns GitHub records and Git publication; the maintainer owns merge.

Keep validation bounded: implement reviewable slices, run relevant tests, perform one fresh-diff self-review and the protocol's bounded completion scan, fix blocking findings only, and avoid recursive validators. Remove .ai/adoption/meandai-capabilities.json only when all adoption gates are satisfied.

Your final response must start with MEANDAI_ADOPTION_READY only when the manifest has been removed and the repository-local adoption work is complete. Otherwise start with MEANDAI_ADOPTION_BLOCKED and state the exact blocker. Include concise test evidence.
"@
    Invoke-LocalCodexExec -Runner $runner -WorkingDirectory $ClonePath `
        -Prompt $prompt -OutputPath $resultPath `
        -TimeoutMilliseconds $timeoutMilliseconds `
        -TimeoutDescription $timeoutDescription `
        -WindowsSandboxMode $windowsSandboxMode
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        throw 'Local Codex completed without a final result file.'
    }
    $result = [IO.File]::ReadAllText($resultPath).Trim()
    if (-not $result.StartsWith('MEANDAI_ADOPTION_READY', [StringComparison]::Ordinal)) {
        if ($result.Length -gt 1200) { $result = $result.Substring(0, 1200) + '...' }
        throw "Local Codex did not declare the adoption ready. $result"
    }
    return [pscustomobject]@{ Runner = $runner; Result = $result }
}

function Complete-AdoptionWithLocalCodex {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
        [string]$ProtocolToken = ''
    )

    $branch = [string]$PullRequest.headRefName
    $expectedHead = [string]$PullRequest.headRefOid
    $expectedBody = [string]$PullRequest.body
    $localBaseHead = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    $remoteBaseHead = Get-RemoteBranchHead -Repository $TargetRepository `
        -Remote $RemoteName -Branch ([string]$PullRequest.baseRefName)
    if ($CanonicalBaseHead -cnotmatch '^[0-9a-f]{40}$' -or
        $localBaseHead -cne $CanonicalBaseHead -or
        $remoteBaseHead -cne $CanonicalBaseHead) {
        throw 'The canonical consumer base changed before local adoption validation.'
    }
    $remoteHead = Get-RemoteBranchHead -Repository $TargetRepository -Remote $RemoteName -Branch $branch
    if ($remoteHead -cne $expectedHead) {
        throw 'The pull-request head and live adoption branch differ before local execution.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-local-adoption-$([guid]::NewGuid().ToString('N'))"
    $clonePath = Join-Path $temporaryRoot 'consumer'
    [IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    try {
        $remoteUrl = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'remote', 'get-url', $RemoteName
        )).Output -join '').Trim())
        Invoke-External -Command 'git' -Arguments @(
            'clone', '--no-tags', '--single-branch', '--branch', $branch,
            $remoteUrl, $clonePath
        ) | Out-Null

        $cloneHead = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($cloneHead -cne $expectedHead) {
            throw 'The isolated clone did not resolve to the expected pull-request head.'
        }
        Assert-CredentialFilesAbsent -Repository $clonePath

        $manifestPath = Join-Path $clonePath `
            ($adoptionManifestPath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $protocolSource = $null
        if ([string]$PullRequest.meAndAIMarker.phase -ceq 'Publishing') {
            $previousHead = [string]$PullRequest.meAndAIMarker.previousHead
            $plannedHead = [string]$PullRequest.meAndAIMarker.plannedHead
            $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -Destination $temporaryRoot
            if ($expectedHead -ceq $plannedHead) {
                Assert-RecoverablePublishedAdoption -Repository $clonePath `
                    -PreviousHead $previousHead -PlannedHead $plannedHead `
                    -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                    -ProtocolSource $protocolSource
                Ensure-AdoptionLabels -Repository $Repository
                $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
                    -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot
                [void](Complete-AdoptionReviewTransition -Repository $Repository `
                    -PullRequest $PullRequest -PublishedHead $plannedHead `
                    -ExpectedMarkerHead $previousHead -TemporaryDirectory $temporaryRoot `
                    -Issue $adoptionIssue -PersistCompletedMarker)
                return [pscustomobject]@{
                    Ran = $false
                    Pushed = $false
                    Ready = $true
                    RequiresManualReview = $false
                    Runner = 'publishing recovery'
                    Head = $plannedHead
                }
            }
            if ($expectedHead -cne $previousHead) {
                throw 'The publishing adoption branch matches neither persisted transition head.'
            }
            if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
                throw 'The unpushed publishing transition cannot be restored because its proposal manifest is missing.'
            }
            $restoredBody = Set-AdoptionPullRequestProposedMarker `
                -Repository $Repository -PullRequest $PullRequest `
                -PreviousHead $previousHead -TemporaryDirectory $temporaryRoot
            $PullRequest = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
                -OriginalPullRequest $PullRequest -LiveHead $previousHead `
                -MarkerHead $previousHead -Body $restoredBody -Draft $true
            $expectedBody = $restoredBody
        }
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            if ([string]$PullRequest.meAndAIMarker.phase -ceq 'Completed') {
                if ($null -eq $protocolSource) {
                    $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                        -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                        -Destination $temporaryRoot
                }
                $proposalHead = Get-SingleCommitParent -Repository $clonePath `
                    -Commit $expectedHead
                $proposalManifestText = @((Invoke-Git -Repository $clonePath `
                    -Arguments @('show', "${proposalHead}:$adoptionManifestPath")).Output) `
                    -join [Environment]::NewLine
                if ([string]::IsNullOrWhiteSpace($proposalManifestText)) {
                    throw 'The completed adoption parent does not contain its proposal manifest.'
                }
                $proposalManifestPath = Join-Path $temporaryRoot `
                    'completed-proposal-manifest.json'
                [IO.File]::WriteAllText(
                    $proposalManifestPath,
                    $proposalManifestText,
                    [Text.UTF8Encoding]::new($false)
                )
                [void](Get-ValidatedAdoptionManifest `
                    -ManifestPath $proposalManifestPath -Repository $Repository `
                    -PullRequest $PullRequest -ProtocolSource $protocolSource `
                    -ProposalRepository $clonePath -ProposalHead $proposalHead `
                    -CanonicalBaseHead $CanonicalBaseHead)
                Assert-RecoverablePublishedAdoption -Repository $clonePath `
                    -PreviousHead $proposalHead -PlannedHead $expectedHead `
                    -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                    -ProtocolSource $protocolSource
                Ensure-AdoptionLabels -Repository $Repository
                $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
                    -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot
                [void](Complete-AdoptionReviewTransition -Repository $Repository `
                    -PullRequest $PullRequest -PublishedHead $expectedHead `
                    -ExpectedMarkerHead $expectedHead -TemporaryDirectory $temporaryRoot `
                    -Issue $adoptionIssue)
                return [pscustomobject]@{
                    Ran = $false
                    Pushed = $false
                    Ready = $true
                    RequiresManualReview = $false
                    Runner = 'not required'
                    Head = $expectedHead
                }
            }
            Assert-AdoptionProtocolReference -Repository $clonePath `
                -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha)
            return [pscustomobject]@{
                Ran = $false
                Pushed = $false
                Ready = -not [bool]$PullRequest.isDraft
                RequiresManualReview = [bool]$PullRequest.isDraft
                Runner = 'not required'
            }
        }
        if (-not [bool]$PullRequest.isDraft) {
            throw 'The adoption manifest remains but the pull request is no longer a draft.'
        }
        if ([string]$PullRequest.meAndAIMarker.phase -cne 'Proposed') {
            throw 'The adoption manifest remains after the proposal entered a completed phase.'
        }

        if ($null -eq $protocolSource) {
            $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -Destination $temporaryRoot
        }
        $manifest = Get-ValidatedAdoptionManifest -ManifestPath $manifestPath `
            -Repository $Repository -PullRequest $PullRequest `
            -ProtocolSource $protocolSource -ProposalRepository $clonePath `
            -ProposalHead $expectedHead -CanonicalBaseHead $CanonicalBaseHead
        if ([string]$manifest.state -ceq 'BootstrapReady') {
            Assert-AdoptionProtocolReference -Repository $clonePath `
                -ProtocolSha ([string]$manifest.protocolSha)
        }

        Ensure-AdoptionLabels -Repository $Repository
        $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
            -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot

        $codexCompletion = Invoke-AdoptionCodexCompletion -Repository $Repository `
            -PullRequest $PullRequest -Manifest $manifest -ProtocolSource $protocolSource `
            -ClonePath $clonePath -TemporaryRoot $temporaryRoot -AdoptionIssue $adoptionIssue
        Set-QuickAdoptionProgress -Status 'Validating and publishing adoption' `
            -PercentComplete 92
        $runner = $codexCompletion.Runner
        $result = [string]$codexCompletion.Result

        $headAfterCodex = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($headAfterCodex -cne $expectedHead) {
            throw 'Local Codex created a commit; the launcher will not publish an agent-owned history.'
        }
        if (Test-Path -LiteralPath $manifestPath) {
            throw 'Local Codex declared readiness but left the transient adoption manifest.'
        }
        Get-ValidatedAdoptionChangeSet -Repository $clonePath -Manifest $manifest | Out-Null
        Assert-AdoptionUpdaterAssetsExact -Repository $clonePath `
            -ProtocolSource $protocolSource -ProtocolSha ([string]$manifest.protocolSha) `
            -UseIndex

        $liveHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($liveHead -cne $expectedHead) {
            throw 'The adoption branch changed while local Codex was running; no local result was published.'
        }
        [void](Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $PullRequest -LiveHead $expectedHead `
            -MarkerHead $expectedHead -Body $expectedBody -Draft $true)

        $targetName = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'config', 'user.name'
        )).Output -join '').Trim())
        $targetEmail = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'config', 'user.email'
        )).Output -join '').Trim())
        Invoke-Git -Repository $clonePath -Arguments @('config', 'user.name', $targetName) | Out-Null
        Invoke-Git -Repository $clonePath -Arguments @('config', 'user.email', $targetEmail) | Out-Null
        Invoke-Git -Repository $clonePath -Arguments @(
            'commit', '-m', "Complete meAndAI AI capabilities adoption for $ProtocolTag"
        ) | Out-Null
        $publishedHead = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ((Get-SingleCommitParent -Repository $clonePath -Commit $publishedHead) -cne $expectedHead) {
            throw 'The completed adoption commit does not have the exact proposal parent.'
        }
        Assert-AdoptionUpdaterAssetsExact -Repository $clonePath `
            -ProtocolSource $protocolSource -ProtocolSha ([string]$manifest.protocolSha) `
            -Commit $publishedHead
        [void](Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $PullRequest -LiveHead $expectedHead `
            -MarkerHead $expectedHead -Body $expectedBody -Draft $true)
        $publishingBody = Set-AdoptionPullRequestPublishingMarker `
            -Repository $Repository -PullRequest $PullRequest `
            -PreviousHead $expectedHead -PlannedHead $publishedHead `
            -TemporaryDirectory $temporaryRoot
        $publishingPullRequest = Get-RevalidatedAdoptionPullRequest `
            -Repository $Repository -OriginalPullRequest $PullRequest `
            -LiveHead $expectedHead -MarkerHead $expectedHead `
            -Body $publishingBody -Draft $true
        Invoke-Git -Repository $clonePath -Arguments @(
            'push', 'origin',
            "--force-with-lease=refs/heads/$branch`:$expectedHead",
            "HEAD:refs/heads/$branch"
        ) | Out-Null
        $verifiedHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($verifiedHead -cne $publishedHead) {
            throw 'The adoption branch did not resolve to the launcher-published commit.'
        }

        [void](Complete-AdoptionReviewTransition -Repository $Repository `
            -PullRequest $publishingPullRequest -PublishedHead $publishedHead `
            -ExpectedMarkerHead $expectedHead -TemporaryDirectory $temporaryRoot `
            -Issue $adoptionIssue -PersistCompletedMarker)
        return [pscustomobject]@{
            Ran = $true
            Pushed = $true
            Ready = $true
            Runner = $runner.Description
            Head = $publishedHead
            Result = $result
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Set-QuickAdoptionProgress -Status 'Validating prerequisites' -PercentComplete 5
try {
foreach ($command in @('git', 'gh')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Required command '$command' is not available."
    }
}
Assert-MinimumGitHubCliVersion

$target = Get-NormalizedPath -Path $TargetPath
if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "TargetPath must identify an existing directory: $target"
}

Invoke-External -Command 'gh' -Arguments @('auth', 'status') | Out-Null

Set-QuickAdoptionProgress -Status 'Inspecting repository state' -PercentComplete 15

$inside = Invoke-Git -Repository $target -Arguments @('rev-parse', '--is-inside-work-tree') -AllowFailure
if ($inside.ExitCode -eq 0 -and ((@($inside.Output) -join '').Trim() -eq 'true')) {
    $rootResult = Invoke-Git -Repository $target -Arguments @('rev-parse', '--show-toplevel')
    $gitRoot = Get-NormalizedPath -Path ((@($rootResult.Output) -join '').Trim())
    if (-not $gitRoot.Equals($target, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'TargetPath is nested inside another Git repository; select that repository root explicitly.'
    }
}
else {
    Invoke-External -Command 'git' -Arguments @('init', '-b', 'main', $target) | Out-Null
}

Add-LocalTokenExcludes -Repository $target

$headResult = Invoke-Git -Repository $target -Arguments @('rev-parse', '--verify', 'HEAD') -AllowFailure
$hasHead = $headResult.ExitCode -eq 0
$remoteResult = Invoke-Git -Repository $target -Arguments @(
    'config', '--get', "remote.$RemoteName.url"
) -AllowFailure
$hasRemote = $remoteResult.ExitCode -eq 0
$remoteSlug = ''
$remoteIsEmpty = $false
$discoveredExistingRepository = $false
$discoveredRemoteUrl = ''
$candidateRepository = ''
$protocolToken = $null
$workflowBytes = $null
$protocolTokenPath = Join-Path $target 'MEANDAI_RO_FG_PAT.txt'
$protocolTokenFileExists = Test-Path -LiteralPath $protocolTokenPath -PathType Leaf

if ($hasRemote) {
    $remoteUrl = ((@($remoteResult.Output) -join '').Trim())
    $remoteSlug = Get-GitHubSlugFromRemote -RemoteUrl $remoteUrl
    $remoteHeads = Invoke-Git -Repository $target -Arguments @(
        'ls-remote', '--heads', $RemoteName
    )
    $remoteIsEmpty = -not ((@($remoteHeads.Output) -join '').Trim())
}

# Credential exposure checks are unconditional and precede repository-state
# classification. File presence is evaluated separately after identity tells
# us whether the target repository can already own the mapped secrets.
Assert-TokenFilesAreLocalOnly -Repository $target

Set-QuickAdoptionProgress -Status 'Verifying immutable protocol release' `
    -PercentComplete 30

if (-not $hasRemote -and $hasHead) {
    throw "A repository with commits but no '$RemoteName' is outside the safe new-repository flow. Connect and reconcile it manually."
}

if (-not $hasRemote) {
    if (-not $Owner) {
        $ownerResult = Invoke-External -Command 'gh' -Arguments @('api', 'user', '--jq', '.login')
        $Owner = ((@($ownerResult.Output) -join '').Trim())
    }
    if (-not $RepositoryName) {
        $RepositoryName = Split-Path -Leaf $target
    }
    if ($Owner -cnotmatch '^[A-Za-z0-9_.-]+$' -or
        $RepositoryName -cnotmatch '^[A-Za-z0-9_.-]+$' -or
        $RepositoryName -in @('.', '..')) {
        throw 'Owner and RepositoryName must be valid unambiguous GitHub slugs.'
    }

    $candidateRepository = "$Owner/$RepositoryName"
    $candidateView = Invoke-External -Command 'gh' -Arguments @(
        'repo', 'view', $candidateRepository, '--json', 'nameWithOwner,defaultBranchRef'
    ) -AllowFailure
    if ($candidateView.ExitCode -eq 0) {
        try {
            $candidateInfo = ((@($candidateView.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
        }
        catch {
            throw 'GitHub CLI returned invalid repository metadata for the derived repository.'
        }
        if ($null -eq $candidateInfo -or
            $null -eq $candidateInfo.PSObject.Properties['nameWithOwner']) {
            throw 'GitHub CLI returned incomplete repository metadata for the derived repository.'
        }
        $candidateCanonicalName = [string]$candidateInfo.nameWithOwner
        if (-not $candidateCanonicalName.Equals(
            $candidateRepository, [StringComparison]::OrdinalIgnoreCase
        )) {
            throw 'The derived GitHub repository identity is ambiguous.'
        }

        $discoveredRemoteUrl = "https://github.com/$candidateCanonicalName.git"
        $candidateHeads = Invoke-Git -Repository $target -Arguments @(
            'ls-remote', '--heads', $discoveredRemoteUrl
        )
        if ((@($candidateHeads.Output) -join '').Trim()) {
            throw 'The derived GitHub repository already contains history; clone or reconcile it manually.'
        }
        $remoteSlug = $candidateCanonicalName
        $remoteIsEmpty = $true
        $discoveredExistingRepository = $true
    }
}

$requiredTokenFiles = if ($hasRemote -or $discoveredExistingRepository) {
    @()
}
else {
    @($tokenMappings.Keys)
}
foreach ($requiredTokenFile in $requiredTokenFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $target $requiredTokenFile) -PathType Leaf)) {
        throw "Required local credential file '$requiredTokenFile' is missing from the target root."
    }
}

if ($discoveredExistingRepository) {
    # Verify executable source before mutating the local remote configuration.
    # The repository secret value remains unreadable; authenticated gh is the
    # existing file-free source fallback when the local read token is absent.
    if ($protocolTokenFileExists) {
        $protocolToken = Read-LocalToken -Path $protocolTokenPath
        $workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken
    }
    else {
        $workflowBytes = Get-CanonicalWorkflow
    }
    Invoke-Git -Repository $target -Arguments @(
        'remote', 'add', $RemoteName, $discoveredRemoteUrl
    ) | Out-Null
    $hasRemote = $true
}
if ($hasRemote -and -not $remoteIsEmpty -and -not $hasHead) {
    throw 'The connected remote contains history but the local repository has no commit; clone or reconcile it manually.'
}

if ($hasRemote -and $remoteIsEmpty -and $hasHead) {
    $commitCount = ((@(Invoke-Git -Repository $target -Arguments @(
        'rev-list', '--count', 'HEAD'
    )).Output -join '').Trim())
    $treePaths = @((Invoke-Git -Repository $target -Arguments @(
        'ls-tree', '-r', '--name-only', 'HEAD'
    )).Output | Where-Object { $_ })
    if ($commitCount -cne '1' -or $treePaths.Count -ne 1 -or
        $treePaths[0] -cne $workflowTargetPath) {
        throw 'An empty remote may resume only the launcher-owned, single seed-only local commit.'
    }
}

$resumableNewRepository = (-not $hasRemote -and -not $hasHead) -or
    ($hasRemote -and $remoteIsEmpty)
if ($resumableNewRepository) {
    $stagedBefore = Invoke-Git -Repository $target -Arguments @('diff', '--cached', '--name-only') -AllowFailure
    $stagedPaths = @($stagedBefore.Output | Where-Object { $_ })
    if ($stagedPaths.Count -gt 1 -or
        ($stagedPaths.Count -eq 1 -and $stagedPaths[0] -cne $workflowTargetPath)) {
        throw 'The resumable new-repository flow permits only the exact seed workflow in the Git index.'
    }
    if ($hasHead) {
        $resumeBranch = ((@(Invoke-Git -Repository $target -Arguments @(
            'branch', '--show-current'
        )).Output -join '').Trim())
        if ($resumeBranch -cne 'main') {
            throw "The resumable unpublished seed must remain on 'main'."
        }
    }
    else {
        Invoke-Git -Repository $target -Arguments @('branch', '-M', 'main') | Out-Null
    }
}
else {
    $status = Invoke-Git -Repository $target -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )
    foreach ($line in @($status.Output)) {
        if (-not $line) {
            continue
        }
        if ($line.Length -lt 4 -or $line.Substring(3) -cne $workflowTargetPath) {
            throw 'The connected repository must be clean apart from the exact seed workflow candidate.'
        }
    }
}

if (-not $hasRemote) {
    $protocolToken = Read-LocalToken -Path (Join-Path $target 'MEANDAI_RO_FG_PAT.txt')
    $workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken
}

if ($hasRemote) {
    $view = Invoke-External -Command 'gh' -Arguments @(
        'repo', 'view', $remoteSlug, '--json', 'nameWithOwner,defaultBranchRef'
    )
    try {
        $repositoryInfo = ((@($view.Output) -join [Environment]::NewLine) | ConvertFrom-Json)
    }
    catch {
        throw 'GitHub CLI returned invalid repository metadata.'
    }
    $repository = [string]$repositoryInfo.nameWithOwner
    $defaultBranch = if ($null -ne $repositoryInfo.defaultBranchRef) {
        [string]$repositoryInfo.defaultBranchRef.name
    }
    else {
        ''
    }
    if (-not $repository.Equals($remoteSlug, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Remote '$RemoteName' identity does not match GitHub repository metadata."
    }
    if (-not $remoteIsEmpty -and -not $defaultBranch) {
        throw 'The connected GitHub repository has no default branch.'
    }
    if ($remoteIsEmpty) {
        $defaultBranch = 'main'
    }
    if ($Owner -and -not $repository.StartsWith("$Owner/", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The explicit Owner does not match the connected repository.'
    }
    if ($RepositoryName -and
        -not $repository.EndsWith("/$RepositoryName", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The explicit RepositoryName does not match the connected repository.'
    }

    $branch = ((@(Invoke-Git -Repository $target -Arguments @(
        'branch', '--show-current'
    )).Output -join '').Trim())
    if ($branch -cne $defaultBranch) {
        throw "The current branch '$branch' is not the GitHub default branch '$defaultBranch'."
    }
    if (-not $remoteIsEmpty) {
        Invoke-Git -Repository $target -Arguments @('fetch', '--quiet', $RemoteName, $defaultBranch) | Out-Null
        $localHead = ((@($headResult.Output) -join '').Trim())
        $remoteHead = ((@(Invoke-Git -Repository $target -Arguments @(
            'rev-parse', "$RemoteName/$defaultBranch"
        )).Output -join '').Trim())
        if ($localHead -cne $remoteHead) {
            throw 'The local and remote default-branch heads differ; reconcile them before adoption.'
        }
    }
}
else {
    $repository = $candidateRepository
    $defaultBranch = 'main'

    $visibilityArgument = switch ($Visibility) {
        'private' { '--private' }
        'public' { '--public' }
        'internal' { '--internal' }
    }
    Invoke-External -Command 'gh' -Arguments @(
        'repo', 'create', $repository, $visibilityArgument,
        '--source', $target, '--remote', $RemoteName
    ) | Out-Null
    $createdRemoteUrl = ((@(Invoke-Git -Repository $target -Arguments @(
        'config', '--get', "remote.$RemoteName.url"
    )).Output -join '').Trim())
    $createdSlug = Get-GitHubSlugFromRemote -RemoteUrl $createdRemoteUrl
    if (-not $createdSlug.Equals($repository, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The created remote identity does not match the requested GitHub repository.'
    }
    $remoteIsEmpty = $true
}

if ($null -eq $workflowBytes) {
    # Executable source authority is verified before the temporary lock label
    # performs the first repository mutation. Prefer the local read-only token
    # when its verified file is present; otherwise use the authenticated gh
    # identity without attempting to recover an existing Actions secret.
    if ($protocolTokenFileExists) {
        $protocolToken = Read-LocalToken -Path $protocolTokenPath
        $workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken
    }
    else {
        $workflowBytes = Get-CanonicalWorkflow
    }
}

$routingHeadResult = Invoke-Git -Repository $target -Arguments @(
    'rev-parse', '--verify', 'HEAD'
) -AllowFailure
$routingHead = if ($routingHeadResult.ExitCode -eq 0) {
    ((@($routingHeadResult.Output) -join '').Trim())
}
else { '' }
$existingAdoptionRoute = Get-ExistingAdoptionRoute -Repository $target `
    -HeadSha $routingHead -ProtocolToken $protocolToken

if ([string]$existingAdoptionRoute.State -ceq 'InitialAdoption') {
    $repositoryOwner = $repository.Split('/')[0]
    $nameResult = Invoke-Git -Repository $target `
        -Arguments @('config', 'user.name') -AllowFailure
    if ($nameResult.ExitCode -ne 0 -or
        -not ((@($nameResult.Output) -join '').Trim())) {
        Invoke-Git -Repository $target -Arguments @(
            'config', 'user.name', $repositoryOwner
        ) | Out-Null
    }
    $emailResult = Invoke-Git -Repository $target `
        -Arguments @('config', 'user.email') -AllowFailure
    if ($emailResult.ExitCode -ne 0 -or
        -not ((@($emailResult.Output) -join '').Trim())) {
        Invoke-Git -Repository $target -Arguments @(
            'config', 'user.email', "$repositoryOwner@users.noreply.github.com"
        ) | Out-Null
    }
}

$workflowFullPath = Assert-ContainedManagedDestination `
    -Root $target -RelativePath $workflowTargetPath
if ([string]$existingAdoptionRoute.State -ceq 'InitialAdoption' -and
    (Test-Path -LiteralPath $workflowFullPath)) {
    if (-not (Test-Path -LiteralPath $workflowFullPath -PathType Leaf)) {
        throw "The existing seed workflow path '$workflowTargetPath' is not a regular file."
    }
    $existingWorkflowBytes = [IO.File]::ReadAllBytes($workflowFullPath)
    if (-not (Test-ByteArrayEqual -Left $existingWorkflowBytes -Right $workflowBytes)) {
        throw "The existing seed workflow '$workflowTargetPath' differs from the canonical $ProtocolTag bytes; repository secrets were not inspected or changed."
    }
}

Set-QuickAdoptionProgress -Status 'Reconciling repository secrets' `
    -PercentComplete 45
$secretLock = Enter-RepositorySecretReconciliationLock -Repository $repository
$secretOperationError = $null
$secretLockCleanupError = $null
try {
    # The name inventory and every missing-secret write share one GitHub-wide
    # critical section. A competing host cannot act on the same stale snapshot.
    $existingSecretNames = @(Get-RepositorySecretNames -Repository $repository)
    $protocolSecretMissing = $existingSecretNames -notcontains 'MEANDAI_PROTOCOL_TOKEN'
    if ($protocolSecretMissing -and -not $protocolTokenFileExists) {
        throw "Required local credential file 'MEANDAI_RO_FG_PAT.txt' is missing because repository Actions secret 'MEANDAI_PROTOCOL_TOKEN' does not exist."
    }
    if ($null -eq $protocolToken -and $protocolTokenFileExists) {
        $protocolToken = Read-LocalToken -Path $protocolTokenPath
    }

    $updaterSecretMissing = $existingSecretNames -notcontains 'MEANDAI_UPDATER_TOKEN'
    $updaterToken = $null
    if ($updaterSecretMissing) {
        $updaterTokenPath = Join-Path $target 'FG_PAT.txt'
        if (-not (Test-Path -LiteralPath $updaterTokenPath -PathType Leaf)) {
            throw "Required local credential file 'FG_PAT.txt' is missing because repository Actions secret 'MEANDAI_UPDATER_TOKEN' does not exist."
        }
        $updaterToken = Read-LocalToken -Path $updaterTokenPath
        try {
            $targetInfo = Invoke-GitHubApi -Uri "https://api.github.com/repos/$repository" -Token $updaterToken
            if (-not ([string]$targetInfo.full_name).Equals($repository, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'identity mismatch'
            }
        }
        catch {
            throw "The updater token cannot access '$repository'. Add this repository to the token's selected-repository grant, then rerun."
        }
    }

    foreach ($entry in $tokenMappings.GetEnumerator()) {
        if ($existingSecretNames -contains $entry.Value) {
            Write-Host "Repository Actions secret '$($entry.Value)' already exists and was preserved."
            continue
        }
        $value = if ($entry.Key -ceq 'FG_PAT.txt') { $updaterToken } else { $protocolToken }
        Set-RepositorySecret -Repository $repository -Name $entry.Value -Value $value
    }
}
catch {
    $secretOperationError = $_.Exception
}
finally {
    try {
        Exit-RepositorySecretReconciliationLock -Repository $repository -Lock $secretLock
    }
    catch {
        $secretLockCleanupError = $_.Exception
    }
}
if ($null -ne $secretOperationError) {
    if ($null -ne $secretLockCleanupError) {
        throw "$($secretOperationError.Message) Secret-lock cleanup also failed: $($secretLockCleanupError.Message)"
    }
    throw $secretOperationError
}
if ($null -ne $secretLockCleanupError) {
    throw $secretLockCleanupError
}

if ([string]$existingAdoptionRoute.State -ceq 'AlreadyCurrent') {
    Write-Host "The completed meAndAI adoption is already current at $($existingAdoptionRoute.InstalledTag)."
    Write-Host 'The installed updater seed was preserved; no workflow dispatch, Git publication, pull-request resolution, or local Codex execution was required.'
    Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
    return
}
if ([string]$existingAdoptionRoute.State -ceq 'CompatibleUpdate') {
    Write-Host "The completed meAndAI adoption at $($existingAdoptionRoute.InstalledTag) is older than requested target $ProtocolTag."
    Write-Host 'The installed updater seed was preserved; the launcher will not overwrite managed updater assets.'
    if ($SkipLifecycleDispatch) {
        Write-Host 'Installed updater dispatch was explicitly skipped.'
        Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
        return
    }
    Set-QuickAdoptionProgress -Status 'Waiting for installed updater workflow' `
        -PercentComplete 70
    Write-Host "Dispatching installed updater at $($existingAdoptionRoute.InstalledTag)."
    $updateRun = Invoke-LifecycleWorkflow -Repository $repository `
        -Branch $defaultBranch -HeadSha $routingHead
    Write-Host "Installed updater workflow completed successfully: $($updateRun.url)"
    Write-Host 'Review and merge the managed update pull request; adoption Codex execution was not started.'
    Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
    return
}

Set-QuickAdoptionProgress -Status 'Publishing canonical seed workflow' `
    -PercentComplete 58
[void](Write-CanonicalWorkflow -Path $workflowFullPath -Bytes $workflowBytes)

Invoke-Git -Repository $target -Arguments @('add', '--', $workflowTargetPath) | Out-Null
$staged = @((Invoke-Git -Repository $target -Arguments @(
    'diff', '--cached', '--name-only', '--diff-filter=ACMRT'
)).Output | Where-Object { $_ })
if ($staged.Count -gt 1 -or ($staged.Count -eq 1 -and $staged[0] -cne $workflowTargetPath)) {
    throw 'The staged change set is not exactly the canonical seed workflow.'
}

$createdCommit = $false
if ($staged.Count -eq 1) {
    $nameResult = Invoke-Git -Repository $target -Arguments @('config', 'user.name') -AllowFailure
    $emailResult = Invoke-Git -Repository $target -Arguments @('config', 'user.email') -AllowFailure
    if ($nameResult.ExitCode -ne 0 -or $emailResult.ExitCode -ne 0 -or
        -not ((@($nameResult.Output) -join '').Trim()) -or
        -not ((@($emailResult.Output) -join '').Trim())) {
        throw 'Git user.name and user.email are required before the seed can be committed.'
    }
    Invoke-Git -Repository $target -Arguments @(
        'commit', '-m', 'Adopt meAndAI AI capabilities lifecycle'
    ) | Out-Null
    $createdCommit = $true
}

if ($createdCommit -or $remoteIsEmpty) {
    Invoke-Git -Repository $target -Arguments @(
        'push', '-u', $RemoteName, $defaultBranch
    ) | Out-Null
}

Write-Host "meAndAI quick adoption seed is ready in $repository at $ProtocolTag."
Write-Host 'Repository Actions secrets were reconciled by preserving existing names and creating only missing names.'

if ($SkipLifecycleDispatch) {
    Write-Host 'Lifecycle dispatch was explicitly skipped. Run the meAndAI AI capabilities lifecycle workflow before adoption.'
}
else {
    $publishedHead = ((@(Invoke-Git -Repository $target -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    $actorResult = Invoke-External -Command 'gh' -Arguments @('api', 'user', '--jq', '.login')
    $authenticatedActor = ((@($actorResult.Output) -join '').Trim())
    if ($authenticatedActor -cnotmatch '^[A-Za-z0-9_.-]+$') {
        throw 'The authenticated GitHub maintainer identity is invalid.'
    }
    $adoptionBranch = "automation/meandai-capabilities-$ProtocolTag"
    $existingAdoptionHead = Get-RemoteBranchHead -Repository $target `
        -Remote $RemoteName -Branch $adoptionBranch -AllowMissing
    $preExistingPullRequest = if ($existingAdoptionHead) {
        Get-AdoptionPullRequest -Repository $repository -BaseBranch $defaultBranch `
            -ExpectedActor $authenticatedActor -MaxAttempts 1
    }
    else { $null }
    if ($null -ne $preExistingPullRequest -and
        [string]$preExistingPullRequest.meAndAIMarker.phase -cin @('Publishing', 'Completed')) {
        $adoptionPullRequestResults = @($preExistingPullRequest)
        Write-Host 'A launcher-owned completion transition already exists; lifecycle dispatch was not repeated.'
    }
    else {
        Set-QuickAdoptionProgress -Status 'Waiting for lifecycle workflow' `
            -PercentComplete 70
        $run = Invoke-LifecycleWorkflow -Repository $repository -Branch $defaultBranch -HeadSha $publishedHead
        Write-Host "Lifecycle workflow completed successfully: $($run.url)"
        Set-QuickAdoptionProgress -Status 'Resolving adoption draft' `
            -PercentComplete 78
        $adoptionPullRequestResults = @(Get-AdoptionPullRequest -Repository $repository `
            -BaseBranch $defaultBranch -ExpectedActor $authenticatedActor)
    }
    if ($adoptionPullRequestResults.Count -gt 1) {
        $types = @($adoptionPullRequestResults | ForEach-Object { $_.GetType().FullName }) -join ', '
        throw "Adoption pull-request resolution returned ambiguous results: $types"
    }
    $adoptionPullRequest = if ($adoptionPullRequestResults.Count -eq 1) {
        $adoptionPullRequestResults[0]
    }
    else {
        $null
    }
    if ($null -eq $adoptionPullRequest) {
        Write-Host 'No open deterministic adoption draft was produced; inspect the successful lifecycle run before continuing.'
    }
    else {
        if ($null -eq $adoptionPullRequest.PSObject.Properties['url']) {
            $propertyNames = @($adoptionPullRequest.PSObject.Properties | ForEach-Object { $_.Name }) -join ', '
            throw "Resolved adoption pull-request metadata has unexpected properties: $propertyNames"
        }
        Write-Host "Adoption draft: $($adoptionPullRequest.url)"
        if ($SkipLocalCodex) {
            Write-Host 'Local Codex execution was explicitly skipped; use the quick-guide prompt in an isolated checkout of this draft.'
        }
        else {
            Set-QuickAdoptionProgress -Status 'Running local Codex' `
                -PercentComplete 84
            $completion = Complete-AdoptionWithLocalCodex -TargetRepository $target `
                -Repository $repository -PullRequest $adoptionPullRequest `
                -CanonicalBaseHead $publishedHead -ProtocolToken $protocolToken
            if ($completion.Ran) {
                Write-Host "Local Codex completed synchronously through $($completion.Runner)."
                Write-Host "The validated adoption commit was pushed and the pull request is ready: $($adoptionPullRequest.url)"
            }
            else {
                Write-Host 'The adoption manifest was already absent; local Codex was not run again.'
                if ($completion.Ready) {
                    Write-Host "The pull request was already ready for the maintainer's final review: $($adoptionPullRequest.url)"
                }
                else {
                    Write-Host "The draft was not changed because prior manifest removal has no launcher-owned validation evidence; review it and mark it ready manually: $($adoptionPullRequest.url)"
                }
            }
        }
    }
}

Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
Write-Host 'The launcher never approves or merges the adoption pull request; the maintainer owns the final merge.'
}
finally {
    Complete-QuickAdoptionProgress
}
