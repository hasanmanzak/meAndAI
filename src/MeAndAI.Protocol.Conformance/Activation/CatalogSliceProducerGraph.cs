using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

internal sealed class CatalogSliceProducerGraph
{
    private CatalogSliceProducerGraph(
        IReadOnlyList<ProducerGraphNode> nodes,
        IReadOnlyList<ICodecRegistration> codecs,
        IReadOnlyList<IParserRegistration> parsers,
        IReadOnlyList<IIndexRegistration> indexes,
        IReadOnlyList<IDemandProjectorRegistration> projectors,
        IReadOnlyList<ISelectorRegistration> selectors,
        IReadOnlyList<RuleEvaluatorRegistration> evaluators)
    {
        Nodes = nodes;
        CodecRegistrations = codecs;
        ParserRegistrations = parsers;
        IndexRegistrations = indexes;
        DemandProjectorRegistrations = projectors;
        SelectorRegistrations = selectors;
        EvaluatorRegistrations = evaluators;
    }

    internal IReadOnlyList<ProducerGraphNode> Nodes { get; }
    internal IReadOnlyList<ICodecRegistration> CodecRegistrations { get; }
    internal IReadOnlyList<IParserRegistration> ParserRegistrations { get; }
    internal IReadOnlyList<IIndexRegistration> IndexRegistrations { get; }
    internal IReadOnlyList<IDemandProjectorRegistration> DemandProjectorRegistrations { get; }
    internal IReadOnlyList<ISelectorRegistration> SelectorRegistrations { get; }
    internal IReadOnlyList<RuleEvaluatorRegistration> EvaluatorRegistrations { get; }

    internal static CatalogSliceProducerGraph Create(PolicyQualificationSliceExport policy) =>
        Create(
            policy?.CodecRegistrations,
            policy?.ParserRegistrations,
            policy?.IndexRegistrations,
            policy?.DemandProjectorRegistrations,
            policy?.SelectorRegistrations,
            policy?.EvaluatorRegistrations);

    internal static CatalogSliceProducerGraph Create(CompletePolicyPackExport policy) =>
        Create(
            policy?.CodecRegistrations,
            policy?.ParserRegistrations,
            policy?.IndexRegistrations,
            policy?.DemandProjectorRegistrations,
            policy?.SelectorRegistrations,
            policy?.EvaluatorRegistrations);

    private static CatalogSliceProducerGraph Create(
        IReadOnlyList<ICodecRegistration>? codecs,
        IReadOnlyList<IParserRegistration>? parsers,
        IReadOnlyList<IIndexRegistration>? indexes,
        IReadOnlyList<IDemandProjectorRegistration>? projectors,
        IReadOnlyList<ISelectorRegistration>? selectors,
        IReadOnlyList<RuleEvaluatorRegistration>? evaluators)
    {
        ArgumentNullException.ThrowIfNull(codecs);
        ArgumentNullException.ThrowIfNull(parsers);
        ArgumentNullException.ThrowIfNull(indexes);
        ArgumentNullException.ThrowIfNull(projectors);
        ArgumentNullException.ThrowIfNull(selectors);
        ArgumentNullException.ThrowIfNull(evaluators);
        if (codecs.Count != 3 || parsers.Count != 2 || indexes.Count != 4 ||
            projectors.Count != 1 || selectors.Count != 3 || evaluators.Count != 5)
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
        }

