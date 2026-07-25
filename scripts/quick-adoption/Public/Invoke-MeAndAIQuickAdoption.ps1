# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function Invoke-MeAndAIQuickAdoption {
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
    $script:QuickAdoptionProgressEnabled = -not $NoProgress
    $script:QuickAdoptionLastProgressKey = ''
    $script:QuickAdoptionLastChildKey = ''
    $script:ValidatedProtocolReleases = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $script:CanonicalProtocolAssets = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    $script:InitialAdoptionPolicy = $null

    Set-QuickAdoptionProgress -Status 'Validating prerequisites' -PercentComplete 5
    $gitHookSuppression = $null
    try {
    if ($AdoptionStrategy -ceq 'Abort') {
        $target = Get-NormalizedPath -Path $TargetPath
        if (-not (Test-Path -LiteralPath $target -PathType Container)) {
            throw "TargetPath must identify an existing directory: $target"
        }
        Write-Host 'Initial adoption was aborted before repository or GitHub mutation.'
        Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
        return
    }
    $gitHookSuppression = Enter-GitHookSuppression
    foreach ($command in @('git', 'gh')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Required command '$command' is not available."
        }
    }
    Assert-GitHookSuppression -State $gitHookSuppression
    Assert-MinimumGitHubCliVersion

    $target = Get-NormalizedPath -Path $TargetPath
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "TargetPath must identify an existing directory: $target"
    }
    foreach ($tokenFileName in $tokenMappings.Keys) {
        $tokenCandidate = Get-Item -LiteralPath (Join-Path $target $tokenFileName) `
            -Force -ErrorAction SilentlyContinue
        if ($null -eq $tokenCandidate) { continue }
        [void](Assert-LocalCredentialRegularFile -Root $target `
            -Name ([string]$tokenFileName))
    }
    $protocolTokenPath = Join-Path $target 'MEANDAI_RO_FG_PAT.txt'
    $protocolTokenFileExists = Test-Path -LiteralPath $protocolTokenPath -PathType Leaf
    $protocolToken = Read-ProtocolTokenForInitialPolicy -Root $target
    if (-not $protocolToken) {
        $protocolToken = $null
    }
    Invoke-External -Command 'gh' -Arguments @('auth', 'status') | Out-Null
    $script:InitialAdoptionPolicy = Import-CanonicalInitialAdoptionPolicy `
        -ProtocolToken ([string]$protocolToken)
    $preflightAssessment = Get-QuickAdoptionPreflightAssessment -Root $target
    $initialAdoptionSelection = Resolve-QuickAdoptionStrategy `
        -Assessment $preflightAssessment -RequestedStrategy $AdoptionStrategy `
        -IsNonInteractive ([bool]$NonInteractive) `
        -LossAcknowledged ([bool]$AcknowledgeProtocolRecordLoss)
    if ([string]$initialAdoptionSelection.State -ceq 'Aborted') {
        Write-Host 'Initial adoption was aborted before repository or GitHub mutation.'
        Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
        return
    }
    $assessmentBeforeLocalMutation = Get-QuickAdoptionPreflightAssessment -Root $target
    Assert-QuickAdoptionPreflightAssessmentUnchanged `
        -Expected $preflightAssessment -Actual $assessmentBeforeLocalMutation `
        -FailureMessage 'Repository protocol evidence changed after strategy selection; no adoption mutation was started.'

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
    $workflowBytes = $null

    if ($hasRemote) {
        $remoteUrl = ((@($remoteResult.Output) -join '').Trim())
        $remoteSlug = Get-GitHubSlugFromRemote -RemoteUrl $remoteUrl
        $remoteRefs = Invoke-Git -Repository $target -Arguments @(
            'ls-remote', $RemoteName
        )
        $remoteIsEmpty = -not ((@($remoteRefs.Output) -join '').Trim())
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
            $candidateRefs = Invoke-Git -Repository $target -Arguments @(
                'ls-remote', $discoveredRemoteUrl
            )
            if ((@($candidateRefs.Output) -join '').Trim()) {
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

    # Resolve the immutable workflow and reject a recognizable-but-modified seed
    # before creating a GitHub repository or attaching a discovered remote.
    if ($protocolTokenFileExists) {
        $workflowBytes = Get-CanonicalWorkflow -ProtocolToken $protocolToken
    }
    else {
        $workflowBytes = Get-CanonicalWorkflow
    }
    $preMutationWorkflowPath = Assert-ContainedManagedDestination `
        -Root $target -RelativePath $workflowTargetPath
    # This early byte gate protects the actions that create a GitHub repository or
    # attach a newly discovered remote. An already connected consumer is routed
    # first, because an exact older managed seed is valid input to the bounded
    # same-major updater path and is verified by that route's pinned contract.
    if (-not $hasRemote -and (Test-Path -LiteralPath $preMutationWorkflowPath)) {
        if (-not (Test-Path -LiteralPath $preMutationWorkflowPath -PathType Leaf) -or
            -not (& $script:TestQuickAdoptionByteArrayEqual `
                -Left ([IO.File]::ReadAllBytes($preMutationWorkflowPath)) `
                -Right ([byte[]]$workflowBytes))) {
            throw "The existing seed workflow '$workflowTargetPath' is not the exact canonical $ProtocolTag file; no GitHub repository or remote was changed."
        }
    }

    if ($discoveredExistingRepository) {
        # Verify executable source before mutating the local remote configuration.
        # The repository secret value remains unreadable; authenticated gh is the
        # existing file-free source fallback when the local read token is absent.
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
        $statusLines = @($status.Output | Where-Object { $_ } | ForEach-Object {
            [string]$_
        })
        foreach ($line in $statusLines) {
            if ($line.Length -lt 4 -or $line.Substring(3) -cne $workflowTargetPath) {
                throw 'The connected repository must be clean apart from the exact seed workflow candidate.'
            }
        }
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
        $assessmentBeforeRepositoryCreation = Get-QuickAdoptionPreflightAssessment `
            -Root $target
        Assert-QuickAdoptionPreflightAssessmentUnchanged `
            -Expected $preflightAssessment `
            -Actual $assessmentBeforeRepositoryCreation `
            -FailureMessage 'Repository protocol evidence changed before GitHub repository creation; no repository was created.'
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
        $hasRemote = $true
        $remoteIsEmpty = $true
    }

    if ($null -eq $workflowBytes) {
        # Executable source authority is verified before the temporary lock label
        # performs the first repository mutation. Prefer the local read-only token
        # when its verified file is present; otherwise use the authenticated gh
        # identity without attempting to recover an existing Actions secret.
        if ($protocolTokenFileExists) {
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
        if ([string]$initialAdoptionSelection.State -cne 'Resolved') {
            throw 'The completed-consumer preflight no longer matches authoritative initial-adoption routing.'
        }
    }
    elseif ([string]$initialAdoptionSelection.State -cne 'DeferredCompletedConsumer') {
        throw 'The initial-adoption preflight no longer matches authoritative completed-consumer routing.'
    }
    if ($routingHead -cne [string]$preflightAssessment.HeadSha) {
        throw 'Repository HEAD changed after initial-adoption strategy assessment; secrets and seed publication were not changed.'
    }
    $assessmentBeforeRepositoryMutation = Get-QuickAdoptionPreflightAssessment `
        -Root $target
    Assert-QuickAdoptionPreflightAssessmentUnchanged `
        -Expected $preflightAssessment -Actual $assessmentBeforeRepositoryMutation `
        -FailureMessage 'Repository protocol evidence changed before repository mutation; secrets and seed publication were not changed.'
    if ($hasRemote -and $remoteIsEmpty) {
        Assert-LiveConsumerRepositoryBoundary -TargetRepository $target `
            -ExpectedRepository $repository -ExpectEmpty `
            -FailureMessage 'The repository assumed to be empty gained history or live identity before repository mutation; secrets and seed publication were not changed.'
    }
    elseif ($hasRemote -and $routingHead) {
        Assert-LiveConsumerRepositoryBoundary -TargetRepository $target `
            -ExpectedRepository $repository `
            -ExpectedDefaultBranch $defaultBranch -ExpectedHead $routingHead `
            -FailureMessage 'The live repository/default branch changed after strategy assessment; secrets and seed publication were not changed.'
    }

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
        if (-not (& $script:TestQuickAdoptionByteArrayEqual `
            -Left $existingWorkflowBytes -Right $workflowBytes)) {
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
            $protocolToken = Read-LocalToken -Root $target `
                -Name 'MEANDAI_RO_FG_PAT.txt'
        }

        $updaterSecretMissing = $existingSecretNames -notcontains 'MEANDAI_UPDATER_TOKEN'
        $updaterToken = $null
        if ($updaterSecretMissing) {
            $updaterTokenPath = Join-Path $target 'FG_PAT.txt'
            if (-not (Test-Path -LiteralPath $updaterTokenPath -PathType Leaf)) {
                throw "Required local credential file 'FG_PAT.txt' is missing because repository Actions secret 'MEANDAI_UPDATER_TOKEN' does not exist."
            }
            $updaterToken = Read-LocalToken -Root $target -Name 'FG_PAT.txt'
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
        Write-Host 'The installed updater seed was preserved; semantic capability discovery remains a separate workflow responsibility.'
        if ($SkipLifecycleDispatch) {
            Write-Host 'Capability discovery dispatch was explicitly skipped.'
        }
        else {
            Set-QuickAdoptionProgress -Status 'Checking current capabilities' `
                -PercentComplete 90
            $run = Invoke-LifecycleWorkflow -Repository $repository `
                -Branch $defaultBranch -HeadSha $routingHead `
                -ResolvedAdoptionStrategy 'Auto' `
                -ProtocolRecordLossAcknowledged $false
            Write-Host "Current capability discovery completed successfully: $($run.url)"
            Write-Host 'Review any separately tracked semantic capability draft created by the installed workflow.'
        }
        Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
        return
    }
    if ([string]$existingAdoptionRoute.State -ceq 'CompatibleUpdate') {
        Write-Host "The completed meAndAI adoption at $($existingAdoptionRoute.InstalledTag) is older than requested target $ProtocolTag."
        Write-Host 'The installed updater seed was preserved; the launcher will not overwrite managed updater assets.'
        if ($SkipLifecycleDispatch) {
            Write-Host 'Current-launcher recovery was explicitly skipped.'
            Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
            return
        }
        Set-QuickAdoptionProgress -Status 'Running target-bound updater recovery' `
            -PercentComplete 70
        $targetRelease = Get-ValidatedImmutableProtocolRelease `
            -ProtocolToken $protocolToken -Tag $ProtocolTag
        [void](Invoke-LocalCurrentLauncherRecovery -Repository $repository `
            -Branch $defaultBranch -HeadSha $routingHead `
            -TargetTag $ProtocolTag `
            -TargetCommit ([string]$targetRelease.CommitSha) `
            -MaintainerRepository $target)
        Write-Host "The exact $ProtocolTag updater created or reconciled the managed update draft locally."
        Write-Host 'Review and merge the managed update pull request; adoption Codex execution was not started.'
        Set-QuickAdoptionProgress -Status 'Completed' -PercentComplete 100
        return
    }

    $assessmentBeforeSeedPublication = Get-QuickAdoptionPreflightAssessment -Root $target
    Assert-QuickAdoptionPreflightAssessmentUnchanged `
        -Expected $preflightAssessment -Actual $assessmentBeforeSeedPublication `
        -FailureMessage 'Repository protocol evidence changed before seed publication; the selected strategy was not published.'
    if ($hasRemote -and $remoteIsEmpty) {
        Assert-LiveConsumerRepositoryBoundary -TargetRepository $target `
            -ExpectedRepository $repository -ExpectEmpty `
            -FailureMessage 'The repository assumed to be empty gained history before seed publication; the selected strategy was not published.'
    }
    elseif ($hasRemote -and $routingHead) {
        Assert-LiveConsumerRepositoryBoundary -TargetRepository $target `
            -ExpectedRepository $repository `
            -ExpectedDefaultBranch $defaultBranch -ExpectedHead $routingHead `
            -FailureMessage 'The live repository/default branch changed before seed publication; the selected strategy was not published.'
    }

    Set-QuickAdoptionProgress -Status 'Publishing canonical seed workflow' `
        -PercentComplete 58
    [void](Write-CanonicalWorkflow -Path $workflowFullPath -Bytes $workflowBytes)

    Invoke-Git -Repository $target -Arguments @('add', '--', $workflowTargetPath) | Out-Null
    $staged = @((Invoke-Git -Repository $target -Arguments @(
        'diff', '--cached', '--name-only'
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

    $publishedHead = ((@(Invoke-Git -Repository $target -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    if ($publishedHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The seed publication head is not canonical.'
    }
    if ($createdCommit) {
        if ([string]$preflightAssessment.HeadSha) {
            if ((Get-SingleCommitParent -Repository $target -Commit $publishedHead) -cne
                [string]$preflightAssessment.HeadSha) {
                throw 'The canonical seed commit does not have the strategy-assessed parent.'
            }
        }
        else {
            $rootCommitLine = ((@(Invoke-Git -Repository $target -Arguments @(
                'rev-list', '--parents', '-n', '1', $publishedHead
            )).Output -join '').Trim())
            if ($rootCommitLine -cne $publishedHead) {
                throw 'The canonical seed for a new repository is not one root commit.'
            }
        }
    }
    elseif ($publishedHead -cne [string]$preflightAssessment.HeadSha) {
        throw 'Repository HEAD changed before seed publication.'
    }
    $seedCommitPaths = @(if ($createdCommit -and [string]$preflightAssessment.HeadSha) {
        @((Invoke-Git -Repository $target -Arguments @(
            'diff-tree', '--no-commit-id', '--name-only', '-r', '--no-renames',
            $publishedHead
        )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    }
    elseif ($createdCommit -or $remoteIsEmpty) {
        @((Invoke-Git -Repository $target -Arguments @(
            'ls-tree', '-r', '--name-only', $publishedHead, '--'
        )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    }
    else { @($workflowTargetPath) }
    )
    if ($seedCommitPaths.Count -ne 1 -or
        [string]$seedCommitPaths[0] -cne $workflowTargetPath) {
        throw 'The committed seed publication is not an exact workflow-only change.'
    }
    $publishedWorkflowEntry = Get-AdoptionTreeEntry -Repository $target `
        -Commit $publishedHead -Path $workflowTargetPath
    $canonicalWorkflowBlob = & $script:GetQuickAdoptionGitBlobSha1 `
        -Bytes ([byte[]]$workflowBytes)
    if ($publishedWorkflowEntry.Mode -cne '100644' -or
        $publishedWorkflowEntry.Type -cne 'blob' -or
        $publishedWorkflowEntry.Sha -cne $canonicalWorkflowBlob) {
        throw 'The committed seed workflow does not match the exact canonical release bytes.'
    }
    $postSeedCommitStatus = @((Invoke-Git -Repository $target -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if ($postSeedCommitStatus.Count -ne 0) {
        throw "The canonical seed commit left staged or working-tree changes and was not published: $($postSeedCommitStatus -join ', ')."
    }
    $publishedPaths = @(Get-QuickAdoptionRelevantTreePaths -Repository $target `
        -Commit $publishedHead -TargetPaths $adoptionCanonicalTargetPaths)
    Assert-QuickAdoptionSeedWorkflowPathIdentity -Paths $publishedPaths
    $dispatchSourceGraph = $preflightAssessment.InstructionGraph
    if ($null -eq $dispatchSourceGraph) {
        # A repository without HEAD gains one exact workflow-only root commit;
        # that commit is both the event head and the first graph base.
        $dispatchSourceGraph = Get-QuickAdoptionInstructionGraph `
            -Repository $target -Commit $publishedHead
    }
    $expectedGraphBase = if ([string]$preflightAssessment.HeadSha) {
        [string]$preflightAssessment.HeadSha
    }
    else { $publishedHead }
    if ([string]$dispatchSourceGraph.baseHead -cne $expectedGraphBase) {
        throw 'The dispatch source graph no longer matches the maintainer-assessed commit.'
    }
    $publishedSurfaces = @($dispatchSourceGraph.protocolSurfaces)
    $publishedCollisions = @(Get-QuickAdoptionCanonicalCollisions `
        -Paths $publishedPaths)
    if (-not (Test-ExactOrdinalPathSet -Actual $publishedSurfaces `
            -Expected @($initialAdoptionSelection.ProtocolSurfaces)) -or
        -not (Test-ExactOrdinalPathSet -Actual $publishedCollisions `
            -Expected @($preflightAssessment.Collisions))) {
        throw 'The canonical seed tree no longer matches the maintainer-selected strategy assessment.'
    }
    $dispatchSourceGraphIdentityJson = ''
    if (Test-CanonicalWorkflowSupportsSourceGraphIdentity `
            -Bytes ([byte[]]$workflowBytes)) {
        $graphIdentityCommand = Get-InitialAdoptionPolicyCommand `
            -Name 'Get-MeAndAIInstructionGraphIdentity'
        $dispatchSourceGraphIdentity = & $graphIdentityCommand `
            -Graph $dispatchSourceGraph
        $dispatchSourceGraphIdentityJson = $dispatchSourceGraphIdentity |
            ConvertTo-Json -Depth 8 -Compress
    }

    if ($createdCommit -or $remoteIsEmpty) {
        $defaultRef = "refs/heads/$defaultBranch"
        $expectedRemoteHead = if ($remoteIsEmpty) { '' } else { $routingHead }
        if ($remoteIsEmpty) {
            Assert-LiveConsumerRepositoryBoundary -TargetRepository $target `
                -ExpectedRepository $repository -ExpectEmpty `
                -FailureMessage 'The repository assumed to be empty gained history immediately before seed push; the seed was not published.'
        }
        else {
            Assert-LiveConsumerRepositoryBoundary -TargetRepository $target `
                -ExpectedRepository $repository `
                -ExpectedDefaultBranch $defaultBranch -ExpectedHead $routingHead `
                -FailureMessage 'The live repository/default branch changed immediately before seed push; the seed was not published.'
        }
        Invoke-Git -Repository $target -Arguments @(
            'push', '-u', "--force-with-lease=${defaultRef}:$expectedRemoteHead",
            $RemoteName, "HEAD:$defaultRef"
        ) | Out-Null
        $verifiedRemoteHead = Get-RemoteBranchHead -Repository $target `
            -Remote $RemoteName -Branch $defaultBranch
        if ($verifiedRemoteHead -cne $publishedHead) {
            throw 'The published seed does not match the exact strategy-bound local head.'
        }
        if ($remoteIsEmpty) {
            $postSeedBindingValid = $true
            try {
                Assert-LiveConsumerRepositoryBoundary `
                    -TargetRepository $target -ExpectedRepository $repository `
                    -ExpectedDefaultBranch $defaultBranch `
                    -ExpectedHead $publishedHead -RequireOnlyExpectedHead `
                    -FailureMessage 'The repository assumed to be empty changed during seed push.'
            }
            catch {
                $postSeedBindingValid = $false
            }
            if (-not $postSeedBindingValid) {
                $compensationFailure = ''
                try {
                    Invoke-Git -Repository $target -Arguments @(
                        'push', "--force-with-lease=${defaultRef}:$publishedHead",
                        $RemoteName, ":$defaultRef"
                    ) | Out-Null
                }
                catch {
                    $compensationFailure = $_.Exception.Message
                }
                $remainingDefaultHead = Get-RemoteBranchHead `
                    -Repository $target -Remote $RemoteName -Branch $defaultBranch `
                    -AllowMissing
                if ($compensationFailure -or $remainingDefaultHead) {
                    throw "The repository assumed to be empty changed during seed push and exact compensation could not be proven; manual review is required. $compensationFailure"
                }
                throw 'The repository assumed to be empty changed during seed push; the exact seed ref was removed and the local seed commit was retained for review.'
            }
        }
        else {
            $postSeedBindingValid = $true
            try {
                Assert-LiveConsumerRepositoryBoundary `
                    -TargetRepository $target -ExpectedRepository $repository `
                    -ExpectedDefaultBranch $defaultBranch -ExpectedHead $publishedHead `
                    -FailureMessage 'The live repository/default branch changed during seed push.'
            }
            catch {
                $postSeedBindingValid = $false
            }
            if (-not $postSeedBindingValid) {
                $compensationFailure = ''
                try {
                    Invoke-Git -Repository $target -Arguments @(
                        'push', "--force-with-lease=${defaultRef}:$publishedHead",
                        $RemoteName, "$routingHead`:$defaultRef"
                    ) | Out-Null
                }
                catch {
                    $compensationFailure = $_.Exception.Message
                }
                $remainingDefaultHead = Get-RemoteBranchHead `
                    -Repository $target -Remote $RemoteName -Branch $defaultBranch
                if ($compensationFailure -or $remainingDefaultHead -cne $routingHead) {
                    throw "The live repository/default branch changed during seed push and exact compensation could not be proven; manual review is required. $compensationFailure"
                }
                throw 'The live repository/default branch changed during seed push; the exact seed push was reverted and the local seed commit was retained for review.'
            }
        }
    }

    Write-Host "meAndAI quick adoption seed is ready in $repository at $ProtocolTag."
    Write-Host 'Repository Actions secrets were reconciled by preserving existing names and creating only missing names.'

    if ($SkipLifecycleDispatch) {
        Write-Host 'Lifecycle dispatch was explicitly skipped. Run the meAndAI AI capabilities lifecycle workflow before adoption.'
    }
    else {
        $currentPublishedHead = ((@(Invoke-Git -Repository $target -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($currentPublishedHead -cne $publishedHead) {
            throw 'Repository HEAD changed after exact seed publication.'
        }
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
                -ExpectedActor $authenticatedActor -MaxAttempts 1 `
                -ExpectedAdoptionStrategy ([string]$initialAdoptionSelection.AdoptionStrategy) `
                -ExpectedProtocolSurfaces @($initialAdoptionSelection.ProtocolSurfaces) `
                -ExpectedProtocolRecordLossAcknowledgement `
                    ([bool]$initialAdoptionSelection.ProtocolRecordLossAcknowledged)
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
            $run = Invoke-LifecycleWorkflow -Repository $repository `
                -Branch $defaultBranch -HeadSha $publishedHead `
                -ResolvedAdoptionStrategy ([string]$initialAdoptionSelection.AdoptionStrategy) `
                -ProtocolRecordLossAcknowledged `
                    ([bool]$initialAdoptionSelection.ProtocolRecordLossAcknowledged) `
                -SourceGraphIdentityJson $dispatchSourceGraphIdentityJson
            Write-Host "Lifecycle workflow completed successfully: $($run.url)"
            Set-QuickAdoptionProgress -Status 'Resolving adoption draft' `
                -PercentComplete 78
            $adoptionPullRequestResults = @(Get-AdoptionPullRequest -Repository $repository `
                -BaseBranch $defaultBranch -ExpectedActor $authenticatedActor `
                -ExpectedAdoptionStrategy ([string]$initialAdoptionSelection.AdoptionStrategy) `
                -ExpectedProtocolSurfaces @($initialAdoptionSelection.ProtocolSurfaces) `
                -ExpectedProtocolRecordLossAcknowledgement `
                    ([bool]$initialAdoptionSelection.ProtocolRecordLossAcknowledged))
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
        try {
            if ($null -ne $script:InitialAdoptionPolicy -and
                $null -ne $script:InitialAdoptionPolicy.Module) {
                Remove-Module -ModuleInfo $script:InitialAdoptionPolicy.Module `
                    -Force -ErrorAction SilentlyContinue
                $script:InitialAdoptionPolicy = $null
            }
            if ($null -ne $gitHookSuppression) {
                Exit-GitHookSuppression -State $gitHookSuppression
            }
        }
        finally {
            Complete-QuickAdoptionProgress
        }
    }
}
