# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function Invoke-LifecycleWorkflow {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$HeadSha,
        [Parameter(Mandatory)][ValidateSet('Auto', 'FreshAdoption', 'FullMigration', 'HybridReconciliation', 'CleanStart')]
        [string]$ResolvedAdoptionStrategy,
        [Parameter(Mandatory)][bool]$ProtocolRecordLossAcknowledged
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
    Invoke-External -Command 'gh' -Arguments @(
        'workflow', 'run', $workflowName, '--repo', $Repository, '--ref', $Branch,
        '--field', "correlation_id=$correlationId",
        '--field', "adoption_strategy=$ResolvedAdoptionStrategy",
        '--field', "acknowledge_protocol_record_loss=$($ProtocolRecordLossAcknowledged.ToString().ToLowerInvariant())",
        '--field', "expected_base_sha=$HeadSha"
    ) | Out-Null

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
                    $createdAt = [DateTimeOffset]::Parse([string]$run.createdAt)
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
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
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
    if ($schema -notin @(2, 3, 4, 5, 6)) {
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
        if ($schema -eq 6) {
            $markerSurfaces = if ($marker.protocolSurfaces -is [array]) {
                @($marker.protocolSurfaces | ForEach-Object { [string]$_ })
            }
            else { @() }
            $classifiedMarkerSurfaces = @(
                Get-QuickAdoptionProtocolSurfaceInventory -Paths $markerSurfaces
            )
            if ([string]$marker.adoptionStrategy -cnotin @(
                'FreshAdoption', 'FullMigration', 'HybridReconciliation',
                'CleanStart'
            ) -or $marker.protocolSurfaces -isnot [array] -or
                $marker.protocolRecordLossAcknowledged -isnot [bool] -or
                -not (([bool]$marker.protocolRecordLossAcknowledged) -eq
                    ([string]$marker.adoptionStrategy -ceq 'CleanStart')) -or
                (($markerSurfaces -join "`n") -cne
                    ($classifiedMarkerSurfaces -join "`n")) -or
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
        if ($schema -notin @(4, 6) -or
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
        if ($schema -in @(4, 6)) {
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
        elseif ($schema -eq 5) { [string]$marker.adoptionStrategy }
        else { 'LegacyUnspecified' }
        [object[]]$contractSurfaces = [object[]]::new(0)
        if ($ExpectedAdoptionStrategy) {
            $contractSurfaces = [object[]]@($ExpectedProtocolSurfaces)
        }
        elseif ($schema -eq 5) {
            $contractSurfaces = [object[]]@($marker.protocolSurfaces)
        }
        $contractLossAcknowledgement = if ($ExpectedAdoptionStrategy) {
            $ExpectedProtocolRecordLossAcknowledgement
        }
        elseif ($schema -eq 5 -and
            $marker.protocolRecordLossAcknowledged -is [bool]) {
            [bool]$marker.protocolRecordLossAcknowledged
        }
        else { $false }
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
                    $contractLossAcknowledgement -ExpectedPhase $phase)) {
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
        [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$IssueNumber
    )

    $trackingLine = "Tracking issue: #$IssueNumber"
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
    if ($trackingStarts.Count -ne 0 -or $exactTrackingLines.Count -ne 0) {
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

function Set-AdoptionPullRequestMarkerBody {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$MarkerJson,
        [Parameter(Mandatory)][string]$TemporaryDirectory,
        [Parameter(Mandatory)][string]$FileName,
        [ValidateRange(0, 2147483647)][int]$TrackingIssueNumber = 0
    )

    $body = [string]$PullRequest.body
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
    $publishingMarkerRecord = if ([long]$marker.schema -in @(5, 6)) {
        [ordered]@{
            schema = 6
            phase = 'Publishing'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            previousHead = $PreviousHead
            plannedHead = $PlannedHead
            adoptionStrategy = [string]$marker.adoptionStrategy
            protocolSurfaces = @($marker.protocolSurfaces)
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
    $publishingMarker = $publishingMarkerRecord | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $publishingMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'publishing-adoption-pr.md'
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
    $proposedMarkerRecord = if ([long]$marker.schema -in @(5, 6)) {
        [ordered]@{
            schema = 5
            phase = 'Proposed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PreviousHead
            adoptionStrategy = [string]$marker.adoptionStrategy
            protocolSurfaces = @($marker.protocolSurfaces)
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
    $proposedMarker = $proposedMarkerRecord | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $proposedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'proposed-adoption-pr.md'
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
    $completedMarkerRecord = if ([long]$marker.schema -in @(5, 6)) {
        [ordered]@{
            schema = 5
            phase = 'Completed'
            state = [string]$marker.state
            target = [string]$marker.target
            protocolSha = [string]$marker.protocolSha
            head = $PublishedHead
            adoptionStrategy = [string]$marker.adoptionStrategy
            protocolSurfaces = @($marker.protocolSurfaces)
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
    $completedMarker = $completedMarkerRecord | ConvertTo-Json -Compress
    return Set-AdoptionPullRequestMarkerBody -Repository $Repository `
        -PullRequest $PullRequest -MarkerJson $completedMarker `
        -TemporaryDirectory $TemporaryDirectory -FileName 'completed-adoption-pr.md' `
        -TrackingIssueNumber $IssueNumber
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

function Get-MarkedAdoptionIssues {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Issues,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$ExpectedTitle,
        [Parameter(Mandatory)][string]$ExpectedBody
    )

    $numbers = [System.Collections.Generic.HashSet[int]]::new()
    $canonicalMarkerPattern = '\A' + [regex]::Escape($Marker) + '(?:\r?\n|\z)'
    $ownershipPrefix = $Marker.Substring(0, $Marker.Length - ' -->'.Length)
    $matching = [System.Collections.Generic.List[object]]::new()
    $normalizedExpectedBody = $ExpectedBody.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
    foreach ($issue in $Issues) {
        if ($null -eq $issue.PSObject.Properties['body']) {
            continue
        }
        $body = [string]$issue.body
        $hasOwnedPrefix = $body.StartsWith(
            $ownershipPrefix, [StringComparison]::OrdinalIgnoreCase
        )
        $canonicalLines = [regex]::Matches(
            $body,
            '(?m)^' + [regex]::Escape($Marker) + '\r?$'
        )
        if (-not [regex]::IsMatch($body, $canonicalMarkerPattern)) {
            if ($hasOwnedPrefix) {
                throw 'A project-owned adoption issue contains a malformed ownership marker; manual review is required.'
            }
            continue
        }
        foreach ($property in @('number', 'url', 'title', 'body', 'state')) {
            if ($null -eq $issue.PSObject.Properties[$property]) {
                throw 'A project-owned adoption issue has incomplete identity metadata.'
            }
        }
        $normalizedBody = $body.Replace("`r`n", "`n").TrimEnd([char[]]"`r`n")
        if ($canonicalLines.Count -ne 1 -or
            [string]$issue.title -cne $ExpectedTitle -or
            $normalizedBody -cne $normalizedExpectedBody) {
            throw 'A canonically marked adoption issue has drifted from its exact owned record; manual review is required.'
        }
        if ([string]$issue.number -cnotmatch '^[1-9][0-9]*$' -or
            [string]$issue.url -notmatch '^https://github\.com/[^/]+/[^/]+/issues/[1-9][0-9]*/?$' -or
            [string]$issue.state -cnotin @('OPEN', 'CLOSED') -or
            -not $numbers.Add([int]$issue.number)) {
            throw 'A project-owned adoption issue has invalid or duplicate identity metadata.'
        }
        $matching.Add($issue)
    }
    return @($matching | Sort-Object { [int]$_.number })
}

function Ensure-AdoptionIssue {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$TemporaryDirectory
    )

    $marker = '<!-- meandai-local-adoption:{0}:pr-{1} -->' -f `
        $ProtocolTag, [string]$PullRequest.number
    $issueTitle = "Track meAndAI AI capabilities adoption from $ProtocolTag"
    $surfaceLines = if (@($PullRequest.meAndAIMarker.protocolSurfaces).Count -gt 0) {
        @($PullRequest.meAndAIMarker.protocolSurfaces | ForEach-Object {
            "- ``$_``"
        })
    }
    else { @('- None') }
    $issueBodyLines = @(
        $marker,
        '## AI capabilities adoption tracking',
        '',
        "- Protocol release: ``$ProtocolTag``",
        "- Adoption draft: $($PullRequest.url)",
        "- Adoption strategy: ``$($PullRequest.meAndAIMarker.adoptionStrategy)``",
        "- Protocol-record loss acknowledged: ``$(([bool]$PullRequest.meAndAIMarker.protocolRecordLossAcknowledged).ToString().ToLowerInvariant())``",
        '',
        '### Detected protocol and governance surfaces',
        ''
    ) + @($surfaceLines) + @(
        '',
        'This issue tracks the project-owned feature and decision records, local memory, tests, evidence, links, and maintainer review required to complete the transient adoption manifest.',
        '',
        'The launcher may prepare the draft and mark it ready after bounded local validation; only the maintainer may merge it.'
    )
    $issueBody = $issueBodyLines -join [Environment]::NewLine
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
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody)

    if ($matchingIssues.Count -eq 0) {
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
            -ExpectedTitle $issueTitle -ExpectedBody $issueBody)
    }

    if ($matchingIssues.Count -eq 0) {
        throw 'The created adoption issue was not observable during convergence.'
    }
    $canonicalNumber = [int]$matchingIssues[0].number
    if ([string]$matchingIssues[0].state -ceq 'CLOSED') {
        Invoke-External -Command 'gh' -Arguments @(
            'issue', 'reopen', [string]$canonicalNumber, '--repo', $Repository
        ) | Out-Null
    }
    foreach ($duplicate in @($matchingIssues | Select-Object -Skip 1)) {
        if ([string]$duplicate.state -ceq 'OPEN') {
            Invoke-External -Command 'gh' -Arguments @(
                'issue', 'close', [string]$duplicate.number, '--repo', $Repository
            ) | Out-Null
        }
    }

    $converged = @(Get-MarkedAdoptionIssues `
        -Issues @(Get-AdoptionIssueInventory -Repository $Repository) -Marker $marker `
        -ExpectedTitle $issueTitle -ExpectedBody $issueBody |
        Where-Object { [string]$_.state -ceq 'OPEN' })
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
