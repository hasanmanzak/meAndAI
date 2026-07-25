# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
function Assert-AdoptionProtocolReference {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProtocolSha
    )

    $protocolIndex = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'ls-files', '--stage', '--', '.ai/protocol'
    )).Output -join '').Trim())
    $expectedProtocolIndex = "160000 $ProtocolSha 0`t.ai/protocol"
    if ($protocolIndex -cne $expectedProtocolIndex) {
        throw 'The completed protocol reference is not the exact manifest gitlink.'
    }

    $gitmodulesPath = Join-Path $Repository '.gitmodules'
    $protocolModulePath = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.path'
    )).Output -join '').Trim())
    $protocolModuleUrl = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'config', '-f', $gitmodulesPath, '--get', 'submodule..ai/protocol.url'
    )).Output -join '').Trim())
    if ($protocolModulePath -cne '.ai/protocol' -or
        $protocolModuleUrl -cne "https://github.com/$ProtocolRepository.git") {
        throw 'The completed protocol submodule metadata is not canonical.'
    }
}

function Get-AdoptionGitModulesConfigurationRows {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [string]$Commit = '',
        [switch]$UseIndex,
        [switch]$AllowAbsent
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one .gitmodules tree source must be selected.'
    }
    $entry = if ($UseIndex) {
        Get-AdoptionTreeEntry -Repository $Repository -Path '.gitmodules' -UseIndex
    }
    else {
        Get-AdoptionTreeEntry -Repository $Repository -Path '.gitmodules' `
            -Commit $Commit
    }
    if (-not $entry.Path) {
        if ($AllowAbsent) { return @() }
        throw 'The completed adoption is missing .gitmodules.'
    }
    if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob') {
        throw 'The adoption .gitmodules source is not one regular file.'
    }
    $blobExpression = if ($UseIndex) { ':.gitmodules' } else { "${Commit}:.gitmodules" }
    $result = Invoke-Git -Repository $Repository -Arguments @(
        'config', '--blob', $blobExpression, '--null', '--list'
    )
    $raw = @($result.Output) -join "`n"
    $rows = [System.Collections.Generic.List[string]]::new()
    foreach ($record in @($raw.Split([char]0))) {
        if ([string]::IsNullOrEmpty($record)) { continue }
        $separator = $record.IndexOf("`n", [StringComparison]::Ordinal)
        if ($separator -le 0) {
            throw 'The adoption .gitmodules configuration could not be parsed exactly.'
        }
        $key = $record.Substring(0, $separator)
        $value = $record.Substring($separator + 1)
        $rows.Add("$key`n$value")
    }
    $sorted = [string[]]@($rows)
    [Array]::Sort($sorted, [StringComparer]::Ordinal)
    return @($sorted)
}

function Assert-AdoptionReservedProtocolSubmoduleAvailable {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Commit
    )

    $rows = @(Get-AdoptionGitModulesConfigurationRows `
        -Repository $Repository -Commit $Commit -AllowAbsent)
    $protocolEntry = Get-AdoptionTreeEntry -Repository $Repository `
        -Commit $Commit -Path '.ai/protocol'
    if (-not (Test-QuickAdoptionReservedSubmoduleContract `
            -Rows $rows -ProtocolEntry $protocolEntry `
            -ProtocolRepository $ProtocolRepository)) {
        throw "The reserved .gitmodules subsection '.ai/protocol' is consumer-owned or noncanonical; reconcile it manually before adoption."
    }
}

function Assert-AdoptionGitModulesPreserved {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($ProposalHead -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption proposal head is not canonical.'
    }
    $consumerBase = Get-SingleCommitParent -Repository $Repository `
        -Commit $ProposalHead
    $baseRows = @(Get-AdoptionGitModulesConfigurationRows `
        -Repository $Repository -Commit $consumerBase -AllowAbsent)
    Assert-AdoptionReservedProtocolSubmoduleAvailable `
        -Repository $Repository -Commit $consumerBase
    $finalRows = if ($UseIndex) {
        @(Get-AdoptionGitModulesConfigurationRows -Repository $Repository -UseIndex)
    }
    else {
        @(Get-AdoptionGitModulesConfigurationRows `
            -Repository $Repository -Commit $Commit)
    }
    $protocolPrefix = 'submodule..ai/protocol.'
    $baseConsumerRows = @($baseRows | Where-Object {
        -not $_.StartsWith($protocolPrefix, [StringComparison]::Ordinal)
    })
    $finalConsumerRows = @($finalRows | Where-Object {
        -not $_.StartsWith($protocolPrefix, [StringComparison]::Ordinal)
    })
    if (($baseConsumerRows -join "`0") -cne ($finalConsumerRows -join "`0")) {
        throw 'Adoption completion changed non-protocol .gitmodules configuration.'
    }
    $protocolRows = @($finalRows | Where-Object {
        $_.StartsWith($protocolPrefix, [StringComparison]::Ordinal)
    })
    $expectedProtocolRows = [string[]]@(
        "submodule..ai/protocol.path`n.ai/protocol",
        "submodule..ai/protocol.url`nhttps://github.com/$ProtocolRepository.git"
    )
    [Array]::Sort($expectedProtocolRows, [StringComparer]::Ordinal)
    if (($protocolRows -join "`0") -cne ($expectedProtocolRows -join "`0")) {
        throw 'The completed protocol .gitmodules section is not exact.'
    }
}