        var nodeCandidates = codecs.Select(item => ProducerGraphNode.Schema(item.Declaration))
            .Concat(parsers.Select(item => ProducerGraphNode.Parser(item.Declaration)))
            .Concat(indexes.Select(item => ProducerGraphNode.Index(item.Declaration)))
            .Concat(projectors.Select(item => ProducerGraphNode.Projector(item.Declaration)))
            .ToArray();
        if (nodeCandidates.Length != 10 ||
            nodeCandidates.Select(item => item.Identity).Distinct(StringComparer.Ordinal).Count() != 10)
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
        }

        var expectedOrder = new[]
        {
            "Schema|protocol.governed-text|1",
            "Schema|protocol.repository-tree|1",
            "Index|protocol.index.repository-tree|1",
            "Parser|protocol.parser.markdown|1",
            "Index|protocol.index.protocol-record|1",
            "Index|protocol.index.governed-reference|1",
            "Projector|protocol.projector.repository-target-resolution-demand|1",
            "Schema|protocol.repository-target-resolution|1",
            "Parser|protocol.parser.repository-target-markdown|1",
            "Index|protocol.index.repository-target-resolution|1"
        };
        var byIdentity = nodeCandidates.ToDictionary(item => item.Identity, StringComparer.Ordinal);
        if (expectedOrder.Any(identity => !byIdentity.ContainsKey(identity)) ||
            byIdentity.Keys.Except(expectedOrder, StringComparer.Ordinal).Any())
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
        }

        ValidateBinderInputs(parsers, indexes);
        var dependencies = new Dictionary<string, string[]>(StringComparer.Ordinal)
        {
            [expectedOrder[0]] = [],
            [expectedOrder[1]] = [],
            [expectedOrder[2]] = [expectedOrder[1]],
            [expectedOrder[3]] = [expectedOrder[0]],
            [expectedOrder[4]] = [expectedOrder[3]],
            [expectedOrder[5]] = [expectedOrder[3], expectedOrder[4]],
            [expectedOrder[6]] = [expectedOrder[5]],
            [expectedOrder[7]] = [expectedOrder[6]],
            [expectedOrder[8]] = [expectedOrder[7]],
            [expectedOrder[9]] = [expectedOrder[5], expectedOrder[7], expectedOrder[8]]
        };
        var wired = byIdentity.ToDictionary(
            item => item.Key,
            item => item.Value.WithDependencies(dependencies[item.Key]),
            StringComparer.Ordinal);
        var nodes = TopologicalOrder(wired);
        if (!nodes.Select(item => item.Identity).SequenceEqual(expectedOrder, StringComparer.Ordinal))
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
        }

        return new CatalogSliceProducerGraph(
            Array.AsReadOnly(nodes),
            Snapshot(codecs),
            Snapshot(parsers),
            Snapshot(indexes),
            Snapshot(projectors),
            Snapshot(selectors),
            Snapshot(evaluators));
    }

    private static ProducerGraphNode[] TopologicalOrder(
        IReadOnlyDictionary<string, ProducerGraphNode> candidates)
    {
        var remaining = new Dictionary<string, ProducerGraphNode>(candidates, StringComparer.Ordinal);
        var emitted = new HashSet<string>(StringComparer.Ordinal);
        var result = new List<ProducerGraphNode>(remaining.Count);
        while (remaining.Count > 0)
        {
            var next = remaining.Values
                .Where(node => node.Dependencies.All(emitted.Contains))
                .OrderBy(node => node.Component.ComponentKey, StringComparer.Ordinal)
                .ThenBy(node => node.Component.ComponentVersion, StringComparer.Ordinal)
                .ThenBy(node => node.Key, StringComparer.Ordinal)
                .ThenBy(node => node.Version, StringComparer.Ordinal)
                .ThenBy(node => node.FamilyRank)
                .FirstOrDefault();
            if (next is null)
            {
                throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
            }

            remaining.Remove(next.Identity);
            emitted.Add(next.Identity);
            result.Add(next);
        }

        return result.ToArray();
    }

    private static void ValidateBinderInputs(
        IReadOnlyList<IParserRegistration> parsers,
        IReadOnlyList<IIndexRegistration> indexes)
    {
        if (parsers.Any(registration => !registration.Accept(BinderInputVisitor.Parser)) ||
            indexes.Any(registration => !registration.Accept(BinderInputVisitor.Index)))
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
        }
    }

    private static IReadOnlyList<T> Snapshot<T>(IReadOnlyList<T> values) where T : class =>
        Array.AsReadOnly(values.ToArray());

    private sealed class BinderInputVisitor :
        IParserRegistrationVisitor<bool>,
        IIndexRegistrationVisitor<bool>
    {
        internal static readonly BinderInputVisitor Parser = new();
        internal static readonly BinderInputVisitor Index = new();

        public bool Visit<TInput, TOutput>(ParserRegistration<TInput, TOutput> registration)
            where TInput : class, IComponentInput
            where TOutput : class, IProtocolSemanticModel =>
            SameInputs(registration.Declaration.Inputs, registration.Binder.Inputs);

        public bool Visit<TInput, TCapability>(IndexRegistration<TInput, TCapability> registration)
            where TInput : class, IComponentInput
            where TCapability : class, IEvidenceCapability =>
            SameInputs(registration.Declaration.Inputs, registration.Binder.Inputs);

        private static bool SameInputs(
            IReadOnlyList<ComponentInputDeclaration> expected,
            IReadOnlyList<ComponentInputDeclaration> actual) =>
            expected.Count == actual.Count &&
            expected.Zip(actual).All(pair => ReferenceEquals(pair.First, pair.Second));
    }
}

