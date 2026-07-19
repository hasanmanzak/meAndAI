Set-StrictMode -Version Latest

$script:FullRoute = 'Full'
$script:ReuseRoute = 'ReuseExactValidatedTree'
$script:WorkflowPath = '.github/workflows/protocol-tests.yml'
$script:StableJobs = @(
    'Validate on ubuntu-latest',
    'Validate on windows-latest'
)

function Invoke-MeAndAIRouteGit {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& git -C $RepositoryRoot @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { [string]$_ })
    }
}

function Get-MeAndAIGitScalar {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $result = Invoke-MeAndAIRouteGit -RepositoryRoot $RepositoryRoot `
        -Arguments $Arguments
    if ($result.ExitCode -ne 0 -or $result.Output.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$result.Output[0])) {
        throw "Git evidence command failed: git $($Arguments -join ' ')."
    }
    return ([string]$result.Output[0]).Trim()
}

function Test-MeAndAIGitCommit {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Commit
    )

    $result = Invoke-MeAndAIRouteGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('cat-file', '-e', "$Commit`^{commit}")
    return $result.ExitCode -eq 0 -and $result.Output.Count -eq 0
}

function Test-MeAndAIAncestor {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Ancestor,
        [Parameter(Mandatory)][string]$Descendant
    )

    $result = Invoke-MeAndAIRouteGit -RepositoryRoot $RepositoryRoot `
        -Arguments @('merge-base', '--is-ancestor', $Ancestor, $Descendant)
    return $result.ExitCode -eq 0 -and $result.Output.Count -eq 0
}

function Invoke-MeAndAIGhJson {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if ([string]::IsNullOrWhiteSpace([string]$env:GH_TOKEN)) {
        throw 'GH_TOKEN is required for validation-evidence lookup.'
    }
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& gh api @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw 'GitHub validation-evidence lookup failed.'
    }
    $json = ($output | ForEach-Object { [string]$_ }) -join "`n"
    if ([string]::IsNullOrWhiteSpace($json)) {
        throw 'GitHub validation-evidence lookup returned no JSON.'
    }
    return ConvertFrom-Json -InputObject $json
}

function Invoke-MeAndAIGhPagedJson {
    param([Parameter(Mandatory)][string]$Endpoint)

    $slurped = Invoke-MeAndAIGhJson -Arguments @(
        '--paginate', '--slurp',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'X-GitHub-Api-Version: 2022-11-28',
        $Endpoint
    )
    foreach ($page in @($slurped)) {
        Write-Output $page
    }
}

function Get-MeAndAIGitHubEvidence {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][hashtable]$Context
    )

    $repository = [string]$Context.Repository
    switch -CaseSensitive ($Kind) {
        'Workflow' {
            return Invoke-MeAndAIGhJson -Arguments @(
                '-H', 'Accept: application/vnd.github+json',
                '-H', 'X-GitHub-Api-Version: 2022-11-28',
                "repos/$repository/actions/workflows/protocol-tests.yml"
            )
        }
        'PullRequests' {
            $pages = @(Invoke-MeAndAIGhPagedJson -Endpoint (
                "repos/$repository/commits/$($Context.AfterCommit)/pulls?per_page=100"
            ))
            return @($pages | ForEach-Object { @($_) })
        }
        'MergeGroupRuns' {
            $pages = @(Invoke-MeAndAIGhPagedJson -Endpoint (
                "repos/$repository/actions/workflows/$($Context.WorkflowId)/runs?head_sha=$($Context.AfterCommit)&event=merge_group&status=success&per_page=100"
            ))
            return @($pages | ForEach-Object { @($_.workflow_runs) })
        }
        'PullRequestRuns' {
            $pages = @(Invoke-MeAndAIGhPagedJson -Endpoint (
                "repos/$repository/actions/workflows/$($Context.WorkflowId)/runs?head_sha=$($Context.HeadCommit)&event=pull_request&status=success&per_page=100"
            ))
            return @($pages | ForEach-Object { @($_.workflow_runs) })
        }
        'Jobs' {
            $pages = @(Invoke-MeAndAIGhPagedJson -Endpoint (
                "repos/$repository/actions/runs/$($Context.RunId)/jobs?per_page=100"
            ))
            return @($pages | ForEach-Object { @($_.jobs) })
        }
        default {
            throw "Unknown GitHub evidence kind '$Kind'."
        }
    }
}

function Get-MeAndAIRouteEvidence {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][hashtable]$Context,
        [scriptblock]$EvidenceProvider
    )

    if ($null -ne $EvidenceProvider) {
        return & $EvidenceProvider $Kind $Context
    }
    return Get-MeAndAIGitHubEvidence -Kind $Kind -Context $Context
}

function Test-MeAndAIStableRun {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Runs,
        [Parameter(Mandatory)][string]$EventName,
        [Parameter(Mandatory)][string]$HeadCommit,
        [string]$HeadBranch = '',
        [Parameter(Mandatory)][string]$Repository,
        [AllowNull()][scriptblock]$EvidenceProvider
    )

    if ($Runs.Count -ne 1) {
        return $false
    }
    $run = $Runs[0]
    if ([string]$run.event -cne $EventName -or
        [string]$run.status -cne 'completed' -or
        [string]$run.conclusion -cne 'success' -or
        [string]$run.head_sha -cne $HeadCommit -or
        [string]$run.path -cne $script:WorkflowPath -or
        (-not [string]::IsNullOrWhiteSpace($HeadBranch) -and
            [string]$run.head_branch -cne $HeadBranch) -or
        [string]$run.id -cnotmatch '^[1-9][0-9]*$') {
        return $false
    }
    $jobs = @(Get-MeAndAIRouteEvidence -Kind 'Jobs' -Context @{
        Repository = $Repository
        RunId = [string]$run.id
    } -EvidenceProvider $EvidenceProvider)
    foreach ($stableName in $script:StableJobs) {
        $matches = @($jobs | Where-Object { [string]$_.name -ceq $stableName })
        if ($matches.Count -ne 1 -or
            [string]$matches[0].status -cne 'completed' -or
            [string]$matches[0].conclusion -cne 'success') {
            return $false
        }
    }
    return $true
}

