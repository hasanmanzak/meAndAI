Set-StrictMode -Version Latest

$script:CapabilityLedgerPath = '.ai/meandai-capabilities-state.json'
$script:CapabilityReviewManifestPath = `
    '.ai/adoption/meandai-capability-review.json'
$script:TerminalOutcomes = @('Conforming', 'NotApplicable')
$script:OpenOutcomes = @('AdoptionRequired', 'ReviewRequired')
$script:SupportedCapabilityTypes = @(
    'Deterministic',
    'DeclarativeMigration',
    'Semantic',
    'Manual'
)

function Get-ObjectPropertyValue {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Label,
        [switch]$AllowMissing
    )

    if ($null -eq $Value) {
        throw "$Label is null."
    }
    $property = $Value.PSObject.Properties[$Name]
    if ($null -eq $property) {
        if ($AllowMissing) { return $null }
        throw "$Label is missing '$Name'."
    }
    Write-Output -NoEnumerate $property.Value
}

function Assert-CanonicalRepository {
    param([Parameter(Mandatory)][string]$Repository)

    if ([string]::IsNullOrWhiteSpace($Repository) -or
        $Repository -cnotmatch `
            '^[a-z0-9](?:[a-z0-9.-]{0,38})/[a-z0-9_.-]{1,100}$') {
        throw "Repository '$Repository' is not canonical lowercase owner/name."
    }
}

function Assert-CanonicalBranch {
    param([Parameter(Mandatory)][string]$Branch, [string]$Label = 'Branch')

    if ([string]::IsNullOrWhiteSpace($Branch) -or
        $Branch.StartsWith('/') -or $Branch.EndsWith('/') -or
        $Branch.Contains('//') -or $Branch.Contains('..') -or
        $Branch -cnotmatch '^[A-Za-z0-9._/-]+$') {
        throw "$Label '$Branch' is not canonical."
    }
}

function Assert-GitSha {
    param(
        [Parameter(Mandatory)][string]$Sha,
        [Parameter(Mandatory)][string]$Label,
        [ValidateSet(40, 64)][int]$Length = 40
    )

    if ($Sha -cnotmatch "^[0-9a-f]{$Length}$") {
        throw "$Label must be a lowercase $Length-character hexadecimal identity."
    }
}

function Assert-CanonicalVersion {
    param(
        [string]$Version,
        [Parameter(Mandatory)][string]$Label,
        [switch]$AllowEmpty
    )

    if ([string]::IsNullOrEmpty($Version)) {
        if ($AllowEmpty) { return }
        throw "$Label must not be empty."
    }
    if ($Version -cnotmatch '^v(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)$') {
        throw "$Label '$Version' is not canonical vM.m.rev."
    }
}

