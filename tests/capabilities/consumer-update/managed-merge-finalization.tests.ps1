[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$adapterPath = Join-Path $root 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
$workflowPath = Join-Path $root 'templates/project/.github/workflows/meandai-protocol-update.yml'
$scenarioAuthorityPath = Join-Path $root 'tests/scenario-ownership.psd1'
Import-Module (Join-Path $root 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1') -Force
Import-Module (Join-Path $root 'scripts/MeAndAI.ConsumerMigrations.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()
$outerSummaryPath = Join-Path ([IO.Path]::GetTempPath()) `
    "meandai-finalization-outer-$([guid]::NewGuid().ToString('N')).md"
$outerSummarySentinel = 'outer-summary-sentinel'
$previousStepSummary = $env:GITHUB_STEP_SUMMARY

$testManagedAssets = @(
    [pscustomobject]@{
        ConsumerPath = '.github/workflows/meandai-protocol-update.yml'
        TemplatePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'
        TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    }
)
$testMigrationCatalog = Import-MeAndAIConsumerMigrationCatalog `
    -IndexPath (Join-Path $root 'migrations/index.json')

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function ConvertTo-TestBase64Json {
    param($InputObject)
    $json = $InputObject | ConvertTo-Json -Depth 10 -Compress
    [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
}

function Add-FinalizationEvent {
    param([string]$Event)
    $global:MeAndAIFinalizationScenario.Events.Add($Event)
}

function Get-TestPathSetSha256 {
    param([string[]]$Paths)

    $ordered = [string[]]@($Paths)
    [Array]::Sort($ordered, [StringComparer]::Ordinal)
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes(
        (($ordered -join "`n") + "`n")
    )
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace(
            '-', ''
        ).ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-TestSha1 {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $algorithm = [Security.Cryptography.SHA1]::Create()
    try {
        return -join @($algorithm.ComputeHash($Bytes) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-TestGitBlobSha {
    param([Parameter(Mandatory)][byte[]]$Bytes)

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    return Get-TestSha1 -Bytes $payload
}

function Get-TestSha1Text {
    param([Parameter(Mandatory)][string]$Text)

    return Get-TestSha1 -Bytes ([Text.UTF8Encoding]::new($false).GetBytes($Text))
}

function New-TestGitGraph {
    [pscustomobject]@{
        Commits = @{}
        Trees = @{}
        Blobs = @{}
    }
}

function Add-TestGitCommit {
    param(
        [Parameter(Mandatory)]$Graph,
        [Parameter(Mandatory)][string]$Commit,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Entries
    )

    $files = [System.Collections.Generic.List[object]]::new()
    $directories = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    [void]$directories.Add('')
    foreach ($entry in @($Entries)) {
        $path = [string]$entry.Path
        if ([string]::IsNullOrWhiteSpace($path) -or $path.Contains('\') -or
            $path.StartsWith('/') -or $path.EndsWith('/')) {
            throw "Test Git entry path '$path' is not canonical."
        }
        $slash = $path.LastIndexOf('/')
        $directory = if ($slash -ge 0) { $path.Substring(0, $slash) } else { '' }
        $name = if ($slash -ge 0) { $path.Substring($slash + 1) } else { $path }
        $cursor = $directory
        while ($cursor) {
            [void]$directories.Add($cursor)
            $parentSlash = $cursor.LastIndexOf('/')
            $cursor = if ($parentSlash -ge 0) {
                $cursor.Substring(0, $parentSlash)
            }
            else { '' }
        }

        if ([string]$entry.Mode -ceq '160000') {
            $sha = [string]$entry.Sha
            if ($sha -cnotmatch '^[0-9a-f]{40}$') {
                throw "Test gitlink '$path' has an invalid commit identity."
            }
            $files.Add([pscustomobject]@{
                Directory = $directory; Name = $name; Path = $path
                Mode = '160000'; Type = 'commit'; Sha = $sha
            })
            continue
        }

        $bytes = [byte[]]$entry.Bytes
        $sha = Get-TestGitBlobSha -Bytes $bytes
        if ($Graph.Blobs.ContainsKey($sha)) {
            $existing = [byte[]]$Graph.Blobs[$sha]
            if ($existing.Length -ne $bytes.Length) {
                throw "Test blob collision at '$path'."
            }
        }
        else {
            $Graph.Blobs[$sha] = $bytes
        }
        $files.Add([pscustomobject]@{
            Directory = $directory; Name = $name; Path = $path
            Mode = '100644'; Type = 'blob'; Sha = $sha
        })
    }

    $treeByDirectory = @{}
    $orderedDirectories = @($directories) | Sort-Object {
        if ($_ -eq '') { 0 } else { @($_.Split('/')).Count }
    } -Descending
    foreach ($directory in $orderedDirectories) {
        $treeEntries = [System.Collections.Generic.List[object]]::new()
        foreach ($file in @($files | Where-Object {
            [string]$_.Directory -ceq [string]$directory
        })) {
            $treeEntries.Add([ordered]@{
                path = [string]$file.Name
                mode = [string]$file.Mode
                type = [string]$file.Type
                sha = [string]$file.Sha
            })
        }
        foreach ($child in @($directories | Where-Object {
            if ($_ -eq '') { return $false }
            $lastSlash = $_.LastIndexOf('/')
            $parent = if ($lastSlash -ge 0) { $_.Substring(0, $lastSlash) } else { '' }
            $parent -ceq $directory
        })) {
            $childSlash = $child.LastIndexOf('/')
            $childName = if ($childSlash -ge 0) {
                $child.Substring($childSlash + 1)
            }
            else { $child }
            $treeEntries.Add([ordered]@{
                path = $childName; mode = '040000'; type = 'tree'
                sha = [string]$treeByDirectory[$child]
            })
        }
        $orderedEntries = @($treeEntries | Sort-Object { [string]$_.path })
        $identity = ($orderedEntries | ForEach-Object {
            "$($_.mode)|$($_.type)|$($_.sha)|$($_.path)"
        }) -join "`n"
        $treeSha = Get-TestSha1Text -Text (
            "test-tree|$Commit|$directory`n$identity`n"
        )
        $Graph.Trees[$treeSha] = $orderedEntries
        $treeByDirectory[$directory] = $treeSha
    }
    $Graph.Commits[$Commit] = [string]$treeByDirectory['']
}

function New-TestBlobEntry {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][byte[]]$Bytes)

    [pscustomobject]@{ Path = $Path; Mode = '100644'; Bytes = $Bytes }
}

function New-TestGitlinkEntry {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Sha)

    [pscustomobject]@{ Path = $Path; Mode = '160000'; Sha = $Sha }
}

function New-TestMigrationFixture {
    param([Parameter(Mandatory)][bool]$LedgerExists)

    Import-Module (Join-Path $root 'scripts/MeAndAI.ConsumerMigrations.psm1') -Force
    $pathText = [System.Collections.Generic.Dictionary[string,string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($migration in @($testMigrationCatalog.Migrations)) {
        foreach ($operation in @($migration.Operations)) {
            $path = [string]$operation.Path
            $prefix = if ($pathText.ContainsKey($path)) {
                [string]$pathText[$path] + "`nfixture-boundary`n"
            }
            else { '' }
            $pathText[$path] = $prefix + [string]$operation.Before + "`n"
        }
    }
    $files = @($pathText.Keys | Sort-Object | ForEach-Object {
        [pscustomobject]@{
            Path = [string]$_
            Bytes = [Text.UTF8Encoding]::new($false).GetBytes(
                [string]$pathText[[string]$_]
            )
        }
    })
    $ledgerBytes = if ($LedgerExists) {
        [Text.UTF8Encoding]::new($false).GetBytes(
            "{`"schema`":1,`"satisfied`":[]}`n"
        )
    }
    else { $null }
    $plan = Resolve-MeAndAIConsumerMigrationPlan `
        -Catalog $testMigrationCatalog -Files $files -LedgerBytes $ledgerBytes
    [pscustomobject]@{
        Files = $files
        LedgerBytes = $ledgerBytes
        Plan = $plan
    }
}

function Get-TestTargetProtocolEntries {
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($path in @(
        'migrations/index.json',
        'scripts/MeAndAI.ConsumerMigrations.psm1'
    ) + @($testMigrationCatalog.Migrations | ForEach-Object {
        "migrations/$([string]$_.Definition)"
    }) + @($testManagedAssets | ForEach-Object { [string]$_.TemplatePath })) {
        $fullPath = Join-Path $root ($path -replace '/', [IO.Path]::DirectorySeparatorChar)
        $entries.Add((New-TestBlobEntry -Path $path -Bytes ([IO.File]::ReadAllBytes($fullPath))))
    }
    return @($entries)
}

function Get-TestTargetManagedConsumerEntries {
    $entries = [System.Collections.Generic.List[object]]::new()
    foreach ($asset in $testManagedAssets) {
        $template = Join-Path $root (
            ([string]$asset.TemplatePath) -replace '/', [IO.Path]::DirectorySeparatorChar
        )
        $entries.Add((New-TestBlobEntry -Path ([string]$asset.ConsumerPath) `
            -Bytes ([IO.File]::ReadAllBytes($template))))
    }
    return @($entries)
}

function New-FinalizationScenario {
    param(
        [ValidateSet('Adoption', 'Update', 'MigrationReconciliation', 'Normal')]
        [string]$Kind = 'Adoption',
        [ValidateSet('Canonical', 'Absent', 'Placeholder')]
        [string]$TrackingMode = 'Canonical',
        [ValidateSet(1, 2)]
        [int]$UpdateSchema = 1,
        [bool]$InvalidLegacyRelease = $false,
        [bool]$WrongLegacyAssetBlob = $false,
        [bool]$FabricatedSchema2Output = $false,
        [bool]$RecoveryBranch = $false,
        [switch]$MissingCreatedIssueUser
    )

    $head = 'a' * 40
    $protocolSha = 'b' * 40
    $base = '6' * 40
    $mergeCommit = 'd' * 40
    $defaultHead = 'e' * 40
    $target = 'v0.10.3'
    $isSchema2 = $Kind -ceq 'MigrationReconciliation' -or
        ($Kind -ceq 'Update' -and $UpdateSchema -eq 2)
    $fixture = if ($isSchema2) {
        New-TestMigrationFixture -LedgerExists ($Kind -ceq 'Update')
    }
    else { $null }
    $migrationPlanSha = if ($isSchema2) {
        [string]$fixture.Plan.PlanSha256
    }
    else { '' }

    $protocolGraph = New-TestGitGraph
    Add-TestGitCommit -Graph $protocolGraph -Commit $protocolSha `
        -Entries (Get-TestTargetProtocolEntries)

    $targetManagedEntries = @(Get-TestTargetManagedConsumerEntries)
    $baseEntries = [System.Collections.Generic.List[object]]::new()
    $headEntries = [System.Collections.Generic.List[object]]::new()
    $changedPaths = [System.Collections.Generic.List[string]]::new()
    if ($isSchema2) {
        $baseEntries.Add((New-TestGitlinkEntry -Path '.ai/protocol' `
            -Sha $(if ($Kind -ceq 'Update') { '1' * 40 } else { $protocolSha })))
        $headEntries.Add((New-TestGitlinkEntry -Path '.ai/protocol' -Sha $protocolSha))
        foreach ($entry in $targetManagedEntries) {
            $headEntries.Add($entry)
            if ($Kind -ceq 'Update') {
                $baseEntries.Add((New-TestBlobEntry -Path ([string]$entry.Path) `
                    -Bytes ([Text.UTF8Encoding]::new($false).GetBytes(
                        "pre-target:$([string]$entry.Path)`n"
                    ))))
                $changedPaths.Add([string]$entry.Path)
            }
            else {
                $baseEntries.Add($entry)
            }
        }
        if ($Kind -ceq 'Update') {
            $changedPaths.Add('.ai/protocol')
        }
        foreach ($file in @($fixture.Files)) {
            $baseEntries.Add((New-TestBlobEntry -Path ([string]$file.Path) `
                -Bytes ([byte[]]$file.Bytes)))
        }
        if ($null -ne $fixture.LedgerBytes) {
            $baseEntries.Add((New-TestBlobEntry `
                -Path '.ai/meandai-update-state.json' `
                -Bytes ([byte[]]$fixture.LedgerBytes)))
        }
        foreach ($pathResult in @($fixture.Plan.Paths)) {
            $resultBytes = [byte[]]$pathResult.ResultBytes
            if ($FabricatedSchema2Output -and
                [string]$pathResult.Path -ceq 'AGENTS.md') {
                $resultBytes = [Text.UTF8Encoding]::new($false).GetBytes(
                    "fabricated-output-with-valid-marker-and-path-set`n"
                )
            }
            $headEntries.Add((New-TestBlobEntry -Path ([string]$pathResult.Path) `
                -Bytes $resultBytes))
        }
        $headEntries.Add((New-TestBlobEntry `
            -Path ([string]$fixture.Plan.Ledger.Path) `
            -Bytes ([byte[]]$fixture.Plan.Ledger.ResultBytes)))
        foreach ($path in @($fixture.Plan.ExpectedChangedPaths)) {
            $changedPaths.Add([string]$path)
        }
    }
    elseif ($Kind -ceq 'Update') {
        $baseEntries.Add((New-TestGitlinkEntry -Path '.ai/protocol' -Sha ('1' * 40)))
        $headEntries.Add((New-TestGitlinkEntry -Path '.ai/protocol' -Sha $protocolSha))
        $adapterAsset = @($targetManagedEntries | Where-Object {
            [string]$_.Path -ceq '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
        })[0]
        $adapterBytes = if ($WrongLegacyAssetBlob) {
            [Text.UTF8Encoding]::new($false).GetBytes("wrong-legacy-adapter`n")
        }
        else { [byte[]]$adapterAsset.Bytes }
        $headEntries.Add((New-TestBlobEntry -Path ([string]$adapterAsset.Path) `
            -Bytes $adapterBytes))
        $baseEntries.Add((New-TestBlobEntry -Path ([string]$adapterAsset.Path) `
            -Bytes ([Text.UTF8Encoding]::new($false).GetBytes("old-adapter`n"))))
        $changedPaths.Add('.ai/protocol')
        $changedPaths.Add([string]$adapterAsset.Path)
    }
    elseif ($Kind -ceq 'Adoption') {
        $headEntries.Add((New-TestGitlinkEntry -Path '.ai/protocol' -Sha $protocolSha))
        $headEntries.Add((New-TestBlobEntry -Path 'AGENTS.md' `
            -Bytes ([Text.UTF8Encoding]::new($false).GetBytes("# Consumer instructions`n"))))
        $changedPaths.Add('.ai/protocol')
        $changedPaths.Add('AGENTS.md')
    }
    else {
        $headEntries.Add((New-TestBlobEntry -Path 'README.md' `
            -Bytes ([Text.UTF8Encoding]::new($false).GetBytes("# Ordinary`n"))))
        $changedPaths.Add('README.md')
    }

    $consumerGraph = New-TestGitGraph
    Add-TestGitCommit -Graph $consumerGraph -Commit $base -Entries @($baseEntries)
    Add-TestGitCommit -Graph $consumerGraph -Commit $head -Entries @($headEntries)
    Add-TestGitCommit -Graph $consumerGraph -Commit $mergeCommit -Entries @($headEntries)
    Add-TestGitCommit -Graph $consumerGraph -Commit $defaultHead -Entries @($headEntries)

    $branch = switch ($Kind) {
        'Adoption' { "automation/meandai-capabilities-$target" }
        'Update' {
            "automation/meandai-protocol-$target$(if ($RecoveryBranch) { '-recovery' } else { '' })"
        }
        'MigrationReconciliation' {
            "automation/meandai-protocol-$target-migrations"
        }
        default { 'feature/ordinary-change' }
    }
    $marker = switch ($Kind) {
        'Adoption' {
            [ordered]@{
                schema = 3; phase = 'Completed'; state = 'BootstrapReady'
                target = $target; protocolSha = $protocolSha; head = $head
                repository = 'owner/consumer'; actor = 'updater-owner'
            } | ConvertTo-Json -Compress
        }
        'Update' {
            if ($isSchema2) {
                [ordered]@{
                    schema = 2; kind = 'update'; target = $target
                    protocolSha = $protocolSha
                    migrationPlanSha = $migrationPlanSha
                    pathsSha = Get-TestPathSetSha256 -Paths @($changedPaths)
                    head = $head; repository = 'owner/consumer'
                } | ConvertTo-Json -Compress
            }
            else {
                [ordered]@{
                    schema = 1; target = $target; protocolSha = $protocolSha
                    head = $head; repository = 'owner/consumer'
                } | ConvertTo-Json -Compress
            }
        }
        'MigrationReconciliation' {
            [ordered]@{
                schema = 2; kind = 'migration-reconciliation'; target = $target
                protocolSha = $protocolSha; migrationPlanSha = $migrationPlanSha
                pathsSha = Get-TestPathSetSha256 -Paths @($changedPaths)
                head = $head; repository = 'owner/consumer'
            } | ConvertTo-Json -Compress
        }
        default { '' }
    }
    $body = switch ($Kind) {
        'Adoption' { "<!-- meandai-capabilities-adoption:$marker -->`n## Adoption`n`nTracking issue: #9" }
        'Update' {
            $tracking = switch ($TrackingMode) {
                'Canonical' { "`n`nTracking issue: #9" }
                'Placeholder' { "`n`nTracking issue: #REQUIRED" }
                default { '' }
            }
            "<!-- meandai-protocol-update:$marker -->`n## Update$tracking"
        }
        'MigrationReconciliation' {
            "<!-- meandai-protocol-update:$marker -->`n## Reconciliation`n`nTracking issue: #9"
        }
        default { '## Ordinary pull request' }
    }
    $changedFiles = @($changedPaths | ForEach-Object {
        [pscustomobject]@{
            filename = [string]$_
            status = if ($_ -ceq '.ai/meandai-update-state.json' -and
                ($Kind -ceq 'MigrationReconciliation')) { 'added' } else { 'modified' }
        }
    })
    $issueBody = if ($Kind -ceq 'Adoption') {
        "<!-- meandai-local-adoption:$target`:pr-42 -->`n## AI capabilities adoption tracking"
    }
    else {
        $isMigration = $Kind -ceq 'MigrationReconciliation'
        $issueMarker = if ($isSchema2) {
            [ordered]@{
                schema = 2
                kind = if ($isMigration) { 'migration-reconciliation' } else { 'update' }
                target = $target
                protocolSha = $protocolSha; migrationPlanSha = $migrationPlanSha
                repository = 'owner/consumer'
            } | ConvertTo-Json -Compress
        }
        else {
            [ordered]@{
                schema = 1; target = $target; protocolSha = $protocolSha
                repository = 'owner/consumer'
            } | ConvertTo-Json -Compress
        }
        $issueLines = [System.Collections.Generic.List[string]]::new()
        foreach ($line in @(
            "<!-- meandai-protocol-update-issue:$issueMarker -->",
            $(if ($isMigration) {
                '## Managed consumer reconciliation tracking'
            } else { '## Managed protocol update tracking' }), '',
            "- Target release: ``$target``",
            "- Protocol commit: ``$protocolSha``"
        )) {
            $issueLines.Add([string]$line)
        }
        if ($isSchema2) {
            $issueLines.Add("- Migration plan: ``$migrationPlanSha``")
        }
        foreach ($line in @(
            "- Deterministic branch: ``$branch``", '',
            'This issue is the canonical same-repository work record for the managed protocol proposal.',
            'The workflow creates or reuses it, the maintainer reviews and merges the draft, and post-merge finalization closes it only after exact branch convergence.'
        )) {
            $issueLines.Add([string]$line)
        }
        $issueLines -join [Environment]::NewLine
    }
    [pscustomobject]@{
        Kind = $Kind
        Repository = 'owner/consumer'
        DefaultBranch = 'main'
        PullRequestNumber = 42
        PullRequestState = 'closed'
        Merged = $true
        BaseBranch = 'main'
        BaseHead = $base
        HeadRepository = 'owner/consumer'
        HeadAuthor = 'updater-owner'
        Branch = $branch
        ExpectedHead = $head
        MergeCommitSha = $mergeCommit
        DefaultHead = $defaultHead
        CompareStatus = 'ahead'
        LiveHead = $head
        BranchExists = $Kind -cne 'Normal'
        MoveBeforeDelete = $false
        ProbeCalls = 0
        Body = $body
        ChangedFiles = @($changedFiles)
        IssueNumber = 9
        IssueTitle = if ($Kind -ceq 'Adoption') {
            "Track meAndAI AI capabilities adoption from $target"
        }
        elseif ($Kind -ceq 'MigrationReconciliation') {
            "Track meAndAI consumer reconciliation for $target"
        }
        else { "Track meAndAI protocol update to $target" }
        IssueBody = $issueBody
        IssueState = 'open'
        HistoricalOwnerLogin = 'updater-owner'
        AuthenticatedActorLogin = 'active-updater-owner'
        IssueAuthorLogin = 'updater-owner'
        IssueTokenActorLogin = 'github-actions[bot]'
        IssueUserPresent = $true
        MissingCreatedIssueUser = [bool]$MissingCreatedIssueUser
        CreatedIssueThisRun = $false
        CreatedIssueIdentityReads = 0
        CreateIssueObservedToken = ''
        IssueIsPullRequest = $false
        IssueLabels = [System.Collections.Generic.List[string]]::new(
            [string[]]@($(if ($Kind -ceq 'Adoption') { 'type:feature' } else { 'type:task' }), 'priority:p1', 'status:needs-review')
        )
        AdoptionIssueCount = if ($Kind -ceq 'Adoption') { 1 } else { 0 }
        IssueExists = $Kind -cne 'Update' -or $TrackingMode -ceq 'Canonical'
        OpenBranchReuseCount = 0
        ExistingEvidenceComments = 0
        ProposalEvidenceComments = if ($Kind -cin @(
            'Update', 'MigrationReconciliation'
        ) -and $TrackingMode -ceq 'Canonical') { 1 } else { 0 }
        InvalidLegacyRelease = $InvalidLegacyRelease
        WrongLegacyAssetBlob = $WrongLegacyAssetBlob
        IsSchema2 = $isSchema2
        MigrationPlan = if ($isSchema2) { $fixture.Plan } else { $null }
        ProtocolGraph = $protocolGraph
        ConsumerGraph = $consumerGraph
        Events = [System.Collections.Generic.List[string]]::new()
    }
}

function global:git {
    $scenario = $global:MeAndAIFinalizationScenario
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0

    if ($arguments[0] -ceq 'ls-remote') {
        $scenario.ProbeCalls++
        Add-FinalizationEvent "probe-branch-$($scenario.ProbeCalls)"
        if ($scenario.MoveBeforeDelete -and $scenario.ProbeCalls -ge 2) {
            $scenario.LiveHead = 'c' * 40
        }
        if ($scenario.BranchExists) {
            "$($scenario.LiveHead)`trefs/heads/$($scenario.Branch)"
        }
        else {
            $global:LASTEXITCODE = 2
        }
        return
    }
    if ($arguments[0] -ceq 'push') {
        $ref = "refs/heads/$($scenario.Branch)"
        $lease = "--force-with-lease=${ref}:$($scenario.ExpectedHead)"
        if ($arguments -cnotcontains $lease -or
            [string]$arguments[-1] -cne ":$ref") {
            throw "Branch deletion omitted its exact expected-head lease: $($arguments -join ' ')"
        }
        if ($scenario.LiveHead -cne $scenario.ExpectedHead) {
            $global:LASTEXITCODE = 1
            'stale info: remote ref changed'
            return
        }
        $scenario.BranchExists = $false
        Add-FinalizationEvent 'delete-branch'
        return
    }
    throw "Unexpected fake git command: $($arguments -join ' ')"
}

function Get-TestGhBody {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $bodyArguments = @($Arguments | Where-Object {
        ([string]$_).StartsWith('body=', [StringComparison]::Ordinal)
    })
    if ($bodyArguments.Count -ne 1) {
        throw "Expected exactly one fake gh body field: $($Arguments -join ' ')"
    }
    $body = ([string]$bodyArguments[0]).Substring('body='.Length)
    if (-not $body.StartsWith('@', [StringComparison]::Ordinal)) {
        return $body
    }

    $bodyPath = $body.Substring(1)
    if (-not [IO.File]::Exists($bodyPath)) {
        throw "Fake gh body file does not exist: $bodyPath"
    }
    return [IO.File]::ReadAllText($bodyPath, [Text.UTF8Encoding]::new($false))
}

function global:gh {
    $scenario = $global:MeAndAIFinalizationScenario
    $arguments = @($args | ForEach-Object { [string]$_ })
    $global:LASTEXITCODE = 0

    if ($arguments[0] -cne 'api') {
        throw "Unexpected fake gh command: $($arguments -join ' ')"
    }

    $endpoints = @($arguments | Where-Object {
        [string]$_ -ceq 'user' -or [string]$_ -like 'repos/*'
    })
    if ($endpoints.Count -ne 1) {
        throw "Expected exactly one fake gh API endpoint: $($arguments -join ' ')"
    }
    $endpoint = [string]$endpoints[0]
    $method = 'GET'
    $methodIndex = [array]::IndexOf($arguments, '--method')
    if ($methodIndex -ge 0) {
        $method = [string]$arguments[$methodIndex + 1]
    }
    if ($endpoint -ceq 'user') {
        if ($env:GH_TOKEN -cne 'test-updater-token') {
            throw 'Authenticated actor lookup crossed the updater credential boundary.'
        }
        [ordered]@{ login = $scenario.AuthenticatedActorLogin } |
            ConvertTo-Json -Compress
        return
    }
    if ($endpoint -like 'repos/hasanmanzak/meAndAI/*') {
        if ($env:GH_TOKEN -cne 'test-protocol-token') {
            throw 'Legacy release evidence crossed the protocol credential boundary.'
        }
        if ($endpoint -ceq 'repos/hasanmanzak/meAndAI/releases/tags/v0.10.3') {
            [ordered]@{
                tag_name = 'v0.10.3'; draft = $false; prerelease = $false
                immutable = $true; published_at = '2026-07-17T00:00:00Z'
            } | ConvertTo-Json -Compress
            return
        }
        if ($endpoint -ceq 'repos/hasanmanzak/meAndAI/git/ref/tags/v0.10.3') {
            [ordered]@{
                object = [ordered]@{
                    type = 'commit'
                    sha = if ($scenario.InvalidLegacyRelease) { 'c' * 40 } else { 'b' * 40 }
                }
            } | ConvertTo-Json -Depth 4 -Compress
            return
        }
        if ($endpoint -ceq "repos/hasanmanzak/meAndAI/compare/$('1' * 40)...$('b' * 40)") {
            [ordered]@{ status = 'ahead' } | ConvertTo-Json -Compress
            return
        }
        if ($endpoint -match '^repos/hasanmanzak/meAndAI/git/commits/(?<sha>[0-9a-f]{40})$' -and
            $scenario.ProtocolGraph.Commits.ContainsKey([string]$Matches.sha)) {
            [ordered]@{
                tree = [ordered]@{
                    sha = [string]$scenario.ProtocolGraph.Commits[[string]$Matches.sha]
                }
            } | ConvertTo-Json -Depth 4 -Compress
            return
        }
        if ($endpoint -match '^repos/hasanmanzak/meAndAI/git/trees/(?<sha>[0-9a-f]{40})$' -and
            $scenario.ProtocolGraph.Trees.ContainsKey([string]$Matches.sha)) {
            [ordered]@{
                tree = @($scenario.ProtocolGraph.Trees[[string]$Matches.sha])
            } | ConvertTo-Json -Depth 6 -Compress
            return
        }
        if ($endpoint -match '^repos/hasanmanzak/meAndAI/git/blobs/(?<sha>[0-9a-f]{40})$' -and
            $scenario.ProtocolGraph.Blobs.ContainsKey([string]$Matches.sha)) {
            $bytes = [byte[]]$scenario.ProtocolGraph.Blobs[[string]$Matches.sha]
            [ordered]@{
                sha = [string]$Matches.sha
                encoding = 'base64'
                size = $bytes.Length
                content = [Convert]::ToBase64String($bytes)
            } | ConvertTo-Json -Compress
            return
        }
        throw "Unexpected fake protocol API command: $($arguments -join ' ')"
    }
    if ($endpoint -ceq 'repos/owner/consumer/pulls/42') {
        if ($method -ceq 'PATCH') {
            if ($env:GH_TOKEN -cne 'test-issue-token') {
                throw 'Tracking repair crossed the issue credential boundary.'
            }
            $scenario.Body = Get-TestGhBody -Arguments $arguments
            Add-FinalizationEvent 'repair-tracking-line'
        }
        Add-FinalizationEvent 'read-pull-request'
        [ordered]@{
            number = 42
            state = $scenario.PullRequestState
            merged = [bool]$scenario.Merged
            merged_at = if ($scenario.Merged) { '2026-07-17T00:00:00Z' } else { $null }
            merge_commit_sha = $scenario.MergeCommitSha
            body = $scenario.Body
            user = [ordered]@{ login = $scenario.HeadAuthor }
            head = [ordered]@{
                ref = $scenario.Branch
                sha = $scenario.ExpectedHead
                repo = [ordered]@{ full_name = $scenario.HeadRepository }
            }
            base = [ordered]@{
                ref = $scenario.BaseBranch
                sha = $scenario.BaseHead
                repo = [ordered]@{ full_name = $scenario.Repository }
            }
        } | ConvertTo-Json -Depth 8 -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer') {
        Add-FinalizationEvent 'read-repository'
        [ordered]@{
            full_name = $scenario.Repository
            default_branch = $scenario.DefaultBranch
        } | ConvertTo-Json -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/git/ref/heads/main') {
        Add-FinalizationEvent 'read-default-head'
        [ordered]@{
            ref = 'refs/heads/main'
            object = [ordered]@{ type = 'commit'; sha = $scenario.DefaultHead }
        } | ConvertTo-Json -Depth 5 -Compress
        return
    }
    if ($endpoint -match '^repos/owner/consumer/git/commits/(?<sha>[0-9a-f]{40})$' -and
        $scenario.ConsumerGraph.Commits.ContainsKey([string]$Matches.sha)) {
        [ordered]@{
            tree = [ordered]@{
                sha = [string]$scenario.ConsumerGraph.Commits[[string]$Matches.sha]
            }
        } | ConvertTo-Json -Depth 4 -Compress
        return
    }
    if ($endpoint -match '^repos/owner/consumer/git/trees/(?<sha>[0-9a-f]{40})$' -and
        $scenario.ConsumerGraph.Trees.ContainsKey([string]$Matches.sha)) {
        [ordered]@{
            tree = @($scenario.ConsumerGraph.Trees[[string]$Matches.sha])
        } | ConvertTo-Json -Depth 6 -Compress
        return
    }
    if ($endpoint -match '^repos/owner/consumer/git/blobs/(?<sha>[0-9a-f]{40})$' -and
        $scenario.ConsumerGraph.Blobs.ContainsKey([string]$Matches.sha)) {
        $bytes = [byte[]]$scenario.ConsumerGraph.Blobs[[string]$Matches.sha]
        [ordered]@{
            sha = [string]$Matches.sha
            encoding = 'base64'
            size = $bytes.Length
            content = [Convert]::ToBase64String($bytes)
        } | ConvertTo-Json -Compress
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/compare/$($scenario.MergeCommitSha)...$($scenario.DefaultHead)") {
        Add-FinalizationEvent 'verify-merge-containment'
        [ordered]@{ status = $scenario.CompareStatus } |
            ConvertTo-Json -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/pulls/42/files?per_page=100') {
        Add-FinalizationEvent 'read-pull-request-files'
        foreach ($file in @($scenario.ChangedFiles)) {
            ConvertTo-TestBase64Json $file
        }
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/labels?per_page=100') {
        if ($env:GH_TOKEN -cne 'test-issue-token') {
            throw 'Managed label inventory crossed the issue credential boundary.'
        }
        foreach ($name in @(
            'type:task', 'priority:p1', 'status:in-progress',
            'status:needs-review', 'status:blocked'
        )) {
            ConvertTo-TestBase64Json ([pscustomobject]@{ name = $name })
        }
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/issues' -and $method -ceq 'POST') {
        if ($env:GH_TOKEN -cne 'test-issue-token') {
            throw 'Managed issue creation crossed the issue credential boundary.'
        }
        $titleArgument = @($arguments | Where-Object { $_ -like 'title=*' })[0]
        $scenario.IssueTitle = $titleArgument.Substring('title='.Length)
        $scenario.IssueBody = Get-TestGhBody -Arguments $arguments
        $scenario.IssueState = 'open'
        $scenario.IssueAuthorLogin = $scenario.IssueTokenActorLogin
        $scenario.IssueUserPresent = -not $scenario.MissingCreatedIssueUser
        $scenario.CreatedIssueThisRun = $true
        $scenario.CreateIssueObservedToken = [string]$env:GH_TOKEN
        $scenario.IssueExists = $true
        $scenario.IssueLabels = [System.Collections.Generic.List[string]]::new(
            [string[]]@('type:task', 'priority:p1', 'status:needs-review')
        )
        Add-FinalizationEvent 'create-update-issue'
        [ordered]@{ number = $scenario.IssueNumber } | ConvertTo-Json -Compress
        return
    }
    if ($endpoint -ceq 'repos/owner/consumer/issues?state=all&per_page=100') {
        Add-FinalizationEvent 'inventory-adoption-issues'
        $count = if ($scenario.Kind -ceq 'Adoption') {
            $scenario.AdoptionIssueCount
        } elseif ($scenario.IssueExists) { 1 } else { 0 }
        for ($index = 0; $index -lt $count; $index++) {
            $issueRecord = [pscustomobject][ordered]@{
                number = $scenario.IssueNumber
                title = $scenario.IssueTitle
                body = $scenario.IssueBody
                state = $scenario.IssueState
                labels = @($scenario.IssueLabels | ForEach-Object {
                    [pscustomobject]@{ name = $_ }
                })
            }
            if ($scenario.IssueUserPresent) {
                $issueRecord | Add-Member -NotePropertyName user `
                    -NotePropertyValue ([pscustomobject]@{
                        login = $scenario.IssueAuthorLogin
                    })
            }
            if ($scenario.IssueIsPullRequest) {
                $issueRecord | Add-Member -NotePropertyName pull_request `
                    -NotePropertyValue ([pscustomobject]@{ url = 'https://api.github.com/pulls/9' })
            }
            ConvertTo-TestBase64Json $issueRecord
        }
        return
    }
    if ($endpoint -like 'repos/owner/consumer/pulls?state=open&head=owner:*&per_page=100') {
        Add-FinalizationEvent 'check-open-branch-reuse'
        for ($index = 0; $index -lt $scenario.OpenBranchReuseCount; $index++) {
            ConvertTo-TestBase64Json ([pscustomobject]@{
                number = 100 + $index
                state = 'open'
                head = [pscustomobject]@{
                    ref = $scenario.Branch
                    sha = $scenario.ExpectedHead
                }
            })
        }
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)/labels" -and
        $method -ceq 'POST') {
        foreach ($argument in @($arguments | Where-Object {
            ([string]$_).StartsWith('labels[]=', [StringComparison]::Ordinal)
        })) {
            $label = $argument.Substring('labels[]='.Length)
            if ($scenario.IssueLabels -cnotcontains $label) {
                $scenario.IssueLabels.Add($label)
            }
        }
        '{}'
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)") {
        if ($method -ceq 'PATCH') {
            $scenario.IssueState = 'closed'
            Add-FinalizationEvent 'close-issue'
            '{}'
        }
        else {
            if ($scenario.CreatedIssueThisRun -and
                $scenario.CreatedIssueIdentityReads -eq 0) {
                if ($env:GH_TOKEN -cne 'test-issue-token') {
                    throw 'Created-issue identity read crossed the issue credential boundary.'
                }
                $scenario.CreatedIssueIdentityReads++
            }
            Add-FinalizationEvent 'read-issue'
            $issueRecord = [pscustomobject][ordered]@{
                number = $scenario.IssueNumber
                title = $scenario.IssueTitle
                body = $scenario.IssueBody
                state = $scenario.IssueState
                labels = @($scenario.IssueLabels | ForEach-Object {
                    [ordered]@{ name = $_ }
                })
            }
            if ($scenario.IssueUserPresent) {
                $issueRecord | Add-Member -NotePropertyName user `
                    -NotePropertyValue ([pscustomobject]@{
                        login = $scenario.IssueAuthorLogin
                    })
            }
            if ($scenario.IssueIsPullRequest) {
                $issueRecord | Add-Member -NotePropertyName pull_request `
                    -NotePropertyValue ([pscustomobject]@{ url = 'https://api.github.com/pulls/9' })
            }
            $issueRecord | ConvertTo-Json -Depth 5 -Compress
        }
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)/comments?per_page=100") {
        Add-FinalizationEvent 'read-issue-comments'
        for ($index = 0; $index -lt $scenario.ProposalEvidenceComments; $index++) {
            ConvertTo-TestBase64Json ([pscustomobject]@{
                body = "<!-- meandai-protocol-update-proposal:pr-42:head-$($scenario.ExpectedHead) -->`nManaged protocol proposal: #42"
            })
        }
        for ($index = 0; $index -lt $scenario.ExistingEvidenceComments; $index++) {
            ConvertTo-TestBase64Json ([pscustomobject]@{
                body = "<!-- meandai-managed-merge-finalization:pr-42:head-$($scenario.ExpectedHead) -->`nExisting evidence"
            })
        }
        return
    }
    if ($endpoint -ceq "repos/owner/consumer/issues/$($scenario.IssueNumber)/comments" -and
        $method -ceq 'POST') {
        $body = Get-TestGhBody -Arguments $arguments
        if ($body.StartsWith(
            '<!-- meandai-protocol-update-proposal:', [StringComparison]::Ordinal
        )) {
            $scenario.ProposalEvidenceComments = 1
            Add-FinalizationEvent 'comment-proposal-link'
        }
        else {
            $scenario.ExistingEvidenceComments = 1
            Add-FinalizationEvent 'comment-issue'
        }
        '{}'
        return
    }
    if ($endpoint -like "repos/owner/consumer/issues/$($scenario.IssueNumber)/labels/*" -and
        $method -ceq 'DELETE') {
        $encodedLabel = $endpoint.Substring($endpoint.LastIndexOf('/') + 1)
        $label = [Uri]::UnescapeDataString($encodedLabel)
        [void]$scenario.IssueLabels.Remove($label)
        Add-FinalizationEvent "remove-label-$label"
        return
    }
    throw "Unexpected fake gh API command: $($arguments -join ' ')"
}

function Invoke-FinalizationScenario {
    param([Parameter(Mandatory)]$Scenario)

    $global:MeAndAIFinalizationScenario = $Scenario
    $previousRepository = $env:GITHUB_REPOSITORY
    $previousDefaultBranch = $env:DEFAULT_BRANCH
    $previousToken = $env:GH_TOKEN
    $previousIssueToken = $env:ISSUE_TOKEN
    $previousProtocolToken = $env:PROTOCOL_TOKEN
    $previousStepSummary = $env:GITHUB_STEP_SUMMARY
    $summaryPath = Join-Path ([IO.Path]::GetTempPath()) `
        "meandai-finalization-summary-$([guid]::NewGuid().ToString('N')).md"
    $summaryLines = @()
    $threw = $false
    $errorMessage = ''
    $exceptionMessage = ''
    try {
        $env:GITHUB_REPOSITORY = $Scenario.Repository
        $env:DEFAULT_BRANCH = $Scenario.DefaultBranch
        $env:GH_TOKEN = 'test-updater-token'
        $env:ISSUE_TOKEN = 'test-issue-token'
        $env:PROTOCOL_TOKEN = 'test-protocol-token'
        $env:GITHUB_STEP_SUMMARY = $summaryPath
        & $adapterPath -FinalizeMergedPullRequest `
            -PullRequestNumber $Scenario.PullRequestNumber
    }
    catch {
        $threw = $true
        $exceptionMessage = $_.Exception.Message
        $errorMessage = $exceptionMessage
        if (-not [string]::IsNullOrWhiteSpace([string]$_.ScriptStackTrace)) {
            $errorMessage += " [$($_.ScriptStackTrace)]"
        }
    }
    finally {
        try {
            if (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
                $summaryLines = @(Get-Content -LiteralPath $summaryPath)
            }
        }
        catch {
            $threw = $true
            if ([string]::IsNullOrWhiteSpace($errorMessage)) {
                $errorMessage = "Unable to read isolated test summary: $($_.Exception.Message)"
            }
        }
        finally {
            $env:GITHUB_REPOSITORY = $previousRepository
            $env:DEFAULT_BRANCH = $previousDefaultBranch
            $env:GH_TOKEN = $previousToken
            $env:ISSUE_TOKEN = $previousIssueToken
            $env:PROTOCOL_TOKEN = $previousProtocolToken
            $env:GITHUB_STEP_SUMMARY = $previousStepSummary
            if (Test-Path -LiteralPath $summaryPath) {
                Remove-Item -LiteralPath $summaryPath -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
    return [pscustomobject]@{
        Threw = $threw
        Error = $errorMessage
        ExceptionMessage = $exceptionMessage
        Scenario = $Scenario
        SummaryLines = [string[]]@($summaryLines)
    }
}

function Test-NoFinalizationMutation {
    param([Parameter(Mandatory)]$Result, [Parameter(Mandatory)][string]$Name)

    $mutations = @($Result.Scenario.Events | Where-Object {
        $_ -ceq 'delete-branch' -or $_ -ceq 'comment-issue' -or
        $_ -ceq 'close-issue' -or $_ -like 'remove-label-*'
    })
    if ($mutations.Count -ne 0) {
        Add-Failure "TEST-0110 $Name mutated finalization state: $($mutations -join ', ')"
    }
}

try {
    [IO.File]::WriteAllLines(
        $outerSummaryPath,
        [string[]]@($outerSummarySentinel),
        [Text.UTF8Encoding]::new($false)
    )
    $env:GITHUB_STEP_SUMMARY = $outerSummaryPath

    $adoption = Invoke-FinalizationScenario -Scenario (New-FinalizationScenario -Kind Adoption)
    if ($adoption.Threw -or $adoption.Scenario.BranchExists -or
        $adoption.Scenario.IssueState -cne 'closed' -or
        $adoption.Scenario.ExistingEvidenceComments -ne 1 -or
        $adoption.Scenario.IssueLabels -contains 'status:needs-review' -or
        @($adoption.Scenario.Events | Where-Object { $_ -ceq 'delete-branch' }).Count -ne 1) {
        Add-Failure "TEST-0108 exact adoption merge did not converge: $($adoption.Error)"
    }
    $expectedAdoptionSummary = "Managed merge #42 finalized at ``$($adoption.Scenario.ExpectedHead)``; exact branch absent and issue #9 closed."
    $adoptionSummaryProperty = $adoption.PSObject.Properties['SummaryLines']
    $adoptionSummaryLines = @(
        if ($null -ne $adoptionSummaryProperty) {
            @($adoptionSummaryProperty.Value)
        }
    )
    if ($adoptionSummaryLines.Count -ne 1 -or
        [string]$adoptionSummaryLines[0] -cne $expectedAdoptionSummary) {
        Add-Failure "TEST-0142 adoption summary was not captured exactly in its isolated invocation: $($adoptionSummaryLines -join ' | ')"
    }
    $deleteIndex = [array]::IndexOf(@($adoption.Scenario.Events), 'delete-branch')
    $commentIndex = [array]::IndexOf(@($adoption.Scenario.Events), 'comment-issue')
    $closeIndex = [array]::IndexOf(@($adoption.Scenario.Events), 'close-issue')
    if ($deleteIndex -lt 0 -or $commentIndex -le $deleteIndex -or $closeIndex -le $commentIndex) {
        Add-Failure 'TEST-0108 issue finalization did not follow verified branch deletion.'
    }

    $adoption.Scenario.Events.Clear()
    $rerun = Invoke-FinalizationScenario -Scenario $adoption.Scenario
    if ($rerun.Threw -or @($rerun.Scenario.Events | Where-Object {
        $_ -ceq 'delete-branch' -or $_ -ceq 'comment-issue' -or $_ -ceq 'close-issue'
    }).Count -ne 0) {
        Add-Failure "TEST-0108 exact recovery rerun was not idempotent: $($rerun.Error)"
    }

    $update = Invoke-FinalizationScenario -Scenario (New-FinalizationScenario -Kind Update)
    if ($update.Threw -or $update.Scenario.BranchExists -or
        $update.Scenario.ExistingEvidenceComments -ne 1 -or
        $update.Scenario.IssueLabels -contains 'status:needs-review' -or
        $update.Scenario.IssueState -cne 'closed' -or
        @($update.Scenario.Events | Where-Object { $_ -ceq 'close-issue' }).Count -ne 1) {
        Add-Failure "TEST-0109 exact update merge did not converge through its tracking issue: $($update.Error)"
    }

    $schema2Update = Invoke-FinalizationScenario -Scenario (
        New-FinalizationScenario -Kind Update -UpdateSchema 2
    )
    if ($schema2Update.Threw -or $schema2Update.Scenario.BranchExists -or
        $schema2Update.Scenario.ExistingEvidenceComments -ne 1 -or
        $schema2Update.Scenario.IssueLabels -contains 'status:needs-review' -or
        $schema2Update.Scenario.IssueState -cne 'closed' -or
        $schema2Update.Scenario.ChangedFiles.filename -cnotcontains '.ai/protocol' -or
        $schema2Update.Scenario.ChangedFiles.filename -cnotcontains
            '.ai/meandai-update-state.json' -or
        @($schema2Update.Scenario.Events | Where-Object {
            $_ -ceq 'delete-branch'
        }).Count -ne 1) {
        Add-Failure "TEST-0121 exact schema-2 update did not independently verify and finalize its immutable target plan: $($schema2Update.Error)"
    }

    $recoveryUpdate = Invoke-FinalizationScenario -Scenario (
        New-FinalizationScenario -Kind Update -UpdateSchema 2 `
            -RecoveryBranch $true
    )
    if ($recoveryUpdate.Threw -or $recoveryUpdate.Scenario.BranchExists -or
        $recoveryUpdate.Scenario.ExistingEvidenceComments -ne 1 -or
        $recoveryUpdate.Scenario.IssueState -cne 'closed' -or
        @($recoveryUpdate.Scenario.Events | Where-Object {
            $_ -ceq 'delete-branch'
        }).Count -ne 1) {
        Add-Failure "TEST-0126 merged recovery proposal did not finalize its exact suffixed branch and issue: $($recoveryUpdate.Error)"
    }

    $migration = Invoke-FinalizationScenario -Scenario (
        New-FinalizationScenario -Kind MigrationReconciliation
    )
    if ($migration.Threw -or $migration.Scenario.BranchExists -or
        $migration.Scenario.ExistingEvidenceComments -ne 1 -or
        $migration.Scenario.IssueLabels -contains 'status:needs-review' -or
        $migration.Scenario.IssueState -cne 'closed' -or
        $migration.Scenario.ChangedFiles.filename -ccontains '.ai/protocol' -or
        @($migration.Scenario.Events | Where-Object {
            $_ -ceq 'delete-branch'
        }).Count -ne 1) {
        Add-Failure "TEST-0122 exact schema-2 same-target migration merge did not finalize its suffixed branch and issue: $($migration.Error)"
    }

    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($requiredText in @(
        'pull_request:', 'types: [closed]', 'finalize_pull_request:',
        'finalize-managed-merge:', 'pull-requests: write', 'issues: write',
        'contents: write', '-FinalizeMergedPullRequest', '-PullRequestNumber',
        '-RecoverMergedPullRequests'
    )) {
        if (-not $workflow.Contains($requiredText)) {
            Add-Failure "TEST-0109 consumer workflow is missing '$requiredText'."
        }
    }
    if (-not $workflow.Contains("github.event.pull_request.merged == true") -or
        -not $workflow.Contains("inputs.finalize_pull_request == ''") -or
        -not $workflow.Contains('needs: finalize-managed-merge')) {
        Add-Failure 'TEST-0109 consumer workflow does not separate update discovery from event/recovery finalization.'
    }

    $normal = Invoke-FinalizationScenario -Scenario (New-FinalizationScenario -Kind Normal)
    if ($normal.Threw) {
        Add-Failure "TEST-0110 ordinary pull request did not remain a no-op: $($normal.Error)"
    }
    Test-NoFinalizationMutation -Result $normal -Name 'ordinary pull request'
    $normalSummaryProperty = $normal.PSObject.Properties['SummaryLines']
    if ($null -ne $normalSummaryProperty -and
        @($normalSummaryProperty.Value).Count -ne 0) {
        Add-Failure 'TEST-0142 ordinary no-op emitted finalization summary output.'
    }

    foreach ($legacyMode in @('Absent', 'Placeholder')) {
        $legacy = Invoke-FinalizationScenario -Scenario (
            New-FinalizationScenario -Kind Update -TrackingMode $legacyMode
        )
        if ($legacy.Threw -or $legacy.Scenario.BranchExists -or
            $legacy.Scenario.IssueState -cne 'closed' -or
            $legacy.Scenario.Body -cnotmatch '(?m)^Tracking issue: #9$' -or
            @($legacy.Scenario.Events | Where-Object {
                $_ -ceq 'create-update-issue'
            }).Count -ne 1 -or
            [array]::IndexOf(@($legacy.Scenario.Events), 'repair-tracking-line') -gt
                [array]::IndexOf(@($legacy.Scenario.Events), 'delete-branch')) {
            Add-Failure "TEST-0112 legacy installing-update mode '$legacyMode' did not repair and finalize exactly: $($legacy.Error)"
        }
    }
    $missingCreatedIssueAuthor = New-FinalizationScenario -Kind Update `
        -TrackingMode Absent -MissingCreatedIssueUser
    $missingAuthorResult = Invoke-FinalizationScenario `
        -Scenario $missingCreatedIssueAuthor
    $postCreationMutations = @($missingAuthorResult.Scenario.Events | Where-Object {
        $_ -ceq 'repair-tracking-line' -or $_ -ceq 'delete-branch' -or
        $_ -ceq 'comment-proposal-link' -or $_ -ceq 'comment-issue' -or
        $_ -ceq 'close-issue' -or $_ -like 'remove-label-*'
    })
    if (-not $missingAuthorResult.Threw -or
        [string]$missingAuthorResult.ExceptionMessage -cne
            'The created protocol-update issue did not converge to its exact owned record.' -or
        @($missingAuthorResult.Scenario.Events | Where-Object {
            $_ -ceq 'create-update-issue'
        }).Count -ne 1 -or
        $postCreationMutations.Count -ne 0 -or
        -not $missingAuthorResult.Scenario.BranchExists -or
        [string]$missingAuthorResult.Scenario.Body -cmatch
            '(?m)^Tracking issue: #[1-9][0-9]*$' -or
        [string]$missingAuthorResult.Scenario.CreateIssueObservedToken -cne
            'test-issue-token' -or
        $missingAuthorResult.Scenario.CreatedIssueIdentityReads -ne 1 -or
        [string]$missingAuthorResult.Scenario.AuthenticatedActorLogin -ceq
            [string]$missingAuthorResult.Scenario.HistoricalOwnerLogin -or
        [string]$missingAuthorResult.Scenario.IssueTokenActorLogin -ceq
            [string]$missingAuthorResult.Scenario.HistoricalOwnerLogin -or
        [string]$missingAuthorResult.Scenario.IssueTokenActorLogin -ceq
            [string]$missingAuthorResult.Scenario.AuthenticatedActorLogin) {
        Add-Failure "TEST-0112 missing created-issue author did not fail with a controlled convergence error before later mutation: $($missingAuthorResult.Error)"
    }
    $legacyEvidenceNegatives = @(
        [pscustomobject]@{
            Name = 'immutable release mismatch'
            Scenario = New-FinalizationScenario -Kind Update -TrackingMode Absent `
                -InvalidLegacyRelease $true
        },
        [pscustomobject]@{
            Name = 'target updater blob mismatch'
            Scenario = New-FinalizationScenario -Kind Update -TrackingMode Placeholder `
                -WrongLegacyAssetBlob $true
        }
    )
    foreach ($negative in $legacyEvidenceNegatives) {
        $result = Invoke-FinalizationScenario -Scenario $negative.Scenario
        $mutations = @($result.Scenario.Events | Where-Object {
            $_ -cin @(
                'create-update-issue', 'repair-tracking-line', 'delete-branch',
                'comment-issue', 'close-issue'
            )
        })
        if (-not $result.Threw -or $mutations.Count -ne 0) {
            Add-Failure "TEST-0112 $($negative.Name) did not fail before legacy tracking mutation."
        }
    }

    $negativeScenarios = [System.Collections.Generic.List[object]]::new()

    $unmerged = New-FinalizationScenario -Kind Adoption
    $unmerged.Merged = $false
    $negativeScenarios.Add([pscustomobject]@{ Name = 'unmerged'; Scenario = $unmerged })

    $crossRepository = New-FinalizationScenario -Kind Adoption
    $crossRepository.HeadRepository = 'attacker/fork'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'cross-repository'; Scenario = $crossRepository })

    $wrongBase = New-FinalizationScenario -Kind Adoption
    $wrongBase.BaseBranch = 'release'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'wrong base'; Scenario = $wrongBase })

    $mergeNotContained = New-FinalizationScenario -Kind Adoption
    $mergeNotContained.CompareStatus = 'diverged'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'merge not on default'; Scenario = $mergeNotContained })

    $duplicateMarker = New-FinalizationScenario -Kind Adoption
    $duplicateMarker.Body += "`n$($duplicateMarker.Body.Split("`n")[0])"
    $negativeScenarios.Add([pscustomobject]@{ Name = 'duplicate marker'; Scenario = $duplicateMarker })

    $missingAdoptionIssue = New-FinalizationScenario -Kind Adoption
    $missingAdoptionIssue.AdoptionIssueCount = 0
    $negativeScenarios.Add([pscustomobject]@{ Name = 'missing adoption issue'; Scenario = $missingAdoptionIssue })

    $multipleUpdateIssues = New-FinalizationScenario -Kind Update
    $multipleUpdateIssues.Body += "`nTracking issue: #10"
    $negativeScenarios.Add([pscustomobject]@{ Name = 'multiple update issues'; Scenario = $multipleUpdateIssues })

    $malformedTracking = New-FinalizationScenario -Kind Update
    $malformedTracking.Body = $malformedTracking.Body.Replace(
        'Tracking issue: #9', 'tracking issue: #9'
    )
    $negativeScenarios.Add([pscustomobject]@{ Name = 'noncanonical tracking line'; Scenario = $malformedTracking })

    $preclosedIssue = New-FinalizationScenario -Kind Adoption
    $preclosedIssue.IssueState = 'closed'
    $negativeScenarios.Add([pscustomobject]@{ Name = 'closed issue without evidence'; Scenario = $preclosedIssue })

    $pullRequestAsIssue = New-FinalizationScenario -Kind Update
    $pullRequestAsIssue.IssueIsPullRequest = $true
    $negativeScenarios.Add([pscustomobject]@{ Name = 'pull request as issue'; Scenario = $pullRequestAsIssue })

    $unexpectedUpdatePath = New-FinalizationScenario -Kind Update
    $unexpectedUpdatePath.ChangedFiles += [pscustomobject]@{
        filename = 'src/application.cs'; status = 'modified'
    }
    $negativeScenarios.Add([pscustomobject]@{ Name = 'unexpected update path'; Scenario = $unexpectedUpdatePath })

    $fabricatedSchema2Output = New-FinalizationScenario -Kind Update `
        -UpdateSchema 2 -FabricatedSchema2Output $true
    $negativeScenarios.Add([pscustomobject]@{
        Name = 'fabricated internally consistent schema-2 output'
        Scenario = $fabricatedSchema2Output
        ExpectedError = 'Schema-2 proposal migration output or ledger differs from the independently computed plan.'
    })

    $renamedPath = New-FinalizationScenario -Kind Update
    $renamedPath.ChangedFiles[0] = [pscustomobject]@{
        filename = '.ai/protocol'; previous_filename = '.ai/old-protocol'
        status = 'renamed'
    }
    $negativeScenarios.Add([pscustomobject]@{ Name = 'renamed path'; Scenario = $renamedPath })

    $markerHeadMismatch = New-FinalizationScenario -Kind Adoption
    $markerHeadMismatch.ExpectedHead = 'f' * 40
    $negativeScenarios.Add([pscustomobject]@{ Name = 'marker head mismatch'; Scenario = $markerHeadMismatch })

    $movedBranch = New-FinalizationScenario -Kind Adoption
    $movedBranch.MoveBeforeDelete = $true
    $negativeScenarios.Add([pscustomobject]@{ Name = 'moved branch'; Scenario = $movedBranch })

    $reusedBranch = New-FinalizationScenario -Kind Adoption
    $reusedBranch.OpenBranchReuseCount = 1
    $negativeScenarios.Add([pscustomobject]@{ Name = 'open branch reuse'; Scenario = $reusedBranch })

    foreach ($negative in $negativeScenarios) {
        $result = Invoke-FinalizationScenario -Scenario $negative.Scenario
        if (-not $result.Threw) {
            Add-Failure "TEST-0110 $($negative.Name) did not fail closed."
        }
        $expectedErrorProperty = $negative.PSObject.Properties['ExpectedError']
        if ($null -ne $expectedErrorProperty -and
            [string]$result.Error -cnotlike "*$([string]$expectedErrorProperty.Value)*") {
            Add-Failure "TEST-0121 $($negative.Name) did not fail on independent schema-2 evidence: $($result.Error)"
        }
        Test-NoFinalizationMutation -Result $result -Name $negative.Name
        $negativeSummaryProperty = $result.PSObject.Properties['SummaryLines']
        if ($null -ne $negativeSummaryProperty -and
            @($negativeSummaryProperty.Value).Count -ne 0) {
            Add-Failure "TEST-0142 rejected '$($negative.Name)' emitted finalization summary output."
        }
    }

    $outerSummaryLines = @(Get-Content -LiteralPath $outerSummaryPath)
    if ($outerSummaryLines.Count -ne 1 -or
        [string]$outerSummaryLines[0] -cne $outerSummarySentinel) {
        Add-Failure "TEST-0142 inherited outer summary was mutated: $($outerSummaryLines -join ' | ')"
    }
}
finally {
    $env:GITHUB_STEP_SUMMARY = $previousStepSummary
    if (Test-Path -LiteralPath $outerSummaryPath) {
        Remove-Item -LiteralPath $outerSummaryPath -Force -ErrorAction SilentlyContinue
    }
    Remove-Item Function:\global:git -ErrorAction SilentlyContinue
    Remove-Item Function:\global:gh -ErrorAction SilentlyContinue
    Remove-Variable MeAndAIFinalizationScenario -Scope Global -ErrorAction SilentlyContinue
}

$adapterLifecycleSource = Get-Content -LiteralPath $adapterPath -Raw
foreach ($requiredLegacyText in @(
    'Repair-LegacyInstallingUpdateTracking',
    'Invoke-LegacyInstallingUpdateRecovery',
    'Tracking issue: #REQUIRED',
    'meandai-protocol-update-issue:'
)) {
    if (-not $adapterLifecycleSource.Contains($requiredLegacyText)) {
        Add-Failure "TEST-0112 managed finalizer lacks bounded legacy transition '$requiredLegacyText'."
    }
}
if (-not $workflow.Contains('push:') -or
    -not $workflow.Contains("github.event_name == 'push'") -or
    -not $workflow.Contains('pull-requests: write')) {
    Add-Failure 'TEST-0112 consumer workflow cannot recover an installing legacy update on its default-branch merge.'
}

if ($failures.Count -gt 0) {
    Write-Host "Managed merge finalization tests failed with $($failures.Count) problem(s):" `
        -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Managed merge finalization tests passed.' -ForegroundColor Green
$scenarioResult = New-MeAndAIScenarioResult `
    -Owner 'tests/capabilities/consumer-update/managed-merge-finalization.tests.ps1' `
    -SourcePaths @($PSCommandPath) -AuthorityPath $scenarioAuthorityPath
Write-Host ('MEANDAI_SCENARIO_RESULTS=' + ($scenarioResult | ConvertTo-Json -Compress))
