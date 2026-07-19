[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$modulePath = Join-Path $PSScriptRoot 'MeAndAI.MainValidationRoute.psm1'
$workflowPath = Join-Path $root '.github/workflows/protocol-tests.yml'
$protocolPath = Join-Path $root 'PROTOCOL.md'
$authorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()
$previousProtocolToken = $env:GH_TOKEN
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-main-route-$([guid]::NewGuid().ToString('N'))"
$repositoryRoot = Join-Path $tempRoot 'repository'

function Add-Failure {
    param([Parameter(Mandatory)][string]$Message)
    $failures.Add($Message)
}

function Invoke-TestGit {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $repositoryRoot @Arguments 2>&1)
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

    $path = Join-Path $repositoryRoot $RelativePath
    [IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function New-TestCommit {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][scriptblock]$Change
    )

    & $Change
    Invoke-TestGit -Arguments @('add', '--all') | Out-Null
    Invoke-TestGit -Arguments @('commit', '-m', $Message) | Out-Null
    return (@(Invoke-TestGit -Arguments @('rev-parse', 'HEAD'))[0]).Trim()
}

function New-GreenJobs {
    param([int]$RunId = 501)

    return @(
        [pscustomobject]@{
            id = ($RunId * 10 + 1)
            name = 'Validate on ubuntu-latest'
            status = 'completed'
            conclusion = 'success'
        },
        [pscustomobject]@{
            id = ($RunId * 10 + 2)
            name = 'Validate on windows-latest'
            status = 'completed'
            conclusion = 'success'
        }
    )
}

function New-Evidence {
    param(
        [Parameter(Mandatory)][string]$AfterCommit,
        [Parameter(Mandatory)][string]$HeadCommit,
        [string]$BaseCommit = $script:baseline,
        [string]$HeadBranch = 'codex/feature',
        [int]$PullRequestNumber = 85
    )

    $runId = 501
    return [pscustomobject]@{
        Workflow = [pscustomobject]@{
            id = 77
            path = '.github/workflows/protocol-tests.yml'
            state = 'active'
        }
        MergeGroupRuns = @()
        PullRequests = @(
            [pscustomobject]@{
                number = $PullRequestNumber
                merged_at = '2026-07-19T00:00:00Z'
                merge_commit_sha = $AfterCommit
                base = [pscustomobject]@{
                    ref = 'main'
                    sha = $BaseCommit
                    repo = [pscustomobject]@{ full_name = 'owner/repository' }
                }
                head = [pscustomobject]@{
                    ref = $HeadBranch
                    sha = $HeadCommit
                    repo = [pscustomobject]@{ full_name = 'owner/repository' }
                }
            }
        )
        PullRequestRuns = @(
            [pscustomobject]@{
                id = $runId
                event = 'pull_request'
                status = 'completed'
                conclusion = 'success'
                head_sha = $HeadCommit
                head_branch = $HeadBranch
                path = '.github/workflows/protocol-tests.yml'
                pull_requests = @([pscustomobject]@{ number = $PullRequestNumber })
            }
        )
        JobsByRun = @{ [string]$runId = @(New-GreenJobs -RunId $runId) }
        ThrowKind = ''
    }
}

function New-EvidenceProvider {
    param([Parameter(Mandatory)]$Evidence)

    $captured = $Evidence
    return {
        param(
            [Parameter(Mandatory)][string]$Kind,
            [Parameter(Mandatory)][hashtable]$Context
        )

        if ([string]$captured.ThrowKind -ceq $Kind) {
            throw "Synthetic provider failure for $Kind."
        }
        switch -CaseSensitive ($Kind) {
            'Workflow' { return $captured.Workflow }
            'MergeGroupRuns' { return @($captured.MergeGroupRuns) }
            'PullRequests' { return @($captured.PullRequests) }
            'PullRequestRuns' { return @($captured.PullRequestRuns) }
            'Jobs' { return @($captured.JobsByRun[[string]$Context.RunId]) }
            default { throw "Unexpected evidence kind '$Kind'." }
        }
    }.GetNewClosure()
}

function Assert-Route {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Expected,
        [Parameter(Mandatory)][AllowEmptyString()][string]$BeforeCommit,
        [Parameter(Mandatory)][AllowEmptyString()][string]$AfterCommit,
        [Parameter(Mandatory)]$Evidence,
        [string]$EventName = 'push'
    )

    try {
        $observed = @(Resolve-MeAndAIMainValidationRoute `
            -EventName $EventName -Repository 'owner/repository' `
            -DefaultBranch 'main' -BeforeCommit $BeforeCommit `
            -AfterCommit $AfterCommit -RepositoryRoot $repositoryRoot `
            -EvidenceProvider (New-EvidenceProvider -Evidence $Evidence))
        if ($observed.Count -ne 1 -or [string]$observed[0] -cne $Expected) {
            Add-Failure "TEST-0143 '$Name' expected '$Expected'; observed '$($observed -join ' | ')'."
        }
    }
    catch {
        Add-Failure "TEST-0143 '$Name' threw instead of failing closed: $($_.Exception.Message)"
    }
}

