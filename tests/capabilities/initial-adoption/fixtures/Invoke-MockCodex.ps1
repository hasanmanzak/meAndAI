[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'
$stdin = [Console]::In.ReadToEnd()
$logPath = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_LOG')
if ([string]::IsNullOrWhiteSpace($logPath)) {
    throw 'MEANDAI_TEST_CODEX_LOG is required.'
}
$record = [ordered]@{
    Arguments = @($Arguments)
    Stdin = $stdin
} | ConvertTo-Json -Compress -Depth 5
Add-Content -LiteralPath $logPath -Value $record -Encoding UTF8

$mode = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_MODE')
if (-not $mode) {
    $mode = 'Success'
}

function Write-CodexJsonEvent {
    param([Parameter(Mandatory)]$Value)

    [Console]::Out.WriteLine(($Value | ConvertTo-Json -Compress -Depth 8))
    [Console]::Out.Flush()
}

if ($Arguments.Count -gt 0 -and $Arguments[0] -ceq 'sandbox') {
    $sandboxMode = [Environment]::GetEnvironmentVariable(
        'MEANDAI_TEST_CODEX_SANDBOX_MODE'
    )
    if (-not $sandboxMode) {
        $sandboxMode = 'Success'
    }
    $argumentText = $Arguments -join "`n"
    $selectedModeMatch = [regex]::Match(
        $argumentText,
        'windows\.sandbox=[\"''](?<mode>elevated|unelevated)[\"'']'
    )
    if (-not $selectedModeMatch.Success) {
        [Console]::Error.WriteLine('Mock sandbox did not receive an explicit Windows mode.')
        exit 1
    }
    $selectedMode = $selectedModeMatch.Groups['mode'].Value
    if ($sandboxMode -ceq 'FailAll' -or
        ($sandboxMode -ceq 'FailElevated' -and $selectedMode -ceq 'elevated')) {
        [Console]::Error.WriteLine("Mock $selectedMode sandbox setup failed.")
        exit 1
    }
    if ($sandboxMode -ceq 'Residue') {
        $workingIndex = [Array]::IndexOf([object[]]$Arguments, '-C')
        $probeMatch = [regex]::Match(
            $argumentText,
            '(?<name>\.meandai-codex-sandbox-probe-[0-9a-f]+\.tmp)'
        )
        if ($workingIndex -lt 0 -or $workingIndex + 1 -ge $Arguments.Count -or
            -not $probeMatch.Success) {
            [Console]::Error.WriteLine('Mock sandbox residue fixture is incomplete.')
            exit 1
        }
        [IO.File]::WriteAllText(
            (Join-Path $Arguments[$workingIndex + 1] $probeMatch.Groups['name'].Value),
            'residue',
            [Text.UTF8Encoding]::new($false)
        )
    }
    [Console]::Out.WriteLine("Mock $selectedMode sandbox preflight completed.")
    exit 0
}
if (($Arguments -join ' ') -eq 'login status') {
    if ($mode -ceq 'Unauthenticated') {
        [Console]::Error.WriteLine('Not logged in')
        exit 1
    }
    [Console]::Out.WriteLine('Logged in using test authentication')
    exit 0
}
if ($Arguments.Count -eq 0 -or $Arguments[0] -cne 'exec') {
    throw "Unexpected mock Codex call: $($Arguments -join ' ')"
}

$workingIndex = [Array]::IndexOf([object[]]$Arguments, '--cd')
$outputIndex = [Array]::IndexOf([object[]]$Arguments, '--output-last-message')
$jsonIndex = [Array]::IndexOf([object[]]$Arguments, '--json')
if ($workingIndex -lt 0 -or $workingIndex + 1 -ge $Arguments.Count -or
    $outputIndex -lt 0 -or $outputIndex + 1 -ge $Arguments.Count -or
    $jsonIndex -lt 0) {
    throw 'Mock Codex did not receive isolated working/output paths and JSONL streaming.'
}
$working = $Arguments[$workingIndex + 1]
$output = $Arguments[$outputIndex + 1]
$target = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_TARGET')
if ($working -ceq $target -or
    (Test-Path -LiteralPath (Join-Path $working 'FG_PAT.txt')) -or
    (Test-Path -LiteralPath (Join-Path $working 'MEANDAI_RO_FG_PAT.txt'))) {
    throw 'Mock Codex was exposed to the consumer credential workspace.'
}
if ($stdin.Contains('write-token-value') -or $stdin.Contains('read-token-value')) {
    throw 'Mock Codex prompt contains a credential value.'
}
$argumentText = $Arguments -join "`n"
$networkIndex = [Array]::IndexOf([object[]]$Arguments, 'sandbox_workspace_write.network_access')
$networkDisabled = $argumentText.Contains('sandbox_workspace_write.network_access=false') -or
    ($networkIndex -ge 0 -and $networkIndex + 1 -lt $Arguments.Count -and
        $Arguments[$networkIndex + 1] -ceq 'false')
$networkEnabled = $argumentText.Contains('sandbox_workspace_write.network_access=true') -or
    ($networkIndex -ge 0 -and $networkIndex + 1 -lt $Arguments.Count -and
        $Arguments[$networkIndex + 1] -ceq 'true')
if (-not $networkDisabled -or $networkEnabled -or
    $stdin.Contains('Use gh only') -or $stdin.Contains('Use gh for')) {
    throw "Mock Codex did not receive the enforced network-free publication boundary (disabled=$networkDisabled; enabled=$networkEnabled; arguments=$($Arguments -join '|'))."
}

Write-CodexJsonEvent ([ordered]@{
    type = 'thread.started'
    thread_id = 'mock-adoption-thread'
})
Write-CodexJsonEvent ([ordered]@{ type = 'turn.started' })
Write-CodexJsonEvent ([ordered]@{
    type = 'item.completed'
    item = [ordered]@{
        id = 'message-1'
        type = 'agent_message'
        text = 'Inspecting project records.'
    }
})
Write-CodexJsonEvent ([ordered]@{
    type = 'item.started'
    item = [ordered]@{
        id = 'command-1'
        type = 'command_execution'
        command = 'git status --porcelain'
        aggregated_output = 'MEANDAI_TEST_HIDDEN_COMMAND_OUTPUT'
        status = 'in_progress'
    }
})

$manifestPath = Join-Path $working '.ai/adoption/meandai-capabilities.json'
$manifest = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
$strategy = if ($null -ne $manifest.PSObject.Properties['adoptionStrategy']) {
    [string]$manifest.adoptionStrategy
}
else { 'LegacyUnspecified' }
$lossAcknowledged = if ($null -ne $manifest.PSObject.Properties[
    'protocolRecordLossAcknowledged'
]) {
    [bool]$manifest.protocolRecordLossAcknowledged
}
else { $false }
if (-not $stdin.Contains("The maintainer-selected adoption strategy is $strategy.") -or
    -not $stdin.Contains(
        "Protocol-record loss acknowledgement is $($lossAcknowledged.ToString().ToLowerInvariant())."
    )) {
    throw 'Mock Codex did not receive the exact manifest-selected strategy identity.'
}
$promptSurfaces = if ($null -ne $manifest.PSObject.Properties['protocolSurfaces']) {
    @($manifest.protocolSurfaces)
}
else { @() }
foreach ($surface in $promptSurfaces) {
    if (-not $stdin.Contains("- $surface")) {
        throw "Mock Codex prompt omitted approved surface '$surface'."
    }
}
$protocolSourceMatch = [regex]::Match(
    $stdin,
    '(?m)Read the exact protocol source at (?<path>.+?), every applicable AGENTS\.md'
)
if (-not $protocolSourceMatch.Success) {
    throw 'Mock Codex could not resolve the exact protocol source from the launcher prompt.'
}
$protocolSource = $protocolSourceMatch.Groups['path'].Value
$adoptionAssets = @(
    [pscustomobject]@{ ConsumerPath = 'AGENTS.md'; TemplatePath = 'templates/project/AGENTS.submodule.md' },
    [pscustomobject]@{ ConsumerPath = '.ai/memory/README.md'; TemplatePath = 'templates/project/.ai/memory/README.md' },
    [pscustomobject]@{ ConsumerPath = '.ai/memory/project.md'; TemplatePath = 'templates/project/.ai/memory/project.md' },
    [pscustomobject]@{ ConsumerPath = '.ai/memory/log/README.md'; TemplatePath = 'templates/project/.ai/memory/log/README.md' },
    [pscustomobject]@{ ConsumerPath = 'docs/ideas/README.md'; TemplatePath = 'templates/project/docs/ideas/README.md' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/bug.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/bug.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/epic.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/epic.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/feature.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/feature.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/finding.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/finding.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/subfeature.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/subfeature.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/ISSUE_TEMPLATE/task.yml'; TemplatePath = '.github/ISSUE_TEMPLATE/task.yml' },
    [pscustomobject]@{ ConsumerPath = '.github/PULL_REQUEST_TEMPLATE.md'; TemplatePath = '.github/PULL_REQUEST_TEMPLATE.md' },
    [pscustomobject]@{ ConsumerPath = '.github/scripts/MeAndAI.ProtocolUpdate.psm1'; TemplatePath = 'templates/project/.github/scripts/MeAndAI.ProtocolUpdate.psm1' },
    [pscustomobject]@{ ConsumerPath = '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'; TemplatePath = 'templates/project/.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1' }
)
foreach ($asset in $adoptionAssets) {
    $sourceAsset = Join-Path $protocolSource ([string]$asset.TemplatePath)
    $destinationAsset = Join-Path $working ([string]$asset.ConsumerPath)
    if (-not (Test-Path -LiteralPath $sourceAsset -PathType Leaf)) {
        throw "Mock protocol source is missing '$($asset.TemplatePath)'."
    }
    $forceExactUpdater = [string]$asset.ConsumerPath -cin @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    )
    if ($forceExactUpdater -or
        -not (Test-Path -LiteralPath $destinationAsset -PathType Leaf)) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $destinationAsset) `
            -Force | Out-Null
        Copy-Item -LiteralPath $sourceAsset -Destination $destinationAsset -Force
    }
}
if ($mode -ceq 'ReconcileCanonicalAgentsOnly') {
    Copy-Item -LiteralPath (
        Join-Path $protocolSource 'templates/project/AGENTS.submodule.md'
    ) -Destination (Join-Path $working 'AGENTS.md') -Force
}
$migrationModulePath = Join-Path $protocolSource 'scripts/MeAndAI.ConsumerMigrations.psm1'
$migrationIndexPath = Join-Path $protocolSource 'migrations/index.json'
$migrationModules = @(Import-Module -Name $migrationModulePath -Force -PassThru)
if ($migrationModules.Count -ne 1) {
    throw 'Mock Codex could not import the exact consumer migration contract.'
}
$migrationModule = $migrationModules[0]
try {
    $catalog = & $migrationModule.ExportedCommands[
        'Import-MeAndAIConsumerMigrationCatalog'
    ] -IndexPath $migrationIndexPath
    $baseline = & $migrationModule.ExportedCommands[
        'New-MeAndAIConsumerMigrationBaseline'
    ] -Catalog $catalog
    $baselinePath = Join-Path $working ([string]$baseline.Path)
    New-Item -ItemType Directory -Path (Split-Path -Parent $baselinePath) `
        -Force | Out-Null
    [IO.File]::WriteAllBytes($baselinePath, [byte[]]$baseline.Bytes)
}
finally {
    Remove-Module -Name ([string]$migrationModule.Name) -Force `
        -ErrorAction SilentlyContinue
}
$protocolEntry = (& git -C $working ls-files --stage -- .ai/protocol 2>&1) -join ''
if (-not $protocolEntry) {
    $canonicalProtocolSection = @(
        '[submodule ".ai/protocol"]',
        "`tpath = .ai/protocol",
        "`turl = https://github.com/hasanmanzak/meAndAI.git",
        ''
    ) -join "`n"
    $gitmodulesPath = Join-Path $working '.gitmodules'
    $gitmodules = if (Test-Path -LiteralPath $gitmodulesPath -PathType Leaf) {
        $existingGitmodules = [IO.File]::ReadAllText($gitmodulesPath)
        if ($existingGitmodules -match
                '(?m)^\[submodule "\.ai/protocol"\]\r?$') {
            $existingGitmodules
        }
        else {
            $separator = if ($existingGitmodules.EndsWith("`n")) { '' } else { "`n" }
            $existingGitmodules + $separator + $canonicalProtocolSection
        }
    }
    else {
        $canonicalProtocolSection
    }
    [IO.File]::WriteAllText(
        $gitmodulesPath,
        $gitmodules,
        [Text.UTF8Encoding]::new($false)
    )
    & git -C $working update-index --add --cacheinfo "160000,$([string]$manifest.protocolSha),.ai/protocol"
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to stage the mock protocol gitlink.'
    }
    $testProtocolRepository = [Environment]::GetEnvironmentVariable(
        'MEANDAI_TEST_PROTOCOL_REPOSITORY'
    )
    if ([string]::IsNullOrWhiteSpace($testProtocolRepository)) {
        throw 'Mock protocol repository is unavailable for gitlink materialization.'
    }
    $protocolCheckout = Join-Path $working '.ai/protocol'
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $null = & git clone --no-checkout $testProtocolRepository `
            $protocolCheckout 2>&1
        $cloneExitCode = $LASTEXITCODE
        if ($cloneExitCode -eq 0) {
            $null = & git -C $protocolCheckout checkout --detach `
                ([string]$manifest.protocolSha) 2>&1
            $checkoutExitCode = $LASTEXITCODE
        }
        else {
            $checkoutExitCode = $cloneExitCode
        }
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($cloneExitCode -ne 0 -or $checkoutExitCode -ne 0) {
        throw 'Unable to materialize the exact mock protocol checkout.'
    }
}
$evidencePath = Join-Path $working 'docs/governance/ai-adoption.md'
New-Item -ItemType Directory -Path (Split-Path -Parent $evidencePath) -Force | Out-Null
Set-Content -LiteralPath $evidencePath -Value '# Local adoption evidence' -Encoding UTF8
if ($mode -ceq 'DeleteApplication') {
    $applicationPath = Join-Path $working 'app.txt'
    if (-not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
        throw 'Mock application-deletion fixture is missing app.txt.'
    }
    Remove-Item -LiteralPath $applicationPath -Force
}
if ($mode -ceq 'ModifyApplication') {
    $applicationPath = Join-Path $working 'app.txt'
    if (-not (Test-Path -LiteralPath $applicationPath -PathType Leaf)) {
        throw 'Mock application-modification fixture is missing app.txt.'
    }
    [IO.File]::AppendAllText(
        $applicationPath,
        "unauthorized application mutation`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'AddApplication') {
    $newApplicationPath = Join-Path $working 'src/unauthorized-application.txt'
    New-Item -ItemType Directory -Path (Split-Path -Parent $newApplicationPath) `
        -Force | Out-Null
    [IO.File]::WriteAllText(
        $newApplicationPath,
        "unauthorized application addition`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'AddProtocolSurface') {
    $newProtocolSurfacePath = Join-Path $working 'PROTOCOL.md'
    [IO.File]::WriteAllText(
        $newProtocolSurfacePath,
        "# Unauthorized new protocol authority`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'AddCursorRule') {
    $newCursorRulePath = Join-Path $working '.cursor/rules/unauthorized.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $newCursorRulePath) `
        -Force | Out-Null
    [IO.File]::WriteAllText(
        $newCursorRulePath,
        "# Unauthorized new cursor rule`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'ModifyAiModel') {
    $aiModelPath = Join-Path $working 'ai/model.py'
    if (-not (Test-Path -LiteralPath $aiModelPath -PathType Leaf)) {
        throw 'Mock ai/model.py modification fixture is missing its product file.'
    }
    [IO.File]::AppendAllText(
        $aiModelPath,
        "# unauthorized product mutation`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'DeleteReadOnlyRelease') {
    $releasePath = Join-Path $working 'RELEASES.md'
    if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
        throw 'Mock read-only RELEASES.md fixture is missing.'
    }
    Remove-Item -LiteralPath $releasePath -Force
}
if ($mode -ceq 'DeleteReadOnlyFeature') {
    $featurePath = Join-Path $working 'docs/features/product.md'
    if (-not (Test-Path -LiteralPath $featurePath -PathType Leaf)) {
        throw 'Mock read-only product feature fixture is missing.'
    }
    Remove-Item -LiteralPath $featurePath -Force
}
if ($mode -ceq 'ModifyProductSubmodule') {
    $gitmodulesPath = Join-Path $working '.gitmodules'
    $gitmodules = [IO.File]::ReadAllText($gitmodulesPath)
    $originalUrl = 'url = https://example.invalid/product.git'
    if (-not $gitmodules.Contains($originalUrl)) {
        throw 'Mock product-submodule modification fixture is missing its original URL.'
    }
    [IO.File]::WriteAllText(
        $gitmodulesPath,
        $gitmodules.Replace(
            $originalUrl,
            'url = https://example.invalid/changed-product.git'
        ),
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'DeleteProductSubmodule') {
    $gitmodulesPath = Join-Path $working '.gitmodules'
    $gitmodules = [IO.File]::ReadAllText($gitmodulesPath)
    $productSectionPattern =
        '(?m)^\[submodule "vendor/case-sensitive-product"\]\r?\n(?:[ \t][^\r\n]*(?:\r?\n|$))*'
    $updatedGitmodules = [regex]::Replace(
        $gitmodules, $productSectionPattern, '', 1
    )
    if ($updatedGitmodules -ceq $gitmodules) {
        throw 'Mock product-submodule deletion fixture is missing its product section.'
    }
    [IO.File]::WriteAllText(
        $gitmodulesPath,
        $updatedGitmodules,
        [Text.UTF8Encoding]::new($false)
    )
}
if (@(
        'AddHybridDecision', 'AddHybridDecisionRestoreRootAgents'
    ) -ccontains $mode) {
    $decisionPath = Join-Path `
        $working 'docs/decisions/hybrid-adoption-precedence.md'
    New-Item -ItemType Directory -Path (Split-Path -Parent $decisionPath) `
        -Force | Out-Null
    [IO.File]::WriteAllText(
        $decisionPath,
        "# Hybrid adoption ownership and precedence`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -ceq 'HybridNoDecision') {
    $decisionRoot = Join-Path $working 'docs/decisions'
    if (Test-Path -LiteralPath $decisionRoot -PathType Container) {
        Remove-Item -LiteralPath $decisionRoot -Recurse -Force
    }
}
if (@(
        'AddHybridDecision', 'ReconcileAgentsOnly',
        'ReconcileRequiredSurfaces', 'CompleteCleanStart',
        'DeleteApprovedSurface',
        'RetainLegacyCommonAuthority', 'RetainCursorAuthority'
    ) -ccontains $mode) {
    $canonicalAgents = [IO.File]::ReadAllText(
        (Join-Path $protocolSource 'templates/project/AGENTS.submodule.md')
    ).TrimEnd([char[]]"`r`n")
    [IO.File]::WriteAllText(
        (Join-Path $working 'AGENTS.md'),
        $canonicalAgents +
            "`n`n- Preserve the consumer-specific mock directive.`n",
        [Text.UTF8Encoding]::new($false)
    )
}
if (@(
        'ReconcileMemoryRestoreAgents', 'ReconcileRequiredSurfaces',
        'CompleteCleanStart'
    ) -ccontains $mode) {
    Copy-Item -LiteralPath (
        Join-Path $protocolSource 'templates/project/.ai/memory/project.md'
    ) -Destination (Join-Path $working '.ai/memory/project.md') -Force
}
if (@(
        'RestoreRootAgents', 'AddHybridDecisionRestoreRootAgents',
        'ReconcileMemoryRestoreAgents'
    ) -ccontains $mode) {
    & git -C $working checkout-index --force -- AGENTS.md
    if ($LASTEXITCODE -ne 0) {
        throw 'Mock could not restore the exact proposal AGENTS.md bytes.'
    }
}
if ($mode -cin @('RestoreRootAgents', 'RetainLegacyCommonAuthority')) {
    foreach ($focusedAuthority in @(
        '.cursor/rules/legacy.md',
        '.github/instructions/legacy.instructions.md'
    )) {
        if (@($promptSurfaces) -cnotcontains $focusedAuthority) {
            throw "Mock focused authority fixture was not bound to $focusedAuthority."
        }
        $focusedAuthorityPath = Join-Path $working $focusedAuthority
        if (-not (Test-Path -LiteralPath $focusedAuthorityPath -PathType Leaf)) {
            throw "Mock focused authority fixture is missing $focusedAuthority."
        }
        Remove-Item -LiteralPath $focusedAuthorityPath -Force
    }
}
if ($mode -ceq 'CompleteCleanStartRuleGitlink') {
    $cursorRuleRoot = '.cursor/rules'
    if (@($promptSurfaces) -cnotcontains $cursorRuleRoot) {
        throw "Mock clean-start gitlink completion was not bound to $cursorRuleRoot."
    }
    $cursorRuleEntry = (& git -C $working ls-files --stage -- $cursorRuleRoot `
        2>&1) -join ''
    if (-not $cursorRuleEntry.StartsWith('160000 ')) {
        throw "Mock clean-start gitlink fixture is missing $cursorRuleRoot."
    }
    & git -C $working update-index --force-remove -- $cursorRuleRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Mock could not retire exact-root gitlink $cursorRuleRoot."
    }
}
if ($mode -cin @(
        'AddHybridDecisionRestoreRootAgents', 'ReconcileRequiredSurfaces',
        'ReconcileMemoryRestoreAgents', 'ReconcileAgentsOnly'
    )) {
    $githubInstruction = '.github/instructions/legacy.instructions.md'
    if (@($promptSurfaces) -cnotcontains $githubInstruction) {
        throw "Mock focused strategy fixture was not bound to $githubInstruction."
    }
    $githubInstructionPath = Join-Path $working $githubInstruction
    if (-not (Test-Path -LiteralPath $githubInstructionPath -PathType Leaf)) {
        throw "Mock focused strategy fixture is missing $githubInstruction."
    }
    Remove-Item -LiteralPath $githubInstructionPath -Force
}
if ($mode -ceq 'CompleteCleanStart') {
    foreach ($legacySurface in @(
        'PROTOCOL.md', 'ai/WORK_INDEX.md',
        'docs/governance/cleanstart.md',
        '.github/instructions/legacy.instructions.md'
    )) {
        if (@($promptSurfaces) -cnotcontains $legacySurface) {
            throw "Mock clean-start completion was not bound to $legacySurface."
        }
        $legacySurfacePath = Join-Path $working $legacySurface
        if (-not (Test-Path -LiteralPath $legacySurfacePath -PathType Leaf)) {
            throw "Mock clean-start completion is missing $legacySurface."
        }
        Remove-Item -LiteralPath $legacySurfacePath -Force
    }
}
if ($mode -cin @('DeleteApprovedSurface', 'RetainCursorAuthority')) {
    $approvedSurfacesToDelete = @(
        'PROTOCOL.md', 'ai/WORK_INDEX.md',
        'docs/governance/legacy-protocol.md',
        '.github/instructions/legacy.instructions.md'
    )
    if ($mode -ceq 'DeleteApprovedSurface') {
        $approvedSurfacesToDelete += '.cursor/rules/legacy.md'
    }
    foreach ($approvedSurface in $approvedSurfacesToDelete) {
        if (@($promptSurfaces) -cnotcontains $approvedSurface) {
            throw "Mock approved-surface deletion was not bound to $approvedSurface."
        }
        $approvedSurfacePath = Join-Path $working $approvedSurface
        if (-not (Test-Path -LiteralPath $approvedSurfacePath -PathType Leaf)) {
            throw "Mock approved-surface deletion fixture is missing $approvedSurface."
        }
        Remove-Item -LiteralPath $approvedSurfacePath -Force
    }
}
if ($mode -ceq 'RetainLegacyCommonAuthority') {
    $approvedSurface = 'docs/governance/legacy-protocol.md'
    if (@($promptSurfaces) -cnotcontains $approvedSurface -or
        @($promptSurfaces) -cnotcontains 'PROTOCOL.md') {
        throw 'Mock retained-authority fixture is not bound to both legacy surfaces.'
    }
    $approvedSurfacePath = Join-Path $working $approvedSurface
    if (-not (Test-Path -LiteralPath $approvedSurfacePath -PathType Leaf)) {
        throw "Mock retained-authority fixture is missing $approvedSurface."
    }
    Remove-Item -LiteralPath $approvedSurfacePath -Force
}
if ($mode -ceq 'RenameWorkflowAway') {
    $workflowPath = Join-Path $working '.github/workflows/meandai-protocol-update.yml'
    $renamedPath = Join-Path $working '.github/workflows/meandai-protocol-update-renamed.yml'
    & git -C $working mv -- $workflowPath $renamedPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to rename the protected mock lifecycle workflow.'
    }
}
if ($mode -ceq 'CaseMoveWorkflow') {
    $workflowPath = Join-Path $working '.github/workflows/meandai-protocol-update.yml'
    $temporaryWorkflowPath = Join-Path $working '.github/workflows/meandai-protocol-update.case-move'
    $caseMovedPath = Join-Path $working '.github/workflows/MeAndAI-protocol-update.yml'
    & git -C $working mv -- $workflowPath $temporaryWorkflowPath
    if ($LASTEXITCODE -eq 0) {
        & git -C $working mv -- $temporaryWorkflowPath $caseMovedPath
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to case-move the protected mock lifecycle workflow.'
    }
}
if ($mode -ceq 'CaseVariantCredential') {
    [IO.File]::WriteAllText(
        (Join-Path $working 'fg_pat.txt'),
        'non-secret-test-placeholder',
        [Text.UTF8Encoding]::new($false)
    )
}
if ($mode -cne 'LeaveManifest') {
    Remove-Item -LiteralPath $manifestPath -Force
}
if ($mode -ceq 'CreateCommit') {
    & git -C $working config user.name 'meAndAI Test'
    & git -C $working config user.email 'meandai-test@example.invalid'
    & git -C $working config commit.gpgsign false
    & git -C $working add -A
    & git -C $working commit -m 'Unexpected Codex commit'
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to create the unexpected mock Codex commit.'
    }
}
if ($mode -ceq 'RemoteRace') {
    $remote = [Environment]::GetEnvironmentVariable('MEANDAI_TEST_CODEX_REMOTE')
    $raceRoot = Join-Path ([IO.Path]::GetTempPath()) "meandai-mock-race-$([guid]::NewGuid().ToString('N'))"
    $raceClone = Join-Path $raceRoot 'clone'
    try {
        New-Item -ItemType Directory -Path $raceRoot -Force | Out-Null
        & git clone --branch 'automation/meandai-capabilities-v0.13.2' $remote $raceClone
        if ($LASTEXITCODE -ne 0) { throw 'Unable to create mock race clone.' }
        & git -C $raceClone config user.name 'meAndAI Test'
        & git -C $raceClone config user.email 'meandai-test@example.invalid'
        & git -C $raceClone config commit.gpgsign false
        Set-Content -LiteralPath (Join-Path $raceClone 'concurrent.txt') -Value 'race' -Encoding UTF8
        & git -C $raceClone add concurrent.txt
        & git -C $raceClone commit -m 'Concurrent adoption change'
        & git -C $raceClone push origin HEAD
        if ($LASTEXITCODE -ne 0) { throw 'Unable to publish mock race change.' }
    }
    finally {
        if (Test-Path -LiteralPath $raceRoot) {
            Remove-Item -LiteralPath $raceRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
if ($mode -ceq 'Sleep') {
    Start-Sleep -Seconds 120
}

[IO.File]::WriteAllText(
    $output,
    'MEANDAI_ADOPTION_READY - mock local completion',
    [Text.UTF8Encoding]::new($false)
)
Write-CodexJsonEvent ([ordered]@{
    type = 'item.completed'
    item = [ordered]@{
        id = 'file-1'
        type = 'file_change'
        changes = @([ordered]@{ path = 'docs/governance/ai-adoption.md'; kind = 'update' })
    }
})
Write-CodexJsonEvent ([ordered]@{
    type = 'item.completed'
    item = [ordered]@{
        id = 'message-2'
        type = 'agent_message'
        text = 'MEANDAI_ADOPTION_READY - mock local completion'
    }
})
Write-CodexJsonEvent ([ordered]@{
    type = 'turn.completed'
    usage = [ordered]@{ input_tokens = 1; output_tokens = 1 }
})