function Get-ValidatedAdoptionManifest {
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProposalRepository,
        [Parameter(Mandatory)][string]$ProposalHead,
        [Parameter(Mandatory)][string]$CanonicalBaseHead
    )

    try {
        $manifest = [IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json
    }
    catch {
        throw 'The adoption manifest is not valid JSON.'
    }
    if ([string]$PullRequest.meAndAIMarker.protocolSha -cnotmatch '^[0-9a-f]{40}$') {
        throw 'The adoption manifest does not match the pull-request ownership marker.'
    }

    $modulePath = Join-Path $ProtocolSource `
        'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        throw 'The exact protocol source is missing its capabilities contract module.'
    }
    $modules = @(Import-Module -Name $modulePath -Force -PassThru)
    if ($modules.Count -ne 1) {
        throw 'The exact protocol capabilities contract module could not be loaded unambiguously.'
    }
    $module = $modules[0]
    try {
        $validators = @(Get-Command -Name 'Test-MeAndAIExactAdoptionManifest' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $resolvers = @(Get-Command -Name 'Resolve-MeAndAICapabilitiesLifecycle' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $targetPathGetters = @(Get-Command -Name 'Get-MeAndAIAdoptionTargetPaths' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        $surfaceGetters = @(Get-Command -Name 'Get-MeAndAIProtocolSurfaceInventory' `
            -Module ([string]$module.Name) -CommandType Function -ErrorAction SilentlyContinue)
        if ($validators.Count -ne 1 -or $resolvers.Count -ne 1 -or
            $targetPathGetters.Count -ne 1) {
            throw 'The exact protocol capabilities contract does not export one path getter, resolver, and manifest validator.'
        }
        $targetPathGetter = $targetPathGetters[0]
        $targetPaths = @(& $targetPathGetter)
        $contract = Get-ExpectedAdoptionManifestContract `
            -Repository $ProposalRepository -ProposalHead $ProposalHead `
            -TargetPaths $targetPaths
        if ($null -eq $workflowBytes) {
            throw 'The independently verified canonical seed workflow bytes are unavailable.'
        }
        $sourceWorkflowSha = & $script:GetQuickAdoptionGitBlobSha1 `
            -Bytes ([byte[]]$workflowBytes)
        $baseWorkflowEntry = Get-AdoptionTreeEntry -Repository $ProposalRepository `
            -Commit ([string]$contract.BaseHead) -Path $workflowTargetPath
        $seedWorkflowState = if ($baseWorkflowEntry.Mode -ceq '100644' -and
            $baseWorkflowEntry.Type -ceq 'blob' -and
            $baseWorkflowEntry.Sha -ceq $sourceWorkflowSha) {
            'Exact'
        }
        elseif (-not $baseWorkflowEntry.Path) { 'Missing' }
        else { 'Drifted' }
        $resolver = $resolvers[0]
        $validator = $validators[0]
        $newValidatorParameters = @(
            'ExpectedAdoptionStrategy', 'ExpectedProtocolSurfaces',
            'ExpectedProtocolRecordLossAcknowledgement'
        )
        $newParameterCount = @($newValidatorParameters | Where-Object {
            $validator.Parameters.ContainsKey($_)
        }).Count
        $usesStrategyContract = $newParameterCount -eq $newValidatorParameters.Count -and
            $surfaceGetters.Count -eq 1
        $usesLegacyContract = $newParameterCount -eq 0 -and $surfaceGetters.Count -eq 0
        if (-not $usesStrategyContract -and -not $usesLegacyContract) {
            throw 'The exact protocol capabilities contract mixes incompatible adoption schemas.'
        }
        if ($usesStrategyContract) {
            $markerSchema = [long]$PullRequest.meAndAIMarker.schema
            $graphAwareProposal = $markerSchema -in @(7, 8, 9, 10)
            if ($markerSchema -notin @(5, 6, 7, 8, 9, 10, 11, 12)) {
                throw 'The strategy-aware protocol source requires a strategy-bound proposal marker.'
            }
            if ($graphAwareProposal -ne ([long]$manifest.schema -eq 3)) {
                throw 'The adoption manifest and ownership marker mix graph-aware and legacy schemas.'
            }
            $sourceGraph = $null
            $proposalProtocolSurfaces = @(
                $PullRequest.meAndAIMarker.protocolSurfaces
            )
            if ($graphAwareProposal) {
                if (-not $validator.Parameters.ContainsKey('ExpectedSourceGraph') -or
                    $null -eq $manifest.PSObject.Properties['sourceGraph'] -or
                    [string]$manifest.sourceGraph.baseHead -cnotmatch
                        '^[0-9a-f]{40}$') {
                    throw 'The graph-aware adoption proposal lacks its complete source graph contract.'
                }
                $sourceGraph = Get-QuickAdoptionInstructionGraph `
                    -Repository $ProposalRepository `
                    -Commit ([string]$manifest.sourceGraph.baseHead)
                if ($markerSchema -in @(9, 10)) {
                    $proposalProtocolSurfaces = @($sourceGraph.protocolSurfaces)
                }
                $identityValidator = Get-InitialAdoptionPolicyCommand `
                    -Name 'Test-MeAndAIExactInstructionGraphIdentity'
                $markerIdentity = [pscustomobject][ordered]@{
                    schema = 1
                    graphBase = [string]$PullRequest.meAndAIMarker.graphBase
                    graphDigest = [string]$PullRequest.meAndAIMarker.graphDigest
                    graphCounts = $PullRequest.meAndAIMarker.graphCounts
                    graphLimits = $PullRequest.meAndAIMarker.graphLimits
                    protocolSurfaces = @($proposalProtocolSurfaces)
                }
                if (-not [bool](& $identityValidator `
                    -Identity $markerIdentity -Graph $sourceGraph)) {
                    throw 'The proposal marker does not match the independently rebuilt source graph.'
                }
                $structuralBaseHead = [string]$contract.BaseHead
                if ([string]$sourceGraph.baseHead -cne $structuralBaseHead) {
                    if ((Get-SingleCommitParent -Repository $ProposalRepository `
                            -Commit $structuralBaseHead) -cne
                        [string]$sourceGraph.baseHead) {
                        throw 'The proposal base is not one exact child of its source graph base.'
                    }
                    $seedOnlyPaths = @((Invoke-Git `
                        -Repository $ProposalRepository -Arguments @(
                            'diff-tree', '--no-commit-id', '--name-only', '-r',
                            '--no-renames', $structuralBaseHead, '--'
                        )).Output | Where-Object { $_ } | ForEach-Object {
                            [string]$_
                        })
                    if ($seedOnlyPaths.Count -ne 1 -or
                        [string]$seedOnlyPaths[0] -cne $workflowTargetPath) {
                        throw 'The proposal base child is not the exact workflow-only seed commit.'
                    }
                }
            }
            elseif ($validator.Parameters.ContainsKey('ExpectedSourceGraph')) {
                $reassessmentGraph = Get-QuickAdoptionInstructionGraph `
                    -Repository $ProposalRepository `
                    -Commit ([string]$contract.BaseHead)
                if ((@($reassessmentGraph.protocolSurfaces) -join "`n") -cne
                    (@($proposalProtocolSurfaces) -join "`n")) {
                    throw 'The legacy adoption proposal now has expanded instruction authority; close it and rerun exact graph assessment.'
                }
            }
            $lifecycleProtocolSurfaces = if ($graphAwareProposal) {
                @($sourceGraph.protocolSurfaces)
            }
            else { @($contract.ProtocolSurfaces) }
            $plan = & $resolver -Snapshot ([pscustomobject]@{
                SchemaVersion = if ($graphAwareProposal) { 3 } else { 2 }
                LocalUpdaterState = [string]$contract.LocalUpdaterState
                SeedWorkflowState = $seedWorkflowState
                Collisions = @($contract.Collisions)
                AdoptionStrategy = [string]$PullRequest.meAndAIMarker.adoptionStrategy
                ProtocolSurfaces = @($lifecycleProtocolSurfaces)
                AcknowledgeProtocolRecordLoss = [bool]$PullRequest.meAndAIMarker.protocolRecordLossAcknowledged
                ManifestExists = $false
                RemoteBranchExists = $false
                OpenPullRequestCount = 0
                ExistingProposalValid = $false
                SourceGraph = $sourceGraph
            })
        }
        else {
            if ([long]$PullRequest.meAndAIMarker.schema -notin @(2, 3, 4)) {
                throw 'A legacy protocol source cannot validate a strategy-bound proposal marker.'
            }
            if (@($contract.ProtocolSurfaces).Count -gt 0) {
                throw 'The legacy adoption proposal now has migration-policy evidence; close it and rerun initial assessment with an explicit maintainer strategy.'
            }
            $plan = & $resolver -Snapshot ([pscustomobject]@{
                SchemaVersion = 1
                LocalUpdaterState = [string]$contract.LocalUpdaterState
                SeedWorkflowState = $seedWorkflowState
                Collisions = @($contract.Collisions)
                ManifestExists = $false
                RemoteBranchExists = $false
                OpenPullRequestCount = 0
                ExistingProposalValid = $false
            })
        }
        if ($null -eq $plan -or
            [string]$plan.State -cnotin @('BootstrapReady', 'AdoptionReviewRequired') -or
            [string]$PullRequest.meAndAIMarker.state -cne [string]$plan.State) {
            throw 'The adoption proposal is not permitted by the independently derived lifecycle contract.'
        }
        if ($usesStrategyContract) {
            if ([string]$plan.AdoptionStrategy -cne
                    [string]$PullRequest.meAndAIMarker.adoptionStrategy -or
                ((@($plan.ProtocolSurfaces) -join "`n") -cne
                    (@($proposalProtocolSurfaces) -join "`n")) -or
                [bool]$plan.ProtocolRecordLossAcknowledged -ne
                    [bool]$PullRequest.meAndAIMarker.protocolRecordLossAcknowledged) {
                throw 'The independently derived lifecycle plan does not match the proposal strategy identity.'
            }
            $valid = & $validator -Manifest $manifest -Repository $Repository `
                -TargetTag $ProtocolTag `
                -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -ExpectedState ([string]$plan.State) `
                -ExpectedAdoptionStrategy ([string]$plan.AdoptionStrategy) `
                -ExpectedProtocolSurfaces @($plan.ProtocolSurfaces) `
                -ExpectedProtocolRecordLossAcknowledgement `
                    ([bool]$plan.ProtocolRecordLossAcknowledged) `
                -ExpectedCollisions @($contract.Collisions) `
                -ExpectedSourceGraph $sourceGraph
        }
        else {
            $valid = & $validator -Manifest $manifest -Repository $Repository `
                -TargetTag $ProtocolTag `
                -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -ExpectedState ([string]$plan.State) `
                -ExpectedCollisions @($contract.Collisions)
        }
    }
    finally {
        Remove-Module -Name ([string]$module.Name) -Force -ErrorAction SilentlyContinue
    }
    if ($valid -isnot [bool] -or -not $valid) {
        throw 'The adoption manifest does not exactly match the independently derived protocol contract.'
    }
    Assert-ExactAdoptionProposal -Repository $ProposalRepository `
        -ProposalHead $ProposalHead -CanonicalBaseHead $CanonicalBaseHead `
        -ProposalMode ([string]$plan.ProposalMode) -TargetPaths $targetPaths `
        -ProtocolSource $ProtocolSource `
        -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha)
    return $manifest
}

function Test-QuickAdoptionConsumerGovernancePath {
    param([Parameter(Mandatory)][string]$Path)

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAIConsumerGovernancePath'
    return [bool](& $command -Path $Path)
}

function Test-QuickAdoptionLegacyGovernancePath {
    param([Parameter(Mandatory)][string]$Path)

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAILegacyGovernancePath'
    return [bool](& $command -Path $Path)
}

function Test-QuickAdoptionLegacyCommonAuthorityPath {
    param([Parameter(Mandatory)][string]$Path)

    $command = Get-InitialAdoptionPolicyCommand `
        -Name 'Test-MeAndAILegacyCommonAuthorityPath'
    return [bool](& $command -Path $Path)
}

