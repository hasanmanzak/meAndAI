using System.Reflection;
using System.Security.Cryptography;
using System.Text;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ProtectedPolicyConvergenceTests
{
    private const string ScenarioTrait = "Scenario=TEST-0211";
    private const string ConformanceOwner =
        "tests/dotnet/MeAndAI.Protocol.Conformance.Tests/" +
        "MeAndAI.Protocol.Conformance.Tests.csproj";
    private const string FeatureOwner =
        "docs/features/FEAT-0065-shared-executable-conformance-runtime/" +
        "test-cases.md";
    private const string ProtocolCommandPrefix =
        "dotnet test MeAndAI.Protocol.slnx --configuration Release " +
        "--no-restore --nologo --verbosity minimal --filter \"";
    private const string FilterPrefix =
        "Scenario=TEST-" + "0220|Scenario=TEST-" +
        "0221|Scenario=TEST-" + "0210";
    private const string FilterSuffix =
        "|ContractSlice=A|ContractSlice=B|ContractSlice=C|ContractSlice=D" +
        "|FullyQualifiedName=MeAndAI.Protocol.Conformance.Tests." +
        "ContractSliceActivationTopologyTests." +
        "Matches_exact_contract_slice_scenario_inventory";
    private const string WorkflowStepName =
        "name: Run protocol-domain vocabulary tests";
    private const string InventoryDigest =
        "ACD4354E28B3640B3B10E8C8FFD336D95C282EAB1965611038C59D7403B6D024";

    private static readonly string[] FrozenFqns =
    [
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyConvergenceTests.Evaluates_protected_baseline_extensions_dispositions_and_self_consumption",
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyDebtEnforcementTests.Applies_exact_debt_and_enforcement_precedence",
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyExtensionAuthorityTests.Keeps_active_extension_authority_separate_from_candidate_proposal",
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyExtensionEvaluationTests.Evaluates_only_protocol_owned_additive_extension_kinds",
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicySelfConsumptionTests.Rejects_candidate_only_and_unreviewed_differential_authority",
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicySurfaceTests.Exposes_exact_extension_waiver_debt_and_self_consumption_surface",
        "MeAndAI.Protocol.Conformance.Tests.ProtectedPolicyWaiverDispositionTests.Applies_exact_waiver_identity_expiry_and_nonwaivable_rules",
    ];

    private static readonly string PredecessorExecutableOwner = Lines(
        "Evidence = 'DotNetTestProject'",
        $"            Owner = '{ConformanceOwner}'",
        "            TestIds = @('TEST-" + "0210')");

    private static readonly string ActivatedExecutableOwner = Lines(
        "Evidence = 'DotNetTestProject'",
        $"            Owner = '{ConformanceOwner}'",
        "            TestIds = @('TEST-" + "0210', 'TEST-" + "0211')");

    private static readonly string PredecessorPlannedOwner = Lines(
        "Evidence = 'PlannedDocumentation'",
        $"            Owner = '{FeatureOwner}'",
        "            TestIds = @(",
        "                'TEST-" + "0209', 'TEST-" + "0211', 'TEST-" + "0222'",
        "            )");

    private static readonly string ActivatedPlannedOwner = Lines(
        "Evidence = 'PlannedDocumentation'",
        $"            Owner = '{FeatureOwner}'",
        "            TestIds = @(",
        "                'TEST-" + "0209', 'TEST-" + "0222'",
        "            )");

    private static readonly string PredecessorWorkflowCommand =
        ProtocolCommandPrefix + FilterPrefix + FilterSuffix + "\"";

    private static readonly string ActivatedWorkflowCommand =
        ProtocolCommandPrefix + FilterPrefix + "|Scenario=TEST-0211" +
        FilterSuffix + "\"";

    [Fact]
    [Trait("Scenario", "TEST-0211")]
    public void Evaluates_protected_baseline_extensions_dispositions_and_self_consumption()
    {
        new ProtectedPolicySurfaceTests()
            .Exposes_exact_extension_waiver_debt_and_self_consumption_surface();
        new ProtectedPolicyExtensionAuthorityTests()
            .Keeps_active_extension_authority_separate_from_candidate_proposal();
        new ProtectedPolicyExtensionEvaluationTests()
            .Evaluates_only_protocol_owned_additive_extension_kinds();
        new ProtectedPolicyWaiverDispositionTests()
            .Applies_exact_waiver_identity_expiry_and_nonwaivable_rules();
        new ProtectedPolicyDebtEnforcementTests()
            .Applies_exact_debt_and_enforcement_precedence();
        new ProtectedPolicySelfConsumptionTests()
            .Rejects_candidate_only_and_unreviewed_differential_authority();

        var rows = ProtectedPolicyRows();
        Assert.Equal(FrozenFqns, rows.Select(row => row.Fqn).ToArray());
        Assert.Equal(InventoryDigest, Digest(rows.Select(row => row.Fqn)));
        Assert.All(rows, AssertExactFactShape);

        var predecessorTraits = rows.All(row => row.Traits.Length == 0);
        var activatedTraits = rows.All(row =>
            row.Traits.SequenceEqual([ScenarioTrait], StringComparer.Ordinal));
        Assert.True(predecessorTraits ^ activatedTraits);

        var repositoryRoot = FindRepositoryRoot();
        var ownership = ReadNormalized(
            repositoryRoot,
            "tests/scenario-ownership.psd1");
        var workflow = ReadNormalized(
            repositoryRoot,
            ".github/workflows/protocol-tests.yml");

        var predecessorOwner = IsOwnerState(
            ownership,
            PredecessorExecutableOwner,
            PredecessorPlannedOwner,
            ActivatedExecutableOwner,
            ActivatedPlannedOwner);
        var activatedOwner = IsOwnerState(
            ownership,
            ActivatedExecutableOwner,
            ActivatedPlannedOwner,
            PredecessorExecutableOwner,
            PredecessorPlannedOwner);
        Assert.True(predecessorOwner ^ activatedOwner);

        var predecessorWorkflow = IsWorkflowState(
            workflow,
            PredecessorWorkflowCommand,
            ActivatedWorkflowCommand,
            expectedScenarioOccurrences: 0);
        var activatedWorkflow = IsWorkflowState(
            workflow,
            ActivatedWorkflowCommand,
            PredecessorWorkflowCommand,
            expectedScenarioOccurrences: 2);
        Assert.True(predecessorWorkflow ^ activatedWorkflow);

        var predecessor = predecessorTraits &&
            predecessorOwner && predecessorWorkflow;
        var activated = activatedTraits && activatedOwner && activatedWorkflow;
        Assert.True(predecessor ^ activated);

        Assert.True(activated);
    }

    private static TopologyRow[] ProtectedPolicyRows()
    {
        return typeof(ProtectedPolicyConvergenceTests).Assembly
            .GetTypes()
            .Where(type =>
                type.Namespace == typeof(ProtectedPolicyConvergenceTests).Namespace &&
                type.Name.StartsWith("ProtectedPolicy", StringComparison.Ordinal) &&
                type.Name.EndsWith("Tests", StringComparison.Ordinal))
            .SelectMany(type => type.GetMethods(
                    BindingFlags.Public |
                    BindingFlags.Instance |
                    BindingFlags.Static |
                    BindingFlags.DeclaredOnly)
                .Where(method => method.CustomAttributes.Any(attribute =>
                    attribute.AttributeType.FullName is
                        "Xunit.FactAttribute" or "Xunit.TheoryAttribute"))
                .Select(method => Row(type, method)))
            .OrderBy(row => row.Fqn, StringComparer.Ordinal)
            .ToArray();
    }

    private static TopologyRow Row(Type type, MethodInfo method)
    {
        var methodAttributes = method.CustomAttributes.ToArray();
        var classAttributes = type.CustomAttributes.ToArray();
        var factAttributes = methodAttributes.Where(attribute =>
            attribute.AttributeType.FullName == "Xunit.FactAttribute").ToArray();

        return new(
            $"{type.FullName}.{method.Name}",
            factAttributes.Length,
            methodAttributes.Count(attribute =>
                attribute.AttributeType.FullName == "Xunit.TheoryAttribute"),
            factAttributes.Sum(attribute => attribute.NamedArguments.Count),
            Traits(methodAttributes),
            Traits(classAttributes),
            type.IsPublic,
            type.IsSealed,
            method.IsPublic,
            method.IsStatic,
            method.IsGenericMethod,
            method.ReturnType,
            method.GetParameters().Length);
    }

    private static string[] Traits(IEnumerable<CustomAttributeData> attributes) =>
        attributes.Where(attribute =>
                attribute.AttributeType.FullName == "Xunit.TraitAttribute" &&
                attribute.ConstructorArguments.Count == 2)
            .Select(attribute =>
                $"{attribute.ConstructorArguments[0].Value}=" +
                $"{attribute.ConstructorArguments[1].Value}")
            .ToArray();

    private static void AssertExactFactShape(TopologyRow row)
    {
        Assert.Equal(1, row.Facts);
        Assert.Equal(0, row.Theories);
        Assert.Equal(0, row.FactNamedArguments);
        Assert.Empty(row.ClassTraits);
        Assert.True(row.DeclaringTypeIsPublic);
        Assert.True(row.DeclaringTypeIsSealed);
        Assert.True(row.MethodIsPublic);
        Assert.False(row.MethodIsStatic);
        Assert.False(row.MethodIsGeneric);
        Assert.Equal(typeof(void), row.ReturnType);
        Assert.Equal(0, row.ParameterCount);
    }

    private static bool IsOwnerState(
        string source,
        string expectedExecutable,
        string expectedPlanned,
        string otherExecutable,
        string otherPlanned) =>
        CountOccurrences(source, ConformanceOwner) == 1 &&
        CountOccurrences(source, FeatureOwner) == 1 &&
        CountOccurrences(source, "'TEST-0211'") == 1 &&
        CountOccurrences(source, expectedExecutable) == 1 &&
        CountOccurrences(source, expectedPlanned) == 1 &&
        CountOccurrences(source, otherExecutable) == 0 &&
        CountOccurrences(source, otherPlanned) == 0;

    private static bool IsWorkflowState(
        string source,
        string expectedCommand,
        string otherCommand,
        int expectedScenarioOccurrences)
    {
        var linux = Section(source, "  linux-validation:", "  windows-validation:");
        var windows = Section(source, "  windows-validation:", "  post-publication:");

        return CountOccurrences(source, ProtocolCommandPrefix) == 2 &&
            CountOccurrences(source, WorkflowStepName) == 2 &&
            CountOccurrences(source, "Scenario=TEST-0211") ==
                expectedScenarioOccurrences &&
            CountOccurrences(source, expectedCommand) == 2 &&
            CountOccurrences(source, otherCommand) == 0 &&
            CountOccurrences(linux, WorkflowStepName) == 1 &&
            CountOccurrences(linux, expectedCommand) == 1 &&
            CountOccurrences(windows, WorkflowStepName) == 1 &&
            CountOccurrences(windows, expectedCommand) == 1;
    }

    private static string Section(string source, string start, string end)
    {
        var startIndex = source.IndexOf(start, StringComparison.Ordinal);
        var endIndex = source.IndexOf(end, StringComparison.Ordinal);
        if (startIndex < 0 || endIndex <= startIndex)
        {
            throw new InvalidDataException(
                $"Workflow section '{start}' does not have the exact boundary.");
        }

        return source[startIndex..endIndex];
    }

    private static string ReadNormalized(string repositoryRoot, string relativePath) =>
        File.ReadAllText(Path.Combine(
                repositoryRoot,
                relativePath.Replace('/', Path.DirectorySeparatorChar)))
            .Replace("\r\n", "\n", StringComparison.Ordinal)
            .Replace('\r', '\n');

    private static string FindRepositoryRoot()
    {
        var candidate = new DirectoryInfo(AppContext.BaseDirectory);
        while (candidate is not null)
        {
            if (File.Exists(Path.Combine(candidate.FullName, "MeAndAI.Protocol.slnx")))
            {
                return candidate.FullName;
            }

            candidate = candidate.Parent;
        }

        throw new DirectoryNotFoundException(
            "Could not locate the protocol solution from the test output directory.");
    }

    private static string Digest(IEnumerable<string> values) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(
            string.Join("\n", values) + "\n")));

    private static int CountOccurrences(string source, string value)
    {
        var count = 0;
        var start = 0;
        while ((start = source.IndexOf(value, start, StringComparison.Ordinal)) >= 0)
        {
            count++;
            start += value.Length;
        }

        return count;
    }

    private static string Lines(params string[] values) => string.Join("\n", values);

    private sealed record TopologyRow(
        string Fqn,
        int Facts,
        int Theories,
        int FactNamedArguments,
        string[] Traits,
        string[] ClassTraits,
        bool DeclaringTypeIsPublic,
        bool DeclaringTypeIsSealed,
        bool MethodIsPublic,
        bool MethodIsStatic,
        bool MethodIsGeneric,
        Type ReturnType,
        int ParameterCount);
}
