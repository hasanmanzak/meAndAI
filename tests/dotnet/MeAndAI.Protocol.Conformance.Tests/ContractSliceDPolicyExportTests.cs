using System.Reflection;
using System.Runtime.CompilerServices;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;
using MeAndAI.Protocol.Policy;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceDPolicyExportTests
{
    private const string Marker = "TEST-0210-D-BEHAVIOR-RED-0001";

    private static readonly string[] ExpectedImplementationComponents =
    [
        "protocol.codec.governed-text|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec",
        "protocol.codec.repository-target-resolution|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec",
        "protocol.codec.repository-tree|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec",
        "protocol.evaluator.rule-0001|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Rules.FeaturePacketRuleEvaluator",
        "protocol.evaluator.rule-0002|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Rules.DecisionRecordRuleEvaluator",
        "protocol.evaluator.rule-0003|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Rules.ClickableExactTargetRuleEvaluator",
        "protocol.evaluator.rule-0004|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Rules.StableFragmentRuleEvaluator",
        "protocol.evaluator.rule-0005|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Rules.CommitPermalinkRuleEvaluator",
        "protocol.index.governed-reference|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex",
        "protocol.index.protocol-record|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex",
        "protocol.index.repository-target-resolution|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex",
        "protocol.index.repository-tree|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex",
        "protocol.parser.markdown|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser",
        "protocol.parser.repository-target-markdown|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser",
        "protocol.projector.repository-target-resolution-demand|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector",
        "protocol.selector.decision-record|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Selectors.DecisionRecordSelectorResolver",
        "protocol.selector.feature-readme|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Selectors.FeatureReadmeSelectorResolver",
        "protocol.selector.feature-test-cases|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Selectors.FeatureTestCasesSelectorResolver",
    ];

    private static readonly string[] ExpectedTypeComponents =
    [
        "protocol.type.capability.governed-reference-index|MeAndAI.Protocol.Conformance.Abstractions|MeAndAI.Protocol.Conformance.Abstractions.IGovernedReferenceIndex",
        "protocol.type.capability.protocol-record-index|MeAndAI.Protocol.Conformance.Abstractions|MeAndAI.Protocol.Conformance.Abstractions.IProtocolRecordIndex",
        "protocol.type.capability.repository-target-resolution-index|MeAndAI.Protocol.Conformance.Abstractions|MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTargetResolutionIndex",
        "protocol.type.capability.repository-tree|MeAndAI.Protocol.Conformance.Abstractions|MeAndAI.Protocol.Conformance.Abstractions.IRepositoryTree",
        "protocol.type.model.markdown-document|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel",
        "protocol.type.model.repository-target-markdown-document-set|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel",
        "protocol.type.model.repository-target-resolution|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel",
        "protocol.type.model.repository-tree|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Models.RepositoryTreeModel",
        "protocol.type.model.source-text|MeAndAI.Protocol.Policy|MeAndAI.Protocol.Policy.Models.SourceTextModel",
    ];

    [Fact]
    [Trait("ContractSlice", "D")]
    [Trait("Scenario", "TEST-0210")]
    public void Exports_exact_real_registration_graph()
    {
        PolicyQualificationSliceExport export =
            InitialRuleQualificationPolicy.Export;
        if (export is null)
        {
            Assert.Fail(Marker);
        }

        Assert.Equal("protocol.policy.initial-rule-qualification", export.ExportKey);
        Assert.Equal("1", export.ExportVersion);
        Assert.Equal("protocol.catalog-slice.initial-common-rules", export.Catalog.SliceKey);
        Assert.Equal("1", export.Catalog.SliceVersion);
        Assert.Equal("0.17.0", export.Catalog.ProtocolVersion);
        Assert.Equal(1, export.Catalog.CatalogVersion.Value);
        Assert.Equal(
            ["RULE-0001", "RULE-0002", "RULE-0003", "RULE-0004", "RULE-0005"],
            export.Catalog.Rules.Select(rule => rule.RuleId.Value));

        Assert.Equal(3, export.CodecRegistrations.Count);
        Assert.Equal(2, export.ParserRegistrations.Count);
        Assert.Equal(4, export.IndexRegistrations.Count);
        Assert.Single(export.DemandProjectorRegistrations);
        Assert.Equal(3, export.SelectorRegistrations.Count);
        Assert.Equal(5, export.EvaluatorRegistrations.Count);

        Assert.Equal(
            ExpectedImplementationComponents,
            export.Components.Select(Identity));
        Assert.Equal(
            ExpectedImplementationComponents.Concat(ExpectedTypeComponents)
                .Order(StringComparer.Ordinal),
            LogicalComponents(export));
        Assert.Equal(27, LogicalComponents(export).Count);

        Assert.All(export.EvaluatorRegistrations.Select((item, index) =>
            (item, index)), pair =>
            Assert.Same(export.Catalog.Rules[pair.index], pair.item.Declaration));
        Assert.Equal(
            export.SchemaRegistry.PayloadSchemas,
            export.CodecRegistrations.Select(item => item.Declaration));
        Assert.Equal(
            export.SchemaRegistry.Parsers,
            export.ParserRegistrations.Select(item => item.Declaration));
        Assert.Equal(
            export.SchemaRegistry.Indexes,
            export.IndexRegistrations.Select(item => item.Declaration));
        Assert.Equal(
            export.SchemaRegistry.DemandProjectors,
            export.DemandProjectorRegistrations.Select(item => item.Declaration));
    }

    private static IReadOnlyList<string> LogicalComponents(
        PolicyQualificationSliceExport export)
    {
        var values = export.Components.Select(Identity)
            .Concat(export.CodecRegistrations.SelectMany(item =>
                item.Accept(LogicalComponentVisitor.Instance)))
            .Concat(export.ParserRegistrations.SelectMany(item =>
                item.Accept(LogicalComponentVisitor.Instance)))
            .Concat(export.IndexRegistrations.SelectMany(item =>
                item.Accept(LogicalComponentVisitor.Instance)))
            .Concat(export.DemandProjectorRegistrations.SelectMany(item =>
                item.Accept(LogicalComponentVisitor.Instance)))
            .Distinct(StringComparer.Ordinal)
            .Order(StringComparer.Ordinal)
            .ToArray();
        return Array.AsReadOnly(values);
    }

    private static string Identity(ComponentTypeIdentity value) =>
        $"{value.ComponentKey}|{value.AssemblyName}|{value.TypeName}";

    private sealed class LogicalComponentVisitor :
        ICodecRegistrationVisitor<IReadOnlyList<string>>,
        IParserRegistrationVisitor<IReadOnlyList<string>>,
        IIndexRegistrationVisitor<IReadOnlyList<string>>,
        IDemandProjectorRegistrationVisitor<IReadOnlyList<string>>
    {
        internal static LogicalComponentVisitor Instance { get; } = new();

        public IReadOnlyList<string> Visit<TModel>(
            CodecRegistration<TModel> registration)
            where TModel : class, IProtocolSemanticModel =>
            [Identity(registration.OutputModel.Contract.ImplementationType)];

        public IReadOnlyList<string> Visit<TInput, TOutput>(
            ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel =>
            [Identity(registration.OutputModel.Contract.ImplementationType)];

        public IReadOnlyList<string> Visit<TInput, TCapability>(
            IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability =>
            [Identity(registration.OutputCapability.Contract.InterfaceType)];

        public IReadOnlyList<string> Visit<TCapability>(
            DemandProjectorRegistration<TCapability> registration)
            where TCapability : class, IEvidenceCapability => [];
    }
}

public sealed class ContractSliceDOwnershipTests
{
    private static readonly string[] InternalPolicyTypes =
    [
        "MeAndAI.Protocol.Policy.Codecs.GovernedTextCodec",
        "MeAndAI.Protocol.Policy.Codecs.RepositoryTargetResolutionCodec",
        "MeAndAI.Protocol.Policy.Codecs.RepositoryTreeCodec",
        "MeAndAI.Protocol.Policy.Demands.RepositoryTargetResolutionDemandProjector",
        "MeAndAI.Protocol.Policy.Indexes.GovernedReferenceIndex",
        "MeAndAI.Protocol.Policy.Indexes.ProtocolRecordIndex",
        "MeAndAI.Protocol.Policy.Indexes.RepositoryTargetResolutionIndex",
        "MeAndAI.Protocol.Policy.Indexes.RepositoryTreeIndex",
        "MeAndAI.Protocol.Policy.Models.MarkdownDocumentModel",
        "MeAndAI.Protocol.Policy.Models.RepositoryTargetMarkdownDocumentSetModel",
        "MeAndAI.Protocol.Policy.Models.RepositoryTargetResolutionModel",
        "MeAndAI.Protocol.Policy.Models.RepositoryTreeModel",
        "MeAndAI.Protocol.Policy.Models.SourceTextModel",
        "MeAndAI.Protocol.Policy.Parsers.MarkdownDocumentParser",
        "MeAndAI.Protocol.Policy.Parsers.RepositoryTargetMarkdownDocumentParser",
        "MeAndAI.Protocol.Policy.Rules.ClickableExactTargetRuleEvaluator",
        "MeAndAI.Protocol.Policy.Rules.CommitPermalinkRuleEvaluator",
        "MeAndAI.Protocol.Policy.Rules.DecisionRecordRuleEvaluator",
        "MeAndAI.Protocol.Policy.Rules.FeaturePacketRuleEvaluator",
        "MeAndAI.Protocol.Policy.Rules.StableFragmentRuleEvaluator",
        "MeAndAI.Protocol.Policy.Selectors.DecisionRecordSelectorResolver",
        "MeAndAI.Protocol.Policy.Selectors.FeatureReadmeSelectorResolver",
        "MeAndAI.Protocol.Policy.Selectors.FeatureTestCasesSelectorResolver",
    ];

    [Fact]
    [Trait("ContractSlice", "D")]
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_exact_policy_friend_and_negative_surface()
    {
        var abstractions = typeof(PolicyQualificationSliceExport).Assembly;
        var conformance = typeof(ConformanceKernel).Assembly;
        var domain = typeof(RuleId).Assembly;
        var policy = typeof(InitialRuleQualificationPolicy).Assembly;

        Assert.Equal(
            [
                "MeAndAI.Protocol.Conformance",
                "MeAndAI.Protocol.Conformance.Tests",
                "MeAndAI.Protocol.Policy",
            ],
            Friends(abstractions));
        Assert.Equal(["MeAndAI.Protocol.Conformance.Tests"], Friends(conformance));
        Assert.Equal(["MeAndAI.Protocol.Conformance.Tests"], Friends(policy));
        Assert.DoesNotContain(abstractions.GetReferencedAssemblies(),
            assembly => assembly.Name == "MeAndAI.Protocol.Policy");
        Assert.DoesNotContain(conformance.GetReferencedAssemblies(),
            assembly => assembly.Name == "MeAndAI.Protocol.Policy");
        Assert.DoesNotContain(domain.GetReferencedAssemblies(),
            assembly => assembly.Name == "MeAndAI.Protocol.Policy");

        Assert.All(InternalPolicyTypes, name =>
        {
            var type = policy.GetType(name, throwOnError: true, ignoreCase: false)!;
            Assert.False(type.IsPublic || type.IsNestedPublic, name);
        });
    }

    private static string[] Friends(Assembly assembly) => assembly
        .GetCustomAttributes<InternalsVisibleToAttribute>()
        .Select(attribute => attribute.AssemblyName)
        .Order(StringComparer.Ordinal)
        .ToArray();
}

public sealed class ContractSliceDStructuralTests
{
    [Fact]
    [Trait("ContractSlice", "D")]
    [Trait("Scenario", "TEST-0210")]
    public void Matches_exact_final_cumulative_public_surface()
    {
        var abstractions = typeof(PolicyQualificationSliceExport).Assembly;
        var conformance = typeof(ConformanceKernel).Assembly;
        var domain = typeof(RuleId).Assembly;
        var policy = typeof(InitialRuleQualificationPolicy).Assembly;

        ProtectedPolicySurfaceTests.AssertPredecessorInventory(
            abstractions,
            ProtectedPolicySurfaceTests.PredecessorAbstractionsTypes);
        ProtectedPolicySurfaceTests.AssertPredecessorInventory(
            conformance,
            ProtectedPolicySurfaceTests.PredecessorConformanceTypes);
        ProtectedPolicySurfaceTests.AssertPredecessorInventory(
            domain,
            ProtectedPolicySurfaceTests.PredecessorDomainTypes);
        ProtectedPolicySurfaceTests.AssertPredecessorInventory(
            policy,
            ProtectedPolicySurfaceTests.PredecessorPolicyTypes);

        var type = typeof(InitialRuleQualificationPolicy);
        Assert.True(type.IsPublic && type.IsAbstract && type.IsSealed);
        Assert.Empty(type.GetConstructors(
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static));
        Assert.Empty(type.GetFields(
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static));
        var property = Assert.Single(type.GetProperties(
            BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly));
        Assert.Equal("Export", property.Name);
        Assert.Equal(typeof(PolicyQualificationSliceExport), property.PropertyType);
        Assert.NotNull(property.GetMethod);
        Assert.Null(property.SetMethod);
        Assert.DoesNotContain(
            type.GetMethods(
                BindingFlags.Public | BindingFlags.Static | BindingFlags.DeclaredOnly),
            method => !method.IsSpecialName);
    }
}