function ConvertFrom-AdoptionStatusLines {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Lines)

    $changes = [System.Collections.Generic.List[object]]::new()
    foreach ($value in @($Lines)) {
        $line = [string]$value
        $match = [regex]::Match($line, '^(?<status>[ADMT])\t(?<path>[^\t]+)$')
        if (-not $match.Success -or
            -not (Test-QuickAdoptionCanonicalRepositoryPath `
                -Path ([string]$match.Groups['path'].Value))) {
            throw 'Local Codex produced an unparseable or noncanonical staged change.'
        }
        $changes.Add([pscustomobject]@{
            Status = [string]$match.Groups['status'].Value
            Path = [string]$match.Groups['path'].Value
        })
    }
    return @($changes)
}

function Assert-QuickAdoptionFinalSeedWorkflowIdentity {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one final workflow tree source must be selected.'
    }
    $pathLines = if ($UseIndex) {
        @((Invoke-Git -Repository $Repository -Arguments @(
            'ls-files', '--cached'
        )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    }
    else {
        @((Invoke-Git -Repository $Repository -Arguments @(
            'ls-tree', '-r', '--name-only', $Commit, '--'
        )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    }
    foreach ($path in $pathLines) {
        Assert-QuickAdoptionCanonicalPathCasing -Path $path
    }
    $matches = @($pathLines | Where-Object {
        $_.Equals($workflowTargetPath, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($matches.Count -ne 1 -or [string]$matches[0] -cne $workflowTargetPath) {
        throw "The final adoption tree must contain exactly one canonical '$workflowTargetPath'."
    }
    $entry = if ($UseIndex) {
        Get-AdoptionTreeEntry -Repository $Repository `
            -Path $workflowTargetPath -UseIndex
    }
    else {
        Get-AdoptionTreeEntry -Repository $Repository `
            -Path $workflowTargetPath -Commit $Commit
    }
    if ($entry.Mode -cne '100644' -or $entry.Type -cne 'blob') {
        throw 'The final lifecycle seed workflow is not one regular canonical file.'
    }
}

function Assert-AdoptionCompletionEnvelope {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Changes,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ProposalHead,
        [string]$Commit = '',
        [switch]$UseIndex
    )

    if ($UseIndex -eq [bool]$Commit) {
        throw 'Exactly one adoption completion tree source must be selected.'
    }
    $strategy = if ($null -ne $Manifest.PSObject.Properties['adoptionStrategy']) {
        [string]$Manifest.adoptionStrategy
    }
    else { 'LegacyUnspecified' }
    $sourceGraphEvidence = if ([long]$Manifest.schema -eq 3 -and
        $null -ne $Manifest.PSObject.Properties['sourceGraph']) {
        $Manifest.sourceGraph
    }
    else { $null }
    [object[]]$protocolSurfaces = [object[]]::new(0)
    if ($null -ne $Manifest.PSObject.Properties['protocolSurfaces']) {
        $protocolSurfaces = [object[]]@($Manifest.protocolSurfaces)
    }
    $evidencePathSet = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($path in @($adoptionCanonicalTargetPaths) + $protocolSurfaces) {
        [void]$evidencePathSet.Add([string]$path)
    }
    foreach ($change in @($Changes | Where-Object {
        [string]$_.Status -cne 'D'
    })) {
        [void]$evidencePathSet.Add([string]$change.Path)
    }
    $evidencePaths = [string[]]@($evidencePathSet)
    [Array]::Sort($evidencePaths, [StringComparer]::Ordinal)
    $finalEntries = @($evidencePaths | ForEach-Object {
        $path = [string]$_
        $entry = if ($UseIndex) {
            Get-AdoptionTreeEntry -Repository $Repository -Path $path -UseIndex
        }
        else {
            Get-AdoptionTreeEntry -Repository $Repository -Path $path -Commit $Commit
        }
        [pscustomobject]@{
            Path = $path
            Exists = [bool](-not [string]::IsNullOrEmpty([string]$entry.Path))
            Mode = [string]$entry.Mode
        }
    })
    if (-not (Test-QuickAdoptionCompletedChangeSet `
            -Changes @($Changes) -ExpectedAdoptionStrategy $strategy `
            -ProtocolSurfaces $protocolSurfaces `
            -TargetPaths $adoptionCanonicalTargetPaths `
            -FinalEntries $finalEntries `
            -SourceGraph $sourceGraphEvidence)) {
        throw 'The adoption completion change set violates the canonical capabilities contract.'
    }
    if ($UseIndex) {
        Assert-QuickAdoptionFinalSeedWorkflowIdentity `
            -Repository $Repository -UseIndex
        Assert-AdoptionGitModulesPreserved -Repository $Repository `
            -ProposalHead $ProposalHead -UseIndex
    }
    else {
        Assert-QuickAdoptionFinalSeedWorkflowIdentity `
            -Repository $Repository -Commit $Commit
        Assert-AdoptionGitModulesPreserved -Repository $Repository `
            -ProposalHead $ProposalHead -Commit $Commit
    }
    $baseline = Get-ExactConsumerMigrationBaseline -ProtocolSource $ProtocolSource `
        -ProtocolSha ([string]$Manifest.protocolSha)
    $ledgerEntry = if ($UseIndex) {
        Get-AdoptionTreeEntry -Repository $Repository `
            -Path $consumerMigrationLedgerPath -UseIndex
    }
    else {
        Get-AdoptionTreeEntry -Repository $Repository `
            -Path $consumerMigrationLedgerPath -Commit $Commit
    }
    if ($ledgerEntry.Mode -cne '100644' -or
        $ledgerEntry.Sha -cne [string]$baseline.Blob) {
        throw 'The consumer migration ledger does not match the exact protocol baseline.'
    }
}

function Get-ValidatedAdoptionChangeSet {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$ProtocolSource
    )

    Assert-CredentialFilesAbsent -Repository $Repository
    Invoke-Git -Repository $Repository -Arguments @('diff', '--check') | Out-Null
    Invoke-Git -Repository $Repository -Arguments @(
        'add', '-A', '--', '.', ':(exclude).ai/protocol'
    ) | Out-Null
    $statusLines = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--cached', '--name-status', '--no-renames',
        '--diff-filter=ACMTD'
    )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if ($statusLines.Count -eq 0) {
        throw 'Local Codex produced no reviewable adoption change.'
    }
    $changes = @(ConvertFrom-AdoptionStatusLines -Lines $statusLines)
    $changedPaths = @($changes | ForEach-Object { [string]$_.Path })
    $proposalHead = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    Assert-AdoptionCompletionEnvelope -Repository $Repository `
        -Manifest $Manifest -Changes $changes -ProtocolSource $ProtocolSource `
        -ProposalHead $proposalHead -UseIndex
    Assert-AdoptionProtocolReference -Repository $Repository `
        -ProtocolSha ([string]$Manifest.protocolSha)
    Invoke-Git -Repository $Repository -Arguments @('diff', '--cached', '--check') | Out-Null
    return $changedPaths
}

