using System.Reflection;

namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceActivationTopologyTests
{
    private const string Marker = "TEST-0210-D-BEHAVIOR-RED-0009";

    [Fact]
    [Trait("ContractSlice", "D")]
    [Trait("Scenario", "TEST-0210")]
    public void Matches_exact_contract_slice_scenario_inventory()
    {
        var frozen = FrozenInventory();
        var rows = typeof(ContractSliceActivationTopologyTests).Assembly
            .GetTypes()
            .SelectMany(type => type.GetMethods(BindingFlags.Public |
                BindingFlags.Instance | BindingFlags.Static |
                BindingFlags.DeclaredOnly)
                .Select(method => Row(type, method)))
            .Where(row => row.Slices.Length != 0)
            .OrderBy(row => row.Fqn, StringComparer.Ordinal)
            .ToArray();

        Assert.All(rows, row =>
        {
            Assert.Equal(1, row.Facts);
            Assert.Equal(0, row.Theories);
            Assert.Single(row.Slices);
            Assert.Equal(["TEST-0210"], row.Scenarios);
            Assert.Empty(row.ClassSlices);
            Assert.Empty(row.ClassScenarios);
        });

        IReadOnlyDictionary<string, string>? expected = frozen;
        if (expected is null)
        {
            Assert.Fail(Marker);
        }

        var actual = new SortedDictionary<string, string>(StringComparer.Ordinal);
        foreach (var row in rows)
        {
            actual.Add(row.Fqn, row.Slices[0]);
        }

        var scenarioIdentities = rows
            .Where(row => row.Scenarios.Length == 1 &&
                string.Equals(row.Scenarios[0], "TEST-0210",
                    StringComparison.Ordinal))
            .Select(row => row.Fqn)
            .OrderBy(fqn => fqn, StringComparer.Ordinal)
            .ToArray();

        Assert.Equal(65, frozen.Count);
        Assert.Equal(frozen.ToArray(), expected.ToArray());
        Assert.Equal(expected.ToArray(), actual.ToArray());
        Assert.Equal(expected.Keys.ToArray(), scenarioIdentities);
        Assert.Equal(32, actual.Count(pair => pair.Value == "A"));
        Assert.Equal(11, actual.Count(pair => pair.Value == "B"));
        Assert.Equal(11, actual.Count(pair => pair.Value == "C"));
        Assert.Equal(11, actual.Count(pair => pair.Value == "D"));
    }

    private static TopologyRow Row(Type type, MethodInfo method)
    {
        var methodAttributes = method.CustomAttributes.ToArray();
        var classAttributes = type.CustomAttributes.ToArray();
        return new(
            $"{type.FullName}.{method.Name}",
            Count(methodAttributes, "Xunit.FactAttribute"),
            Count(methodAttributes, "Xunit.TheoryAttribute"),
            Traits(methodAttributes, "ContractSlice"),
            Traits(methodAttributes, "Scenario"),
            Traits(classAttributes, "ContractSlice"),
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
                string.Equals((string?)attribute.ConstructorArguments[0].Value, name,
                    StringComparison.Ordinal))
            .Select(attribute => (string)attribute.ConstructorArguments[1].Value!)
            .ToArray();

    private static IReadOnlyDictionary<string, string> FrozenInventory()
    {
        var result = new SortedDictionary<string, string>(StringComparer.Ordinal);
        Add(result, "A", [
            "ContractSliceAAdmissionProofManifestTests.Enforces_admission_proof_declarations_with_exact_kind_component_and_artifact_closure",
            "ContractSliceAArtifactComponentGraphTests.Enforces_exact_binding_runtime_anchor_and_reachability_graph",
            "ContractSliceACanonicalJsonGrammarTests.Enforces_exact_document_and_slice_structural_grammar",
            "ContractSliceACanonicalNumberTests.Enforces_exact_integer_grammar_and_range",
            "ContractSliceACanonicalStringTests.Enforces_exact_canonical_manifest_string_encoding",
            "ContractSliceACompleteCatalogProfileTests.Enforces_exact_provider_profile_genesis_catalog_inventory_digest_and_added_transitions",
            "ContractSliceAFindingManifestTests.Enforces_finding_declarations_with_exact_reference_roles",
            "ContractSliceAFullManifestGraphTests.Full_declaration_graph_equals_the_exact_five_rule_six_artifact_thirty_five_component_snapshot",
            "ContractSliceAGovernedReferenceSlotsManifestTests.Enforces_exact_governed_reference_index_and_dual_governed_text_slot_capability_closure",
            "ContractSliceAIndexSlotManifestTests.Enforces_exact_repository_tree_index_and_slot_capability_closure",
            "ContractSliceALifecycleManifestTests.Enforces_rule_lifecycle_against_transitions_and_active_profiles",
            "ContractSliceAManifestTests.Parses_minimal_canonical_qualification_manifest",
            "ContractSliceAOwnershipTests.DomainExportsEqualTheOrdinalUnionOfPredecessorInventories", "ContractSliceAOwnershipTests.SolutionAndProjectReferencesEqualTheContractSliceAGraph", "ContractSliceAOwnershipTests.PackageReferencesEqualTheContractSliceAGraph", "ContractSliceAOwnershipTests.LocksEqualTheContractSliceATotalGraph", "ContractSliceAOwnershipTests.EffectiveRestoreGraphsEqualTheContractSliceATotalGraph", "ContractSliceAOwnershipTests.FriendAssembliesEqualTheCurrentContractSliceAMatrix",
            "ContractSliceAParserRecordSlotManifestTests.Enforces_exact_markdown_parser_protocol_record_index_and_slot_capability_closure",
            "ContractSliceAPredecessorManifestTests.Enforces_existing_predecessor_version_and_exact_digests",
            "ContractSliceAProjectorDagManifestTests.Enforces_exact_projector_bindings_and_global_producer_graph",
            "ContractSliceAPublicApiTests.ExportedTypesEqualTheContractSliceAInventories", "ContractSliceAPublicApiTests.DeclaredPublicSurfaceEqualsTheContractSliceASnapshot", "ContractSliceAPublicApiTests.PublicTypesHaveNoConstructionOrSerializationLeak", "ContractSliceAPublicApiTests.FriendAssembliesEqualTheCurrentContractSliceAAllowlist", "ContractSliceAPublicApiTests.StagedExportsExposeOnlyTheContractSliceASeam",
            "ContractSliceAResourceManifestTests.Enforces_exact_manifest_byte_reachable_depth_and_token_ceilings",
            "ContractSliceARuleDeclarationTests.Enforces_canonical_multi_fragment_rule_provenance",
            "ContractSliceASchemaSlotManifestTests.Enforces_exact_schema_and_zero_capability_evidence_slot_closure",
            "ContractSliceASelectorManifestTests.Enforces_expected_selectors_with_exact_slot_schema_resolver_and_finding_closure",
            "ContractSliceATargetParserIndexSlotManifestTests.Enforces_exact_repository_target_schema_parser_index_and_slot_capability_closure",
            "ContractSliceATransitionManifestTests.Enforces_exact_unchanged_added_revised_and_retired_transition_shapes",
        ]);
        Add(result, "B", [
            "ContractSliceBActivationTests.Activates_exact_codec_mirror", "ContractSliceBAdmissionProofTests.Admits_exact_observed_failed_and_no_input_proofs", "ContractSliceBDecodeModelCacheTests.Enforces_exact_codec_cache_single_flight_collision_and_eviction", "ContractSliceBGovernedTextCodecTests.Round_trips_exact_governed_text_wire", "ContractSliceBQualifiedReferenceTests.Seals_exact_codec_derived_reference_and_location_narrowing", "ContractSliceBRepositoryTargetCodecTests.Round_trips_exact_repository_target_resolution_wire", "ContractSliceBRepositoryTreeCodecTests.Round_trips_exact_repository_tree_wire", "ContractSliceBResourceLedgerTests.Enforces_exact_codec_local_four_counter_ledger", "ContractSliceBSealedContextTests.Seals_exact_context_proof_and_root_references", "ContractSliceBPublicApiTests.Matches_exact_cumulative_b_public_surface", "ContractSliceBOwnershipTests.Enforces_exact_friend_factory_and_negative_surface",
        ]);
        Add(result, "C", [
            "ContractSliceCActivationTests.Activates_exact_synthetic_registration_graph", "ContractSliceCAggregationTests.Aggregates_exact_catalog_evaluation_and_verdict", "ContractSliceCApplicabilityClosureTests.Closes_applicability_with_exact_terminal_shapes", "ContractSliceCApplicabilityPlanTests.Plans_exact_static_applicability_instructions", "ContractSliceCEvaluationAdvanceTests.Advances_owner_sharded_evaluation_to_closure", "ContractSliceCEvaluationPlanTests.Plans_exact_projected_evaluation_round", "ContractSliceCIntentTests.Mints_exact_intents_findings_and_failures", "ContractSliceCOwnershipTests.Retains_exact_friend_project_and_policy_ownership_boundary", "ContractSliceCProducerPipelineTests.Activates_and_orders_exact_six_family_producer_graph", "ContractSliceCRegistrationTests.Rejects_registration_mismatch_without_kernel_activation", "ContractSliceCStructuralTests.Matches_exact_cumulative_c_public_surface",
        ]);
        Add(result, "D", [
            "ContractSliceActivationTopologyTests.Matches_exact_contract_slice_scenario_inventory", "ContractSliceDOwnershipTests.Enforces_exact_policy_friend_and_negative_surface", "ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0001_against_fresh_qualified_fixture", "ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0002_against_fresh_qualified_fixture", "ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0003_with_exact_target_specialization_and_co_report", "ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0004_with_exact_fragment_specialization_and_co_report", "ContractSliceDPolicyEvaluatorTests.Evaluates_rule_0005_with_exact_commit_specialization_and_co_report", "ContractSliceDPolicyExportTests.Exports_exact_real_registration_graph", "ContractSliceDProducerInfrastructureTests.Activates_exact_real_codec_parser_index_projector_selector_evaluator_graph", "ContractSliceDRepositoryProviderEquivalenceTests.Produces_equivalent_results_from_fresh_repository_and_provider_fixtures", "ContractSliceDStructuralTests.Matches_exact_final_cumulative_public_surface",
        ]);
        return result;
    }

    private static void Add(
        IDictionary<string, string> inventory,
        string slice,
        IEnumerable<string> names)
    {
        foreach (var name in names)
        {
            inventory.Add($"MeAndAI.Protocol.Conformance.Tests.{name}", slice);
        }
    }

    private sealed record TopologyRow(
        string Fqn, int Facts, int Theories, string[] Slices,
        string[] Scenarios, string[] ClassSlices, string[] ClassScenarios);
}
