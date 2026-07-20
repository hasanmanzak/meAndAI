# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
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

function Enter-GitHookSuppression {
    $countName = 'GIT_CONFIG_COUNT'
    $previousCount = [Environment]::GetEnvironmentVariable($countName, 'Process')
    $count = if ([string]::IsNullOrEmpty($previousCount)) {
        0
    }
    elseif ($previousCount -cmatch '^(?:0|[1-9][0-9]*)$' -and
        [int64]$previousCount -le 64) {
        [int]$previousCount
    }
    else {
        throw 'The process Git configuration environment is malformed; hooks cannot be suppressed safely.'
    }
    $keyName = "GIT_CONFIG_KEY_$count"
    $valueName = "GIT_CONFIG_VALUE_$count"
    $previousKey = [Environment]::GetEnvironmentVariable($keyName, 'Process')
    $previousValue = [Environment]::GetEnvironmentVariable($valueName, 'Process')
    $disabledHooksPath = Join-Path ([IO.Path]::GetTempPath()) `
        ".meandai-disabled-hooks-$([guid]::NewGuid().ToString('N'))"
    if (Test-Path -LiteralPath $disabledHooksPath) {
        throw 'Unable to establish a unique disabled Git hooks path.'
    }

    try {
        [Environment]::SetEnvironmentVariable(
            $keyName, 'core.hooksPath', 'Process'
        )
        [Environment]::SetEnvironmentVariable(
            $valueName, $disabledHooksPath, 'Process'
        )
        [Environment]::SetEnvironmentVariable(
            $countName, [string]($count + 1), 'Process'
        )
    }
    catch {
        [Environment]::SetEnvironmentVariable($countName, $previousCount, 'Process')
        [Environment]::SetEnvironmentVariable($keyName, $previousKey, 'Process')
        [Environment]::SetEnvironmentVariable($valueName, $previousValue, 'Process')
        throw
    }

    return [pscustomobject]@{
        CountName = $countName
        PreviousCount = $previousCount
        KeyName = $keyName
        PreviousKey = $previousKey
        ValueName = $valueName
        PreviousValue = $previousValue
        DisabledHooksPath = $disabledHooksPath
    }
}

function Assert-GitHookSuppression {
    param([Parameter(Mandatory)]$State)

    $result = Invoke-External -Command 'git' -Arguments @(
        'config', '--get', 'core.hooksPath'
    )
    $values = @($result.Output | Where-Object { $_ } | ForEach-Object {
        [string]$_
    })
    if ($values.Count -ne 1 -or
        $values[0] -cne [string]$State.DisabledHooksPath) {
        throw 'The installed Git does not honor the launcher hook-suppression boundary.'
    }
}

function Exit-GitHookSuppression {
    param([Parameter(Mandatory)]$State)

    [Environment]::SetEnvironmentVariable(
        [string]$State.CountName, $State.PreviousCount, 'Process'
    )
    [Environment]::SetEnvironmentVariable(
        [string]$State.KeyName, $State.PreviousKey, 'Process'
    )
    [Environment]::SetEnvironmentVariable(
        [string]$State.ValueName, $State.PreviousValue, 'Process'
    )
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