function Assert-RecoverablePublishedAdoption {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$PreviousHead,
        [Parameter(Mandatory)][string]$PlannedHead,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$ProtocolSha,
        [Parameter(Mandatory)][string]$ProtocolSource
    )

    $head = ((@(Invoke-Git -Repository $Repository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    if ($head -cne $PlannedHead -or
        (Get-SingleCommitParent -Repository $Repository -Commit $PlannedHead) -cne $PreviousHead) {
        throw 'The published adoption recovery commit does not match its persisted transition.'
    }
    $status = @((Invoke-Git -Repository $Repository -Arguments @(
        'status', '--porcelain=v1', '--untracked-files=all'
    )).Output | Where-Object { $_ })
    if ($status.Count -ne 0) {
        throw "The published adoption recovery clone is not clean: $($status -join ', ')."
    }
    Assert-CredentialFilesAbsent -Repository $Repository
    $manifestPath = Join-Path $Repository `
        ($adoptionManifestPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (Test-Path -LiteralPath $manifestPath) {
        throw 'The published adoption recovery commit still contains the transient manifest.'
    }
    Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--check', $PreviousHead, $PlannedHead, '--'
    ) | Out-Null
    $statusLines = @((Invoke-Git -Repository $Repository -Arguments @(
        'diff', '--no-renames', '--name-status', '--diff-filter=ACMTD',
        $PreviousHead, $PlannedHead, '--'
    )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
    if ($statusLines.Count -eq 0) {
        throw 'The published adoption recovery commit contains no reviewable change.'
    }
    $changes = @(ConvertFrom-AdoptionStatusLines -Lines $statusLines)
    Assert-AdoptionCompletionEnvelope -Repository $Repository `
        -Manifest $Manifest -Changes $changes -ProtocolSource $ProtocolSource `
        -ProposalHead $PreviousHead -Commit $PlannedHead
    if ([long]$Manifest.schema -eq 3) {
        if ($null -eq $Manifest.PSObject.Properties['sourceGraph']) {
            throw 'The graph-aware adoption manifest lost its source graph.'
        }
        $sourceGraph = Get-QuickAdoptionInstructionGraph `
            -Repository $Repository `
            -Commit ([string]$Manifest.sourceGraph.baseHead)
        $finalGraph = Get-QuickAdoptionInstructionGraph `
            -Repository $Repository -Commit $PlannedHead
        $closureResolver = Get-InitialAdoptionPolicyCommand `
            -Name 'Resolve-MeAndAIInstructionGraphClosure'
        $closure = & $closureResolver -SourceGraph $sourceGraph `
            -FinalGraph $finalGraph `
            -ExpectedAdoptionStrategy ([string]$Manifest.adoptionStrategy) `
            -Changes $changes -TargetPaths $adoptionCanonicalTargetPaths
        if ([string]$closure.State -cne 'Ready') {
            $paths = @($closure.UnresolvedPaths | ForEach-Object { [string]$_ })
            throw "MEANDAI_ADOPTION_BLOCKED: unresolved instruction authority: $($paths -join ', ')"
        }
    }
    Assert-AdoptionProtocolReference -Repository $Repository -ProtocolSha $ProtocolSha
    Assert-AdoptionUpdaterAssetsExact -Repository $Repository `
        -ProtocolSource $ProtocolSource -ProtocolSha $ProtocolSha -Commit $PlannedHead
}

function Get-RemoteBranchHead {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$Remote,
        [Parameter(Mandatory)][string]$Branch,
        [switch]$AllowMissing
    )

    $result = Invoke-Git -Repository $Repository -Arguments @(
        'ls-remote', '--heads', $Remote, "refs/heads/$Branch"
    )
    $lines = @($result.Output | Where-Object { $_ })
    if ($AllowMissing -and $lines.Count -eq 0) {
        return $null
    }
    if ($lines.Count -ne 1) {
        throw 'The deterministic adoption branch is missing or ambiguous on the remote.'
    }
    $parts = ([string]$lines[0]).Split("`t")
    if ($parts.Count -ne 2 -or $parts[0] -cnotmatch '^[0-9a-f]{40}$' -or
        $parts[1] -cne "refs/heads/$Branch") {
        throw 'The deterministic adoption branch returned invalid remote metadata.'
    }
    return $parts[0]
}

function Invoke-AdoptionCodexCompletion {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$ProtocolSource,
        [Parameter(Mandatory)][string]$ClonePath,
        [Parameter(Mandatory)][string]$TemporaryRoot,
        [Parameter(Mandatory)]$AdoptionIssue
    )

    $runner = Resolve-LocalCodexRunner -ExplicitCommand $CodexCommand `
        -FallbackVersion $TemporaryCodexVersion
    $timeoutMilliseconds = if ($CodexTimeoutSeconds -gt 0) {
        [int][Math]::Min(
            [int]::MaxValue, [TimeSpan]::FromSeconds($CodexTimeoutSeconds).TotalMilliseconds
        )
    }
    else {
        [int][Math]::Min(
            [int]::MaxValue, [TimeSpan]::FromMinutes($CodexTimeoutMinutes).TotalMilliseconds
        )
    }
    $timeoutDescription = if ($CodexTimeoutSeconds -gt 0) {
        "$CodexTimeoutSeconds second(s)"
    }
    else { "$CodexTimeoutMinutes minute(s)" }
    Assert-LocalCodexLogin -Runner $runner `
        -TimeoutMilliseconds $timeoutMilliseconds `
        -TimeoutDescription $timeoutDescription
    $windowsSandboxMode = Assert-LocalCodexWorkspaceWrite -Runner $runner `
        -WorkingDirectory $ClonePath `
        -TimeoutMilliseconds $timeoutMilliseconds
    $resultPath = Join-Path $TemporaryRoot 'codex-result.txt'
    $resolvedStrategy = if ($null -ne $Manifest.PSObject.Properties['adoptionStrategy']) {
        [string]$Manifest.adoptionStrategy
    }
    else { 'LegacyUnspecified' }
    $lossAcknowledged = if ($null -ne $Manifest.PSObject.Properties[
        'protocolRecordLossAcknowledged'
    ]) {
        [bool]$Manifest.protocolRecordLossAcknowledged
    }
    else { $false }
    $surfaceText = if ($null -ne $Manifest.PSObject.Properties['protocolSurfaces'] -and
        @($Manifest.protocolSurfaces).Count -gt 0) {
        @($Manifest.protocolSurfaces | ForEach-Object { "- $_" }) -join "`n"
    }
    else { '- None' }
    $collisionText = if (@($Manifest.collisions).Count -gt 0) {
        @($Manifest.collisions | ForEach-Object { "- $_" }) -join "`n"
    }
    else { '- None' }
    $graphText = if ([long]$Manifest.schema -eq 3 -and
        $null -ne $Manifest.PSObject.Properties['sourceGraph']) {
        @(
            "- Base: $([string]$Manifest.sourceGraph.baseHead)",
            "- Digest: $([string]$Manifest.sourceGraph.digest)",
            "- Nodes: $([int]$Manifest.sourceGraph.counts.nodes)",
            "- Edges: $([int]$Manifest.sourceGraph.counts.edges)",
            "- Candidates: $([int]$Manifest.sourceGraph.counts.candidates)"
        ) -join "`n"
    }
    else { '- Legacy graph-unaware proposal' }
    $manifestReadingInstruction = if ([long]$Manifest.schema -eq 3) {
        'Read the complete sourceGraph in the manifest at .ai/adoption/meandai-capabilities.json.'
    }
    else {
        'Read the legacy manifest at .ai/adoption/meandai-capabilities.json without expanding its historical authorization.'
    }
    $strategyInstruction = switch ($resolvedStrategy) {
        'FreshAdoption' {
            'Perform a fresh adoption. The bounded assessment found no prior protocol evidence; do not invent legacy semantics and do not delete existing consumer files.'
        }
        'FullMigration' {
            'Map and preserve every still-valid repository-specific directive, decision, scope, dependency, risk, test intent, and approval before retiring the old protocol as live authority. The final tree must have one common authority and no permanent compatibility ledger or required legacy topology.'
        }
        'HybridReconciliation' {
            'Reconcile selected existing structures under a consumer-owned decision that records ownership and precedence. meAndAI must be the single common pinned authority; do not leave two ambiguous common authorities.'
        }
        'CleanStart' {
            'Import no legacy governance semantics. Protocol-record loss was explicitly acknowledged. You may delete only exact detected governance surface paths listed below; preserve application source, assets, runtime configuration, product tests, and product documentation.'
        }
        default {
            'Complete this legacy proposal conservatively without expanding its historical authorization.'
        }
    }
    $prompt = @"