function Resolve-MeAndAIMainValidationRoute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EventName,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$DefaultBranch,
        [Parameter(Mandatory)][string]$BeforeCommit,
        [Parameter(Mandatory)][string]$AfterCommit,
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [scriptblock]$EvidenceProvider
    )

    try {
        if ($EventName -cne 'push' -or
            $Repository -cnotmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or
            $DefaultBranch -cnotmatch '^[A-Za-z0-9._/-]+$' -or
            $BeforeCommit -cnotmatch '^[0-9a-f]{40}$' -or
            $AfterCommit -cnotmatch '^[0-9a-f]{40}$' -or
            $BeforeCommit -ceq $AfterCommit) {
            return $script:FullRoute
        }
        $RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
        if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container) -or
            -not (Test-MeAndAIGitCommit -RepositoryRoot $RepositoryRoot -Commit $BeforeCommit) -or
            -not (Test-MeAndAIGitCommit -RepositoryRoot $RepositoryRoot -Commit $AfterCommit) -or
            -not (Test-MeAndAIAncestor -RepositoryRoot $RepositoryRoot `
                -Ancestor $BeforeCommit -Descendant $AfterCommit)) {
            return $script:FullRoute
        }

        $workflow = Get-MeAndAIRouteEvidence -Kind 'Workflow' -Context @{
            Repository = $Repository
        } -EvidenceProvider $EvidenceProvider
        if ($null -eq $workflow -or
            [string]$workflow.id -cnotmatch '^[1-9][0-9]*$' -or
            [string]$workflow.path -cne $script:WorkflowPath -or
            [string]$workflow.state -cne 'active') {
            return $script:FullRoute
        }

        $mergeGroupRuns = @(Get-MeAndAIRouteEvidence -Kind 'MergeGroupRuns' `
            -Context @{
                Repository = $Repository
                WorkflowId = [string]$workflow.id
                AfterCommit = $AfterCommit
            } -EvidenceProvider $EvidenceProvider)
        if (Test-MeAndAIStableRun -Runs $mergeGroupRuns `
            -EventName 'merge_group' -HeadCommit $AfterCommit `
            -Repository $Repository -EvidenceProvider $EvidenceProvider) {
            return $script:ReuseRoute
        }

        $parentLine = Get-MeAndAIGitScalar -RepositoryRoot $RepositoryRoot `
            -Arguments @('rev-list', '--parents', '-n', '1', $AfterCommit)
        $parts = @($parentLine.Split(' ', [StringSplitOptions]::RemoveEmptyEntries))
        if ($parts.Count -ne 3 -or $parts[0] -cne $AfterCommit -or
            $parts[1] -cne $BeforeCommit -or
            $parts[2] -cnotmatch '^[0-9a-f]{40}$') {
            return $script:FullRoute
        }
        $headCommit = $parts[2]
        $mergeTree = Get-MeAndAIGitScalar -RepositoryRoot $RepositoryRoot `
            -Arguments @('rev-parse', "$AfterCommit`^{tree}")
        $headTree = Get-MeAndAIGitScalar -RepositoryRoot $RepositoryRoot `
            -Arguments @('rev-parse', "$headCommit`^{tree}")
        if ($mergeTree -cnotmatch '^[0-9a-f]{40}$' -or
            $headTree -cne $mergeTree) {
            return $script:FullRoute
        }

        $pullRequests = @(Get-MeAndAIRouteEvidence -Kind 'PullRequests' `
            -Context @{
                Repository = $Repository
                AfterCommit = $AfterCommit
            } -EvidenceProvider $EvidenceProvider)
        if ($pullRequests.Count -ne 1) {
            return $script:FullRoute
        }
        $pullRequest = $pullRequests[0]
        if ([string]$pullRequest.number -cnotmatch '^[1-9][0-9]*$' -or
            [string]::IsNullOrWhiteSpace([string]$pullRequest.merged_at) -or
            [string]$pullRequest.merge_commit_sha -cne $AfterCommit -or
            [string]$pullRequest.base.ref -cne $DefaultBranch -or
            [string]$pullRequest.base.sha -cne $BeforeCommit -or
            [string]$pullRequest.base.repo.full_name -cne $Repository -or
            [string]$pullRequest.head.sha -cne $headCommit -or
            [string]$pullRequest.head.repo.full_name -cne $Repository -or
            [string]::IsNullOrWhiteSpace([string]$pullRequest.head.ref)) {
            return $script:FullRoute
        }

        $pullRequestRuns = @(Get-MeAndAIRouteEvidence -Kind 'PullRequestRuns' `
            -Context @{
                Repository = $Repository
                WorkflowId = [string]$workflow.id
                HeadCommit = $headCommit
            } -EvidenceProvider $EvidenceProvider)
        if (Test-MeAndAIStableRun -Runs $pullRequestRuns `
            -EventName 'pull_request' -HeadCommit $headCommit `
            -HeadBranch ([string]$pullRequest.head.ref) `
            -Repository $Repository -EvidenceProvider $EvidenceProvider) {
            return $script:ReuseRoute
        }
    }
    catch {
        Write-Verbose "Main validation route failed closed: $($_.Exception.Message)"
        return $script:FullRoute
    }
    return $script:FullRoute
}

Export-ModuleMember -Function Resolve-MeAndAIMainValidationRoute
