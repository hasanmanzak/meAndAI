[CmdletBinding()]
param(
    [string]$TargetPath = '.',
    [string]$Owner = '',
    [string]$RepositoryName = '',
    [ValidateSet('private', 'public', 'internal')]
    [string]$Visibility = 'private',
    [string]$ProtocolRepository = 'hasanmanzak/meAndAI',
    [string]$ProtocolTag = 'v0.15.0',
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
    [string]$TemporaryCodexVersion = '0.144.4'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$modulePath = Join-Path $root 'scripts/quick-adoption/MeAndAI.QuickAdoption.psd1'
$module = Import-Module -Name $modulePath -Force -PassThru
try {
    $command = Get-Command -Name 'Invoke-MeAndAIQuickAdoption' `
        -Module $module.Name -CommandType Function -ErrorAction Stop
    & $command @PSBoundParameters
}
finally {
    Remove-Module -ModuleInfo $module -Force
}