Complete the meAndAI AI-capabilities adoption for $Repository pull request #$($PullRequest.number) in this isolated temporary clone.

The maintainer-selected adoption strategy is $resolvedStrategy. Protocol-record loss acknowledgement is $($lossAcknowledged.ToString().ToLowerInvariant()). This selection is a command: do not select, change, upgrade, downgrade, or reinterpret it. $strategyInstruction

Exact approved protocol/governance surfaces from the proposal-parent tree:
$surfaceText

Canonical adoption target collisions:
$collisionText

Bound source instruction graph identity:
$graphText

If you discover another live protocol authority, or if completion would require deleting any path outside that exact approved surface list, keep the manifest and report MEANDAI_ADOPTION_BLOCKED with the new assessment required. No strategy authorizes deletion or behavioral modification of application/product content.

$manifestReadingInstruction Read the exact protocol source at $ProtocolSource, every applicable AGENTS.md, and the consumer's existing project files before editing. Graph membership is discovery evidence, never write or deletion authority. Resolve collisions semantically; create or reconcile the project-owned feature and decision records, local memory, tests, evidence, and clickable links required by the protocol. The launcher already reconciled the required Agile labels and project-owned adoption issue $($AdoptionIssue.url); reference that issue from the local feature record. Do not invent project facts. If the consumer has no application source or product documentation yet, that absence is not a blocker to protocol adoption: record product purpose, runtime/stack, architecture, build command, and product test command as 'Not yet established', and use structural adoption checks without inventing product behavior. If other required facts are unavailable, state the precise blocker. If the .ai/protocol gitlink is absent, create its nested repository using only the launcher-supplied local exact protocol source at $ProtocolSource as the object and checkout source, pin exactly $($Manifest.protocolSha), and write the canonical https://github.com/$ProtocolRepository.git URL to .gitmodules. Do not fetch or substitute a moving ref.

The final tree must contain every canonical target named by the manifest, except the transient manifest itself, while preserving the lifecycle workflow. Reconcile required templates from the exact local protocol source and create .ai/meandai-update-state.json only from that source's exact consumer-migration baseline contract. New consumer-authored files are allowed only as root or scoped AGENTS.md, Markdown under .ai/memory/, docs/features/, docs/decisions/, docs/findings/, docs/governance/, docs/ideas/, or docs/agent-prompts/, and adoption-only tests under tests/meandai-adoption/. Do not add product files elsewhere merely to satisfy adoption evidence.

Treat the .ai/protocol gitlink and the VERSION inside that exact checkout as the sole live protocol identity. Consumer-owned instructions, memory, decisions, features, indexes, and tests must resolve the current identity from those sources and must not embed a literal current tag or commit. Exact values may appear only as dated historical event evidence.

Secret provisioning is already complete: FG_PAT.txt maps to MEANDAI_UPDATER_TOKEN and MEANDAI_RO_FG_PAT.txt maps to MEANDAI_PROTOCOL_TOKEN. Those source files are intentionally absent. Do not search for, request, print, recreate, or modify credential values or repository secrets.

Work only in this clone. Spawned-command network access is disabled: do not invoke gh, GitHub APIs, remote Git operations, or any other external service. Preserve any existing pinned protocol gitlink and do not change the lifecycle workflow. Do not commit, push, approve, mark the pull request ready, merge, close, delete, or alter branches. The launcher owns GitHub records and Git publication; the maintainer owns merge.

Keep validation bounded: implement reviewable slices, run relevant tests, perform one fresh-diff self-review and the protocol's bounded completion scan, fix blocking findings only, and avoid recursive validators. Remove .ai/adoption/meandai-capabilities.json only when all adoption gates are satisfied.

