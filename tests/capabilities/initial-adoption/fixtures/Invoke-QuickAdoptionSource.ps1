[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.16.0',
    [string]$RemoteName = 'origin',
    [ValidateRange(1, 60)]
    [int]$WorkflowTimeoutMinutes = 15,
    [ValidateRange(1, 120)]
    [int]$CodexTimeoutMinutes = 30,
    [ValidateRange(0, 7200)]
    [int]$CodexTimeoutSeconds = 0,
    [ValidateSet('Auto', 'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart', 'Abort')]
    [string]$AdoptionStrategy = 'Auto',
    [switch]$NonInteractive,
    [switch]$AcknowledgeProtocolRecordLoss,
    [switch]$SkipLifecycleDispatch,
    [Alias('SkipCodexDelegation')]
    [switch]$SkipLocalCodex,
    [switch]$NoProgress,
    [string]$CodexCommand = '',
    [string]$TemporaryCodexVersion = '0.144.4',
    [ValidateSet(
        'Launcher',
        'GitHubCliVersionContract',
        'CredentialContainmentContract',
        'InitialPolicyContract',
        'HistoricalIssueContract'
    )]
    [string]$SupportAction = 'Launcher',
    [AllowNull()][object[]]$SupportInput = @()
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$modulePath = Join-Path $root 'scripts/quick-adoption/MeAndAI.QuickAdoption.psd1'
$module = Import-Module -Name $modulePath -Force -PassThru
try {
    if ($SupportAction -ceq 'GitHubCliVersionContract') {
        $versionOutput = @($SupportInput | ForEach-Object { [string]$_ })
        return & $module {
            param([string[]]$InjectedVersionOutput)

            $script:QuickAdoptionContractCalls =
                [System.Collections.Generic.List[object]]::new()
            function Invoke-External {
                param(
                    [Parameter(Mandatory)][string]$Command,
                    [string[]]$Arguments = @(),
                    [switch]$AllowFailure,
                    [AllowNull()][string]$StandardInput = $null,
                    [AllowNull()][hashtable]$Environment = $null,
                    [AllowNull()][string]$WorkingDirectory = $null
                )

                [void]$script:QuickAdoptionContractCalls.Add(
                    [pscustomobject][ordered]@{
                        Command = $Command
                        Arguments = @($Arguments)
                    }
                )
                return [pscustomobject][ordered]@{
                    ExitCode = 0
                    Output = @($InjectedVersionOutput)
                    Error = @()
                }
            }

            $errorText = ''
            try {
                $versionContract = Get-Command `
                    -Name 'Assert-MinimumGitHubCliVersion' `
                    -CommandType Function -ErrorAction Stop
                & $versionContract
            }
            catch {
                $errorText = $_.Exception.Message
            }
            return [pscustomobject][ordered]@{
                Succeeded = [string]::IsNullOrEmpty($errorText)
                Error = $errorText
                Calls = @($script:QuickAdoptionContractCalls)
            }
        } $versionOutput
    }

    if ($SupportAction -ceq 'CredentialContainmentContract') {
        $resolvedTarget = [IO.Path]::GetFullPath($TargetPath)
        return & $module {
            param([string]$Repository)

            $script:QuickAdoptionContractCalls =
                [System.Collections.Generic.List[object]]::new()
            $script:QuickAdoptionOriginalInvokeGit =
                (Get-Command -Name 'Invoke-Git' -CommandType Function `
                    -ErrorAction Stop).ScriptBlock
            function Invoke-Git {
                param(
                    [Parameter(Mandatory)][string]$Repository,
                    [Parameter(Mandatory)][string[]]$Arguments,
                    [switch]$AllowFailure
                )

                [void]$script:QuickAdoptionContractCalls.Add(
                    [pscustomobject][ordered]@{
                        Arguments = @($Arguments)
                    }
                )
                return & $script:QuickAdoptionOriginalInvokeGit `
                    -Repository $Repository -Arguments $Arguments `
                    -AllowFailure:$AllowFailure
            }

            $errorText = ''
            try {
                $credentialContract = Get-Command `
                    -Name 'Assert-TokenFilesAreLocalOnly' `
                    -CommandType Function -ErrorAction Stop
                & $credentialContract -Repository $Repository
            }
            catch {
                $errorText = $_.Exception.Message
            }
            return [pscustomobject][ordered]@{
                Succeeded = [string]::IsNullOrEmpty($errorText)
                Error = $errorText
                GitProcessCount =
                    [long]$script:QuickAdoptionContractCalls.Count
                Calls = @($script:QuickAdoptionContractCalls)
            }
        } $resolvedTarget
    }

    if ($SupportAction -ceq 'InitialPolicyContract') {
        if ($SupportInput.Count -ne 1 -or
            $null -eq $SupportInput[0] -or
            $SupportInput[0].WorkflowBytes -isnot [byte[]] -or
            $SupportInput[0].PolicyBytes -isnot [byte[]] -or
            [string]$SupportInput[0].PolicySha -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$SupportInput[0].TargetTag -cnotmatch
                '^v[0-9]+\.[0-9]+\.[0-9]+$' -or
            [string]$SupportInput[0].RuntimePolicyTag -cnotmatch
                '^v[0-9]+\.[0-9]+\.[0-9]+$') {
            throw 'Initial-policy contract support input is invalid.'
        }
        $runtimePolicyBytesProperty =
            $SupportInput[0].PSObject.Properties['RuntimePolicyBytes']
        $runtimePolicyShaProperty =
            $SupportInput[0].PSObject.Properties['RuntimePolicySha']
        if (($null -eq $runtimePolicyBytesProperty) -ne
                ($null -eq $runtimePolicyShaProperty) -or
            ($null -ne $runtimePolicyBytesProperty -and
             ($runtimePolicyBytesProperty.Value -isnot [byte[]] -or
              [string]$runtimePolicyShaProperty.Value -cnotmatch
                '^[0-9a-f]{40}$'))) {
            throw 'Initial-policy contract runtime support input is invalid.'
        }
        return & $module {
            param([pscustomobject]$Case)

            $script:QuickAdoptionInitialPolicyContractCase = $Case
            $script:QuickAdoptionInitialPolicyAssetCalls = 0
            function script:Get-CanonicalProtocolAsset {
                param(
                    [Parameter(Mandatory)][string]$Tag,
                    [Parameter(Mandatory)][string]$TemplatePath,
                    [string]$ProtocolToken = ''
                )

                if ($TemplatePath -cne
                        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1' -or
                    -not [string]::IsNullOrEmpty($ProtocolToken)) {
                    throw 'Initial-policy contract requested an unexpected canonical asset.'
                }
                $isTarget = $Tag -ceq
                    [string]$script:QuickAdoptionInitialPolicyContractCase.
                        TargetTag
                $isRuntime = $Tag -ceq
                    [string]$script:QuickAdoptionInitialPolicyContractCase.
                        RuntimePolicyTag -and
                    $null -ne $script:QuickAdoptionInitialPolicyContractCase.
                        PSObject.Properties['RuntimePolicyBytes']
                if (-not $isTarget -and -not $isRuntime) {
                    throw 'Initial-policy contract requested an unexpected canonical asset.'
                }
                $script:QuickAdoptionInitialPolicyAssetCalls++
                [byte[]]$selectedBytes = if ($isTarget) {
                    [byte[]]$script:QuickAdoptionInitialPolicyContractCase.
                        PolicyBytes
                }
                else {
                    [byte[]]$script:QuickAdoptionInitialPolicyContractCase.
                        RuntimePolicyBytes
                }
                $selectedSha = if ($isTarget) {
                    [string]$script:QuickAdoptionInitialPolicyContractCase.
                        PolicySha
                }
                else {
                    [string]$script:QuickAdoptionInitialPolicyContractCase.
                        RuntimePolicySha
                }
                return [pscustomobject][ordered]@{
                    Tag = $Tag
                    TemplatePath = $TemplatePath
                    Bytes = $selectedBytes
                    Sha = $selectedSha
                }
            }

            $policy = $null
            try {
                $selectedTag = Resolve-QuickAdoptionInitialPolicyTag `
                    -WorkflowBytes ([byte[]]$Case.WorkflowBytes) `
                    -TargetTag ([string]$Case.TargetTag) `
                    -RuntimePolicyTag ([string]$Case.RuntimePolicyTag)
                $policy = Import-CanonicalInitialAdoptionPolicy `
                    -Tag $selectedTag
                return [pscustomobject][ordered]@{
                    SelectedTag = [string]$selectedTag
                    ImportedTag = [string]$policy.Tag
                    GraphSchema = [int]$policy.GraphSchema
                    MaximumBlobBytes = [int]$policy.Limits.MaximumBlobBytes
                    AssetCalls =
                        [int]$script:QuickAdoptionInitialPolicyAssetCalls
                    ModuleCount = @($policy.Modules).Count
                    CommandSources = $policy.CommandSources
                }
            }
            finally {
                if ($null -ne $policy) {
                    [object[]]$policyModules = @($policy.Modules)
                    if ($policyModules.Count -eq 0 -and
                        $null -ne $policy.Module) {
                        $policyModules = @($policy.Module)
                    }
                    [array]::Reverse($policyModules)
                    foreach ($policyModule in $policyModules) {
                        Remove-Module -ModuleInfo $policyModule -Force `
                            -ErrorAction SilentlyContinue
                    }
                }
            }
        } ([pscustomobject]$SupportInput[0])
    }

    if ($SupportAction -ceq 'HistoricalIssueContract') {
        if ($SupportInput.Count -ne 1 -or $null -eq $SupportInput[0] -or
            [string]$SupportInput[0].Mode -cnotin @(
                'LocalClassification', 'ProviderProof', 'InventoryProof',
                'SnapshotProof', 'RegistryProof'
            )) {
            throw 'Historical-issue contract support input is invalid.'
        }
        return & $module {
            param([pscustomobject]$Case)

            $script:HistoricalIssueContractCalls =
                [System.Collections.Generic.List[object]]::new()
            $protocolToken = if ($null -ne
                    $Case.PSObject.Properties['ProtocolToken']) {
                [string]$Case.ProtocolToken
            }
            else { '' }
            if ([string]$Case.Mode -ceq 'RegistryProof') {
                $records = @($Case.Tags | ForEach-Object {
                    [pscustomobject]@{
                        Tag = [string]$_
                        Commit = Get-CompletedHistoricalAdoptionReleaseCommit `
                            -Tag ([string]$_)
                    }
                })
                return [pscustomobject][ordered]@{
                    Succeeded = $true
                    Error = ''
                    Result = @($records)
                    Calls = @()
                }
            }
            if ([string]$Case.Mode -ceq 'InventoryProof') {
                function script:Invoke-External {
                    param(
                        [Parameter(Mandatory)][string]$Command,
                        [string[]]$Arguments = @(),
                        [switch]$AllowFailure,
                        [AllowNull()][string]$InputText = $null
                    )
                    $script:HistoricalIssueContractCalls.Add(
                        [pscustomobject]@{
                            Kind = 'IssueInventory'
                            Arguments = @($Arguments)
                        }
                    )
                    if ($null -ne $Case.PSObject.Properties['RawOutput']) {
                        return [pscustomobject]@{
                            ExitCode = 0
                            Output = @([string]$Case.RawOutput)
                            Error = @()
                        }
                    }
                    $issues = [System.Collections.Generic.List[object]]::new()
                    if ([int]$Case.IssueCount -gt 0) {
                        foreach ($number in 1..([int]$Case.IssueCount)) {
                            $issues.Add([pscustomobject]@{
                                number = $number
                                url = "https://github.com/test-owner/consumer/issues/$number"
                                title = "Issue $number"
                                body = ''
                                state = 'OPEN'
                                stateReason = ''
                                closedAt = $null
                                author = [pscustomobject]@{ login = 'test-owner' }
                            })
                        }
                    }
                    $json = if ($issues.Count -eq 0) {
                        '[]'
                    }
                    else {
                        @($issues) | ConvertTo-Json -Depth 4 -Compress
                    }
                    return [pscustomobject]@{
                        ExitCode = 0
                        Output = @($json)
                        Error = @()
                    }
                }
                $errorText = ''
                $resultCount = 0
                try {
                    $resultCount = @(Get-AdoptionIssueInventory `
                        -Repository ([string]$Case.Repository)).Count
                }
                catch { $errorText = $_.Exception.Message }
                return [pscustomobject][ordered]@{
                    Succeeded = [string]::IsNullOrEmpty($errorText)
                    Error = $errorText
                    ResultCount = $resultCount
                    Calls = @($script:HistoricalIssueContractCalls)
                }
            }
            if ([string]$Case.Mode -ceq 'SnapshotProof') {
                $script:HistoricalIssueSnapshotInventoryRead = 0
                function script:Get-AdoptionIssueInventory {
                    param([Parameter(Mandatory)][string]$Repository)
                    $script:HistoricalIssueSnapshotInventoryRead++
                    $script:HistoricalIssueContractCalls.Add(
                        [pscustomobject]@{
                            Kind = 'IssueInventory'
                            Read = $script:HistoricalIssueSnapshotInventoryRead
                        }
                    )
                    if ($script:HistoricalIssueSnapshotInventoryRead -eq 1) {
                        return @($Case.FirstIssues)
                    }
                    return @($Case.SecondIssues)
                }
                function script:Get-ValidatedCompletedHistoricalAdoptionIssue {
                    param(
                        [Parameter(Mandatory)]$Candidate,
                        [Parameter(Mandatory)][string]$Repository,
                        [Parameter(Mandatory)][string]$TargetRepository,
                        [Parameter(Mandatory)][string]$BaseBranch,
                        [Parameter(Mandatory)][string]$TargetRemote,
                        [string]$ProtocolToken = ''
                    )
                    $script:HistoricalIssueContractCalls.Add(
                        [pscustomobject]@{ Kind = 'HistoricalProvider' }
                    )
                    return [pscustomobject]@{
                        number = $Candidate.Issue.number
                        url = $Candidate.Issue.url
                        title = $Candidate.Issue.title
                        body = $Candidate.Issue.body
                        state = $Candidate.Issue.state
                        classification = 'CompletedHistorical'
                        markerKind = 'CompletedHistorical'
                        targetTag = $Candidate.TargetTag
                        pullRequestNumber = $Candidate.PullRequestNumber
                        fingerprint = $Candidate.Fingerprint
                    }
                }
                $errorText = ''
                $snapshot = $null
                $result = @()
                try {
                    $snapshot = Get-AdoptionIssueReconciliationSnapshot `
                        -Repository ([string]$Case.Repository) `
                        -TargetRepository ([string]$Case.TargetRepository) `
                        -BaseBranch ([string]$Case.BaseBranch) `
                        -TargetTag ([string]$Case.ProtocolTag) `
                        -TargetRemote 'origin'
                    $result = @(Confirm-AdoptionIssueReconciliationSnapshot `
                        -Snapshot $snapshot `
                        -Repository ([string]$Case.Repository) `
                        -TargetRepository ([string]$Case.TargetRepository) `
                        -BaseBranch ([string]$Case.BaseBranch) `
                        -TargetTag ([string]$Case.ProtocolTag))
                }
                catch { $errorText = $_.Exception.Message }
                return [pscustomobject][ordered]@{
                    Succeeded = [string]::IsNullOrEmpty($errorText)
                    Error = $errorText
                    Snapshot = $snapshot
                    Result = @($result)
                    Calls = @($script:HistoricalIssueContractCalls)
                }
            }
            if ([string]$Case.Mode -ceq 'LocalClassification') {
                $script:ProtocolTag = [string]$Case.ProtocolTag
                function script:Get-ValidatedCompletedHistoricalAdoptionIssue {
                    param(
                        [Parameter(Mandatory)]$Candidate,
                        [Parameter(Mandatory)][string]$Repository,
                        [Parameter(Mandatory)][string]$TargetRepository,
                        [Parameter(Mandatory)][string]$BaseBranch,
                        [Parameter(Mandatory)][string]$TargetRemote,
                        [string]$ProtocolToken = ''
                    )
                    $script:HistoricalIssueContractCalls.Add(
                        [pscustomobject]@{
                            Kind = 'HistoricalProvider'
                            ProtocolToken = $ProtocolToken
                        }
                    )
                    return [pscustomobject]@{
                        number = $Candidate.Issue.number
                        url = $Candidate.Issue.url
                        title = $Candidate.Issue.title
                        body = $Candidate.Issue.body
                        state = $Candidate.Issue.state
                        classification = 'CompletedHistorical'
                        markerKind = 'CompletedHistorical'
                        targetTag = $Candidate.TargetTag
                        pullRequestNumber = $Candidate.PullRequestNumber
                        fingerprint = $Candidate.Fingerprint
                    }
                }
                $errorText = ''
                $result = @()
                try {
                    $parameters = @{
                        Issues = @($Case.Issues)
                        Repository = [string]$Case.Repository
                        TargetRepository = [string]$Case.TargetRepository
                        BaseBranch = [string]$Case.BaseBranch
                        CurrentTargetTag = [string]$Case.ProtocolTag
                        Marker = [string]$Case.Marker
                        ExpectedTitle = [string]$Case.ExpectedTitle
                        ExpectedBody = [string]$Case.ExpectedBody
                        LegacyMarker = [string]$Case.LegacyMarker
                        LegacyExpectedBody = [string]$Case.LegacyExpectedBody
                        ProtocolToken = $protocolToken
                    }
                    if ($null -ne $Case.PSObject.Properties[
                            'FrozenHistorical']) {
                        $parameters.FrozenHistorical =
                            @($Case.FrozenHistorical)
                    }
                    else {
                        $parameters.ProveHistorical = $true
                    }
                    $result = @(Get-MarkedAdoptionIssues @parameters)
                }
                catch { $errorText = $_.Exception.Message }
                return [pscustomobject][ordered]@{
                    Succeeded = [string]::IsNullOrEmpty($errorText)
                    Error = $errorText
                    Result = @($result)
                    Calls = @($script:HistoricalIssueContractCalls)
                }
            }

            function script:Get-ValidatedImmutableProtocolRelease {
                param([string]$ProtocolToken = '', [string]$Tag)
                $script:HistoricalIssueContractCalls.Add(
                    [pscustomobject]@{
                        Kind = 'Release'
                        Tag = $Tag
                        ProtocolToken = $ProtocolToken
                    }
                )
                if ([string]$Case.ProviderMode -ceq 'ReleaseFailure') {
                    throw 'Injected immutable release failure.'
                }
                return [pscustomobject]@{
                    Tag = $Tag
                    CommitSha = [string]$Case.ReleaseCommit
                }
            }
            function script:Invoke-External {
                param(
                    [Parameter(Mandatory)][string]$Command,
                    [string[]]$Arguments = @(),
                    [switch]$AllowFailure,
                    [AllowNull()][string]$InputText = $null
                )
                $kind = if ($Arguments.Count -ge 2 -and
                    $Arguments[0] -ceq 'pr' -and
                    $Arguments[1] -ceq 'view') { 'PullRequestView' }
                elseif ($Arguments.Count -ge 2 -and
                    $Arguments[0] -ceq 'pr' -and
                    $Arguments[1] -ceq 'list') { 'OpenPullRequestList' }
                else { 'Unexpected' }
                $script:HistoricalIssueContractCalls.Add(
                    [pscustomobject]@{
                        Kind = $kind
                        Arguments = @($Arguments)
                    }
                )
                if ([string]$Case.ProviderMode -ceq 'ProviderFailure') {
                    throw 'Injected historical provider failure.'
                }
                $json = if ($kind -ceq 'PullRequestView') {
                    $Case.PullRequest | ConvertTo-Json -Depth 8 -Compress
                }
                elseif ($kind -ceq 'OpenPullRequestList') {
                    if ($null -ne $Case.PSObject.Properties[
                            'OpenPullRequestRawOutput'] -and
                        $null -ne $Case.OpenPullRequestRawOutput) {
                        [string]$Case.OpenPullRequestRawOutput
                    }
                    elseif (@($Case.OpenPullRequests).Count -eq 0) {
                        '[]'
                    }
                    else {
                        @($Case.OpenPullRequests) |
                            ConvertTo-Json -Depth 8 -Compress
                    }
                }
                else {
                    throw 'Historical-issue contract invoked an unexpected provider route.'
                }
                return [pscustomobject]@{
                    ExitCode = 0
                    Output = @($json)
                    Error = @()
                }
            }
            function script:Test-QuickAdoptionExactPullRequestMarker {
                param(
                    $PullRequest, [string]$RemoteHead,
                    [string]$Repository, [string]$Branch,
                    [string]$BaseBranch, [string]$TargetTag,
                    [string]$TargetSha, [string]$ExpectedActor,
                    [string]$ExpectedState,
                    [string]$ExpectedAdoptionStrategy,
                    [object[]]$ExpectedProtocolSurfaces,
                    [bool]$ExpectedProtocolRecordLossAcknowledgement,
                    $ExpectedSourceGraphIdentity = $null,
                    [string]$ExpectedPhase
                )
                $script:HistoricalIssueContractCalls.Add(
                    [pscustomobject]@{
                        Kind = 'MarkerContract'
                        TargetTag = $TargetTag
                        TargetSha = $TargetSha
                        Actor = $ExpectedActor
                        Phase = $ExpectedPhase
                        Repository = $Repository
                        Branch = $Branch
                        BaseBranch = $BaseBranch
                        RemoteHead = $RemoteHead
                        State = $ExpectedState
                        AdoptionStrategy = $ExpectedAdoptionStrategy
                        ProtocolSurfaces = @($ExpectedProtocolSurfaces)
                        ProtocolRecordLossAcknowledgement =
                            $ExpectedProtocolRecordLossAcknowledgement
                        PullRequestNumber = $PullRequest.number
                        PullRequestUrl = $PullRequest.url
                        PullRequestHead = $PullRequest.headRefOid
                    }
                )
                return [bool]$Case.MarkerContractValid
            }
            function script:Get-RemoteBranchHead {
                param(
                    [Parameter(Mandatory)][string]$Repository,
                    [Parameter(Mandatory)][string]$Remote,
                    [Parameter(Mandatory)][string]$Branch,
                    [switch]$AllowMissing
                )
                $script:HistoricalIssueContractCalls.Add(
                    [pscustomobject]@{
                        Kind = 'RemoteBranch'
                        Repository = $Repository
                        Remote = $Remote
                        Branch = $Branch
                        AllowMissing = [bool]$AllowMissing
                    }
                )
                return [string]$Case.RemoteHead
            }
            $errorText = ''
            $result = $null
            try {
                $result = Get-ValidatedCompletedHistoricalAdoptionIssue `
                    -Candidate $Case.Candidate `
                    -Repository ([string]$Case.Repository) `
                    -TargetRepository ([string]$Case.TargetRepository) `
                    -BaseBranch ([string]$Case.BaseBranch) `
                    -TargetRemote 'origin' `
                    -ProtocolToken $protocolToken
            }
            catch { $errorText = $_.Exception.Message }
            return [pscustomobject][ordered]@{
                Succeeded = [string]::IsNullOrEmpty($errorText)
                Error = $errorText
                Result = $result
                Calls = @($script:HistoricalIssueContractCalls)
            }
        } ([pscustomobject]$SupportInput[0])
    }

    $launcherParameters = @{}
    foreach ($entry in $PSBoundParameters.GetEnumerator()) {
        if ([string]$entry.Key -cnotin @('SupportAction', 'SupportInput')) {
            $launcherParameters[[string]$entry.Key] = $entry.Value
        }
    }
    $command = Get-Command -Name 'Invoke-MeAndAIQuickAdoption' `
        -Module $module.Name -CommandType Function -ErrorAction Stop
    & $command @launcherParameters
}
finally {
    Remove-Module -ModuleInfo $module -Force
}