try {
    [IO.Directory]::CreateDirectory($repositoryRoot) | Out-Null
    Invoke-TestGit -Arguments @('init', '-b', 'main') | Out-Null
    Invoke-TestGit -Arguments @('config', 'user.name', 'meAndAI tests') | Out-Null
    Invoke-TestGit -Arguments @('config', 'user.email', 'tests@meandai.invalid') | Out-Null
    Invoke-TestGit -Arguments @('config', 'core.autocrlf', 'false') | Out-Null
    Invoke-TestGit -Arguments @('config', 'commit.gpgsign', 'false') | Out-Null

    $baseline = New-TestCommit -Message 'baseline' -Change {
        Set-TestFile -RelativePath 'README.md' -Content "baseline`n"
    }
    Invoke-TestGit -Arguments @('switch', '-c', 'feature') | Out-Null
    $featureHead = New-TestCommit -Message 'feature' -Change {
        Set-TestFile -RelativePath 'feature.txt' -Content "feature`n"
    }
    Invoke-TestGit -Arguments @('switch', 'main') | Out-Null
    Invoke-TestGit -Arguments @('merge', '--no-ff', 'feature', '-m', 'merge feature') | Out-Null
    $exactMerge = (@(Invoke-TestGit -Arguments @('rev-parse', 'HEAD'))[0]).Trim()

    Invoke-TestGit -Arguments @('switch', '-c', 'base-extra', $baseline) | Out-Null
    $advancedBase = New-TestCommit -Message 'base extra' -Change {
        Set-TestFile -RelativePath 'base.txt' -Content "base`n"
    }
    Invoke-TestGit -Arguments @('merge', '--no-ff', 'feature', '-m', 'merge with extra base') | Out-Null
    $differentTreeMerge = (@(Invoke-TestGit -Arguments @('rev-parse', 'HEAD'))[0]).Trim()

    Invoke-TestGit -Arguments @('switch', 'main') | Out-Null
    $directPush = New-TestCommit -Message 'direct push' -Change {
        Set-TestFile -RelativePath 'direct.txt' -Content "direct`n"
    }
    Invoke-TestGit -Arguments @('switch', '-c', 'squash', $baseline) | Out-Null
    $squashPush = New-TestCommit -Message 'squashed feature' -Change {
        Set-TestFile -RelativePath 'feature.txt' -Content "feature`n"
    }

    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        Add-Failure 'TEST-0143 main-validation route module is missing.'
    }
    else {
        Import-Module $modulePath -Force
        if ($null -eq (Get-Command Resolve-MeAndAIMainValidationRoute -ErrorAction SilentlyContinue)) {
            Add-Failure 'TEST-0143 main-validation route command is missing.'
        }
        else {
            $exact = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            Assert-Route -Name 'exact validated PR merge tree' `
                -Expected 'ReuseExactValidatedTree' -BeforeCommit $baseline `
                -AfterCommit $exactMerge -Evidence $exact

            $mergeGroup = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $mergeGroup.PullRequests = @()
            $mergeGroup.PullRequestRuns = @()
            $mergeGroup.MergeGroupRuns = @(
                [pscustomobject]@{
                    id = 601; event = 'merge_group'; status = 'completed'
                    conclusion = 'success'; head_sha = $exactMerge
                    path = '.github/workflows/protocol-tests.yml'
                }
            )
            $mergeGroup.JobsByRun = @{ '601' = @(New-GreenJobs -RunId 601) }
            Assert-Route -Name 'exact validated merge-group commit' `
                -Expected 'ReuseExactValidatedTree' -BeforeCommit $baseline `
                -AfterCommit $exactMerge -Evidence $mergeGroup

            Assert-Route -Name 'unprotected direct push' -Expected 'Full' `
                -BeforeCommit $exactMerge -AfterCommit $directPush `
                -Evidence (New-Evidence -AfterCommit $directPush -HeadCommit $directPush)
            Assert-Route -Name 'squash one-parent push' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $squashPush `
                -Evidence (New-Evidence -AfterCommit $squashPush -HeadCommit $squashPush)
            Assert-Route -Name 'rebased one-parent PR head push' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $featureHead `
                -Evidence (New-Evidence -AfterCommit $featureHead -HeadCommit $featureHead)
            Assert-Route -Name 'merge tree differs from PR head tree' -Expected 'Full' `
                -BeforeCommit $advancedBase -AfterCommit $differentTreeMerge `
                -Evidence (New-Evidence -AfterCommit $differentTreeMerge `
                    -HeadCommit $featureHead -BaseCommit $advancedBase)
            Assert-Route -Name 'forced/non-ancestor before identity' -Expected 'Full' `
                -BeforeCommit $directPush -AfterCommit $exactMerge -Evidence $exact

            $wrongHead = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $wrongHead.PullRequests[0].head.sha = $baseline
            Assert-Route -Name 'wrong PR head' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $wrongHead

            $wrongBase = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $wrongBase.PullRequests[0].base.sha = $featureHead
            Assert-Route -Name 'wrong PR base identity' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $wrongBase

            $duplicatePr = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $duplicatePr.PullRequests = @($duplicatePr.PullRequests[0], $duplicatePr.PullRequests[0])
            Assert-Route -Name 'duplicate merged PR evidence' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $duplicatePr

            $duplicateRun = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $duplicateRun.PullRequestRuns = @(
                $duplicateRun.PullRequestRuns[0], $duplicateRun.PullRequestRuns[0]
            )
            Assert-Route -Name 'duplicate successful workflow runs' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $duplicateRun

            $failedJob = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $failedJob.JobsByRun['501'][1].conclusion = 'failure'
            Assert-Route -Name 'failed stable job' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $failedJob

            $duplicateJob = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $duplicateJob.JobsByRun['501'] += $duplicateJob.JobsByRun['501'][0]
            Assert-Route -Name 'duplicate stable job identity' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $duplicateJob

            $missingJob = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $missingJob.JobsByRun['501'] = @($missingJob.JobsByRun['501'][0])
            Assert-Route -Name 'missing stable job identity' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $missingJob

            $missingRun = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $missingRun.PullRequestRuns = @()
            Assert-Route -Name 'missing prior run' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $missingRun

            $failedRun = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $failedRun.PullRequestRuns[0].conclusion = 'cancelled'
            Assert-Route -Name 'canceled prior run' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $failedRun

            $apiFailure = New-Evidence -AfterCommit $exactMerge -HeadCommit $featureHead
            $apiFailure.ThrowKind = 'PullRequests'
            Assert-Route -Name 'API failure' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $apiFailure
            Assert-Route -Name 'ordinary non-push event' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit $exactMerge -Evidence $exact `
                -EventName 'pull_request'
            Assert-Route -Name 'hosted pull-request event with empty before identity' `
                -Expected 'Full' -BeforeCommit '' -AfterCommit $exactMerge `
                -Evidence $exact -EventName 'pull_request'
            Assert-Route -Name 'malformed pushed identity' -Expected 'Full' `
                -BeforeCommit $baseline -AfterCommit 'not-a-commit' -Evidence $exact

            function global:gh {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    [string[]]$Rest
                )

                $global:LASTEXITCODE = 0
                $endpoint = [string]$Rest[-1]
                if ($endpoint -like '*/actions/workflows/protocol-tests.yml') {
                    '{"id":77,"path":".github/workflows/protocol-tests.yml","state":"active"}'
                    return
                }
                if ($endpoint -like '*event=merge_group*') {
                    '[{"total_count":0,"workflow_runs":[]}]'
                    return
                }
                if ($endpoint -like '*/commits/*/pulls?*') {
                    '[[{"number":1}],[{"number":2}]]'
                    return
                }
                if ($endpoint -like '*event=pull_request*') {
                    '[{"total_count":2,"workflow_runs":[{"id":1}]},{"total_count":2,"workflow_runs":[{"id":2}]}]'
                    return
                }
                if ($endpoint -like '*/jobs?*') {
                    '[{"total_count":2,"jobs":[{"id":1}]},{"total_count":2,"jobs":[{"id":2}]}]'
                    return
                }
                throw "Unexpected fake gh endpoint '$endpoint'."
            }
            $env:GH_TOKEN = 'test-route-token'
            $routeModule = Get-Module MeAndAI.MainValidationRoute
            $pagedCounts = & $routeModule {
                $context = @{ Repository = 'owner/repository'; WorkflowId = '77' }
                [pscustomobject]@{
                    MergeGroups = @(Get-MeAndAIGitHubEvidence -Kind 'MergeGroupRuns' `
                        -Context ($context + @{ AfterCommit = 'a' * 40 })).Count
                    PullRequests = @(Get-MeAndAIGitHubEvidence -Kind 'PullRequests' `
                        -Context @{ Repository = 'owner/repository'; AfterCommit = 'a' * 40 }).Count
                    PullRequestRuns = @(Get-MeAndAIGitHubEvidence -Kind 'PullRequestRuns' `
                        -Context ($context + @{ HeadCommit = 'b' * 40 })).Count
                    Jobs = @(Get-MeAndAIGitHubEvidence -Kind 'Jobs' `
                        -Context @{ Repository = 'owner/repository'; RunId = '1' }).Count
                }
            }
            if ($pagedCounts.MergeGroups -ne 0 -or
                $pagedCounts.PullRequests -ne 2 -or
                $pagedCounts.PullRequestRuns -ne 2 -or
                $pagedCounts.Jobs -ne 2) {
                Add-Failure "TEST-0143 paginated GitHub evidence was not flattened exactly: $($pagedCounts | ConvertTo-Json -Compress)"
            }
        }
    }

    $workflowSource = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($requiredWorkflowText in @(
        'push:',
        'Validate on ubuntu-latest',
        'Validate on windows-latest',
        'MeAndAI.MainValidationRoute.psm1',
        'ReuseExactValidatedTree',
        '-StructureOnly',
        "github.event_name == 'pull_request'"
    )) {
        if (-not $workflowSource.Contains($requiredWorkflowText)) {
            Add-Failure "TEST-0143 workflow lacks exact-tree/fail-safe contract '$requiredWorkflowText'."
        }
    }
    if ($workflowSource.Contains('paths:') -or
        $workflowSource.Contains('paths-ignore:')) {
        Add-Failure 'TEST-0143 workflow uses path filtering that can remove stable check evidence.'
    }

    $jobsIndex = $workflowSource.IndexOf("jobs:", [StringComparison]::Ordinal)
    if ($jobsIndex -lt 0) {
        Add-Failure 'TEST-0146 workflow has no canonical jobs section.'
    }
    else {
        $jobsSource = $workflowSource.Substring($jobsIndex)
        $jobIds = @([regex]::Matches(
            $jobsSource,
            '(?m)^  (?<id>[a-z0-9-]+):\r?$'
        ) | ForEach-Object { $_.Groups['id'].Value } | Sort-Object)
        $expectedJobIds = @(
            'linux-validation', 'post-publication', 'windows-validation'
        )
        if (($jobIds -join "`n") -cne ($expectedJobIds -join "`n")) {
            Add-Failure "TEST-0146 workflow job inventory changed: $($jobIds -join ', ')."
        }
    }
    foreach ($stableJobName in @(
        'Validate on ubuntu-latest',
        'Validate on windows-latest'
    )) {
        if ([regex]::Matches(
                $workflowSource,
                [regex]::Escape("name: $stableJobName")
            ).Count -ne 1) {
            Add-Failure "TEST-0146 stable job identity is missing or duplicated: $stableJobName."
        }
    }
    if ($workflowSource -match '(?m)^\s+(?:strategy|matrix|needs):' -or
        $workflowSource -match '(?m)^\s+timeout-minutes:\s+(?:2|3)\s*$') {
        Add-Failure 'TEST-0146 workflow adds fan-out/fan-in or turns the soft runtime goals into timeout gates.'
    }
    foreach ($runtimeContract in @(
        'shell: pwsh',
        'shell: powershell',
        './tests/protocol.tests.ps1',
        '-ExecutionProfile',
        'WindowsNative'
    )) {
        if (-not $workflowSource.Contains($runtimeContract)) {
            Add-Failure "TEST-0146 workflow lost cross-runtime validation contract '$runtimeContract'."
        }
    }

    $protocolSource = Get-Content -LiteralPath $protocolPath -Raw
    if (-not $protocolSource.Contains('sole purpose is to copy external evidence') -or
        -not $protocolSource.Contains('stable external authority')) {
        Add-Failure 'TEST-0143 protocol does not prohibit evidence-only candidate commits while retaining external authority.'
    }
    if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
        $moduleSource = Get-Content -LiteralPath $modulePath -Raw
        foreach ($paginationText in @('--paginate', '--slurp', 'per_page=100')) {
            if (-not $moduleSource.Contains($paginationText)) {
                Add-Failure "TEST-0143 resolver does not exhaust GitHub pagination through '$paginationText'."
            }
        }
    }
}
catch {
    Add-Failure "TEST-0143 fixture failed: $($_.Exception.Message) [$($_.ScriptStackTrace)]"
}
finally {
    $env:GH_TOKEN = $previousProtocolToken
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Module MeAndAI.MainValidationRoute -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Main-validation route tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Main-validation exact-tree route and efficiency tests passed for TEST-0143 and TEST-0146.' `
    -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities/workflow-efficiency/main-validation-route.tests.ps1' `
    -SourcePaths @($PSCommandPath, $modulePath) `
    -AuthorityPath $authorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
