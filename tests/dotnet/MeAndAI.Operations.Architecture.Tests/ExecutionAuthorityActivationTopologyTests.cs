using System.Reflection;

namespace MeAndAI.Operations.Architecture.Tests;

public sealed class ExecutionAuthorityActivationTopologyTests
{
    private const string Scenario = "TEST-0212";
    private const string Subfeature = "SUBF-0145";
    private const string TopologyFqn =
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthorityActivationTopologyTests.Matches_exact_execution_authority_scenario_inventory";

    [Fact]
    public void Matches_exact_execution_authority_scenario_inventory()
    {
        var expected = FrozenFqns();
        var allRows = typeof(ExecutionAuthorityActivationTopologyTests).Assembly
            .GetTypes()
            .SelectMany(type => type.GetMethods(
                    BindingFlags.Public | BindingFlags.Instance |
                    BindingFlags.Static | BindingFlags.DeclaredOnly)
                .Select(method => Row(type, method)))
            .Where(row => row.Facts + row.Theories != 0)
            .OrderBy(row => row.Fqn, StringComparer.Ordinal)
            .ToArray();
        var rows = allRows
            .Where(row => row.MethodName.StartsWith(
                "TEST_0212_", StringComparison.Ordinal))
            .ToArray();

        Assert.Equal(expected, rows.Select(row => row.Fqn).ToArray());
        Assert.Equal(20, rows.Length);
        Assert.All(rows, row =>
        {
            Assert.Equal(1, row.Facts);
            Assert.Equal(0, row.Theories);
            Assert.Equal([Subfeature], row.Subfeatures);
            Assert.Equal([Scenario], row.Scenarios);
            Assert.Empty(row.ClassSubfeatures);
            Assert.Empty(row.ClassScenarios);
        });

        var scenarioFqns = allRows
            .Where(row => row.Scenarios.Contains(Scenario, StringComparer.Ordinal) ||
                row.ClassScenarios.Contains(Scenario, StringComparer.Ordinal))
            .Select(row => row.Fqn)
            .OrderBy(fqn => fqn, StringComparer.Ordinal)
            .ToArray();
        var subfeatureFqns = allRows
            .Where(row => row.Subfeatures.Contains(Subfeature, StringComparer.Ordinal) ||
                row.ClassSubfeatures.Contains(Subfeature, StringComparer.Ordinal))
            .Select(row => row.Fqn)
            .OrderBy(fqn => fqn, StringComparer.Ordinal)
            .ToArray();
        Assert.Equal(expected, scenarioFqns);
        Assert.Equal(expected, subfeatureFqns);

        var topology = Assert.Single(allRows, row => row.Fqn == TopologyFqn);
        Assert.Equal(1, topology.Facts);
        Assert.Equal(0, topology.Theories);
        Assert.Empty(topology.Subfeatures);
        Assert.Empty(topology.Scenarios);
        Assert.Empty(topology.ClassSubfeatures);
        Assert.Empty(topology.ClassScenarios);
    }

    private static TopologyRow Row(Type type, MethodInfo method)
    {
        var methodAttributes = method.CustomAttributes.ToArray();
        var classAttributes = type.CustomAttributes.ToArray();
        return new(
            method.Name,
            $"{type.FullName}.{method.Name}",
            Count(methodAttributes, "Xunit.FactAttribute"),
            Count(methodAttributes, "Xunit.TheoryAttribute"),
            Traits(methodAttributes, "Subfeature"),
            Traits(methodAttributes, "Scenario"),
            Traits(classAttributes, "Subfeature"),
            Traits(classAttributes, "Scenario"));
    }

    private static int Count(
        IEnumerable<CustomAttributeData> attributes,
        string typeName) =>
        attributes.Count(attribute => attribute.AttributeType.FullName == typeName);

    private static string[] Traits(
        IEnumerable<CustomAttributeData> attributes,
        string name) =>
        attributes.Where(attribute =>
                attribute.AttributeType.FullName == "Xunit.TraitAttribute" &&
                attribute.ConstructorArguments.Count == 2 &&
                string.Equals(
                    (string?)attribute.ConstructorArguments[0].Value,
                    name,
                    StringComparison.Ordinal))
            .Select(attribute => (string)attribute.ConstructorArguments[1].Value!)
            .ToArray();

    private static string[] FrozenFqns() =>
    [
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthorityPortTests.TEST_0212_authorizer_factory_rejects_null_ports_by_name",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthorityPortTests.TEST_0212_execution_authority_ports_are_least_authority",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthorityPublicApiTests.TEST_0212_grant_public_api_matches_the_frozen_contract",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthorityPublicApiTests.TEST_0212_snapshot_public_api_matches_the_frozen_contract",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_approval_floors_and_solo_crossings_fail_closed",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_scalar_values_are_canonical_and_closed",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_snapshot_and_role_separation_are_exact",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_snapshot_rejects_incomplete_or_ambiguous_authority",
        "MeAndAI.Operations.Architecture.Tests.ExecutionAuthoritySnapshotTests.TEST_0212_solo_maintainer_exception_is_exact_and_pair_scoped",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_all_capability_binding_pairs_are_non_transitive",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_approval_separation_drift_and_validity_edges_fail_closed",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_atomic_mutation_rechecks_replay_authority_and_store_head",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_first_failure_order_and_pre_mutation_store_checks_are_exact",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_grant_is_fresh_exact_non_transitive_and_single_use",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_grant_values_are_canonical_defensive_and_closed",
        "MeAndAI.Operations.Architecture.Tests.ExecutionGrantContractTests.TEST_0212_pre_cancellation_performs_no_port_call",
        "MeAndAI.Operations.Architecture.Tests.ExtensionActivationContractTests.TEST_0212_only_fresh_winning_cas_activates_extension",
        "MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_binds_sealed_report_and_publication_grant",
        "MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_has_exact_value_equality",
        "MeAndAI.Operations.Architecture.Tests.PublicationEnvelopeContractTests.TEST_0212_envelope_rejects_nonpublication_or_disagreeing_grants"
    ];

    private sealed record TopologyRow(
        string MethodName,
        string Fqn,
        int Facts,
        int Theories,
        string[] Subfeatures,
        string[] Scenarios,
        string[] ClassSubfeatures,
        string[] ClassScenarios);
}