function Get-Sha256Text {
    param([Parameter(Mandatory)][string]$Text)

    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return -join @($algorithm.ComputeHash($bytes) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-CatalogContract {
    param([Parameter(Mandatory)]$Catalog)

    $catalogDigest = Get-ObjectPropertyValue -Value $Catalog `
        -Name 'CatalogDigest' -Label 'Capability catalog'
    $catalogDigest = [string]$catalogDigest
    Assert-GitSha -Sha $catalogDigest -Label 'Capability catalog digest' -Length 64

    $rawCapabilities = Get-ObjectPropertyValue -Value $Catalog `
        -Name 'Capabilities' -Label 'Capability catalog'
    if ($rawCapabilities -isnot [Array]) {
        throw 'Capability catalog Capabilities must be an array.'
    }

    $seenSlugs = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $capabilities = [System.Collections.Generic.List[object]]::new()
    foreach ($rawCapability in @($rawCapabilities)) {
        $slug = [string](Get-ObjectPropertyValue -Value $rawCapability `
            -Name 'Slug' -Label 'Capability catalog entry')
        $definitionBlob = [string](Get-ObjectPropertyValue `
            -Value $rawCapability -Name 'DefinitionBlob' `
            -Label "Capability '$slug'")
        $type = [string](Get-ObjectPropertyValue -Value $rawCapability `
            -Name 'Type' -Label "Capability '$slug'")
        if ($slug -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$' -or
            -not $seenSlugs.Add($slug)) {
            throw "Capability slug '$slug' is invalid or duplicated."
        }
        Assert-GitSha -Sha $definitionBlob `
            -Label "Capability '$slug' definition blob"
        if ($script:SupportedCapabilityTypes -cnotcontains $type) {
            throw "Capability '$slug' has unsupported type '$type'."
        }
        $capabilities.Add([pscustomobject][ordered]@{
            Slug = $slug
            DefinitionBlob = $definitionBlob
            Type = $type
        })
    }
    return [pscustomobject][ordered]@{
        CatalogDigest = $catalogDigest
        Capabilities = @($capabilities)
    }
}

function Test-ReviewedEvidence {
    param($Evidence)

    if ($Evidence -is [string]) {
        return -not [string]::IsNullOrWhiteSpace([string]$Evidence)
    }
    if ($Evidence -isnot [Array] -or @($Evidence).Count -eq 0) {
        return $false
    }
    foreach ($entry in @($Evidence)) {
        if ($entry -isnot [string] -or
            [string]::IsNullOrWhiteSpace([string]$entry)) {
            return $false
        }
    }
    return $true
}

function Get-ReviewIdentity {
    param([Parameter(Mandatory)]$Entry, [Parameter(Mandatory)][string]$Label)

    $identity = Get-ObjectPropertyValue -Value $Entry -Name 'ReviewIdentity' `
        -Label $Label -AllowMissing
    if ($null -eq $identity) {
        $review = Get-ObjectPropertyValue -Value $Entry -Name 'Review' `
            -Label $Label -AllowMissing
        if ($null -ne $review) {
            $identity = Get-ObjectPropertyValue -Value $review -Name 'identity' `
                -Label "$Label review" -AllowMissing
        }
    }
    return [string]$identity
}

function Get-LedgerPrefix {
    param(
        [Parameter(Mandatory)]$Ledger,
        [Parameter(Mandatory)]$CatalogContract,
        [switch]$RequireComplete
    )

    $rawEntries = Get-ObjectPropertyValue -Value $Ledger -Name 'Entries' `
        -Label 'Capability ledger'
    if ($rawEntries -isnot [Array]) {
        throw 'Capability ledger Entries must be an array.'
    }
    $entries = @($rawEntries)
    if ($entries.Count -gt $CatalogContract.Capabilities.Count) {
        throw 'Capability ledger is longer than the release catalog.'
    }
    if ($RequireComplete -and
        $entries.Count -ne $CatalogContract.Capabilities.Count) {
        throw 'Completion requires a complete terminal ledger for the target catalog.'
    }

    $validated = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $entries.Count; $index++) {
        $entry = $entries[$index]
        $capability = $CatalogContract.Capabilities[$index]
        $slug = [string](Get-ObjectPropertyValue -Value $entry -Name 'Slug' `
            -Label "Capability ledger entry $index")
        $definitionBlob = [string](Get-ObjectPropertyValue -Value $entry `
            -Name 'DefinitionBlob' -Label "Capability ledger entry $index")
        $outcome = [string](Get-ObjectPropertyValue -Value $entry `
            -Name 'Outcome' -Label "Capability ledger entry $index")
        $evidence = Get-ObjectPropertyValue -Value $entry -Name 'Evidence' `
            -Label "Capability ledger entry $index"
        $reviewIdentity = Get-ReviewIdentity -Entry $entry `
            -Label "Capability ledger entry $index"

        if ($slug -cne $capability.Slug -or
            $definitionBlob -cne $capability.DefinitionBlob) {
            throw 'Capability ledger is not the exact target-catalog prefix.'
        }
        if ($script:TerminalOutcomes -cnotcontains $outcome) {
            throw "Capability ledger entry '$slug' is not terminal."
        }
        if (-not (Test-ReviewedEvidence -Evidence $evidence) -or
            [string]::IsNullOrWhiteSpace($reviewIdentity)) {
            throw "Capability ledger entry '$slug' lacks reviewed terminal evidence."
        }
        $validated.Add([pscustomobject][ordered]@{
            Slug = $slug
            DefinitionBlob = $definitionBlob
            Outcome = $outcome
            Evidence = $evidence
            ReviewIdentity = $reviewIdentity
        })
    }
    return @($validated)
}

function Get-MeAndAICapabilityReviewMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$CatalogDigest
    )

    Assert-CanonicalRepository -Repository $Repository
    Assert-GitSha -Sha $CatalogDigest -Label 'Capability catalog digest' -Length 64
    return "<!-- meandai-capability-review:v1:${Repository}:${CatalogDigest} -->"
}

function Get-BatchIdentity {
    param([Parameter(Mandatory)][object[]]$Capabilities)

    $lines = @($Capabilities | ForEach-Object {
        "$([string]$_.Slug)@$([string]$_.DefinitionBlob)"
    })
    return Get-Sha256Text -Text ($lines -join "`n")
}

function New-ReviewOperation {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$Branch,
        [Parameter(Mandatory)][string]$CatalogDigest
    )

    return [pscustomobject][ordered]@{
        Kind = $Kind
        Marker = $Marker
        Branch = $Branch
        CatalogDigest = $CatalogDigest
    }
}

function Get-CanonicalInventoryItem {
    param(
        [object[]]$Items,
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Marker
    )

    $inventory = @($Items)
    if ($inventory.Count -gt 1) {
        throw "Canonical inventory contains a duplicate $Kind."
    }
    if ($inventory.Count -eq 0) { return $null }
    $itemMarker = [string](Get-ObjectPropertyValue -Value $inventory[0] `
        -Name 'Marker' -Label "Canonical $Kind")
    if ($itemMarker -cne $Marker) {
        throw "Canonical $Kind marker does not match repository/catalog identity."
    }
    return $inventory[0]
}

function Assert-OpenInventoryRelationships {
    param(
        $Issue,
        $BranchRecord,
        $Manifest,
        $PullRequest,
        [Parameter(Mandatory)][string]$ExpectedBranch,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$CatalogDigest,
        [Parameter(Mandatory)][string]$DefaultBranch,
        [Parameter(Mandatory)][string]$DefaultHead
    )

    if ($null -eq $BranchRecord) {
        if ($null -ne $Issue -or $null -ne $Manifest -or
            $null -ne $PullRequest) {
            throw 'Canonical review inventory is not branch-first.'
        }
        return
    }
    $branchName = [string](Get-ObjectPropertyValue -Value $BranchRecord `
        -Name 'Name' -Label 'Canonical branch')
    $branchBaseHead = [string](Get-ObjectPropertyValue -Value $BranchRecord `
        -Name 'BaseHead' -Label 'Canonical branch')
    $branchHead = [string](Get-ObjectPropertyValue -Value $BranchRecord `
        -Name 'HeadSha' -Label 'Canonical branch')
    if ($branchName -cne $ExpectedBranch -or $branchBaseHead -cne $DefaultHead) {
        throw 'Canonical branch does not match the exact review identity.'
    }
    Assert-GitSha -Sha $branchHead -Label 'Canonical branch head'

    if ($null -eq $Issue) {
        if ($null -ne $Manifest -or $null -ne $PullRequest) {
            throw 'Canonical review inventory contains work without its issue.'
        }
        return
    }
    $issueState = [string](Get-ObjectPropertyValue -Value $Issue -Name 'State' `
        -Label 'Canonical issue')
    $issueNumber = [long](Get-ObjectPropertyValue -Value $Issue -Name 'Number' `
        -Label 'Canonical issue')
    if ($issueState -cne 'Open' -or $issueNumber -le 0) {
        throw 'Canonical capability-review issue is not open and valid.'
    }

    if ($null -eq $Manifest) {
        if ($null -ne $PullRequest) {
            throw 'Canonical draft exists without its transient review manifest.'
        }
        return
    }
    foreach ($binding in @(
        @('Repository', $Repository),
        @('CatalogDigest', $CatalogDigest),
        @('BaseBranch', $DefaultBranch),
        @('BaseHead', $DefaultHead),
        @('Branch', $ExpectedBranch)
    )) {
        $actual = [string](Get-ObjectPropertyValue -Value $Manifest `
            -Name ([string]$binding[0]) -Label 'Capability review manifest')
        if ($actual -cne [string]$binding[1]) {
            throw "Capability review manifest has a mismatched $($binding[0])."
        }
    }
    $manifestIssue = [long](Get-ObjectPropertyValue -Value $Manifest `
        -Name 'IssueNumber' -Label 'Capability review manifest')
    if ($manifestIssue -ne $issueNumber) {
        throw 'Capability review manifest does not bind the canonical issue.'
    }

    if ($null -eq $PullRequest) { return }
    $pullState = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'State' -Label 'Canonical draft pull request')
    $isDraft = [bool](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'IsDraft' -Label 'Canonical draft pull request')
    $pullBranch = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'HeadBranch' -Label 'Canonical draft pull request')
    $pullBase = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'BaseBranch' -Label 'Canonical draft pull request')
    $pullBaseHead = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'BaseHead' -Label 'Canonical draft pull request')
    $pullIssue = [long](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'IssueNumber' -Label 'Canonical draft pull request')
    $pullHead = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'HeadSha' -Label 'Canonical draft pull request')
    Assert-GitSha -Sha $pullHead -Label 'Canonical draft pull-request head'
    if ($pullState -cne 'Open' -or -not $isDraft -or
        $pullBranch -cne $ExpectedBranch -or $pullBase -cne $DefaultBranch -or
        $pullBaseHead -cne $DefaultHead -or $pullIssue -ne $issueNumber -or
        $pullHead -cne $branchHead) {
        throw 'Canonical draft pull request does not match exact review identity.'
    }
}