internal sealed class ProducerGraphNode
{
    private ProducerGraphNode(
        string family,
        string key,
        string version,
        ComponentTypeIdentity component,
        IReadOnlyList<ComponentInputDeclaration> inputs,
        IReadOnlyList<string> dependencies,
        IndexInvocationScope? invocationScope)
    {
        Family = family;
        Key = key;
        Version = version;
        Component = component;
        Inputs = inputs;
        Dependencies = dependencies;
        InvocationScope = invocationScope;
        Identity = $"{family}|{key}|{version}";
    }

    internal string Family { get; }
    internal string Key { get; }
    internal string Version { get; }
    internal ComponentTypeIdentity Component { get; }
    internal IReadOnlyList<ComponentInputDeclaration> Inputs { get; }
    internal IReadOnlyList<string> Dependencies { get; }
    internal IndexInvocationScope? InvocationScope { get; }
    internal string Identity { get; }
    internal int FamilyRank => Family switch
    {
        "Schema" => 0,
        "Parser" => 1,
        "Index" => 2,
        "Projector" => 3,
        _ => throw new InvalidOperationException("The producer family is invalid.")
    };

    internal ProducerGraphNode WithDependencies(IEnumerable<string> dependencies)
    {
        ArgumentNullException.ThrowIfNull(dependencies);
        var values = dependencies.ToArray();
        if (values.Any(string.IsNullOrWhiteSpace) ||
            values.Distinct(StringComparer.Ordinal).Count() != values.Length)
        {
            throw new CatalogIntegrityException(CatalogIntegrityCode.RegistrationMismatch);
        }

        return new ProducerGraphNode(
            Family,
            Key,
            Version,
            Component,
            Inputs,
            Array.AsReadOnly(values),
            InvocationScope);
    }

    internal static ProducerGraphNode Schema(PayloadSchemaDeclaration declaration) =>
        new(
            "Schema",
            declaration.SchemaKey,
            declaration.SchemaVersion,
            declaration.Codec,
            Array.Empty<ComponentInputDeclaration>(),
            Array.Empty<string>(),
            null);

    internal static ProducerGraphNode Parser(SemanticModelParserDeclaration declaration) =>
        new(
            "Parser",
            declaration.ParserKey,
            declaration.ParserVersion,
            declaration.Parser,
            Array.AsReadOnly(declaration.Inputs.ToArray()),
            Array.Empty<string>(),
            null);

    internal static ProducerGraphNode Index(ContextIndexDeclaration declaration) =>
        new(
            "Index",
            declaration.IndexKey,
            declaration.IndexVersion,
            declaration.Indexer,
            Array.AsReadOnly(declaration.Inputs.ToArray()),
            Array.Empty<string>(),
            declaration.InvocationScope);

    internal static ProducerGraphNode Projector(AcquisitionDemandProjectorDeclaration declaration) =>
        new(
            "Projector",
            declaration.ProjectorKey,
            declaration.ProjectorVersion,
            declaration.Projector,
            Array.Empty<ComponentInputDeclaration>(),
            Array.Empty<string>(),
            null);
}
