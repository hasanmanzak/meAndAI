[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.15.4',
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
        'CredentialContainmentContract'
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