function Resolve-MeAndAICapabilityReview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)]$Ledger,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$DefaultBranch,
        [Parameter(Mandatory)][string]$DefaultHead,
        [Parameter(Mandatory)][string]$TargetVersion,
        [Parameter(Mandatory)]
        [ValidateSet('PostFreshAdoption', 'AlreadyCurrent', 'PostProtocolUpdate')]
        [string]$DiscoveryContext,
        [string]$SourceVersion = '',
        [bool]$FrameworkInstalled = $true,
        [object[]]$Assessments = @(),
        [object[]]$ExistingIssues = @(),
        [object[]]$ExistingBranches = @(),
        [object[]]$ExistingPullRequests = @(),
        [object[]]$ExistingManifests = @()
    )

    Assert-CanonicalRepository -Repository $Repository
    Assert-CanonicalBranch -Branch $DefaultBranch -Label 'Default branch'
    Assert-GitSha -Sha $DefaultHead -Label 'Default-branch head'
    Assert-CanonicalVersion -Version $TargetVersion -Label 'Target version'
    Assert-CanonicalVersion -Version $SourceVersion -Label 'Source version' `
        -AllowEmpty
    $contract = Get-CatalogContract -Catalog $Catalog
    $marker = Get-MeAndAICapabilityReviewMarker -Repository $Repository `
        -CatalogDigest $contract.CatalogDigest
    $branchName = 'automation/meandai-capability-review-' + `
        $contract.CatalogDigest.Substring(0, 16)

    if (-not $FrameworkInstalled) {
        if ($DiscoveryContext -cne 'PostProtocolUpdate') {
            throw 'Only ordinary protocol-update discovery may report a missing framework.'
        }
        return [pscustomobject][ordered]@{
            State = 'ProtocolUpdateRequired'
            DiscoveryContext = $DiscoveryContext
            Repository = $Repository
            CatalogDigest = $contract.CatalogDigest
            Marker = $marker
            Branch = $branchName
            AssessmentTarget = $TargetVersion
            SourceVersionSwitch = $false
            InitialAdoptionEnvelopeUnchanged = $true
            AutomationWritePaths = @()
            SemanticWritePaths = @()
            Operations = @(
                [pscustomobject][ordered]@{
                    Kind = 'RunOrdinaryProtocolUpdate'
                    TargetVersion = $TargetVersion
                    SourceVersionSwitch = $false
                }
            )
        }
    }

    $ledgerEntries = @(Get-LedgerPrefix -Ledger $Ledger `
        -CatalogContract $contract)
    if ($ledgerEntries.Count -eq $contract.Capabilities.Count) {
        if (@($ExistingIssues).Count + @($ExistingBranches).Count +
            @($ExistingPullRequests).Count + @($ExistingManifests).Count -gt 0) {
            throw 'Terminal ledger has review inventory; use verified finalization.'
        }
        return [pscustomobject][ordered]@{
            State = 'Current'
            DiscoveryContext = $DiscoveryContext
            Repository = $Repository
            CatalogDigest = $contract.CatalogDigest
            Marker = $marker
            Branch = $branchName
            AssessmentTarget = $TargetVersion
            SourceVersionSwitch = $false
            InitialAdoptionEnvelopeUnchanged = $true
            AutomationWritePaths = @()
            SemanticWritePaths = @()
            Operations = @()
        }
    }

    $assessmentBySlug = [System.Collections.Generic.Dictionary[string,object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($assessment in @($Assessments)) {
        $slug = [string](Get-ObjectPropertyValue -Value $assessment `
            -Name 'Slug' -Label 'Capability assessment')
        if ($assessmentBySlug.ContainsKey($slug)) {
            throw "Capability assessment '$slug' is duplicated."
        }
        $assessmentBySlug.Add($slug, $assessment)
    }

    $pending = @($contract.Capabilities | Select-Object `
        -Skip $ledgerEntries.Count)
    $terminalAppend = [System.Collections.Generic.List[object]]::new()
    $openStarted = $false
    $openAssessments = [System.Collections.Generic.List[object]]::new()
    foreach ($capability in $pending) {
        $assessment = $null
        if (-not $assessmentBySlug.TryGetValue($capability.Slug, [ref]$assessment)) {
            $assessment = [pscustomobject][ordered]@{
                Slug = $capability.Slug
                DefinitionBlob = $capability.DefinitionBlob
                Outcome = 'ReviewRequired'
                Evidence = @()
                ReviewIdentity = ''
            }
        }
        $definitionBlob = [string](Get-ObjectPropertyValue -Value $assessment `
            -Name 'DefinitionBlob' -Label "Assessment '$($capability.Slug)'")
        $outcome = [string](Get-ObjectPropertyValue -Value $assessment `
            -Name 'Outcome' -Label "Assessment '$($capability.Slug)'")
        if ($definitionBlob -cne $capability.DefinitionBlob) {
            throw "Assessment '$($capability.Slug)' has a stale definition blob."
        }
        if ($script:TerminalOutcomes -ccontains $outcome) {
            if ($openStarted) {
                throw 'Terminal capability evidence cannot skip an earlier open assessment.'
            }
            $evidence = Get-ObjectPropertyValue -Value $assessment `
                -Name 'Evidence' -Label "Assessment '$($capability.Slug)'"
            $reviewIdentity = Get-ReviewIdentity -Entry $assessment `
                -Label "Assessment '$($capability.Slug)'"
            if (-not (Test-ReviewedEvidence -Evidence $evidence) -or
                [string]::IsNullOrWhiteSpace($reviewIdentity)) {
                throw "Terminal assessment '$($capability.Slug)' lacks reviewed evidence."
            }
            $terminalAppend.Add([pscustomobject][ordered]@{
                Slug = $capability.Slug
                DefinitionBlob = $capability.DefinitionBlob
                Outcome = $outcome
                Evidence = $evidence
                ReviewIdentity = $reviewIdentity
            })
        }
        elseif ($script:OpenOutcomes -ccontains $outcome) {
            $openStarted = $true
            $openAssessments.Add([pscustomobject][ordered]@{
                Slug = $capability.Slug
                DefinitionBlob = $capability.DefinitionBlob
                Type = $capability.Type
                Outcome = $outcome
            })
        }
        else {
            throw "Assessment '$($capability.Slug)' has unsupported outcome '$outcome'."
        }
        [void]$assessmentBySlug.Remove($capability.Slug)
    }
    if ($assessmentBySlug.Count -gt 0) {
        throw 'Capability assessments contain an entry outside the pending catalog suffix.'
    }

    if ($terminalAppend.Count -gt 0) {
        if (@($ExistingIssues).Count + @($ExistingBranches).Count +
            @($ExistingPullRequests).Count + @($ExistingManifests).Count -gt 0) {
            throw 'Terminal assessment cannot append while canonical review inventory exists.'
        }
        return [pscustomobject][ordered]@{
            State = 'TerminalEvidenceReady'
            DiscoveryContext = $DiscoveryContext
            Repository = $Repository
            CatalogDigest = $contract.CatalogDigest
            Marker = $marker
            Branch = $branchName
            AssessmentTarget = $TargetVersion
            SourceVersionSwitch = $false
            InitialAdoptionEnvelopeUnchanged = $true
            LedgerAppendEntries = @($terminalAppend)
            AutomationWritePaths = @($script:CapabilityLedgerPath)
            SemanticWritePaths = @()
            Operations = @(
                [pscustomobject][ordered]@{
                    Kind = 'AppendTerminalLedger'
                    Path = $script:CapabilityLedgerPath
                    Entries = @($terminalAppend)
                    CatalogDigest = $contract.CatalogDigest
                }
            )
        }
    }

    $batch = @($openAssessments)
    $batchDigest = Get-BatchIdentity -Capabilities $batch
    $issue = Get-CanonicalInventoryItem -Items $ExistingIssues `
        -Kind 'issue' -Marker $marker
    $branchRecord = Get-CanonicalInventoryItem -Items $ExistingBranches `
        -Kind 'branch' -Marker $marker
    $pullRequest = Get-CanonicalInventoryItem -Items $ExistingPullRequests `
        -Kind 'pull request' -Marker $marker
    $manifest = Get-CanonicalInventoryItem -Items $ExistingManifests `
        -Kind 'manifest' -Marker $marker
    Assert-OpenInventoryRelationships -Issue $issue `
        -BranchRecord $branchRecord -Manifest $manifest `
        -PullRequest $pullRequest -ExpectedBranch $branchName `
        -Repository $Repository -CatalogDigest $contract.CatalogDigest `
        -DefaultBranch $DefaultBranch -DefaultHead $DefaultHead

    $operations = [System.Collections.Generic.List[object]]::new()
    if ($null -eq $branchRecord) {
        $operations.Add((New-ReviewOperation -Kind 'CreateBranch' `
            -Marker $marker -Branch $branchName `
            -CatalogDigest $contract.CatalogDigest))
    }
    if ($null -eq $issue) {
        $operations.Add((New-ReviewOperation -Kind 'OpenIssue' `
            -Marker $marker -Branch $branchName `
            -CatalogDigest $contract.CatalogDigest))
    }
    if ($null -eq $manifest) {
        $manifestOperation = New-ReviewOperation -Kind 'WriteReviewManifest' `
            -Marker $marker -Branch $branchName `
            -CatalogDigest $contract.CatalogDigest
        $manifestOperation | Add-Member -NotePropertyName Path `
            -NotePropertyValue $script:CapabilityReviewManifestPath
        $manifestOperation | Add-Member -NotePropertyName BatchDigest `
            -NotePropertyValue $batchDigest
        $operations.Add($manifestOperation)
    }
    if ($null -eq $pullRequest) {
        $operations.Add((New-ReviewOperation -Kind 'OpenDraftPullRequest' `
            -Marker $marker -Branch $branchName `
            -CatalogDigest $contract.CatalogDigest))
    }

    return [pscustomobject][ordered]@{
        State = if ($operations.Count -eq 0) { 'ReviewPending' } `
            else { 'CreateReviewHandoff' }
        DiscoveryContext = $DiscoveryContext
        Repository = $Repository
        CatalogDigest = $contract.CatalogDigest
        Marker = $marker
        Branch = $branchName
        BaseBranch = $DefaultBranch
        BaseHead = $DefaultHead
        BatchDigest = $batchDigest
        CapabilityBatch = $batch
        AssessmentTarget = $TargetVersion
        SourceVersionSwitch = $false
        InitialAdoptionEnvelopeUnchanged = $true
        AutomationWritePaths = @($script:CapabilityReviewManifestPath)
        SemanticWritePaths = @()
        Operations = @($operations)
    }
}

function Resolve-MeAndAICapabilityReviewFinalization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Catalog,
        [Parameter(Mandatory)]$Ledger,
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string]$DefaultBranch,
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$ExpectedBranch,
        [Parameter(Mandatory)][string]$ExpectedBaseHead,
        [Parameter(Mandatory)][string]$ExpectedReviewHead,
        [Parameter(Mandatory)]$Issue,
        $Branch,
        [Parameter(Mandatory)]$PullRequest,
        [Parameter(Mandatory)][bool]$DefaultContainsMerge,
        [Parameter(Mandatory)][bool]$ManifestPresentOnDefault
    )

    Assert-CanonicalRepository -Repository $Repository
    Assert-CanonicalBranch -Branch $DefaultBranch -Label 'Default branch'
    Assert-CanonicalBranch -Branch $ExpectedBranch -Label 'Expected review branch'
    Assert-GitSha -Sha $ExpectedBaseHead -Label 'Expected default-base head'
    Assert-GitSha -Sha $ExpectedReviewHead -Label 'Expected review head'
    $contract = Get-CatalogContract -Catalog $Catalog
    $expectedMarker = Get-MeAndAICapabilityReviewMarker `
        -Repository $Repository -CatalogDigest $contract.CatalogDigest
    if ($Marker -cne $expectedMarker) {
        throw 'Finalization marker does not match repository/catalog identity.'
    }
    [void](Get-LedgerPrefix -Ledger $Ledger -CatalogContract $contract `
        -RequireComplete)
    if (-not $DefaultContainsMerge) {
        throw 'Default branch does not contain the reviewed merge.'
    }
    if ($ManifestPresentOnDefault) {
        throw 'Default branch still contains the transient capability-review manifest.'
    }

    $issueMarker = [string](Get-ObjectPropertyValue -Value $Issue -Name 'Marker' `
        -Label 'Finalization issue')
    $issueNumber = [long](Get-ObjectPropertyValue -Value $Issue -Name 'Number' `
        -Label 'Finalization issue')
    $issueState = [string](Get-ObjectPropertyValue -Value $Issue -Name 'State' `
        -Label 'Finalization issue')
    if ($issueMarker -cne $Marker -or $issueNumber -le 0 -or
        $issueState -cnotin @('Open', 'Closed')) {
        throw 'Finalization issue does not match canonical review identity.'
    }

    $pullMarker = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'Marker' -Label 'Finalization pull request')
    $pullNumber = [long](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'Number' -Label 'Finalization pull request')
    $pullState = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'State' -Label 'Finalization pull request')
    $pullDraft = [bool](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'IsDraft' -Label 'Finalization pull request')
    $pullBranch = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'HeadBranch' -Label 'Finalization pull request')
    $pullHead = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'HeadSha' -Label 'Finalization pull request')
    $pullBase = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'BaseBranch' -Label 'Finalization pull request')
    $pullBaseHead = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'BaseHead' -Label 'Finalization pull request')
    $pullIssue = [long](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'IssueNumber' -Label 'Finalization pull request')
    $mergeCommit = [string](Get-ObjectPropertyValue -Value $PullRequest `
        -Name 'MergeCommit' -Label 'Finalization pull request')
    Assert-GitSha -Sha $pullHead -Label 'Merged review head'
    Assert-GitSha -Sha $mergeCommit -Label 'Capability review merge commit'
    if ($pullMarker -cne $Marker -or $pullNumber -le 0 -or
        $pullState -cne 'Merged' -or $pullDraft -or
        $pullBranch -cne $ExpectedBranch -or
        $pullHead -cne $ExpectedReviewHead -or
        $pullBase -cne $DefaultBranch -or
        $pullBaseHead -cne $ExpectedBaseHead -or
        $pullIssue -ne $issueNumber) {
        throw 'Finalization pull request is not the exact reviewed merge.'
    }

    $closureMarker = `
        "<!-- meandai-capability-review-closed:v1:${Repository}:$($contract.CatalogDigest):pr-${pullNumber}:merge-${mergeCommit} -->"
    if ($issueState -ceq 'Closed') {
        if ($null -ne $Branch) {
            throw 'Capability-review issue was closed before branch deletion.'
        }
        $actualClosure = [string](Get-ObjectPropertyValue -Value $Issue `
            -Name 'ClosureMarker' -Label 'Closed capability-review issue')
        if ($actualClosure -cne $closureMarker) {
            throw 'Closed capability-review issue lacks exact completion evidence.'
        }
        return [pscustomobject][ordered]@{
            State = 'Completed'
            Marker = $Marker
            ClosureMarker = $closureMarker
            SemanticWritePaths = @()
            Operations = @()
        }
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    if ($null -ne $Branch) {
        $branchMarker = [string](Get-ObjectPropertyValue -Value $Branch `
            -Name 'Marker' -Label 'Finalization branch')
        $branchName = [string](Get-ObjectPropertyValue -Value $Branch `
            -Name 'Name' -Label 'Finalization branch')
        $branchHead = [string](Get-ObjectPropertyValue -Value $Branch `
            -Name 'HeadSha' -Label 'Finalization branch')
        $branchBaseHead = [string](Get-ObjectPropertyValue -Value $Branch `
            -Name 'BaseHead' -Label 'Finalization branch')
        if ($branchMarker -cne $Marker -or
            $branchName -cne $ExpectedBranch -or
            $branchBaseHead -cne $ExpectedBaseHead -or
            $branchHead -cne $ExpectedReviewHead) {
            throw 'Finalization branch does not satisfy the exact-head lease.'
        }
        $operations.Add([pscustomobject][ordered]@{
            Kind = 'DeleteBranch'
            Branch = $ExpectedBranch
            ExpectedHead = $ExpectedReviewHead
            Marker = $Marker
        })
    }
    $operations.Add([pscustomobject][ordered]@{
        Kind = 'CloseIssue'
        IssueNumber = $issueNumber
        ClosureMarker = $closureMarker
        Marker = $Marker
    })

    return [pscustomobject][ordered]@{
        State = 'Finalize'
        Marker = $Marker
        ClosureMarker = $closureMarker
        SemanticWritePaths = @()
        Operations = @($operations)
    }
}

function Invoke-MeAndAICapabilityReviewPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Plan,
        [System.Collections.IDictionary]$Handlers = @{},
        [switch]$DryRun
    )

    $operationsProperty = $Plan.PSObject.Properties['Operations']
    if ($null -eq $operationsProperty -or
        $operationsProperty.Value -isnot [Array]) {
        throw 'Capability review plan does not expose an operation array.'
    }
    $operations = @($operationsProperty.Value)
    $supported = @(
        'RunOrdinaryProtocolUpdate',
        'AppendTerminalLedger',
        'CreateBranch',
        'OpenIssue',
        'WriteReviewManifest',
        'OpenDraftPullRequest',
        'DeleteBranch',
        'CloseIssue'
    )
    foreach ($operation in $operations) {
        $kind = [string](Get-ObjectPropertyValue -Value $operation `
            -Name 'Kind' -Label 'Capability review operation')
        if ($supported -cnotcontains $kind) {
            throw "Capability review operation '$kind' is unsupported."
        }
        if (-not $DryRun -and -not $Handlers.Contains($kind)) {
            throw "Capability review handler '$kind' is missing."
        }
    }

    $executed = [System.Collections.Generic.List[string]]::new()
    if (-not $DryRun) {
        foreach ($operation in $operations) {
            $kind = [string]$operation.Kind
            $handler = [scriptblock]$Handlers[$kind]
            [void](& $handler $operation $Plan)
            $executed.Add($kind)
        }
    }
    return [pscustomobject][ordered]@{
        DryRun = [bool]$DryRun
        Planned = @($operations | ForEach-Object { [string]$_.Kind })
        Executed = @($executed)
    }
}

Export-ModuleMember -Function @(
    'Get-MeAndAICapabilityReviewMarker',
    'Resolve-MeAndAICapabilityReview',
    'Resolve-MeAndAICapabilityReviewFinalization',
    'Invoke-MeAndAICapabilityReviewPlan'
)
