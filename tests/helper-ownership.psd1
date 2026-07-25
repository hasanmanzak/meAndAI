@{
    SchemaVersion = 1
    ContractId = 'MEANDAI-TEST-HELPER-OWNERSHIP-0001'
    ScanRoots = @(
        'scripts'
        'tests'
        'templates/project/.github/scripts'
    )
    Owners = @(
        @{
            ContractId = 'THO-0001'
            SemanticKind = 'failure-context'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestContext.psm1'
            CanonicalCommands = @(
                'Add-Failure'
                'Add-MeAndAITestFailure'
                'Assert-MeAndAITestCollectedEqual'
                'Assert-MeAndAITestCollectedTrue'
                'Clear-MeAndAITestContext'
                'Get-MeAndAITestFailures'
                'New-MeAndAITestContext'
                'Set-MeAndAITestContext'
            )
            GuardedNames = @(
                'Add-Failure'
                'Add-MeAndAITestFailure'
                'Assert-MeAndAITestCollectedEqual'
                'Assert-MeAndAITestCollectedTrue'
                'Clear-MeAndAITestContext'
                'Get-MeAndAITestFailures'
                'New-MeAndAITestContext'
                'Set-MeAndAITestContext'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0002'
            SemanticKind = 'fail-fast-assertions'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestAssertions.psm1'
            CanonicalCommands = @(
                'Assert-Equal'
                'Assert-MeAndAITestEqual'
                'Assert-MeAndAITestSequenceEqual'
                'Assert-MeAndAITestThrowsLike'
                'Assert-MeAndAITestTrue'
                'Assert-SequenceEqual'
                'Assert-ThrowsLike'
                'Assert-True'
            )
            GuardedNames = @(
                'Assert-Equal'
                'Assert-MeAndAITestEqual'
                'Assert-MeAndAITestSequenceEqual'
                'Assert-MeAndAITestThrowsLike'
                'Assert-MeAndAITestTrue'
                'Assert-SequenceEqual'
                'Assert-ThrowsLike'
                'Assert-True'
            )
            ReviewedExceptions = @(
                @{
                    Path = 'tests/capabilities/consumer-update/fixtures/legacy-pre-engine-consumer/Verify-MeAndAIAdoption.ps1'
                    Names = @('Assert-True')
                    Reason = 'The frozen pre-engine consumer fixture must remain self-contained and cannot import the current test harness without changing the legacy topology it proves.'
                    ReviewAuthority = 'DEC-0029 / TEST-0125 frozen legacy fixture'
                    RemovalSlice = 'Permanent'
                }
                @{
                    Path = 'tests/capabilities/consumer-update/protocol-update-reliability.tests.ps1'
                    Names = @('Assert-Equal')
                    Reason = 'This capability-owned assertion accumulates case-sensitive reliability diagnostics instead of applying the canonical fail-fast contract.'
                    ReviewAuthority = 'DEC-0029 / SUBF-0096 semantic classification'
                    RemovalSlice = 'Permanent'
                }
                @{
                    Path = 'tests/capabilities/consumer-update/protocol-update.tests.ps1'
                    Names = @('Assert-Equal')
                    Reason = 'This compatibility signature delegates to the canonical collected-equality contract while call-site removal remains a finite migration slice.'
                    ReviewAuthority = 'FEAT-0051 / SUBF-0098 migration ledger'
                    RemovalSlice = 'SUBF-0098'
                }
                @{
                    Path = 'tests/capabilities/initial-adoption/capabilities-bootstrap.tests.ps1'
                    Names = @('Assert-Equal')
                    Reason = 'This compatibility signature delegates to the canonical collected-equality contract while call-site removal remains a finite migration slice.'
                    ReviewAuthority = 'FEAT-0051 / SUBF-0098 migration ledger'
                    RemovalSlice = 'SUBF-0098'
                }
                @{
                    Path = 'tests/capabilities/instruction-graph-discovery/instruction-graph-discovery.tests.ps1'
                    Names = @(
                        'Assert-SequenceEqual'
                        'Assert-ThrowsLike'
                        'Assert-True'
                    )
                    Reason = 'These capability-owned assertions aggregate instruction-graph diagnostics and preserve capability-specific continuation behavior rather than failing fast.'
                    ReviewAuthority = 'DEC-0029 / SUBF-0096 semantic classification'
                    RemovalSlice = 'Permanent'
                }
                @{
                    Path = 'tests/capabilities/test-runtime-efficiency/test-runtime-efficiency.tests.ps1'
                    Names = @(
                        'Assert-Equal'
                        'Assert-ThrowsLike'
                        'Assert-True'
                    )
                    Reason = 'These capability-owned assertions aggregate runtime-efficiency diagnostics, including nullable and case-sensitive evidence contracts, rather than failing fast.'
                    ReviewAuthority = 'DEC-0029 / SUBF-0096 semantic classification'
                    RemovalSlice = 'Permanent'
                }
            )
        }
        @{
            ContractId = 'THO-0003'
            SemanticKind = 'binary-content-identity'
            OwnerPath = 'scripts/MeAndAI.ContentIdentity.psm1'
            CanonicalCommands = @(
                'Get-MeAndAIGitBlobSha1'
                'Get-MeAndAISha256'
                'Test-MeAndAIByteArrayEqual'
            )
            GuardedNames = @(
                'Get-GitBlobSha'
                'Get-MeAndAIGitBlobSha1'
                'Get-MeAndAISha256'
                'Get-Sha256Bytes'
                'Get-TestGitBlobSha'
                'Get-TestSha256'
                'Get-TestSha256Hex'
                'Get-TestSha256Text'
                'Test-ByteArrayEqual'
                'Test-BytesEqual'
                'Test-MeAndAIByteArrayEqual'
                'Test-TestBytesEqual'
            )
            ReviewedExceptions = @(
                @{
                    Path = 'tests/capabilities/initial-adoption/quick-adoption.tests.ps1'
                    Names = @('Get-GitBlobSha')
                    Reason = 'This nested fixture command returns a fixed synthetic blob identity and does not implement content hashing.'
                    ReviewAuthority = 'FEAT-0051 / SUBF-0096 fixture-boundary classification'
                    RemovalSlice = 'Permanent'
                }
            )
        }
        @{
            ContractId = 'THO-0004'
            SemanticKind = 'git-blob-batch-transport'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestGitBatch.psm1'
            CanonicalCommands = @('New-MeAndAITestGitBlobBatchSession')
            GuardedNames = @('New-MeAndAITestGitBlobBatchSession')
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0005'
            SemanticKind = 'test-suite-discovery'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestDiscovery.psm1'
            CanonicalCommands = @(
                'Get-MeAndAITestSuite'
                'Import-MeAndAITestExecutionProfile'
                'Resolve-MeAndAITestOwnerSet'
            )
            GuardedNames = @(
                'Get-MeAndAITestSuite'
                'Import-MeAndAITestExecutionProfile'
                'Resolve-MeAndAITestOwnerSet'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0006'
            SemanticKind = 'scenario-evidence'
            OwnerPath = 'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1'
            CanonicalCommands = @(
                'Confirm-MeAndAIScenarioEvidence'
                'New-MeAndAIScenarioEvidenceContext'
                'New-MeAndAIScenarioResult'
            )
            GuardedNames = @(
                'Confirm-MeAndAIScenarioEvidence'
                'Get-MeAndAISourceBoundScenarioIds'
                'New-MeAndAIScenarioEvidenceContext'
                'New-MeAndAIScenarioResult'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0007'
            SemanticKind = 'test-runtime-evidence'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestRuntime.psm1'
            CanonicalCommands = @(
                'Assert-MeAndAITestSuiteOperationEvidence'
                'Compare-MeAndAIExactScenarioId'
                'Format-MeAndAITestOperationObservation'
                'Format-MeAndAITestSuiteObservation'
                'Get-MeAndAITestRuntimeClass'
                'Import-MeAndAITestOperationContract'
                'Invoke-MeAndAITestSuiteProcess'
                'Read-MeAndAICompatibilityShardResultRecord'
                'Read-MeAndAIScenarioResultRecord'
                'Read-MeAndAITestOperationObservationRecord'
                'Resolve-MeAndAITestOperationExpectation'
            )
            GuardedNames = @(
                'Assert-MeAndAITestSuiteOperationEvidence'
                'Compare-MeAndAIExactScenarioId'
                'Format-MeAndAITestOperationObservation'
                'Format-MeAndAITestSuiteObservation'
                'Get-MeAndAITestRuntimeClass'
                'Import-MeAndAITestOperationContract'
                'Invoke-MeAndAITestSuiteProcess'
                'Read-MeAndAICompatibilityShardResultRecord'
                'Read-MeAndAIScenarioResultRecord'
                'Read-MeAndAITestOperationObservationRecord'
                'Resolve-MeAndAITestOperationExpectation'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0008'
            SemanticKind = 'repository-evidence'
            OwnerPath = 'scripts/MeAndAI.RepositoryEvidence.psm1'
            CanonicalCommands = @('Get-MeAndAIRepositoryEvidence')
            GuardedNames = @('Get-MeAndAIRepositoryEvidence')
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0009'
            SemanticKind = 'temporary-workspace'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestWorkspace.psm1'
            CanonicalCommands = @('New-MeAndAITestDirectoryLink')
            GuardedNames = @(
                'New-MeAndAITestDirectoryLink'
                'New-TestDirectoryLink'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0010'
            SemanticKind = 'markdown-renderer-evidence'
            OwnerPath = 'tests/infrastructure/MeAndAI.MarkdownEvidence.psm1'
            CanonicalCommands = @(
                'Test-MeAndAIContainsExactDocumentTitle'
            )
            GuardedNames = @(
                'Test-ContainsExactDocumentTitle'
                'Test-MeAndAIContainsExactDocumentTitle'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0011'
            SemanticKind = 'test-repository-commit'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestRepository.psm1'
            CanonicalCommands = @('New-MeAndAITestCommit')
            GuardedNames = @(
                'New-MeAndAITestCommit'
                'New-TestCommit'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0012'
            SemanticKind = 'legacy-scenario-evidence-transition'
            OwnerPath = 'tests/infrastructure/MeAndAI.LegacyScenarioEvidence.psm1'
            CanonicalCommands = @(
                'Confirm-MeAndAILegacyScenarioEvidence'
                'Get-MeAndAILegacySourceBoundScenarioIds'
                'New-MeAndAILegacyScenarioResult'
            )
            GuardedNames = @(
                'Confirm-MeAndAILegacyScenarioEvidence'
                'Get-MeAndAILegacySourceBoundScenarioIds'
                'New-MeAndAILegacyScenarioResult'
            )
            ReviewedExceptions = @()
        }
        @{
            ContractId = 'THO-0013'
            SemanticKind = 'test-role-boundary-inspection'
            OwnerPath = 'tests/infrastructure/MeAndAI.TestRole.psm1'
            CanonicalCommands = @('Test-MeAndAITestRoleSource')
            GuardedNames = @('Test-MeAndAITestRoleSource')
            ReviewedExceptions = @()
        }
    )
}
