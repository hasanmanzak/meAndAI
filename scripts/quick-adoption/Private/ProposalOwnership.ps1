# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function Invoke-LifecycleWorkflow {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$HeadSha,
        [Parameter(Mandatory)][ValidateSet('Auto', 'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart')]
        [string]$ResolvedAdoptionStrategy,
        [Parameter(Mandatory)][bool]$ProtocolRecordLossAcknowledged,
        [string]$SourceGraphIdentityJson = ''
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
    $dispatchInputs = [ordered]@{
        correlation_id = [string]$correlationId
        adoption_strategy = [string]$ResolvedAdoptionStrategy
        acknowledge_protocol_record_loss =
            $ProtocolRecordLossAcknowledged.ToString().ToLowerInvariant()
        expected_base_sha = [string]$HeadSha
    }
    if ($SourceGraphIdentityJson) {
        $dispatchInputs.source_graph_identity = [string]$SourceGraphIdentityJson
    }
    $dispatchInputJson = $dispatchInputs | ConvertTo-Json -Depth 10 -Compress
    $dispatchArguments = @(
        'workflow', 'run', $workflowName, '--repo', $Repository, '--ref', $Branch,
        '--json'
    )
    Invoke-External -Command 'gh' -Arguments $dispatchArguments `
        -InputText $dispatchInputJson | Out-Null

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
                    $createdAt = ConvertTo-MeAndAIGitHubTimestamp `
                        -Value $run.createdAt
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
        [string]$ExpectedMarkerHead = '',
        [string]$ExpectedAdoptionStrategy = '',
        [AllowEmptyCollection()][object[]]$ExpectedProtocolSurfaces = @(),
        [bool]$ExpectedProtocolRecordLossAcknowledgement = $false
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
        [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
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
    if ($schema -notin @(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)) {
        throw 'The deterministic adoption pull request ownership marker uses an unsupported schema.'
    }
    $phase = if ($schema -eq 2) { 'Proposed' } else { [string]$marker.phase }
    if ($phase -ceq 'Publishing') {
        $expectedPublishingProperties = if ($schema -eq 4) {
            @(
                'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
                'previousHead', 'plannedHead', 'repository', 'actor'
            )
        }
        elseif ($schema -eq 6) {
            @(
                'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
                'previousHead', 'plannedHead', 'adoptionStrategy',
                'protocolSurfaces', 'protocolRecordLossAcknowledged',
                'repository', 'actor'
            )
        }
        elseif ($schema -eq 8) {
            @(
                'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
                'previousHead', 'plannedHead', 'branch', 'adoptionStrategy',
                'protocolSurfaces', 'protocolRecordLossAcknowledged',
                'graphBase', 'graphDigest', 'graphCounts', 'graphLimits',
                'repository', 'actor'
            )
        }
        elseif ($schema -eq 10) {
            @(
                'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
                'previousHead', 'plannedHead', 'branch', 'adoptionStrategy',
                'protocolRecordLossAcknowledged',
                'graphBase', 'graphDigest', 'graphCounts', 'graphLimits',
                'repository', 'actor'
            )
        }
        elseif ($schema -eq 12) {
            @(
                'schema', 'phase', 'state', 'target', 'protocolSha', 'head',
                'previousHead', 'plannedHead', 'branch', 'adoptionStrategy',
                'surfaceBase', 'surfaceDigest',
                'protocolRecordLossAcknowledged', 'repository', 'actor'
            )
        }
        else { @() }
        $actualPublishingProperties = @(
            $marker.PSObject.Properties | ForEach-Object { $_.Name }
        )
        if ($expectedPublishingProperties.Count -eq 0 -or
            $actualPublishingProperties.Count -ne
                $expectedPublishingProperties.Count -or
            @($expectedPublishingProperties | Where-Object {
                $actualPublishingProperties -cnotcontains $_
            }).Count -ne 0) {
            throw 'The deterministic adoption pull request ownership marker has an unexpected schema.'
        }
        if ([string]$marker.state -cnotin @(
                'BootstrapReady', 'AdoptionReviewRequired'
            ) -or
            [string]$marker.target -cne $ProtocolTag -or
            [string]$marker.protocolSha -cnotmatch '^[0-9a-f]{40}$' -or
            -not ([string]$marker.repository).Equals(
                $Repository, [StringComparison]::OrdinalIgnoreCase
            ) -or
            -not ([string]$marker.actor).Equals(
                $ExpectedActor, [StringComparison]::OrdinalIgnoreCase
            )) {
            throw 'The deterministic adoption pull request ownership marker does not match its live identity.'
        }
        if ($schema -in @(6, 8, 10, 12)) {
            $markerSurfaces = if ($schema -in @(10, 12)) {
                @($ExpectedProtocolSurfaces | ForEach-Object { [string]$_ })
            }
            elseif ($marker.protocolSurfaces -is [array]) {
                @($marker.protocolSurfaces | ForEach-Object { [string]$_ })
            }
            else { @() }
            $classifiedMarkerSurfaces = if ($schema -eq 6) {
                @(Get-QuickAdoptionProtocolSurfaceInventory `
                    -Paths $markerSurfaces)
            }
            else { @($markerSurfaces) }
            $graphIdentityValid = $true
            if ($schema -in @(8, 10)) {
                $identityValidator = Get-InitialAdoptionPolicyCommand `
                    -Name 'Test-MeAndAIExactInstructionGraphIdentityRecord'
                $graphIdentityValid = [bool](& $identityValidator -Identity `
                    ([pscustomobject][ordered]@{
                        schema = [int]$script:InitialAdoptionPolicy.GraphSchema
                        graphBase = [string]$marker.graphBase
                        graphDigest = [string]$marker.graphDigest
                        graphCounts = $marker.graphCounts
                        graphLimits = $marker.graphLimits
                        protocolSurfaces = @($markerSurfaces)
                    }))
                if ($schema -eq 10) {
                    $sectionValidator = Get-InitialAdoptionPolicyCommand `
                        -Name 'Test-MeAndAIExactLinkedPathSection'
                    $graphIdentityValid = $graphIdentityValid -and
                        [bool](& $sectionValidator -Body $body `
                            -Heading '### Detected protocol and governance surfaces' `
                            -Repository $Repository `
                            -Commit ([string]$marker.graphBase) `
                            -Paths @($markerSurfaces))
                }
            }
            if ($schema -eq 12) {
                $digestCommand = Get-InitialAdoptionPolicyCommand `
                    -Name 'Get-MeAndAILinkedPathIdentityDigest'
                $sectionValidator = Get-InitialAdoptionPolicyCommand `
                    -Name 'Test-MeAndAIExactLinkedPathSection'
                $graphIdentityValid =
                    [string]$marker.surfaceBase -cmatch '^[0-9a-f]{40}$' -and
                    [string]$marker.surfaceDigest -ceq
                        [string](& $digestCommand -Paths @($markerSurfaces)) -and
                    [bool](& $sectionValidator -Body $body `
                        -Heading '### Detected protocol and governance surfaces' `
                        -Repository $Repository `
                        -Commit ([string]$marker.surfaceBase) `
                        -Paths @($markerSurfaces))
            }
            if ([string]$marker.adoptionStrategy -cnotin @(
                'FreshAdoption', 'FullMigration', 'HybridReconciliation',
                'CleanStart'
            ) -or ($schema -notin @(10, 12) -and
                    $marker.protocolSurfaces -isnot [array]) -or
                $marker.protocolRecordLossAcknowledged -isnot [bool] -or
                -not (([bool]$marker.protocolRecordLossAcknowledged) -eq
                    ([string]$marker.adoptionStrategy -ceq 'CleanStart')) -or
                (($markerSurfaces -join "`n") -cne
                    ($classifiedMarkerSurfaces -join "`n")) -or
                -not $graphIdentityValid -or
                ($schema -in @(8, 10, 12) -and
                 [string]$marker.branch -cne $Branch) -or
                ($ExpectedAdoptionStrategy -and
                 ([string]$marker.adoptionStrategy -cne
                    $ExpectedAdoptionStrategy -or
                  ($markerSurfaces -join "`n") -cne
                    (@($ExpectedProtocolSurfaces) -join "`n") -or
                  [bool]$marker.protocolRecordLossAcknowledged -ne
                    $ExpectedProtocolRecordLossAcknowledgement))) {
                throw 'The deterministic adoption pull request strategy marker is invalid.'
            }
        }
        elseif ($ExpectedAdoptionStrategy -and
            $ExpectedAdoptionStrategy -cnotin @(
                'LegacyUnspecified', 'FreshAdoption'
            )) {
            throw 'A legacy adoption marker cannot satisfy the expected strategy identity.'
        }
        if ($schema -notin @(4, 6, 8, 10, 12) -or
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
        if ($schema -in @(4, 6, 8, 10, 12)) {
            throw 'The deterministic adoption pull request uses the publishing schema outside its publishing phase.'
        }
        $requiredMarkerHead = if ($ExpectedMarkerHead) {
            $ExpectedMarkerHead
        }
        else {
            [string]$PullRequest.headRefOid
        }
        if ($requiredMarkerHead -cnotmatch '^[0-9a-f]{40}$' -or
            [string]$marker.state -cnotin @(
                'BootstrapReady', 'AdoptionReviewRequired'
            ) -or
            [string]$marker.protocolSha -cnotmatch '^[0-9a-f]{40}$') {
            throw 'The deterministic adoption pull request marker head does not match the expected transition state.'
        }
        $contractStrategy = if ($ExpectedAdoptionStrategy) {
            $ExpectedAdoptionStrategy
        }
        elseif ($schema -in @(5, 7, 9, 11)) { [string]$marker.adoptionStrategy }
        else { 'LegacyUnspecified' }
        [object[]]$contractSurfaces = [object[]]::new(0)
        if ($ExpectedAdoptionStrategy) {
            $contractSurfaces = [object[]]@($ExpectedProtocolSurfaces)
        }
        elseif ($schema -in @(5, 7)) {
            $contractSurfaces = [object[]]@($marker.protocolSurfaces)
        }
        $contractLossAcknowledgement = if ($ExpectedAdoptionStrategy) {
            $ExpectedProtocolRecordLossAcknowledgement
        }
        elseif ($schema -in @(5, 7, 9, 11) -and
            $marker.protocolRecordLossAcknowledged -is [bool]) {
            [bool]$marker.protocolRecordLossAcknowledged
        }
        else { $false }
        $contractGraphIdentity = if ($schema -in @(7, 9)) {
            [pscustomobject][ordered]@{
                schema = [int]$script:InitialAdoptionPolicy.GraphSchema
                graphBase = [string]$marker.graphBase
                graphDigest = [string]$marker.graphDigest
                graphCounts = $marker.graphCounts
                graphLimits = $marker.graphLimits
                protocolSurfaces = @($contractSurfaces)
            }
        }
        else { $null }
        $contractPullRequest = [pscustomobject]@{
            number = $PullRequest.number
            url = $PullRequest.url
            headRefName = $PullRequest.headRefName
            headRefOid = $PullRequest.headRefOid
            baseRefName = $PullRequest.baseRefName
            headRepository = [pscustomobject]@{ nameWithOwner = $Repository }
            author = $PullRequest.author
            body = $PullRequest.body
            # A Completed marker is validated while the live pull request is
            # still draft, immediately before the caller performs the ready
            # transition. The caller owns that live transition; the pure
            # marker contract receives its terminal phase projection.
            isDraft = if ($phase -ceq 'Completed') {
                $false
            }
            else { $PullRequest.isDraft }
            state = $PullRequest.state
        }
        if (-not (Test-QuickAdoptionExactPullRequestMarker `
                -PullRequest $contractPullRequest `
                -RemoteHead $requiredMarkerHead -Repository $Repository `
                -Branch $Branch -BaseBranch $BaseBranch `
                -TargetTag $ProtocolTag `
                -TargetSha ([string]$marker.protocolSha) `
                -ExpectedActor $ExpectedActor `
                -ExpectedState ([string]$marker.state) `
                -ExpectedAdoptionStrategy $contractStrategy `
                -ExpectedProtocolSurfaces $contractSurfaces `
                -ExpectedProtocolRecordLossAcknowledgement `
                    $contractLossAcknowledgement `
                -ExpectedSourceGraphIdentity $contractGraphIdentity `
                -ExpectedPhase $phase)) {
            throw 'The deterministic adoption pull request ownership marker violates the canonical capabilities contract.'
        }
    }
    if ($schema -eq 2) {
        $marker | Add-Member -NotePropertyName phase -NotePropertyValue 'Proposed' -Force
    }
    if ($schema -in @(2, 3, 4)) {
        $marker | Add-Member -NotePropertyName adoptionStrategy `
            -NotePropertyValue 'LegacyUnspecified' -Force
        $marker | Add-Member -NotePropertyName protocolSurfaces `
            -NotePropertyValue @() -Force
        $marker | Add-Member -NotePropertyName protocolRecordLossAcknowledged `
            -NotePropertyValue $false -Force
    }
    if ($schema -in @(9, 10, 11, 12)) {
        $marker | Add-Member -NotePropertyName protocolSurfaces `
            -NotePropertyValue @($ExpectedProtocolSurfaces) -Force
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
        [string]$ExpectedAdoptionStrategy = '',
        [AllowEmptyCollection()][object[]]$ExpectedProtocolSurfaces = @(),
        [bool]$ExpectedProtocolRecordLossAcknowledgement = $false,
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
                -ExpectedActor $ExpectedActor -ExpectedMarkerHead $ExpectedMarkerHead `
                -ExpectedAdoptionStrategy $ExpectedAdoptionStrategy `
                -ExpectedProtocolSurfaces @($ExpectedProtocolSurfaces) `
                -ExpectedProtocolRecordLossAcknowledgement `
                    $ExpectedProtocolRecordLossAcknowledgement
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
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$IssueNumber
    )

    $trackingLine = "Tracking issue: [#$IssueNumber](https://github.com/$Repository/issues/$IssueNumber)"
    $legacyTrackingLine = "Tracking issue: #$IssueNumber"
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
    $legacyTrackingLines = [regex]::Matches(
        $Body, "^$([regex]::Escape($legacyTrackingLine))`r?$",
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
    if ($trackingStarts.Count -eq 1 -and $legacyTrackingLines.Count -eq 1) {
        $legacy = $legacyTrackingLines[0]
        $lineEnding = if (
            $legacy.Value.EndsWith("`r", [StringComparison]::Ordinal)
        ) { "`r" } else { '' }
        $replacement = $trackingLine + $lineEnding
        return [pscustomobject]@{
            Body = $Body.Substring(0, $legacy.Index) + $replacement +
                $Body.Substring($legacy.Index + $legacy.Length)
            Changed = $true
        }
    }
    if ($trackingStarts.Count -ne 0 -or $exactTrackingLines.Count -ne 0 -or
        $legacyTrackingLines.Count -ne 0) {
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

function Convert-AdoptionPullRequestPathSectionToLinks {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [Parameter(Mandatory)][string]$Heading,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit,
        [AllowNull()][object[]]$ExpectedPaths = $null,
        [switch]$Required
    )

    $normalized = $Body.Replace("`r`n", "`n").Replace("`r", "`n")
    $headingMatches = @([regex]::Matches(
        $normalized, '(?m)^' + [regex]::Escape($Heading) + '$',
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    ))
    if ($headingMatches.Count -eq 0 -and -not $Required) {
        return $normalized
    }
    if ($headingMatches.Count -ne 1) {
        throw "The adoption pull request must contain one '$Heading' section."
    }
    $contentStart = [int]$headingMatches[0].Index +
        [int]$headingMatches[0].Length
    if ($contentStart + 2 -gt $normalized.Length -or
        $normalized.Substring($contentStart, 2) -cne "`n`n") {
        throw "The adoption pull request '$Heading' section is malformed."
    }
    $contentStart += 2
    $contentEnd = $normalized.IndexOf(
        "`n`n", $contentStart, [StringComparison]::Ordinal
    )
    if ($contentEnd -lt 0) { $contentEnd = $normalized.Length }
    $content = $normalized.Substring(
        $contentStart, $contentEnd - $contentStart
    )
    $paths = [System.Collections.Generic.List[string]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    if ($content -cne '- None') {
        foreach ($line in @($content.Split("`n"))) {
            $raw = [regex]::Match($line, '^- `(?<path>[^`]+)`$')
            $linked = [regex]::Match(
                $line, '^- \[`(?<path>[^`]+)`\]\((?<url>https://github\.com/[^\s)]+)\)$'
            )
            if (-not $raw.Success -and -not $linked.Success) {
                throw "The adoption pull request '$Heading' section contains noncanonical path evidence."
            }
            $path = if ($raw.Success) {
                [string]$raw.Groups['path'].Value
            }
            else { [string]$linked.Groups['path'].Value }
            $pathValidator = Get-InitialAdoptionPolicyCommand `
                -Name 'Test-MeAndAICanonicalRepositoryPath'
            if (-not [bool](& $pathValidator -Path $path) -or
                -not $seenPaths.Add($path)) {
                throw "The adoption pull request '$Heading' section contains an invalid or duplicate path."
            }
            $paths.Add($path)
        }
    }
    if ($null -ne $ExpectedPaths -and
        (($paths.Count -ne @($ExpectedPaths).Count) -or
         (($paths -join "`n") -cne
            (@($ExpectedPaths | ForEach-Object { [string]$_ }) -join "`n")))) {
        throw "The adoption pull request '$Heading' section differs from its ownership evidence."
    }
    $linkBuilder = Get-InitialAdoptionPolicyCommand `
        -Name 'New-MeAndAIGitHubBlobLink'
    $linkedLines = if ($paths.Count -eq 0) {
        @('- None')
    }
    else {
        @($paths | ForEach-Object {
            '- ' + (& $linkBuilder -Repository $Repository -Commit $Commit `
                -Path ([string]$_))
        })
    }
    $replacement = @($linkedLines) -join "`n"
    return $normalized.Substring(0, $contentStart) + $replacement +
        $normalized.Substring($contentEnd)
}

function Convert-AdoptionPullRequestBodyToCurrentLinks {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$SurfaceCommit,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ProtocolSurfaces,
        [Parameter(Mandatory)][string]$ManifestCommit,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [AllowEmptyString()][string]$GraphBase = ''
    )

    $updated = Convert-AdoptionPullRequestPathSectionToLinks -Body $Body `
        -Heading '### Detected protocol and governance surfaces' `
        -Repository $Repository -Commit $SurfaceCommit `
        -ExpectedPaths @($ProtocolSurfaces) -Required
    $updated = Convert-AdoptionPullRequestPathSectionToLinks -Body $updated `
        -Heading '### Detected collisions' -Repository $Repository `
        -Commit $SurfaceCommit
    $linkBuilder = Get-InitialAdoptionPolicyCommand `
        -Name 'New-MeAndAIGitHubBlobLink'
    $manifestLink = & $linkBuilder -Repository $Repository `
        -Commit $ManifestCommit -Path $adoptionManifestPath
    $manifestReferencePattern = '(?:\[' +
        [regex]::Escape("``$adoptionManifestPath``") +
        '\]\([^\r\n)]+\)|' +
        [regex]::Escape("``$adoptionManifestPath``") + ')'
    $updated = [regex]::Replace(
        $updated, $manifestReferencePattern,
        [Text.RegularExpressions.MatchEvaluator]{ param($match) $manifestLink },
        [Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    $releaseLine = "- Protocol release: [$ProtocolTag](https://github.com/$ProtocolRepository/releases/tag/$ProtocolTag)"
    $protocolCommitLine = "- Protocol commit: [$ProtocolSha](https://github.com/$ProtocolRepository/commit/$ProtocolSha)"
    foreach ($reference in @(
        [pscustomobject]@{ Prefix = '- Protocol release:'; Line = $releaseLine },
        [pscustomobject]@{ Prefix = '- Protocol commit:'; Line = $protocolCommitLine }
    )) {
        $matches = @([regex]::Matches(
            $updated, '(?m)^' + [regex]::Escape([string]$reference.Prefix) +
                '[^\r\n]*$',
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        ))
        if ($matches.Count -gt 1) {
            throw "The adoption pull request contains duplicate '$([string]$reference.Prefix)' references."
        }
        if ($matches.Count -eq 1) {
            $match = $matches[0]
            $updated = $updated.Substring(0, $match.Index) +
                [string]$reference.Line +
                $updated.Substring($match.Index + $match.Length)
        }
    }
    if ($GraphBase -cmatch '^[0-9a-f]{40}$') {
        $matches = @([regex]::Matches(
            $updated, '(?m)^- Source graph base:[^\r\n]*$',
            [Text.RegularExpressions.RegexOptions]::CultureInvariant
        ))
        if ($matches.Count -gt 1) {
            throw 'The adoption pull request contains duplicate source-graph references.'
        }
        if ($matches.Count -eq 1) {
            $match = $matches[0]
            $graphLine = "- Source graph base: [$GraphBase](https://github.com/$Repository/commit/$GraphBase)"
            $updated = $updated.Substring(0, $match.Index) + $graphLine +
                $updated.Substring($match.Index + $match.Length)
        }
    }
    return $updated
}

function Set-AdoptionPullRequestMarkerBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$MarkerJson,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)][string]$FileName,
        [ValidateRange(0, 2147483647)][int]$TrackingIssueNumber = 0,
        [string]$SurfaceCommit = '',
        [AllowEmptyCollection()][object[]]$ProtocolSurfaces = @(),
        [string]$ManifestCommit = '',
        [string]$ProtocolSha = '',
        [string]$GraphBase = ''
    )

    $body = [string]$PullRequest.body
    if ($SurfaceCommit) {
        $body = Convert-AdoptionPullRequestBodyToCurrentLinks -Body $body `
            -Repository $Repository -SurfaceCommit $SurfaceCommit `
            -ProtocolSurfaces @($ProtocolSurfaces) `
            -ManifestCommit $ManifestCommit -ProtocolSha $ProtocolSha `
            -GraphBase $GraphBase
    }
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
            -Repository $Repository `
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
    $markerSchema = [long]$marker.schema
    $graphAware = $markerSchema -in @(7, 8, 9, 10)
    $legacyGraphMarkerFamily = $markerSchema -in @(7, 8)
    $surfaceAware = $markerSchema -in @(5, 6, 7, 8, 9, 10, 11, 12)
    $surfaceBase = if ($graphAware) {
        [string]$marker.graphBase
    }
    elseif ($markerSchema -in @(11, 12)) {
        [string]$marker.surfaceBase
    }
    else { $PreviousHead }
    $branch = if ($null -ne $marker.PSObject.Properties['branch']) {
        [string]$marker.branch
    }
    else { [string]$PullRequest.headRefName }
    $surfaceDigest = if ($surfaceAware -and -not $graphAware) {
        $digestCommand = Get-InitialAdoptionPolicyCommand `
            -Name 'Get-MeAndAILinkedPathIdentityDigest'
        [string](& $digestCommand -Paths @($marker.protocolSurfaces))
    }
    else { '' }
    $publishingMarkerRecord = if ($graphAware) {
        [ordered]@{
            schema = if ($legacyGraphMarkerFamily) { 8 } else { 10 }
            phase = 'Publishing'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            previousHead = $PreviousHead
            plannedHead = $PlannedHead
            branch = [string]$marker.branch
            adoptionStrategy = [string]$marker.adoptionStrategy
            protocolRecordLossAcknowledged = [bool]$marker.protocolRecordLossAcknowledged
            graphBase = [string]$marker.graphBase
            graphDigest = [string]$marker.graphDigest
            graphCounts = $marker.graphCounts
            graphLimits = $marker.graphLimits
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    elseif ($markerSchema -in @(5, 6, 11, 12)) {
        [ordered]@{
            schema = 12
            phase = 'Publishing'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            previousHead = $PreviousHead
            plannedHead = $PlannedHead
            branch = $branch
            adoptionStrategy = [string]$marker.adoptionStrategy
            surfaceBase = $surfaceBase
            surfaceDigest = $surfaceDigest
            protocolRecordLossAcknowledged = [bool]$marker.protocolRecordLossAcknowledged
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    else {
        [ordered]@{
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
        }
    }
    if ($graphAware -and $legacyGraphMarkerFamily) {
        $publishingMarkerRecord.Insert(
            10, 'protocolSurfaces',
            [object[]]@($marker.protocolSurfaces)
        )
    }
    $publishingMarker = $publishingMarkerRecord |
        ConvertTo-Json -Depth 8 -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $publishingMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'publishing-adoption-pr.md' `
        -SurfaceCommit $(if ($surfaceAware) { $surfaceBase } else { '' }) `
        -ProtocolSurfaces @($marker.protocolSurfaces) `
        -ManifestCommit $PreviousHead -ProtocolSha ([string]$marker.protocolSha) `
        -GraphBase $(if ($graphAware) { [string]$marker.graphBase } else { '' })
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
    $markerSchema = [long]$marker.schema
    $graphAware = $markerSchema -in @(7, 8, 9, 10)
    $legacyGraphMarkerFamily = $markerSchema -in @(7, 8)
    $surfaceAware = $markerSchema -in @(5, 6, 7, 8, 9, 10, 11, 12)
    $surfaceBase = if ($graphAware) {
        [string]$marker.graphBase
    }
    elseif ($markerSchema -in @(11, 12)) {
        [string]$marker.surfaceBase
    }
    else { $PreviousHead }
    $branch = if ($null -ne $marker.PSObject.Properties['branch']) {
        [string]$marker.branch
    }
    else { [string]$PullRequest.headRefName }
    $surfaceDigest = if ($surfaceAware -and -not $graphAware) {
        $digestCommand = Get-InitialAdoptionPolicyCommand `
            -Name 'Get-MeAndAILinkedPathIdentityDigest'
        [string](& $digestCommand -Paths @($marker.protocolSurfaces))
    }
    else { '' }
    $proposedMarkerRecord = if ($graphAware) {
        [ordered]@{
            schema = if ($legacyGraphMarkerFamily) { 7 } else { 9 }
            phase = 'Proposed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            branch = [string]$marker.branch
            adoptionStrategy = [string]$marker.adoptionStrategy
            protocolRecordLossAcknowledged = [bool]$marker.protocolRecordLossAcknowledged
            graphBase = [string]$marker.graphBase
            graphDigest = [string]$marker.graphDigest
            graphCounts = $marker.graphCounts
            graphLimits = $marker.graphLimits
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    elseif ($markerSchema -in @(5, 6, 11, 12)) {
        [ordered]@{
            schema = 11
            phase = 'Proposed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            branch = $branch
            adoptionStrategy = [string]$marker.adoptionStrategy
            surfaceBase = $surfaceBase
            surfaceDigest = $surfaceDigest
            protocolRecordLossAcknowledged = [bool]$marker.protocolRecordLossAcknowledged
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    else {
        [ordered]@{
            schema = 3
            phase = 'Proposed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    if ($graphAware -and $legacyGraphMarkerFamily) {
        $proposedMarkerRecord.Insert(
            8, 'protocolSurfaces',
            [object[]]@($marker.protocolSurfaces)
        )
    }
    $proposedMarker = $proposedMarkerRecord |
        ConvertTo-Json -Depth 8 -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $proposedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'proposed-adoption-pr.md' `
        -SurfaceCommit $(if ($surfaceAware) { $surfaceBase } else { '' }) `
        -ProtocolSurfaces @($marker.protocolSurfaces) `
        -ManifestCommit $PreviousHead -ProtocolSha ([string]$marker.protocolSha) `
        -GraphBase $(if ($graphAware) { [string]$marker.graphBase } else { '' })
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
    $markerSchema = [long]$marker.schema
    $graphAware = $markerSchema -in @(7, 8, 9, 10)
    $legacyGraphMarkerFamily = $markerSchema -in @(7, 8)
    $surfaceAware = $markerSchema -in @(5, 6, 7, 8, 9, 10, 11, 12)
    $surfaceBase = if ($graphAware) {
        [string]$marker.graphBase
    }
    elseif ($markerSchema -in @(11, 12)) {
        [string]$marker.surfaceBase
    }
    elseif ($markerSchema -eq 6) {
        [string]$marker.previousHead
    }
    else { [string]$marker.head }
    $manifestCommit = if ($null -ne $marker.PSObject.Properties['previousHead'] -and
        [string]$marker.previousHead -cmatch '^[0-9a-f]{40}$') {
        [string]$marker.previousHead
    }
    else { [string]$marker.head }
    $branch = if ($null -ne $marker.PSObject.Properties['branch']) {
        [string]$marker.branch
    }
    else { [string]$PullRequest.headRefName }
    $surfaceDigest = if ($surfaceAware -and -not $graphAware) {
        $digestCommand = Get-InitialAdoptionPolicyCommand `
            -Name 'Get-MeAndAILinkedPathIdentityDigest'
        [string](& $digestCommand -Paths @($marker.protocolSurfaces))
    }
    else { '' }
    $completedMarkerRecord = if ($graphAware) {
        [ordered]@{
            schema = if ($legacyGraphMarkerFamily) { 7 } else { 9 }
            phase = 'Completed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PublishedHead
            branch = [string]$marker.branch
            adoptionStrategy = [string]$marker.adoptionStrategy
            protocolRecordLossAcknowledged = [bool]$marker.protocolRecordLossAcknowledged
            graphBase = [string]$marker.graphBase
            graphDigest = [string]$marker.graphDigest
            graphCounts = $marker.graphCounts
            graphLimits = $marker.graphLimits
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    elseif ($markerSchema -in @(5, 6, 11, 12)) {
        [ordered]@{
            schema = 11
            phase = 'Completed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PublishedHead
            branch = $branch
            adoptionStrategy = [string]$marker.adoptionStrategy
            surfaceBase = $surfaceBase
            surfaceDigest = $surfaceDigest
            protocolRecordLossAcknowledged = [bool]$marker.protocolRecordLossAcknowledged
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    else {
        [ordered]@{
            schema = 3
            phase = 'Completed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PublishedHead
            repository = [string]$marker.repository
            actor = [string]$marker.actor
        }
    }
    if ($graphAware -and $legacyGraphMarkerFamily) {
        $completedMarkerRecord.Insert(
            8, 'protocolSurfaces',
            [object[]]@($marker.protocolSurfaces)
        )
    }
    $completedMarker = $completedMarkerRecord |
        ConvertTo-Json -Depth 8 -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $completedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'completed-adoption-pr.md' `
        -TrackingIssueNumber $IssueNumber `
        -SurfaceCommit $(if ($surfaceAware) { $surfaceBase } else { '' }) `
        -ProtocolSurfaces @($marker.protocolSurfaces) `
        -ManifestCommit $manifestCommit -ProtocolSha ([string]$marker.protocolSha) `
        -GraphBase $(if ($graphAware) { [string]$marker.graphBase } else { '' })
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
        -ExpectedMarkerHead $MarkerHead `
        -ExpectedAdoptionStrategy ([string]$OriginalPullRequest.meAndAIMarker.adoptionStrategy) `
        -ExpectedProtocolSurfaces @($OriginalPullRequest.meAndAIMarker.protocolSurfaces) `
        -ExpectedProtocolRecordLossAcknowledgement `
            ([bool]$OriginalPullRequest.meAndAIMarker.protocolRecordLossAcknowledged) `
        -ExpectedBody $Body -ExpectedDraft $Draft
}

function Complete-AdoptionReviewTransition {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
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
    Assert-CanonicalConsumerBaseUnchanged -TargetRepository $TargetRepository `
        -Branch ([string]$PullRequest.baseRefName) `
        -ExpectedHead $CanonicalBaseHead `
        -FailureMessage 'The canonical consumer base changed before adoption review transition.'
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
        -Repository $Repository `
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
    $madeReady = $false
    try {
        if ([bool]$current.isDraft) {
            Assert-CanonicalConsumerBaseUnchanged -TargetRepository $TargetRepository `
                -Branch ([string]$current.baseRefName) `
                -ExpectedHead $CanonicalBaseHead `
                -FailureMessage 'The canonical consumer base changed before the adoption pull request became ready.'
            Invoke-External -Command 'gh' -Arguments @(
                'pr', 'ready', [string]$current.number, '--repo', $Repository
            ) | Out-Null
            $madeReady = $true
            $current = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
                -OriginalPullRequest $current -LiveHead $PublishedHead `
                -MarkerHead $PublishedHead -Body $body -Draft $false
        }
        Assert-CanonicalConsumerBaseUnchanged -TargetRepository $TargetRepository `
            -Branch ([string]$current.baseRefName) `
            -ExpectedHead $CanonicalBaseHead `
            -FailureMessage 'The canonical consumer base changed while the adoption pull request became ready.'
    }
    catch {
        $baseFailure = $_.Exception.Message
        $undoFailure = ''
        if ($madeReady) {
            try {
                $readyForCompensation = Get-RevalidatedAdoptionPullRequest `
                    -Repository $Repository -OriginalPullRequest $current `
                    -LiveHead $PublishedHead -MarkerHead $PublishedHead `
                    -Body $body -Draft $false
                Invoke-External -Command 'gh' -Arguments @(
                    'pr', 'ready', [string]$readyForCompensation.number, '--undo',
                    '--repo', $Repository
                ) | Out-Null
                $current = Get-RevalidatedAdoptionPullRequest `
                    -Repository $Repository -OriginalPullRequest $readyForCompensation `
                    -LiveHead $PublishedHead -MarkerHead $PublishedHead `
                    -Body $body -Draft $true
            }
            catch {
                $undoFailure = $_.Exception.Message
            }
        }
        if ($undoFailure) {
            throw "$baseFailure The ready-state compensation could not be proven; manual review is required. $undoFailure"
        }
        if ($madeReady) {
            throw "$baseFailure The pull request was returned to draft for reassessment."
        }
        throw "$baseFailure No ready-state compensation was attempted because this invocation did not own a proven ready transition."
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

function Get-AdoptionIssueOwnershipMarker {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$TargetTag,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][AllowEmptyString()][string]$GraphDigest,
        [Parameter(Mandatory)][string]$PullRequestUrl
    )

    if ($Repository -cnotmatch '^[^/\s]+/[^/\s]+$' -or
        $TargetTag -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$' -or
        $ProtocolSha -cnotmatch '^[0-9a-f]{40}$' -or
        ($GraphDigest -and $GraphDigest -cnotmatch '^[0-9a-f]{64}$') -or
        $PullRequestUrl -cnotmatch ('^https://github\.com/' +
            [regex]::Escape($Repository) + '/pull/[1-9][0-9]*/?$')) {
        throw 'Cannot derive the canonical adoption-issue ownership marker from invalid identity evidence.'
    }
    $payload = @(
        'schema=2',
        "repository=$Repository",
        "target=$TargetTag",
        "protocolSha=$ProtocolSha",
        "graphDigest=$GraphDigest",
        "pullRequestUrl=$($PullRequestUrl.TrimEnd('/'))"
    ) -join "`n"
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $digest = ([BitConverter]::ToString($algorithm.ComputeHash(
            [Text.UTF8Encoding]::new($false).GetBytes($payload)
        ))).Replace('-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
    return "<!-- meandai-local-adoption:v2:$digest -->"
}

function New-AdoptionIssueBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$Marker,
        [switch]$Legacy
    )

    $markerRecord = $PullRequest.meAndAIMarker
    $graphAware = [long]$markerRecord.schema -in @(7, 8, 9, 10)
    $surfaceCommit = if ($graphAware -and
        [string]$markerRecord.graphBase -match
            '^[0-9a-f]{40}$') {
        [string]$markerRecord.graphBase
    }
    elseif ([long]$markerRecord.schema -in @(11, 12) -and
        [string]$markerRecord.surfaceBase -match '^[0-9a-f]{40}$') {
        [string]$markerRecord.surfaceBase
    }
    else { [string]$markerRecord.head }
    if ($Legacy) {
        $surfaceLines = if (@($markerRecord.protocolSurfaces).Count -gt 0) {
            @($markerRecord.protocolSurfaces | ForEach-Object { "- ``$_``" })
        }
        else { @('- None') }
        $graphLines = if ($graphAware) {
            @(
                "- Source graph base: ``$([string]$markerRecord.graphBase)``",
                "- Source graph digest: ``$([string]$markerRecord.graphDigest)``",
                "- Source graph nodes/edges/candidates: ``$([int]$markerRecord.graphCounts.nodes)/$([int]$markerRecord.graphCounts.edges)/$([int]$markerRecord.graphCounts.candidates)``"
            )
        }
        else { @() }
        return (@(
            $Marker,
            '## AI capabilities adoption tracking',
            '',
            "- Protocol release: ``$ProtocolTag``",
            "- Adoption draft: $($PullRequest.url)",
            "- Adoption strategy: ``$($markerRecord.adoptionStrategy)``",
            "- Protocol-record loss acknowledged: ``$(([bool]$markerRecord.protocolRecordLossAcknowledged).ToString().ToLowerInvariant())``"
        ) + @($graphLines) + @(
            '',
            '### Detected protocol and governance surfaces',
            ''
        ) + @($surfaceLines) + @(
            '',
            'This issue tracks the project-owned feature and decision records, local memory, tests, evidence, links, and maintainer review required to complete the transient adoption manifest.',
            '',
            'The launcher may prepare the draft and mark it ready after bounded local validation; only the maintainer may merge it.'
        )) -join [Environment]::NewLine
    }

    $linkCommand = Get-InitialAdoptionPolicyCommand `
        -Name 'New-MeAndAIGitHubBlobLink'
    $surfaceLines = if (@($markerRecord.protocolSurfaces).Count -gt 0) {
        @($markerRecord.protocolSurfaces | ForEach-Object {
            '- ' + (& $linkCommand -Repository $Repository `
                -Commit $surfaceCommit -Path ([string]$_))
        })
    }
    else { @('- None') }
    $graphLines = if ($graphAware) {
        @(
            "- Source graph base: [$([string]$markerRecord.graphBase)](https://github.com/$Repository/commit/$([string]$markerRecord.graphBase))",
            "- Source graph digest: ``$([string]$markerRecord.graphDigest)``",
            "- Source graph nodes/edges/candidates: ``$([int]$markerRecord.graphCounts.nodes)/$([int]$markerRecord.graphCounts.edges)/$([int]$markerRecord.graphCounts.candidates)``"
        )
    }
    else { @() }
    return (@(
        $Marker,
        '## AI capabilities adoption tracking',
        '',
        "- Protocol release: [$ProtocolTag](https://github.com/$ProtocolRepository/releases/tag/$ProtocolTag)",
        "- Protocol commit: [$([string]$markerRecord.protocolSha)](https://github.com/$ProtocolRepository/commit/$([string]$markerRecord.protocolSha))",
        "- Adoption draft: [PR #$([int]$PullRequest.number)]($([string]$PullRequest.url))",
        "- Adoption strategy: ``$($markerRecord.adoptionStrategy)``",
        "- Protocol-record loss acknowledged: ``$(([bool]$markerRecord.protocolRecordLossAcknowledged).ToString().ToLowerInvariant())``"
    ) + @($graphLines) + @(
        '',
        '### Detected protocol and governance surfaces',
        ''
    ) + @($surfaceLines) + @(
        '',
        'This issue tracks the project-owned feature and decision records, local memory, tests, evidence, links, and maintainer review required to complete the transient adoption manifest.',
        '',
        'The launcher may prepare the draft and mark it ready after bounded local validation; only the maintainer may merge it.'
    )) -join [Environment]::NewLine
}

function Get-MarkedAdoptionIssues {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Issues,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$ExpectedTitle,
        [Parameter(Mandatory)][string]$ExpectedBody,
        [Parameter(Mandatory)][string]$LegacyMarker,
        [Parameter(Mandatory)][string]$LegacyExpectedBody
    )

    $numbers = [System.Collections.Generic.HashSet[int]]::new()
    $matching = [System.Collections.Generic.List[object]]::new()
    $normalizedExpectedBody = $ExpectedBody.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    $normalizedLegacyBody = $LegacyExpectedBody.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    foreach ($issue in $Issues) {
        if ($null -eq $issue.PSObject.Properties['body']) {
            continue
        }
        $body = [string]$issue.body
        $normalizedBody = $body.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
        $firstLine = @($normalizedBody.Split("`n"))[0]
        $kind = if ($firstLine -ceq $Marker) { 'Canonical' }
            elseif ($firstLine -ceq $LegacyMarker) { 'Legacy' }
            else { '' }
        if (-not $kind) {
            if ($normalizedBody.IndexOf(
                    '<!-- meandai-local-adoption:',
                    [StringComparison]::OrdinalIgnoreCase
                ) -ge 0) {
                throw 'A project-owned adoption issue contains a malformed ownership marker; manual review is required.'
            }
            continue
        }
        foreach ($property in @('number', 'url', 'title', 'body', 'state')) {
            if ($null -eq $issue.PSObject.Properties[$property]) {
                throw 'A project-owned adoption issue has incomplete identity metadata.'
            }
        }
        $expected = if ($kind -ceq 'Canonical') {
            $normalizedExpectedBody
        }
        else { $normalizedLegacyBody }
        if ([string]$issue.title -cne $ExpectedTitle -or
            $normalizedBody -cne $expected) {
            throw 'A canonically marked adoption issue has drifted from its exact owned record; manual review is required.'
        }
        if ([string]$issue.number -cnotmatch '^[1-9][0-9]*$' -or
            [string]$issue.url -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$' -or
            [string]$issue.state -cnotin @('OPEN', 'CLOSED') -or
            -not $numbers.Add([int]$issue.number)) {
            throw 'A project-owned adoption issue has invalid or duplicate identity metadata.'
        }
        $matching.Add([pscustomobject]@{
            number = $issue.number
            url = $issue.url
            title = $issue.title
            body = $issue.body
            state = $issue.state
            markerKind = $kind
        })
    }
    return @($matching | Sort-Object { [int]$_.number })
}

