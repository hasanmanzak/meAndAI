using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCIntentTests
{
    private const string Marker = "TEST-0210-C-BEHAVIOR-RED-0008";
    private const string ProfileName =
        "protocol.profile.consumer-provider-exact-commit-conformance-audit";
    private const string TreeSlot = "protocol.slot.repository-tree";
    private const string GovernedSlot =
        "protocol.slot.repository-governed-text";

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Mints_exact_intents_findings_and_failures()
    {
        CarrierInvariants();
        var calls = new Dictionary<string, int>(StringComparer.Ordinal);
        var callbacks = Callbacks(calls);
        var context = CreateContext(callbacks);

        var evaluations = EvaluationIntentCore.Mint(
            context.Closure,
            CancellationToken.None);
        if (evaluations is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal(
            ["RULE-0001", "RULE-0002", "RULE-0003", "RULE-0004", "RULE-0005"],
            evaluations.Select(item => item.RuleId.Value));
        Assert.Equal(
            [
                RuleEvaluationStatus.Satisfied,
                RuleEvaluationStatus.Violated,
                RuleEvaluationStatus.NotApplicable,
                RuleEvaluationStatus.NotEvaluated,
                RuleEvaluationStatus.NotEvaluated,
            ],
            evaluations.Select(item => item.Status));
        Assert.Equal(1, calls["RULE-0002"]);
        Assert.Equal(1, calls["RULE-0005"]);

        var satisfied = evaluations[0];
        Assert.False(satisfied.IsApplicabilityUnresolved);
        Assert.Empty(satisfied.ApplicabilityReferences);
        Assert.Empty(satisfied.UnresolvedSlotKeys);
        Assert.Empty(satisfied.Findings);
        Assert.Empty(satisfied.Failures);

        var violated = evaluations[1];
        var finding = Assert.Single(violated.Findings);
        var findingDeclaration = context.Fixture.Export.Catalog.Rules[1]
            .Findings.Single(item => item.Code.Equals(finding.Code));
        Assert.Equal("protocol.decision.record-missing", finding.Code.Value);
        Assert.Same(findingDeclaration.Severity, finding.Severity);
        Assert.Same(findingDeclaration.Remediation, finding.Remediation);
        Assert.Equal(QualifiedEvidenceReferenceKind.ContextProof,
            finding.PrimaryReference.Kind);
        Assert.Equal(TreeSlot, finding.PrimaryReference.SlotKey);
        Assert.Empty(finding.RelatedReferences);
        Assert.Empty(violated.Failures);

        var terminalNotApplicable = context.Applicability.TerminalEvaluations
            .Single(item => item.RuleId.Value == "RULE-0003");
        var terminalUnresolved = context.Applicability.TerminalEvaluations
            .Single(item => item.RuleId.Value == "RULE-0004");
        Assert.Same(terminalNotApplicable, evaluations[2]);
        Assert.Same(terminalUnresolved, evaluations[3]);
        Assert.True(evaluations[3].IsApplicabilityUnresolved);

        var failed = evaluations[4];
        var failure = Assert.Single(failed.Failures);
        Assert.Equal(
            "protocol.evaluator.reference-ambiguity",
            failure.Code.Value);
        Assert.Equal(QualifiedEvidenceReferenceKind.ContextProof,
            failure.PrimaryReference.Kind);
        Assert.Equal(TreeSlot, failure.PrimaryReference.SlotKey);
        Assert.Empty(failure.RelatedReferences);

        var repeated = EvaluationIntentCore.Mint(
            context.Closure,
            CancellationToken.None);
        Assert.Equal(2, calls["RULE-0002"]);
        Assert.Equal(2, calls["RULE-0005"]);
        Assert.Equal(
            evaluations.Select(item => (item.RuleId.Value, item.Status.Value)),
            repeated.Select(item => (item.RuleId.Value, item.Status.Value)));

        using (var cancellation = new CancellationTokenSource())
        {
            cancellation.Cancel();
            Assert.Throws<OperationCanceledException>(() =>
                EvaluationIntentCore.Mint(context.Closure, cancellation.Token));
        }
        Assert.Equal(2, calls["RULE-0002"]);
        Assert.Equal(2, calls["RULE-0005"]);

        var incompleteCalls = new Dictionary<string, int>(StringComparer.Ordinal);
        var incomplete = CreateContext(
            Callbacks(incompleteCalls),
            incompleteSlot: GovernedSlot);
        var incompleteResults = EvaluationIntentCore.Mint(
            incomplete.Closure,
            CancellationToken.None);
        Assert.Empty(incompleteCalls);
        var unresolved = incompleteResults.Single(item =>
            item.RuleId.Value == "RULE-0005");
        Assert.Equal(RuleEvaluationStatus.NotEvaluated, unresolved.Status);
        Assert.False(unresolved.IsApplicabilityUnresolved);
        Assert.Equal([GovernedSlot], unresolved.UnresolvedSlotKeys);
        Assert.Empty(unresolved.Findings);
        Assert.Empty(unresolved.Failures);

        var foreign = CreateContext(new Dictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>>(StringComparer.Ordinal)
        {
            ["RULE-0002"] = input => EvaluationIntent.Create(
                [FindingIntent.Create(
                    FindingCode.Parse("protocol.decision.record-missing"),
                    QualifiedEvidenceHandle.Create(),
                    [])],
                []),
        });
        AssertIntentInvalid(() => EvaluationIntentCore.Mint(
            foreign.Closure,
            CancellationToken.None));

        var throwing = CreateContext(new Dictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>>(StringComparer.Ordinal)
        {
            ["RULE-0001"] = _ => throw new InvalidOperationException("host-failure"),
        });
        var hostFailure = Assert.Throws<InvalidOperationException>(() =>
            EvaluationIntentCore.Mint(throwing.Closure, CancellationToken.None));
        Assert.Equal("host-failure", hostFailure.Message);

        var duplicate = new EvaluationClosure(
            context.Closure.CompletedRoundCount,
            context.Closure.Applicability,
            context.Closure.Context,
            context.Closure.Acquisitions.Concat([context.Closure.Acquisitions[0]]),
            context.Closure.TerminalEvaluations);
        AssertPlanInvalid(() => EvaluationIntentCore.Mint(
            duplicate,
            CancellationToken.None));
    }

    private static IReadOnlyDictionary<string,
        Func<RuleEvaluationInput, EvaluationIntent>> Callbacks(
        IDictionary<string, int> calls) =>
        new Dictionary<string, Func<RuleEvaluationInput, EvaluationIntent>>(
            StringComparer.Ordinal)
        {
            ["RULE-0002"] = input =>
            {
                Increment(calls, "RULE-0002");
                return EvaluationIntent.Create(
                    [FindingIntent.Create(
                        FindingCode.Parse("protocol.decision.record-missing"),
                        input.GetContextProof(TreeSlot),
                        [])],
                    []);
            },
            ["RULE-0005"] = input =>
            {
                Increment(calls, "RULE-0005");
                return EvaluationIntent.Create(
                    [],
                    [EvaluationFailureIntent.Create(
                        EvaluationFailureCode.Parse(
                            "protocol.evaluator.reference-ambiguity"),
                        input.GetContextProof(TreeSlot),
                        [])]);
            },
        };

    internal static MintingContext CreateContext(
        IReadOnlyDictionary<string,
            Func<RuleEvaluationInput, EvaluationIntent>> callbacks,
        string? incompleteSlot = null,
        IReadOnlyDictionary<string,
            Func<RuleApplicabilityInput, ApplicabilityIntent>>?
            applicabilityByRule = null)
    {
        var fixture = ContractSliceCApplicabilityClosureTests.CreateFixture(
            evaluationReady: true,
            evaluationByRule: callbacks,
            applicabilityByRule: applicabilityByRule);
        Assert.Single(fixture.Export.DemandProjectorRegistrations)
            .Accept(ProjectorVisitor.Instance)
            .Configure([]);
        var proof = new ContractSliceCActivationProof(
            fixture.Manifest,
            fixture.Export,
            fixture.Candidates);
        var kernel = ConformanceKernel.Activate(
            fixture.Manifest,
            fixture.Export,
            proof,
            predecessor: null);
        var profile = kernel.ResolveNamedProfile(ProfileName);
        var plan = kernel.PlanApplicability(
            profile,
            [fixture.ProviderTarget, fixture.RepositoryTarget]);
        var applicability = kernel.CloseApplicability(plan, fixture.Proofs);
        var evaluationPlan = Assert.IsType<EvaluationPlan>(
            kernel.PlanEvaluation(applicability));
        var observed = evaluationPlan.Instructions.Select(instruction =>
            CObservedQualificationProof.Create(
                fixture.Manifest,
                instruction,
                complete: !string.Equals(
                    instruction.Slot.SlotKey,
                    incompleteSlot,
                    StringComparison.Ordinal))).ToArray();
        proof.Authorize(observed);
        var closure = Assert.IsType<EvaluationClosure>(kernel.AdvanceEvaluation(
            evaluationPlan,
            AcquisitionProofSet.Create(observed, [], [])));
        return new MintingContext(
            fixture,
            kernel,
            profile,
            applicability,
            closure);
    }

    private static void CarrierInvariants()
    {
        var handle = QualifiedEvidenceHandle.Create();
        var other = QualifiedEvidenceHandle.Create();
        var applicability = new List<QualifiedEvidenceHandle> { handle };
        var intent = ApplicabilityIntent.NotApplicable(applicability);
        applicability.Clear();
        Assert.Same(handle, Assert.Single(intent.References));
        Assert.Throws<ArgumentException>(() =>
            ApplicabilityIntent.Applicable([handle, handle]));

        var related = new List<QualifiedEvidenceHandle> { other };
        var finding = FindingIntent.Create(
            FindingCode.Parse("protocol.decision.record-missing"),
            handle,
            related);
        related.Clear();
        Assert.Same(other, Assert.Single(finding.RelatedReferences));
        Assert.Throws<ArgumentException>(() => FindingIntent.Create(
            finding.Code,
            handle,
            [handle]));

        var failure = EvaluationFailureIntent.Create(
            EvaluationFailureCode.Parse(
                "protocol.evaluator.reference-ambiguity"),
            handle,
            [other]);
        Assert.Throws<ArgumentException>(() => EvaluationFailureIntent.Create(
            failure.Code,
            handle,
            [other, other]));
        Assert.Throws<ArgumentException>(() => EvaluationIntent.Create(
            [finding, FindingIntent.Create(finding.Code, handle, [other])],
            []));
        Assert.Throws<ArgumentException>(() => EvaluationIntent.Create(
            [],
            [failure, EvaluationFailureIntent.Create(
                failure.Code,
                handle,
                [other])]));
    }

    private static void Increment(IDictionary<string, int> calls, string ruleId) =>
        calls[ruleId] = calls.TryGetValue(ruleId, out var count) ? count + 1 : 1;

    private static void AssertIntentInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.IntentInvalid, error.Code);
    }

    private static void AssertPlanInvalid(Action action)
    {
        var error = Assert.Throws<CatalogIntegrityException>(action);
        Assert.Equal(CatalogIntegrityCode.PlanStateInvalid, error.Code);
    }

    internal sealed record MintingContext(
        ContractSliceCApplicabilityClosureTests.ClosureFixture Fixture,
        ConformanceKernel Kernel,
        NamedExecutionProfile Profile,
        ApplicabilityClosure Applicability,
        EvaluationClosure Closure);

    private sealed class ProjectorVisitor :
        IDemandProjectorRegistrationVisitor<RepositoryTargetProjectorMirror>
    {
        internal static ProjectorVisitor Instance { get; } = new();

        public RepositoryTargetProjectorMirror Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability =>
            Assert.IsType<RepositoryTargetProjectorMirror>(registration.Projector);
    }
}
