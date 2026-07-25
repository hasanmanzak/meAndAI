[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$owner = 'tests/capabilities/windows-validation/windows-validation-profile.tests.ps1'
$selectorPath = Join-Path $root 'tests/capabilities/windows-validation/Select-WindowsValidationProfile.ps1'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestContext.psm1') -Force
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.TestRepository.psm1') -Force
$scenarioEvidenceContext = New-MeAndAIScenarioEvidenceContext `
    -Owner $owner -AuthorityPath $scenarioAuthorityPath
$failureContext = New-MeAndAITestContext
Set-MeAndAITestContext -Context $failureContext
$failures = $failureContext.Failures
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-windows-profile-$([guid]::NewGuid().ToString('N'))"
$repository = Join-Path $tempRoot 'repository'

function Invoke-TestGit {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $repository @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}


function Set-TestFile {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Content
    )

    $path = Join-Path $repository $RelativePath
    [IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function Assert-Profile {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Expected,
        [Parameter(Mandatory)][string]$EventName,
        [string]$BaseCommit = '',
        [string]$HeadCommit = ''
    )

    if (-not (Test-Path -LiteralPath $selectorPath -PathType Leaf)) {
        Add-Failure "TEST-0123 selector is missing while evaluating '$Name'."
        return
    }

    try {
        $output = @(& $selectorPath -EventName $EventName `
            -BaseCommit $BaseCommit -HeadCommit $HeadCommit `
            -RepositoryRoot $repository 2>&1 | ForEach-Object { [string]$_ })
        $observed = @($output | Where-Object {
            $_ -ceq 'Full' -or $_ -ceq 'WindowsNative'
        })
        if ($observed.Count -ne 1 -or $observed[0] -cne $Expected -or
            @($output | Where-Object {
                $_ -cne 'Full' -and $_ -cne 'WindowsNative'
            }).Count -ne 0) {
            Add-Failure "TEST-0123 '$Name' expected '$Expected' and one clean output line; observed '$($output -join ' | ')'."
        }
    }
    catch {
        Add-Failure "TEST-0123 '$Name' threw instead of failing safe: $($_.Exception.Message)"
    }
}

try {
    [IO.Directory]::CreateDirectory($repository) | Out-Null
    Invoke-TestGit -Arguments @('init') | Out-Null
    Invoke-TestGit -Arguments @('config', 'user.name', 'meAndAI tests') | Out-Null
    Invoke-TestGit -Arguments @('config', 'user.email', 'tests@meandai.invalid') | Out-Null
    Invoke-TestGit -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
    Invoke-TestGit -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null
    Invoke-TestGit -Arguments @('config', 'tag.gpgsign', 'false') | Out-Null

    $baseline = New-MeAndAITestCommit -Repository $repository -Message 'Baseline' -Change {
        Set-TestFile -RelativePath 'README.md' -Content "baseline`n"
        Set-TestFile -RelativePath 'scripts/tool.ps1' -Content "'baseline'`n"
    }
    $markdown = New-MeAndAITestCommit -Repository $repository -Message 'Documentation change' -Change {
        Set-TestFile -RelativePath 'README.md' -Content "documentation`n"
    }
    Assert-Profile -Name 'pull request documentation diff' `
        -Expected 'WindowsNative' -EventName 'pull_request' `
        -BaseCommit $baseline -HeadCommit $markdown
    Assert-Profile -Name 'push documentation diff' `
        -Expected 'WindowsNative' -EventName 'push' `
        -BaseCommit $baseline -HeadCommit $markdown

    $powerShell = New-MeAndAITestCommit -Repository $repository -Message 'PowerShell change' -Change {
        Set-TestFile -RelativePath 'scripts/tool.ps1' -Content "'changed'`n"
    }
    Assert-Profile -Name 'PowerShell modification' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $markdown -HeadCommit $powerShell

    $workflow = New-MeAndAITestCommit -Repository $repository -Message 'Workflow change' -Change {
        Set-TestFile -RelativePath 'templates/project/.github/workflows/update.yml' `
            -Content "name: update`n"
    }
    Assert-Profile -Name 'nested workflow definition' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $powerShell -HeadCommit $workflow

    $migration = New-MeAndAITestCommit -Repository $repository -Message 'Migration change' -Change {
        Set-TestFile -RelativePath 'migrations/MIG-9000.json' -Content "{}`n"
    }
    Assert-Profile -Name 'migration definition' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $workflow -HeadCommit $migration

    $commandWrapper = New-MeAndAITestCommit -Repository $repository -Message 'Command wrapper change' -Change {
        Set-TestFile -RelativePath 'tools/run.cmd' -Content "@echo off`n"
    }
    Assert-Profile -Name 'Windows command wrapper' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $migration -HeadCommit $commandWrapper

    $deleted = New-MeAndAITestCommit -Repository $repository -Message 'Delete PowerShell source' -Change {
        Remove-Item -LiteralPath (Join-Path $repository 'scripts/tool.ps1') -Force
    }
    Assert-Profile -Name 'sensitive deletion' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $commandWrapper -HeadCommit $deleted

    $renameBase = New-MeAndAITestCommit -Repository $repository -Message 'Add rename source' -Change {
        Set-TestFile -RelativePath 'scripts/renamed.ps1' -Content "'rename'`n"
    }
    $renamed = New-MeAndAITestCommit -Repository $repository -Message 'Rename sensitive source' -Change {
        [IO.Directory]::CreateDirectory((Join-Path $repository 'docs')) | Out-Null
        Invoke-TestGit -Arguments @(
            'mv', 'scripts/renamed.ps1', 'docs/renamed.md'
        ) | Out-Null
    }
    Assert-Profile -Name 'sensitive rename sees removed path' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $renameBase -HeadCommit $renamed

    $oversizedBase = $renamed
    $oversized = New-MeAndAITestCommit -Repository $repository -Message 'Oversized documentation diff' -Change {
        foreach ($index in 1..301) {
            Set-TestFile -RelativePath "docs/generated/$index.md" -Content "$index`n"
        }
    }
    Assert-Profile -Name 'more than 300 changed paths' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit $oversizedBase -HeadCommit $oversized

    Assert-Profile -Name 'empty diff' -Expected 'Full' -EventName 'pull_request' `
        -BaseCommit $oversized -HeadCommit $oversized
    Assert-Profile -Name 'malformed commit identity' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit 'not-a-commit' -HeadCommit $oversized
    Assert-Profile -Name 'unavailable commit identity' -Expected 'Full' `
        -EventName 'pull_request' -BaseCommit ('f' * 40) -HeadCommit $oversized
    Assert-Profile -Name 'manual ordinary dispatch' -Expected 'Full' `
        -EventName 'workflow_dispatch'
    Assert-Profile -Name 'merge queue' -Expected 'Full' -EventName 'merge_group'
}
catch {
    Add-Failure "TEST-0123 fixture failed: $($_.Exception.Message) [$($_.ScriptStackTrace)]"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Windows validation profile tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Confirm-MeAndAIScenarioEvidence -Context $scenarioEvidenceContext `
    -TestId 'TEST-0123'
Write-Host 'Windows validation profile tests passed for TEST-0123.' `
    -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult -Context $scenarioEvidenceContext
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