function Ensure-AdoptionIssue {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    $graphDigest = if ([long]$PullRequest.meAndAIMarker.schema -in
            @(7, 8, 9, 10)) {
        [string]$PullRequest.meAndAIMarker.graphDigest
    }
    else { '' }
    $marker = Get-AdoptionIssueOwnershipMarker -Repository $Repository `
        -TargetTag $ProtocolTag `
        -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
        -GraphDigest $graphDigest -PullRequestUrl ([string]$PullRequest.url)
    $legacyMarker = '<!-- meandai-local-adoption:{0}:pr-{1} -->' -f `
        $ProtocolTag, [string]$PullRequest.number
    $issueTitle = "Track meAndAI AI capabilities adoption from $ProtocolTag"
    $issueBody = New-AdoptionIssueBody -Repository $Repository `
        -PullRequest $PullRequest -Marker $marker
    $legacyIssueBody = New-AdoptionIssueBody -Repository $Repository `
        -PullRequest $PullRequest -Marker $legacyMarker -Legacy
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
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody `
        -LegacyMarker $legacyMarker -LegacyExpectedBody $legacyIssueBody)

    $canonicalIssues = @($matchingIssues | Where-Object {
        [string]$_.markerKind -ceq 'Canonical'
    })
    if ($canonicalIssues.Count -eq 0) {
        $legacyIssues = @($matchingIssues | Where-Object {
            [string]$_.markerKind -ceq 'Legacy'
        })
        if ($legacyIssues.Count -gt 0) {
            $bodyPath = Join-Path $TemporaryDirectory `
                'canonical-adoption-issue.md'
            [IO.File]::WriteAllText(
                $bodyPath, $issueBody + [Environment]::NewLine,
                [Text.UTF8Encoding]::new($false)
            )
            Invoke-External -Command 'gh' -Arguments @(
                'issue', 'edit', [string]$legacyIssues[0].number,
                '--repo', $Repository, '--body-file', $bodyPath
            ) | Out-Null
            $matchingIssues = @(Get-MarkedAdoptionIssues `
                -Issues @(Get-AdoptionIssueInventory -Repository $Repository) `
                -Marker $marker -ExpectedTitle $issueTitle `
                -ExpectedBody $issueBody -LegacyMarker $legacyMarker `
                -LegacyExpectedBody $legacyIssueBody)
            $canonicalIssues = @($matchingIssues | Where-Object {
                [string]$_.markerKind -ceq 'Canonical'
            })
        }
    }

    if ($canonicalIssues.Count -eq 0) {
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
            -ExpectedTitle $issueTitle -ExpectedBody $issueBody `
            -LegacyMarker $legacyMarker -LegacyExpectedBody $legacyIssueBody)
        $canonicalIssues = @($matchingIssues | Where-Object {
            [string]$_.markerKind -ceq 'Canonical'
        })
    }

    if ($canonicalIssues.Count -eq 0) {
        throw 'The created adoption issue was not observable during convergence.'
    }
    $canonicalNumber = [int]$canonicalIssues[0].number
    if ([string]$canonicalIssues[0].state -ceq 'CLOSED') {
        Invoke-External -Command 'gh' -Arguments @(
            'issue', 'reopen', [string]$canonicalNumber, '--repo', $Repository
        ) | Out-Null
    }
    foreach ($duplicate in @($matchingIssues | Where-Object {
        [int]$_.number -ne $canonicalNumber
    })) {
        if ([string]$duplicate.state -ceq 'OPEN') {
            Invoke-External -Command 'gh' -Arguments @(
                'issue', 'close', [string]$duplicate.number, '--repo', $Repository
            ) | Out-Null
        }
    }

    $converged = @(Get-MarkedAdoptionIssues `
        -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody `
        -LegacyMarker $legacyMarker -LegacyExpectedBody $legacyIssueBody |
        Where-Object {
            [string]$_.state -ceq 'OPEN' -and
            [string]$_.markerKind -ceq 'Canonical'
        })
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