Your final response must start with MEANDAI_ADOPTION_READY only when the manifest has been removed and the repository-local adoption work is complete. Otherwise start with MEANDAI_ADOPTION_BLOCKED and state the exact blocker. Include concise test evidence.
"@
    Invoke-LocalCodexExec -Runner $runner -WorkingDirectory $ClonePath `
        -Prompt $prompt -OutputPath $resultPath `
        -TimeoutMilliseconds $timeoutMilliseconds `
        -TimeoutDescription $timeoutDescription `
        -WindowsSandboxMode $windowsSandboxMode
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        throw 'Local Codex completed without a final result file.'
    }
    $result = [IO.File]::ReadAllText($resultPath).Trim()
    if (-not $result.StartsWith('MEANDAI_ADOPTION_READY', [StringComparison]::Ordinal)) {
        if ($result.Length -gt 1200) { $result = $result.Substring(0, 1200) + '...' }
        throw "Local Codex did not declare the adoption ready. $result"
    }
    return [pscustomobject]@{ Runner = $runner; Result = $result }
}

function Assert-LiveConsumerRepositoryBoundary {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$ExpectedRepository,
        [AllowEmptyString()][string]$ExpectedDefaultBranch = '',
        [AllowEmptyString()][string]$ExpectedHead = '',
        [switch]$ExpectEmpty,
        [switch]$RequireOnlyExpectedHead,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    # Read the configured identity rather than Git's rewritten transport URL.
    # Tests and maintainers may use url.*.insteadOf for a safe local transport,
    # while repository identity must remain bound to the canonical GitHub URL.
    $remoteUrl = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
        'config', '--get', "remote.$RemoteName.url"
    )).Output -join '').Trim())
    $remoteSlug = Get-GitHubSlugFromRemote -RemoteUrl $remoteUrl
    if (-not $remoteSlug.Equals(
        $ExpectedRepository, [StringComparison]::OrdinalIgnoreCase
    )) {
        throw $FailureMessage
    }
    $readLiveMetadata = {
        $view = Invoke-External -Command 'gh' -Arguments @(
            'repo', 'view', $remoteSlug, '--json',
            'nameWithOwner,defaultBranchRef'
        )
        try {
            $repositoryInfo = ((@($view.Output) -join [Environment]::NewLine) |
                ConvertFrom-Json)
        }
        catch {
            throw $FailureMessage
        }
        return [pscustomobject]@{
            Repository = if ($null -ne $repositoryInfo) {
                [string]$repositoryInfo.nameWithOwner
            }
            else { '' }
            DefaultBranch = if ($null -ne $repositoryInfo -and
                $null -ne $repositoryInfo.defaultBranchRef) {
                [string]$repositoryInfo.defaultBranchRef.name
            }
            else { '' }
        }
    }
    $liveMetadata = & $readLiveMetadata
    if (-not ([string]$liveMetadata.Repository).Equals(
        $ExpectedRepository, [StringComparison]::OrdinalIgnoreCase
    )) {
        throw $FailureMessage
    }

    if ($ExpectEmpty) {
        if ($ExpectedDefaultBranch -or $ExpectedHead -or
            [string]$liveMetadata.DefaultBranch) {
            throw $FailureMessage
        }
        $advertisedRefs = @((Invoke-Git -Repository $TargetRepository -Arguments @(
            'ls-remote', $RemoteName
        )).Output | Where-Object { $_ })
        if ($advertisedRefs.Count -ne 0) {
            throw $FailureMessage
        }
        return
    }

    $remoteHead = Get-RemoteBranchHead -Repository $TargetRepository `
        -Remote $RemoteName -Branch $ExpectedDefaultBranch
    if ($ExpectedDefaultBranch -eq '' -or
        $ExpectedHead -cnotmatch '^[0-9a-f]{40}$' -or
        $remoteHead -cne $ExpectedHead) {
        throw $FailureMessage
    }
    if ($RequireOnlyExpectedHead) {
        $advertisedRefs = @((Invoke-Git -Repository $TargetRepository -Arguments @(
            'ls-remote', $RemoteName
        )).Output | Where-Object { $_ } | ForEach-Object { [string]$_ })
        $expectedBranchLine = "$ExpectedHead`trefs/heads/$ExpectedDefaultBranch"
        $expectedHeadLine = "$ExpectedHead`tHEAD"
        $branchLines = @($advertisedRefs | Where-Object {
            $_ -ceq $expectedBranchLine
        })
        $headLines = @($advertisedRefs | Where-Object {
            $_ -ceq $expectedHeadLine
        })
        $unexpectedRefs = @($advertisedRefs | Where-Object {
            $_ -cne $expectedBranchLine -and $_ -cne $expectedHeadLine
        })
        if ($branchLines.Count -ne 1 -or $headLines.Count -gt 1 -or
            $unexpectedRefs.Count -gt 0) {
            throw $FailureMessage
        }
        # GitHub may expose the exact first branch before its repository
        # metadata reports defaultBranchRef. Retry only that one unambiguous
        # transient state; a contradictory nonempty branch name fails at once.
        $metadataRetried = $false
        if (-not [string]$liveMetadata.DefaultBranch) {
            $metadataRetried = $true
            for ($attempt = 1; $attempt -le 5; $attempt++) {
                Start-Sleep -Milliseconds 500
                $liveMetadata = & $readLiveMetadata
                if (-not ([string]$liveMetadata.Repository).Equals(
                    $ExpectedRepository, [StringComparison]::OrdinalIgnoreCase
                )) {
                    throw $FailureMessage
                }
                if ([string]$liveMetadata.DefaultBranch) { break }
            }
        }
        if ($metadataRetried) {
            $remoteHead = Get-RemoteBranchHead -Repository $TargetRepository `
                -Remote $RemoteName -Branch $ExpectedDefaultBranch
            $advertisedRefs = @((Invoke-Git -Repository $TargetRepository `
                -Arguments @('ls-remote', $RemoteName)).Output |
                Where-Object { $_ } | ForEach-Object { [string]$_ })
            $branchLines = @($advertisedRefs | Where-Object {
                $_ -ceq $expectedBranchLine
            })
            $headLines = @($advertisedRefs | Where-Object {
                $_ -ceq $expectedHeadLine
            })
            $unexpectedRefs = @($advertisedRefs | Where-Object {
                $_ -cne $expectedBranchLine -and $_ -cne $expectedHeadLine
            })
            if ($remoteHead -cne $ExpectedHead -or
                $branchLines.Count -ne 1 -or $headLines.Count -gt 1 -or
                $unexpectedRefs.Count -gt 0) {
                throw $FailureMessage
            }
        }
    }
    if ([string]$liveMetadata.DefaultBranch -cne $ExpectedDefaultBranch) {
        throw $FailureMessage
    }
}

