# Mechanically extracted from the reviewed v0.12.4 quick-adoption launcher.
$minimumGitHubCliVersion = '2.82.1'
$workflowSourcePath = 'templates/project/.github/workflows/meandai-protocol-update.yml'
$workflowTargetPath = '.github/workflows/meandai-protocol-update.yml'
$adoptionManifestPath = '.ai/adoption/meandai-capabilities.json'
$initialAdoptionPolicyTag = 'v0.14.3'
$initialAdoptionPolicySourcePath =
    'templates/project/.github/scripts/MeAndAI.CapabilitiesBootstrap.psm1'
$consumerMigrationModulePath = 'scripts/MeAndAI.ConsumerMigrations.psm1'
$consumerMigrationIndexPath = 'migrations/index.json'
$consumerMigrationLedgerPath = '.ai/meandai-update-state.json'
$adoptionAssets = @(
    [pscustomobject]@{
        ConsumerPath = 'AGENTS.md'
        TemplatePath = 'templates/project/AGENTS.submodule.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/README.md'
        TemplatePath = 'templates/project/.ai/memory/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/project.md'
        TemplatePath = 'templates/project/.ai/memory/project.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.ai/memory/log/README.md'
        TemplatePath = 'templates/project/.ai/memory/log/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = 'docs/ideas/README.md'
        TemplatePath = 'templates/project/docs/ideas/README.md'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/bug.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/bug.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/epic.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/epic.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/feature.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/feature.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/finding.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/finding.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/subfeature.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/subfeature.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/ISSUE_TEMPLATE/task.yml'
        TemplatePath = '.github/ISSUE_TEMPLATE/task.yml'
    },
    [pscustomobject]@{
        ConsumerPath = '.github/PULL_REQUEST_TEMPLATE.md'
        TemplatePath = '.github/PULL_REQUEST_TEMPLATE.md'
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
$adoptionUpdaterAssets = @($adoptionAssets | Where-Object {
    [string]$_.ConsumerPath -cin @(
        '.github/scripts/MeAndAI.ProtocolUpdate.psm1',
        '.github/scripts/Invoke-MeAndAIProtocolUpdate.ps1'
    )
})
$managedUpdaterAssets = @(
    [pscustomobject]@{
        ConsumerPath = $workflowTargetPath
        TemplatePath = $workflowSourcePath
    }
) + @($adoptionUpdaterAssets)
$adoptionCanonicalTargetPaths = @(
    '.gitmodules', '.ai/protocol', '.ai/meandai-update-state.json'
) + @($adoptionAssets | ForEach-Object { [string]$_.ConsumerPath })
$adoptionCanonicalIdentityPaths = @(
    $workflowTargetPath, $adoptionManifestPath
) + @($adoptionCanonicalTargetPaths)
$protocolSurfaceTraversalMaximumDirectoryCount = 4096
$protocolSurfaceTraversalMaximumEntryCount = 65536
$secretLockLabel = 'meandai:secret-reconciliation-lock'
$tokenMappings = [ordered]@{
    'FG_PAT.txt' = 'MEANDAI_UPDATER_TOKEN'
    'MEANDAI_RO_FG_PAT.txt' = 'MEANDAI_PROTOCOL_TOKEN'
}
$adoptionLabels = @(
    [pscustomobject]@{ Name = 'type:epic'; Color = '5319e7'; Description = 'Agile epic' },
    [pscustomobject]@{ Name = 'type:feature'; Color = '1d76db'; Description = 'User-facing feature' },
    [pscustomobject]@{ Name = 'type:subfeature'; Color = '0e8a16'; Description = 'Independently testable feature slice' },
    [pscustomobject]@{ Name = 'type:task'; Color = 'd4c5f9'; Description = 'Implementation or maintenance task' },
    [pscustomobject]@{ Name = 'type:bug'; Color = 'd73a4a'; Description = 'Defect' },
    [pscustomobject]@{ Name = 'type:finding'; Color = 'fbca04'; Description = 'Review or scan finding' },
    [pscustomobject]@{ Name = 'priority:p0'; Color = 'b60205'; Description = 'Critical priority' },
    [pscustomobject]@{ Name = 'priority:p1'; Color = 'd93f0b'; Description = 'High priority' },
    [pscustomobject]@{ Name = 'priority:p2'; Color = 'fbca04'; Description = 'Normal priority' },
    [pscustomobject]@{ Name = 'priority:p3'; Color = '0e8a16'; Description = 'Low priority' },
    [pscustomobject]@{ Name = 'status:blocked'; Color = 'b60205'; Description = 'Blocked by an unresolved dependency' },
    [pscustomobject]@{ Name = 'status:in-progress'; Color = '1d76db'; Description = 'Implementation in progress' },
    [pscustomobject]@{ Name = 'status:needs-review'; Color = '5319e7'; Description = 'Ready for maintainer review' }
)
