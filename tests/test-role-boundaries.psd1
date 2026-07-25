@{
    SchemaVersion = 1
    RootRunner = 'tests/protocol.tests.ps1'
    RunnerAggregationCommands = @(
        'Assert-MeAndAITestSuiteOperationEvidence'
    )
    Harnesses = @(
        'tests/infrastructure/MeAndAI.MarkdownEvidence.psm1'
        'tests/infrastructure/MeAndAI.ScenarioEvidence.psm1'
        'tests/infrastructure/MeAndAI.TestAssertions.psm1'
        'tests/infrastructure/MeAndAI.TestContext.psm1'
        'tests/infrastructure/MeAndAI.TestDiscovery.psm1'
        'tests/infrastructure/MeAndAI.TestGitBatch.psm1'
        'tests/infrastructure/MeAndAI.TestHelperOwnership.psm1'
        'tests/infrastructure/MeAndAI.TestRepository.psm1'
        'tests/infrastructure/MeAndAI.TestRole.psm1'
        'tests/infrastructure/MeAndAI.TestRuntime.psm1'
        'tests/infrastructure/MeAndAI.TestWorkspace.psm1'
    )
    Supports = @(
        'tests/capabilities/initial-adoption/fixtures/Invoke-QuickAdoptionSource.ps1'
    )
    Mocks = @(
        'tests/capabilities/consumer-update/fixtures/Invoke-MockProtocolUpdateGh.ps1'
        'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodex.ps1'
        'tests/capabilities/initial-adoption/fixtures/Invoke-MockCodexEventProcess.ps1'
        'tests/capabilities/initial-adoption/fixtures/Invoke-MockQuickAdoptionRuntimeGh.ps1'
    )
    Cases = @(
        'tests/capabilities/consumer-update/protocol-update-adapter.case.ps1'
        'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter-drift.case.ps1'
        'tests/capabilities/initial-adoption/capabilities-bootstrap-adapter.case.ps1'
        'tests/capabilities/initial-adoption/capabilities-bootstrap-graph-identity.case.ps1'
        'tests/capabilities/initial-adoption/source-graph-dispatch.case.ps1'
    )
    InertFixtures = @(
        'tests/capabilities/test-architecture/fixtures/helper-ownership/helper-ownership.psd1.fixture'
    )
    ReviewedInertExceptions = @(
        @{
            Path = 'tests/capabilities/consumer-update/fixtures/legacy-pre-engine-consumer/Verify-MeAndAIAdoption.ps1'
            Role = 'Fixture'
            ExpectedViolationCodes = @(
                'Assertion', 'ConcreteTestIdentity', 'FailureAggregation'
            )
            Reason = 'Frozen pre-engine consumer snapshot; tracked bytes are inert and execute only after copying into an isolated derived consumer.'
            ReviewAuthority = 'DEC-0029 / TEST-0125 / TEST-0138'
        }
        @{
            Path = 'tests/capabilities/test-architecture/fixtures/helper-ownership/owner.psm1.fixture'
            Role = 'Fixture'
            ExpectedViolationCodes = @('Assertion')
            Reason = 'Inert AST owner input for TEST-0184; it is parsed after copying and is never a runtime test owner.'
            ReviewAuthority = 'DEC-0029 / TEST-0184'
        }
        @{
            Path = 'tests/capabilities/test-architecture/fixtures/helper-ownership/unauthorized.ps1.fixture'
            Role = 'Fixture'
            ExpectedViolationCodes = @('Assertion')
            Reason = 'Inert AST rejection input for TEST-0184; it is parsed after copying and is never a runtime test owner.'
            ReviewAuthority = 'DEC-0029 / TEST-0184'
        }
        @{
            Path = 'tests/capabilities/test-architecture/fixtures/runtime-scenario-identity/scenario-ownership.psd1.fixture'
            Role = 'Fixture'
            ExpectedViolationCodes = @('ConcreteTestIdentity')
            Reason = 'Inert isolated authority data for TEST-0185; its synthetic TEST identities are parsed as data and never complete repository tests.'
            ReviewAuthority = 'DEC-0029 / TEST-0185'
        }
    )
    Examples = @(
        @{ Path = 'runner-positive.ps1.fixture'; Role = 'Runner'; ExpectedViolationCodes = @() }
        @{ Path = 'harness-positive.psm1.fixture'; Role = 'Harness'; ExpectedViolationCodes = @() }
        @{ Path = 'case-positive.ps1.fixture'; Role = 'Case'; ExpectedViolationCodes = @() }
        @{ Path = 'support-positive.ps1.fixture'; Role = 'Support'; ExpectedViolationCodes = @() }
        @{ Path = 'fixture-positive.ps1.fixture'; Role = 'Fixture'; ExpectedViolationCodes = @() }
        @{ Path = 'mock-positive.ps1.fixture'; Role = 'Mock'; ExpectedViolationCodes = @() }
        @{ Path = 'runner-test-identity.ps1.fixture'; Role = 'Runner'; ExpectedViolationCodes = @('ConcreteTestIdentity') }
        @{ Path = 'runner-assertion.ps1.fixture'; Role = 'Runner'; ExpectedViolationCodes = @('Assertion') }
        @{ Path = 'runner-completion.ps1.fixture'; Role = 'Runner'; ExpectedViolationCodes = @('CaseCompletion') }
        @{ Path = 'runner-result-emission.ps1.fixture'; Role = 'Runner'; ExpectedViolationCodes = @('ScenarioResultEmission') }
        @{ Path = 'harness-test-identity.psm1.fixture'; Role = 'Harness'; ExpectedViolationCodes = @('ConcreteTestIdentity') }
        @{ Path = 'support-assertion.ps1.fixture'; Role = 'Support'; ExpectedViolationCodes = @('Assertion') }
        @{ Path = 'fixture-failure-aggregation.ps1.fixture'; Role = 'Fixture'; ExpectedViolationCodes = @('FailureAggregation') }
        @{ Path = 'mock-completion.ps1.fixture'; Role = 'Mock'; ExpectedViolationCodes = @('CaseCompletion') }
        @{ Path = 'support-result-emission.ps1.fixture'; Role = 'Support'; ExpectedViolationCodes = @('ScenarioResultEmission') }
        @{ Path = 'fixture-suite-dispatch.ps1.fixture'; Role = 'Fixture'; ExpectedViolationCodes = @('CanonicalSuiteDispatch') }
    )
}