function Assert-LiveConsumerDefaultBranchUnchanged {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$ExpectedHead,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    $remoteUrl = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
        'config', '--get', "remote.$RemoteName.url"
    )).Output -join '').Trim())
    $remoteSlug = Get-GitHubSlugFromRemote -RemoteUrl $remoteUrl
    Assert-LiveConsumerRepositoryBoundary `
        -TargetRepository $TargetRepository -ExpectedRepository $remoteSlug `
        -ExpectedDefaultBranch $Branch -ExpectedHead $ExpectedHead `
        -FailureMessage $FailureMessage
}

function Assert-CanonicalConsumerBaseUnchanged {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$ExpectedHead,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    $localHead = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
        'rev-parse', 'HEAD'
    )).Output -join '').Trim())
    if ($localHead -cne $ExpectedHead) {
        throw $FailureMessage
    }
    Assert-LiveConsumerDefaultBranchUnchanged `
        -TargetRepository $TargetRepository -Branch $Branch `
        -ExpectedHead $ExpectedHead -FailureMessage $FailureMessage
}

function Complete-AdoptionWithLocalCodex {
    param(
        [Parameter(Mandatory)][string]$TargetRepository,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][string]$CanonicalBaseHead,
        [string]$ProtocolToken = ''
    )

    $branch = [string]$PullRequest.headRefName
    $expectedHead = [string]$PullRequest.headRefOid
    $expectedBody = [string]$PullRequest.body
    Assert-CanonicalConsumerBaseUnchanged -TargetRepository $TargetRepository `
        -Branch ([string]$PullRequest.baseRefName) -ExpectedHead $CanonicalBaseHead `
        -FailureMessage 'The canonical consumer base changed before local adoption validation.'
    $remoteHead = Get-RemoteBranchHead -Repository $TargetRepository -Remote $RemoteName -Branch $branch
    if ($remoteHead -cne $expectedHead) {
        throw 'The pull-request head and live adoption branch differ before local execution.'
    }

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-local-adoption-$([guid]::NewGuid().ToString('N'))"
    $clonePath = Join-Path $temporaryRoot 'consumer'
    [IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    try {
        $remoteUrl = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'remote', 'get-url', $RemoteName
        )).Output -join '').Trim())
        Invoke-External -Command 'git' -Arguments @(
            'clone', '--no-tags', '--single-branch', '--branch', $branch,
            $remoteUrl, $clonePath
        ) | Out-Null

        $cloneHead = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($cloneHead -cne $expectedHead) {
            throw 'The isolated clone did not resolve to the expected pull-request head.'
        }
        Assert-CredentialFilesAbsent -Repository $clonePath

        $manifestPath = Join-Path $clonePath `
            ($adoptionManifestPath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $protocolSource = $null
        if ([string]$PullRequest.meAndAIMarker.phase -ceq 'Publishing') {
            $previousHead = [string]$PullRequest.meAndAIMarker.previousHead
            $plannedHead = [string]$PullRequest.meAndAIMarker.plannedHead
            $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -Destination $temporaryRoot
            if ($expectedHead -ceq $plannedHead) {
                $proposalManifestText = @((Invoke-Git -Repository $clonePath `
                    -Arguments @('show', "${previousHead}:$adoptionManifestPath")).Output) `
                    -join [Environment]::NewLine
                if ([string]::IsNullOrWhiteSpace($proposalManifestText)) {
                    throw 'The publishing recovery parent does not contain its proposal manifest.'
                }
                $proposalManifestPath = Join-Path $temporaryRoot `
                    'publishing-proposal-manifest.json'
                [IO.File]::WriteAllText(
                    $proposalManifestPath,
                    $proposalManifestText,
                    [Text.UTF8Encoding]::new($false)
                )
                $recoveryManifest = Get-ValidatedAdoptionManifest `
                    -ManifestPath $proposalManifestPath -Repository $Repository `
                    -PullRequest $PullRequest -ProtocolSource $protocolSource `
                    -ProposalRepository $clonePath -ProposalHead $previousHead `
                    -CanonicalBaseHead $CanonicalBaseHead
                Assert-RecoverablePublishedAdoption -Repository $clonePath `
                    -PreviousHead $previousHead -PlannedHead $plannedHead `
                    -Manifest $recoveryManifest `
                    -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                    -ProtocolSource $protocolSource
                Ensure-AdoptionLabels -Repository $Repository
                $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
                    -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot
                Assert-CanonicalConsumerBaseUnchanged `
                    -TargetRepository $TargetRepository `
                    -Branch ([string]$PullRequest.baseRefName) `
                    -ExpectedHead $CanonicalBaseHead `
                    -FailureMessage 'The canonical consumer base changed before publishing recovery readiness.'
                [void](Complete-AdoptionReviewTransition -Repository $Repository `
                    -TargetRepository $TargetRepository `
                    -PullRequest $PullRequest -PublishedHead $plannedHead `
                    -CanonicalBaseHead $CanonicalBaseHead `
                    -ExpectedMarkerHead $previousHead -TemporaryDirectory $temporaryRoot `
                    -Issue $adoptionIssue -PersistCompletedMarker)
                return [pscustomobject]@{
                    Ran = $false
                    Pushed = $false
                    Ready = $true
                    RequiresManualReview = $false
                    Runner = 'publishing recovery'
                    Head = $plannedHead
                }
            }
            if ($expectedHead -cne $previousHead) {
                throw 'The publishing adoption branch matches neither persisted transition head.'
            }
            if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
                throw 'The unpushed publishing transition cannot be restored because its proposal manifest is missing.'
            }
            $restoredBody = Set-AdoptionPullRequestProposedMarker `
                -Repository $Repository -PullRequest $PullRequest `
                -PreviousHead $previousHead -TemporaryDirectory $temporaryRoot
            $PullRequest = Get-RevalidatedAdoptionPullRequest -Repository $Repository `
                -OriginalPullRequest $PullRequest -LiveHead $previousHead `
                -MarkerHead $previousHead -Body $restoredBody -Draft $true
            $expectedBody = $restoredBody
        }
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            if ([string]$PullRequest.meAndAIMarker.phase -ceq 'Completed') {
                if ($null -eq $protocolSource) {
                    $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                        -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                        -Destination $temporaryRoot
                }
                $proposalHead = Get-SingleCommitParent -Repository $clonePath `
                    -Commit $expectedHead
                $proposalManifestText = @((Invoke-Git -Repository $clonePath `
                    -Arguments @('show', "${proposalHead}:$adoptionManifestPath")).Output) `
                    -join [Environment]::NewLine
                if ([string]::IsNullOrWhiteSpace($proposalManifestText)) {
                    throw 'The completed adoption parent does not contain its proposal manifest.'
                }
                $proposalManifestPath = Join-Path $temporaryRoot `
                    'completed-proposal-manifest.json'
                [IO.File]::WriteAllText(
                    $proposalManifestPath,
                    $proposalManifestText,
                    [Text.UTF8Encoding]::new($false)
                )
                $recoveryManifest = Get-ValidatedAdoptionManifest `
                    -ManifestPath $proposalManifestPath -Repository $Repository `
                    -PullRequest $PullRequest -ProtocolSource $protocolSource `
                    -ProposalRepository $clonePath -ProposalHead $proposalHead `
                    -CanonicalBaseHead $CanonicalBaseHead
                Assert-RecoverablePublishedAdoption -Repository $clonePath `
                    -PreviousHead $proposalHead -PlannedHead $expectedHead `
                    -Manifest $recoveryManifest `
                    -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha) `
                    -ProtocolSource $protocolSource
                Ensure-AdoptionLabels -Repository $Repository
                $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
                    -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot
                Assert-CanonicalConsumerBaseUnchanged `
                    -TargetRepository $TargetRepository `
                    -Branch ([string]$PullRequest.baseRefName) `
                    -ExpectedHead $CanonicalBaseHead `
                    -FailureMessage 'The canonical consumer base changed before completed recovery readiness.'
                [void](Complete-AdoptionReviewTransition -Repository $Repository `
                    -TargetRepository $TargetRepository `
                    -PullRequest $PullRequest -PublishedHead $expectedHead `
                    -CanonicalBaseHead $CanonicalBaseHead `
                    -ExpectedMarkerHead $expectedHead -TemporaryDirectory $temporaryRoot `
                    -Issue $adoptionIssue)
                return [pscustomobject]@{
                    Ran = $false
                    Pushed = $false
                    Ready = $true
                    RequiresManualReview = $false
                    Runner = 'not required'
                    Head = $expectedHead
                }
            }
            Assert-AdoptionProtocolReference -Repository $clonePath `
                -ProtocolSha ([string]$PullRequest.meAndAIMarker.protocolSha)
            return [pscustomobject]@{
                Ran = $false
                Pushed = $false
                Ready = -not [bool]$PullRequest.isDraft
                RequiresManualReview = [bool]$PullRequest.isDraft
                Runner = 'not required'
            }
        }
        if (-not [bool]$PullRequest.isDraft) {
            throw 'The adoption manifest remains but the pull request is no longer a draft.'
        }
        if ([string]$PullRequest.meAndAIMarker.phase -cne 'Proposed') {
            throw 'The adoption manifest remains after the proposal entered a completed phase.'
        }

        if ($null -eq $protocolSource) {
            $protocolSource = Get-ProtocolSourceSnapshot -Token $ProtocolToken `
                -Commit ([string]$PullRequest.meAndAIMarker.protocolSha) `
                -Destination $temporaryRoot
        }
        $manifest = Get-ValidatedAdoptionManifest -ManifestPath $manifestPath `
            -Repository $Repository -PullRequest $PullRequest `
            -ProtocolSource $protocolSource -ProposalRepository $clonePath `
            -ProposalHead $expectedHead -CanonicalBaseHead $CanonicalBaseHead
        if ([string]$manifest.state -ceq 'BootstrapReady') {
            Assert-AdoptionProtocolReference -Repository $clonePath `
                -ProtocolSha ([string]$manifest.protocolSha)
        }

        Ensure-AdoptionLabels -Repository $Repository
        $adoptionIssue = Ensure-AdoptionIssue -Repository $Repository `
            -PullRequest $PullRequest -TemporaryDirectory $temporaryRoot

        $codexCompletion = Invoke-AdoptionCodexCompletion -Repository $Repository `
            -PullRequest $PullRequest -Manifest $manifest -ProtocolSource $protocolSource `
            -ClonePath $clonePath -TemporaryRoot $temporaryRoot -AdoptionIssue $adoptionIssue
        Set-QuickAdoptionProgress -Status 'Validating and publishing adoption' `
            -PercentComplete 92
        $runner = $codexCompletion.Runner
        $result = [string]$codexCompletion.Result

        $headAfterCodex = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ($headAfterCodex -cne $expectedHead) {
            throw 'Local Codex created a commit; the launcher will not publish an agent-owned history.'
        }
        if (Test-Path -LiteralPath $manifestPath) {
            throw 'Local Codex declared readiness but left the transient adoption manifest.'
        }
        Get-ValidatedAdoptionChangeSet -Repository $clonePath -Manifest $manifest `
            -ProtocolSource $protocolSource | Out-Null
        Assert-AdoptionUpdaterAssetsExact -Repository $clonePath `
            -ProtocolSource $protocolSource -ProtocolSha ([string]$manifest.protocolSha) `
            -UseIndex

        $liveHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($liveHead -cne $expectedHead) {
            throw 'The adoption branch changed while local Codex was running; no local result was published.'
        }
        [void](Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $PullRequest -LiveHead $expectedHead `
            -MarkerHead $expectedHead -Body $expectedBody -Draft $true)

        $targetName = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'config', 'user.name'
        )).Output -join '').Trim())
        $targetEmail = ((@(Invoke-Git -Repository $TargetRepository -Arguments @(
            'config', 'user.email'
        )).Output -join '').Trim())
        Invoke-Git -Repository $clonePath -Arguments @('config', 'user.name', $targetName) | Out-Null
        Invoke-Git -Repository $clonePath -Arguments @('config', 'user.email', $targetEmail) | Out-Null
        Invoke-Git -Repository $clonePath -Arguments @(
            'commit', '-m', "Complete meAndAI AI capabilities adoption for $ProtocolTag"
        ) | Out-Null
        $publishedHead = ((@(Invoke-Git -Repository $clonePath -Arguments @(
            'rev-parse', 'HEAD'
        )).Output -join '').Trim())
        if ((Get-SingleCommitParent -Repository $clonePath -Commit $publishedHead) -cne $expectedHead) {
            throw 'The completed adoption commit does not have the exact proposal parent.'
        }
        Assert-RecoverablePublishedAdoption -Repository $clonePath `
            -PreviousHead $expectedHead -PlannedHead $publishedHead `
            -Manifest $manifest -ProtocolSha ([string]$manifest.protocolSha) `
            -ProtocolSource $protocolSource
        [void](Get-RevalidatedAdoptionPullRequest -Repository $Repository `
            -OriginalPullRequest $PullRequest -LiveHead $expectedHead `
            -MarkerHead $expectedHead -Body $expectedBody -Draft $true)
        Assert-CanonicalConsumerBaseUnchanged -TargetRepository $TargetRepository `
            -Branch ([string]$PullRequest.baseRefName) `
            -ExpectedHead $CanonicalBaseHead `
            -FailureMessage 'The canonical consumer base changed while local Codex was running; no completion result was published.'
        $publishingBody = Set-AdoptionPullRequestPublishingMarker `
            -Repository $Repository -PullRequest $PullRequest `
            -PreviousHead $expectedHead -PlannedHead $publishedHead `
            -TemporaryDirectory $temporaryRoot
        $publishingPullRequest = Get-RevalidatedAdoptionPullRequest `
            -Repository $Repository -OriginalPullRequest $PullRequest `
            -LiveHead $expectedHead -MarkerHead $expectedHead `
            -Body $publishingBody -Draft $true
        Invoke-Git -Repository $clonePath -Arguments @(
            'push', 'origin',
            "--force-with-lease=refs/heads/$branch`:$expectedHead",
            "HEAD:refs/heads/$branch"
        ) | Out-Null
        $verifiedHead = Get-RemoteBranchHead -Repository $clonePath -Remote 'origin' -Branch $branch
        if ($verifiedHead -cne $publishedHead) {
            throw 'The adoption branch did not resolve to the launcher-published commit.'
        }

        Assert-CanonicalConsumerBaseUnchanged -TargetRepository $TargetRepository `
            -Branch ([string]$PullRequest.baseRefName) `
            -ExpectedHead $CanonicalBaseHead `
            -FailureMessage 'The canonical consumer base changed before adoption readiness.'
        [void](Complete-AdoptionReviewTransition -Repository $Repository `
            -TargetRepository $TargetRepository `
            -PullRequest $publishingPullRequest -PublishedHead $publishedHead `
            -CanonicalBaseHead $CanonicalBaseHead `
            -ExpectedMarkerHead $expectedHead -TemporaryDirectory $temporaryRoot `
            -Issue $adoptionIssue -PersistCompletedMarker)
        return [pscustomobject]@{
            Ran = $true
            Pushed = $true
            Ready = $true
            Runner = $runner.Description
            Head = $publishedHead
            Result = $result
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
