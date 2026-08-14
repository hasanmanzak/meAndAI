using System.Reflection;
using MeAndAI.Protocol.Conformance;
using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceCStructuralTests
{
    private static readonly string[] AbstractionsC =
    [
        "ApplicabilityIntent",
        "ApplicabilityIntentKind",
        "EvaluationFailureIntent",
        "EvaluationIntent",
        "FindingIntent",
        "IRuleEvaluator",
        "RuleApplicabilityInput",
        "RuleEvaluationInput",
    ];

    private static readonly string[] ConformanceC =
    [
        "AcquisitionInstruction",
        "ApplicabilityClosure",
        "ApplicabilityPlan",
        "CatalogSliceEvaluation",
        "CatalogSliceKernel",
        "CompleteCatalogEvaluation",
        "ConformanceKernel",
        "EvaluationAdvanceResult",
        "EvaluationClosure",
        "EvaluationPlan",
        "RuleEvaluation",
        "RuleEvaluationFailure",
        "RuleFinding",
        "SealedAcquisitionAttempt",
        "SealedAcquisitionOutcome",
    ];

    [Fact]
    [Trait("ContractSlice", "C")]
    [Trait("Scenario", "TEST-0210")]
    public void Matches_exact_cumulative_c_public_surface()
    {
        var abstractions = typeof(IRuleEvaluator).Assembly;
        var conformance = typeof(ConformanceKernel).Assembly;

        Assert.Equal(
            AbstractionsC.Order(StringComparer.Ordinal),
            ExportedNames(abstractions, AbstractionsC));
        Assert.Equal(
            ConformanceC.Order(StringComparer.Ordinal),
            ExportedNames(conformance, ConformanceC));
        Assert.Equal(
            95,
            abstractions.GetExportedTypes().Length +
            conformance.GetExportedTypes().Length);
        foreach (var type in AbstractionsC
            .Select(name => RequireType(abstractions, name))
            .Concat(ConformanceC.Select(name => RequireType(conformance, name))))
        {
            if (!type.IsInterface)
            {
                Assert.Empty(type.GetConstructors(
                    BindingFlags.Public |
                    BindingFlags.Instance |
                    BindingFlags.DeclaredOnly));
            }

            Assert.Empty(type.GetFields(
                BindingFlags.Public |
                BindingFlags.Instance |
                BindingFlags.Static |
                BindingFlags.DeclaredOnly));
            Assert.All(
                type.GetProperties(
                    BindingFlags.Public |
                    BindingFlags.Instance |
                    BindingFlags.Static |
                    BindingFlags.DeclaredOnly),
                property => Assert.Null(property.SetMethod));
        }

        Assert.Same(
            ApplicabilityIntentKind.Applicable,
            ApplicabilityIntentKind.Parse("applicable"));
        Assert.Same(
            ApplicabilityIntentKind.NotApplicable,
            ApplicabilityIntentKind.Parse("not-applicable"));
        Assert.Same(
            ApplicabilityIntentKind.Unresolved,
            ApplicabilityIntentKind.Parse("unresolved"));
    }

    private static string[] ExportedNames(
        Assembly assembly,
        IEnumerable<string> expected) =>
        assembly.GetExportedTypes()
            .Where(type => expected.Contains(type.Name, StringComparer.Ordinal))
            .Select(type => type.Name)
            .Order(StringComparer.Ordinal)
            .ToArray();

    private static Type RequireType(Assembly assembly, string name) =>
        assembly.GetType(
            $"{assembly.GetName().Name}.{name}",
            throwOnError: true,
            ignoreCase: false)!;
}
