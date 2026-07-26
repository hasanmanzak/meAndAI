[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.15.5',
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
        'InitialPolicyContract'
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
