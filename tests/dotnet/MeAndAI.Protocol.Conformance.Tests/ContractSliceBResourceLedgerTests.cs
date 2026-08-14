namespace MeAndAI.Protocol.Conformance.Tests;

public sealed class ContractSliceBResourceLedgerTests
{
    private const string Marker = "TEST-0210-B-BEHAVIOR-RED-0006";
    private const string PayloadDigest =
        "936D99ECDDC7332999B2641787BF160A1D126F27DAEB4F54BE1EBC8F426EE6F0";
    private const string InvocationDigest =
        "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF";
    private const string PayloadKey =
        "0|protocol.repository-target-resolution|1|" + PayloadDigest;

    [Fact]
    [Trait("ContractSlice", "B")]
    [Trait("Scenario", "TEST-0210")]
    public void Enforces_exact_codec_local_four_counter_ledger()
    {
        AssertConstructionBoundaries();
        AssertFitBoundaries();
        AssertLedgerClosure();
        AssertCoordinatorRejections();

        var input = CreateInput();
        var value = RepositoryTargetResourceShapeMirror.Create(
            4,
            61,
            InvocationDigest);
        var meter = new TrackingMeter(
            SemanticResourceLocalUsageMirror.Create(0, 4, 61, 0));
        var token = new CancellationTokenSource().Token;
        var result = new RepositoryTargetResourceCoordinatorMirror().Qualify(
            input,
            ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                .Produced(
                    value,
                    SemanticResourceLocalUsageMirror.Create(0, 4, 61, 0)),
            meter,
            token);

        Assert.Equal(1, meter.Calls);
        Assert.Same(input, meter.Input);
        Assert.Same(value, meter.Value);
        Assert.Equal(token, meter.Token);
        if (result is null)
        {
            Assert.Fail(Marker);
        }

        var qualified = Observe(result);
        Assert.True(qualified.Qualified);
        AssertUsage(qualified.Measured!, 0, 4, 61, 0);
        AssertUsage(qualified.Ledger!.Usage, 1465, 4, 61, 1526);
        Assert.Equal(2, qualified.Ledger.Contributions.Count);
        Assert.Equal(PayloadKey, qualified.Ledger.Contributions[0].RowKey);
        Assert.Equal(
            "2|protocol.codec.repository-target-resolution|1|" +
                InvocationDigest,
            qualified.Ledger.Contributions[1].RowKey);
    }

    private static RepositoryTargetResourceInputMirror CreateInput(
        string rowKey = PayloadKey)
    {
        var baseline = SemanticResourceUsageMirror.Create(1465, 0, 0, 1465);
        var budget = SemanticResourceBudgetMirror.Create(
            33554432,
            64,
            500000,
            34054432);
        return RepositoryTargetResourceInputMirror.Create(
            SemanticResourceAllowanceMirror.Create(budget, baseline),
            SemanticResourceContributionMirror.Payload(rowKey, 1465));
    }

    private static void AssertConstructionBoundaries()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            SemanticResourceUsageMirror.Create(-1, 0, 0, 0));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            SemanticResourceLocalUsageMirror.Create(0, -1, 0, 0));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            SemanticResourceBudgetMirror.Create(0, 1, 1, 1));
        Assert.Throws<ArgumentException>(() =>
            RepositoryTargetResourceShapeMirror.Create(0, 1, InvocationDigest));
        Assert.Throws<ArgumentException>(() =>
            RepositoryTargetResourceShapeMirror.Create(1, 0, InvocationDigest));
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            RepositoryTargetResourceShapeMirror.Create(5, 1, InvocationDigest));
        Assert.Throws<ArgumentException>(() =>
            RepositoryTargetResourceShapeMirror.Create(1, 1, "abcdef"));

        var allowance = SemanticResourceAllowanceMirror.Create(
            SemanticResourceBudgetMirror.Create(10, 10, 10, 20),
            SemanticResourceUsageMirror.Create(1, 0, 0, 1));
        var wrongRank = SemanticResourceContributionMirror.Layer("row", 1, 1);
        var wrongRankError = Assert.Throws<ArgumentException>(() =>
            RepositoryTargetResourceInputMirror.Create(allowance, wrongRank));
        Assert.Equal("selectedPayload", wrongRankError.ParamName);
        var wrongUsage = SemanticResourceContributionMirror.Payload("row", 2);
        var wrongUsageError = Assert.Throws<ArgumentException>(() =>
            RepositoryTargetResourceInputMirror.Create(allowance, wrongUsage));
        Assert.Equal("selectedPayload", wrongUsageError.ParamName);
    }

    private static void AssertFitBoundaries()
    {
        var baseline = SemanticResourceUsageMirror.Create(1465, 0, 0, 1465);
        var budget = SemanticResourceBudgetMirror.Create(
            33554432,
            64,
            500000,
            34054432);
        var allowance = SemanticResourceAllowanceMirror.Create(budget, baseline);

        AssertFit(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                33554432 - 1465,
                0,
                0,
                0)),
            33554432,
            0,
            0,
            33554432);
        AssertExceeded(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                33554432 - 1465 + 1,
                0,
                0,
                0)),
            ResourceCounterMirror.Bytes);

        AssertFit(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                0,
                4,
                500000,
                0)),
            1465,
            4,
            500000,
            501465);
        AssertExceeded(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                0,
                4,
                500001,
                0)),
            ResourceCounterMirror.Nodes);

        AssertFit(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                0,
                0,
                0,
                34054432 - 1465)),
            1465,
            0,
            0,
            34054432);
        AssertExceeded(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                0,
                0,
                0,
                34054432 - 1465 + 1)),
            ResourceCounterMirror.Complexity);
        AssertExceeded(
            allowance.FitLocal(SemanticResourceLocalUsageMirror.Create(
                0,
                4,
                500001,
                34054432)),
            ResourceCounterMirror.Nodes);

        var overflow = SemanticResourceAllowanceMirror.Create(
            SemanticResourceBudgetMirror.Create(
                long.MaxValue,
                64,
                long.MaxValue,
                long.MaxValue),
            SemanticResourceUsageMirror.Create(
                long.MaxValue,
                0,
                0,
                long.MaxValue));
        AssertExceeded(
            overflow.FitLocal(
                SemanticResourceLocalUsageMirror.Create(1, 0, 0, 0)),
            ResourceCounterMirror.Bytes);
    }

    private static void AssertLedgerClosure()
    {
        var payload = SemanticResourceContributionMirror.Payload(PayloadKey, 1465);
        var layer = SemanticResourceContributionMirror.Layer(
            "2|protocol.codec.repository-target-resolution|1|" +
                InvocationDigest,
            4,
            61);
        var source = new[] { layer, payload, payload };
        var ledger = SemanticResourceLedgerMirror.Create(source);
        source[0] = payload;
        Assert.Equal(2, ledger.Contributions.Count);
        Assert.Equal(0, ledger.Contributions[0].KindRank);
        Assert.Equal(2, ledger.Contributions[1].KindRank);
        AssertUsage(ledger.Usage, 1465, 4, 61, 1526);

        var collision = Assert.Throws<ResourceLedgerCollisionMirrorException>(() =>
            SemanticResourceLedgerMirror.Create(
            [
                SemanticResourceContributionMirror.Payload("same", 1),
                SemanticResourceContributionMirror.GeneratedBytes("same", 1),
            ]));
        Assert.Equal("same", collision.RowKey);
        Assert.Equal("Conflicting resource row: same.", collision.Message);

        Assert.Throws<OverflowException>(() =>
            SemanticResourceLedgerMirror.Create(
            [
                SemanticResourceContributionMirror.Payload("a", long.MaxValue),
                SemanticResourceContributionMirror.GeneratedBytes("b", 1),
            ]));
    }

    private static void AssertCoordinatorRejections()
    {
        var coordinator = new RepositoryTargetResourceCoordinatorMirror();
        var input = CreateInput();
        var value = RepositoryTargetResourceShapeMirror.Create(
            4,
            61,
            InvocationDigest);
        var local = SemanticResourceLocalUsageMirror.Create(0, 4, 61, 0);

        var rejectedMeter = new TrackingMeter(local);
        AssertRejected(
            coordinator.Qualify(
                input,
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Rejected(ResourceFailureMirror.ProducerRejected),
                rejectedMeter,
                CancellationToken.None),
            ResourceFailureMirror.ProducerRejected);
        Assert.Equal(0, rejectedMeter.Calls);

        AssertRejected(
            coordinator.Qualify(
                input,
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Produced(value, local),
                null,
                CancellationToken.None),
            ResourceFailureMirror.RegistrationMismatch);

        var mismatchMeter = new TrackingMeter(local);
        AssertRejected(
            coordinator.Qualify(
                input,
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Produced(
                        value,
                        SemanticResourceLocalUsageMirror.Create(1, 4, 61, 1)),
                mismatchMeter,
                CancellationToken.None),
            ResourceFailureMirror.IntentInvalid);
        Assert.Equal(1, mismatchMeter.Calls);

        var overBudget = new TrackingMeter(
            SemanticResourceLocalUsageMirror.Create(33554432, 0, 0, 0));
        AssertRejected(
            coordinator.Qualify(
                input,
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Produced(
                        value,
                        SemanticResourceLocalUsageMirror.Create(
                            33554432,
                            0,
                            0,
                            0)),
                overBudget,
                CancellationToken.None),
            ResourceFailureMirror.IntentInvalid);

        var collisionKey =
            "2|protocol.codec.repository-target-resolution|1|" +
            InvocationDigest;
        AssertRejected(
            coordinator.Qualify(
                CreateInput(collisionKey),
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Produced(value, local),
                new TrackingMeter(local),
                CancellationToken.None),
            ResourceFailureMirror.IntentInvalid);

        var cancellationMeter = new TrackingMeter(local);
        Assert.Throws<OperationCanceledException>(() =>
            coordinator.Qualify(
                input,
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Produced(value, local),
                cancellationMeter,
                new CancellationToken(true)));
        Assert.Equal(0, cancellationMeter.Calls);

        var expected = new HostMeterException();
        var throwingMeter = new TrackingMeter(local, expected);
        Assert.Same(
            expected,
            Assert.Throws<HostMeterException>(() => coordinator.Qualify(
                input,
                ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror>
                    .Produced(value, local),
                throwingMeter,
                CancellationToken.None)));
        Assert.Equal(1, throwingMeter.Calls);
    }

    private static ResourceOutcome Observe(
        ResourceQualificationMirrorResult result) =>
        result.Accept(ResourceObserver.Instance);

    private static void AssertRejected(
        ResourceQualificationMirrorResult result,
        ResourceFailureMirror expected)
    {
        var outcome = Observe(result);
        Assert.False(outcome.Qualified);
        Assert.Equal(expected, outcome.Failure);
        Assert.Null(outcome.Measured);
        Assert.Null(outcome.Ledger);
    }

    private static void AssertFit(
        ResourceFitMirror fit,
        long bytes,
        int depth,
        long nodes,
        long complexity)
    {
        Assert.True(fit.Fits);
        Assert.Equal(ResourceCounterMirror.None, fit.FirstExceeded);
        AssertUsage(fit.Aggregate!, bytes, depth, nodes, complexity);
    }

    private static void AssertExceeded(
        ResourceFitMirror fit,
        ResourceCounterMirror expected)
    {
        Assert.False(fit.Fits);
        Assert.Equal(expected, fit.FirstExceeded);
        Assert.Null(fit.Aggregate);
    }

    private static void AssertUsage(
        SemanticResourceUsageMirror usage,
        long bytes,
        int depth,
        long nodes,
        long complexity)
    {
        Assert.Equal(bytes, usage.Bytes);
        Assert.Equal(depth, usage.MaxDepth);
        Assert.Equal(nodes, usage.Nodes);
        Assert.Equal(complexity, usage.Complexity);
    }

    private static void AssertUsage(
        SemanticResourceLocalUsageMirror usage,
        long bytes,
        int depth,
        long nodes,
        long complexity)
    {
        Assert.Equal(bytes, usage.GeneratedBytes);
        Assert.Equal(depth, usage.LayerDepth);
        Assert.Equal(nodes, usage.LayerNodes);
        Assert.Equal(complexity, usage.AdditionalComplexity);
    }

    private sealed class TrackingMeter :
        ISemanticResourceMeterMirror<RepositoryTargetResourceInputMirror,
            RepositoryTargetResourceShapeMirror>
    {
        private readonly SemanticResourceLocalUsageMirror _usage;
        private readonly Exception? _exception;

        internal TrackingMeter(
            SemanticResourceLocalUsageMirror usage,
            Exception? exception = null)
        {
            _usage = usage;
            _exception = exception;
        }

        internal int Calls { get; private set; }
        internal RepositoryTargetResourceInputMirror? Input { get; private set; }
        internal RepositoryTargetResourceShapeMirror? Value { get; private set; }
        internal CancellationToken Token { get; private set; }

        public SemanticResourceLocalUsageMirror MeasureLocal(
            RepositoryTargetResourceInputMirror input,
            RepositoryTargetResourceShapeMirror value,
            CancellationToken cancellationToken)
        {
            Calls++;
            Input = input;
            Value = value;
            Token = cancellationToken;
            if (_exception is not null)
            {
                throw _exception;
            }
            return _usage;
        }
    }

    private sealed class ResourceObserver :
        IResourceQualificationMirrorVisitor<ResourceOutcome>
    {
        internal static ResourceObserver Instance { get; } = new();

        public ResourceOutcome VisitQualified(
            SemanticResourceLocalUsageMirror measuredLocalUsage,
            SemanticResourceLedgerMirror ledger) =>
            new(true, measuredLocalUsage, ledger, null);

        public ResourceOutcome VisitRejected(ResourceFailureMirror failure) =>
            new(false, null, null, failure);
    }

    private sealed record ResourceOutcome(
        bool Qualified,
        SemanticResourceLocalUsageMirror? Measured,
        SemanticResourceLedgerMirror? Ledger,
        ResourceFailureMirror? Failure);

    private sealed class HostMeterException : Exception;
}

internal sealed class SemanticResourceUsageMirror
{
    private SemanticResourceUsageMirror(
        long bytes,
        int maxDepth,
        long nodes,
        long complexity)
    {
        Bytes = bytes;
        MaxDepth = maxDepth;
        Nodes = nodes;
        Complexity = complexity;
    }

    internal long Bytes { get; }
    internal int MaxDepth { get; }
    internal long Nodes { get; }
    internal long Complexity { get; }

    internal static SemanticResourceUsageMirror Create(
        long bytes,
        int maxDepth,
        long nodes,
        long complexity)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(bytes);
        ArgumentOutOfRangeException.ThrowIfNegative(maxDepth);
        ArgumentOutOfRangeException.ThrowIfNegative(nodes);
        ArgumentOutOfRangeException.ThrowIfNegative(complexity);
        return new(bytes, maxDepth, nodes, complexity);
    }
}

internal sealed class SemanticResourceLocalUsageMirror
{
    private SemanticResourceLocalUsageMirror(
        long generatedBytes,
        int layerDepth,
        long layerNodes,
        long additionalComplexity)
    {
        GeneratedBytes = generatedBytes;
        LayerDepth = layerDepth;
        LayerNodes = layerNodes;
        AdditionalComplexity = additionalComplexity;
    }

    internal long GeneratedBytes { get; }
    internal int LayerDepth { get; }
    internal long LayerNodes { get; }
    internal long AdditionalComplexity { get; }

    internal static SemanticResourceLocalUsageMirror Create(
        long generatedBytes,
        int layerDepth,
        long layerNodes,
        long additionalComplexity)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(generatedBytes);
        ArgumentOutOfRangeException.ThrowIfNegative(layerDepth);
        ArgumentOutOfRangeException.ThrowIfNegative(layerNodes);
        ArgumentOutOfRangeException.ThrowIfNegative(additionalComplexity);
        if (layerDepth > 4)
        {
            throw new ArgumentOutOfRangeException(nameof(layerDepth));
        }
        if ((layerDepth == 0) != (layerNodes == 0))
        {
            throw new ArgumentException("Layer depth and nodes must be coherent.");
        }
        return new(generatedBytes, layerDepth, layerNodes, additionalComplexity);
    }
}

internal sealed class SemanticResourceBudgetMirror
{
    private SemanticResourceBudgetMirror(
        long maximumBytes,
        int maximumDepth,
        long maximumNodes,
        long maximumComplexity)
    {
        MaximumBytes = maximumBytes;
        MaximumDepth = maximumDepth;
        MaximumNodes = maximumNodes;
        MaximumComplexity = maximumComplexity;
    }

    internal long MaximumBytes { get; }
    internal int MaximumDepth { get; }
    internal long MaximumNodes { get; }
    internal long MaximumComplexity { get; }

    internal static SemanticResourceBudgetMirror Create(
        long maximumBytes,
        int maximumDepth,
        long maximumNodes,
        long maximumComplexity)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(maximumBytes, 1);
        ArgumentOutOfRangeException.ThrowIfLessThan(maximumDepth, 1);
        ArgumentOutOfRangeException.ThrowIfLessThan(maximumNodes, 1);
        ArgumentOutOfRangeException.ThrowIfLessThan(maximumComplexity, 1);
        return new(maximumBytes, maximumDepth, maximumNodes, maximumComplexity);
    }
}

internal sealed class SemanticResourceAllowanceMirror
{
    private SemanticResourceAllowanceMirror(
        SemanticResourceBudgetMirror aggregateBudget,
        SemanticResourceUsageMirror selectedBaseline)
    {
        AggregateBudget = aggregateBudget;
        SelectedBaseline = selectedBaseline;
    }

    internal SemanticResourceBudgetMirror AggregateBudget { get; }
    internal SemanticResourceUsageMirror SelectedBaseline { get; }

    internal static SemanticResourceAllowanceMirror Create(
        SemanticResourceBudgetMirror aggregateBudget,
        SemanticResourceUsageMirror selectedBaseline) =>
        new(
            aggregateBudget ?? throw new ArgumentNullException(nameof(aggregateBudget)),
            selectedBaseline ?? throw new ArgumentNullException(nameof(selectedBaseline)));

    internal ResourceFitMirror FitLocal(
        SemanticResourceLocalUsageMirror localUsage)
    {
        ArgumentNullException.ThrowIfNull(localUsage);
        long bytes;
        long nodes;
        long complexity;
        try
        {
            bytes = checked(SelectedBaseline.Bytes + localUsage.GeneratedBytes);
        }
        catch (OverflowException)
        {
            return ResourceFitMirror.Exceeded(ResourceCounterMirror.Bytes);
        }
        if (bytes > AggregateBudget.MaximumBytes)
        {
            return ResourceFitMirror.Exceeded(ResourceCounterMirror.Bytes);
        }
        var depth = Math.Max(SelectedBaseline.MaxDepth, localUsage.LayerDepth);
        if (depth > AggregateBudget.MaximumDepth)
        {
            return ResourceFitMirror.Exceeded(ResourceCounterMirror.MaxDepth);
        }
        try
        {
            nodes = checked(SelectedBaseline.Nodes + localUsage.LayerNodes);
        }
        catch (OverflowException)
        {
            return ResourceFitMirror.Exceeded(ResourceCounterMirror.Nodes);
        }
        if (nodes > AggregateBudget.MaximumNodes)
        {
            return ResourceFitMirror.Exceeded(ResourceCounterMirror.Nodes);
        }
        try
        {
            complexity = checked(
                SelectedBaseline.Complexity +
                localUsage.GeneratedBytes +
                localUsage.LayerNodes +
                localUsage.AdditionalComplexity);
        }
        catch (OverflowException)
        {
            return ResourceFitMirror.Exceeded(ResourceCounterMirror.Complexity);
        }
        return complexity > AggregateBudget.MaximumComplexity
            ? ResourceFitMirror.Exceeded(ResourceCounterMirror.Complexity)
            : ResourceFitMirror.Accepted(
                SemanticResourceUsageMirror.Create(bytes, depth, nodes, complexity));
    }
}

internal enum ResourceCounterMirror
{
    None,
    Bytes,
    MaxDepth,
    Nodes,
    Complexity,
}

internal sealed class ResourceFitMirror
{
    private ResourceFitMirror(
        bool fits,
        ResourceCounterMirror firstExceeded,
        SemanticResourceUsageMirror? aggregate)
    {
        Fits = fits;
        FirstExceeded = firstExceeded;
        Aggregate = aggregate;
    }

    internal bool Fits { get; }
    internal ResourceCounterMirror FirstExceeded { get; }
    internal SemanticResourceUsageMirror? Aggregate { get; }

    internal static ResourceFitMirror Accepted(
        SemanticResourceUsageMirror aggregate) =>
        new(true, ResourceCounterMirror.None, aggregate);

    internal static ResourceFitMirror Exceeded(ResourceCounterMirror counter) =>
        new(false, counter, null);
}

internal sealed class SemanticResourceContributionMirror
{
    private SemanticResourceContributionMirror(
        int kindRank,
        string rowKey,
        SemanticResourceUsageMirror usage)
    {
        KindRank = kindRank;
        RowKey = rowKey;
        Usage = usage;
    }

    internal int KindRank { get; }
    internal string RowKey { get; }
    internal SemanticResourceUsageMirror Usage { get; }

    internal static SemanticResourceContributionMirror Payload(
        string rowKey,
        long bytes) =>
        CreateBytes(0, rowKey, bytes);

    internal static SemanticResourceContributionMirror GeneratedBytes(
        string rowKey,
        long bytes) =>
        CreateBytes(1, rowKey, bytes);

    internal static SemanticResourceContributionMirror Layer(
        string rowKey,
        int depth,
        long nodes)
    {
        ValidateKey(rowKey);
        ArgumentOutOfRangeException.ThrowIfLessThan(depth, 1);
        ArgumentOutOfRangeException.ThrowIfLessThan(nodes, 1);
        return new(
            2,
            rowKey,
            SemanticResourceUsageMirror.Create(0, depth, nodes, nodes));
    }

    internal static SemanticResourceContributionMirror ComplexityTerm(
        string rowKey,
        long amount)
    {
        ValidateKey(rowKey);
        ArgumentOutOfRangeException.ThrowIfLessThan(amount, 1);
        return new(
            3,
            rowKey,
            SemanticResourceUsageMirror.Create(0, 0, 0, amount));
    }

    private static SemanticResourceContributionMirror CreateBytes(
        int rank,
        string rowKey,
        long bytes)
    {
        ValidateKey(rowKey);
        ArgumentOutOfRangeException.ThrowIfLessThan(bytes, 1);
        return new(
            rank,
            rowKey,
            SemanticResourceUsageMirror.Create(bytes, 0, 0, bytes));
    }

    private static void ValidateKey(string rowKey)
    {
        ArgumentException.ThrowIfNullOrEmpty(rowKey);
    }
}

internal sealed class SemanticResourceLedgerMirror
{
    private SemanticResourceLedgerMirror(
        SemanticResourceContributionMirror[] contributions,
        SemanticResourceUsageMirror usage)
    {
        Contributions = Array.AsReadOnly(contributions);
        Usage = usage;
    }

    internal IReadOnlyList<SemanticResourceContributionMirror> Contributions { get; }
    internal SemanticResourceUsageMirror Usage { get; }

    internal static SemanticResourceLedgerMirror Create(
        IEnumerable<SemanticResourceContributionMirror> contributions)
    {
        ArgumentNullException.ThrowIfNull(contributions);
        var ordered = contributions
            .Select(item => item ?? throw new ArgumentException(
                "A contribution cannot be null.",
                nameof(contributions)))
            .OrderBy(item => item.KindRank)
            .ThenBy(item => item.RowKey, StringComparer.Ordinal)
            .ToArray();
        var distinct = new List<SemanticResourceContributionMirror>();
        foreach (var item in ordered)
        {
            var existing = distinct.FirstOrDefault(candidate =>
                string.Equals(candidate.RowKey, item.RowKey, StringComparison.Ordinal));
            if (existing is null)
            {
                distinct.Add(item);
                continue;
            }
            if (!Equal(existing, item))
            {
                throw new ResourceLedgerCollisionMirrorException(item.RowKey);
            }
        }

        long bytes = 0;
        var depth = 0;
        long nodes = 0;
        long additional = 0;
        checked
        {
            foreach (var item in distinct)
            {
                if (item.KindRank is 0 or 1)
                {
                    bytes += item.Usage.Bytes;
                }
                else if (item.KindRank == 2)
                {
                    depth = Math.Max(depth, item.Usage.MaxDepth);
                    nodes += item.Usage.Nodes;
                }
                else
                {
                    additional += item.Usage.Complexity;
                }
            }
        }
        var complexity = checked(bytes + nodes + additional);
        return new(
            [.. distinct],
            SemanticResourceUsageMirror.Create(bytes, depth, nodes, complexity));
    }

    private static bool Equal(
        SemanticResourceContributionMirror left,
        SemanticResourceContributionMirror right) =>
        left.KindRank == right.KindRank &&
        left.Usage.Bytes == right.Usage.Bytes &&
        left.Usage.MaxDepth == right.Usage.MaxDepth &&
        left.Usage.Nodes == right.Usage.Nodes &&
        left.Usage.Complexity == right.Usage.Complexity;
}

internal sealed class RepositoryTargetResourceInputMirror
{
    private RepositoryTargetResourceInputMirror(
        SemanticResourceAllowanceMirror allowance,
        SemanticResourceContributionMirror selectedPayload)
    {
        Allowance = allowance;
        SelectedPayload = selectedPayload;
    }

    internal SemanticResourceAllowanceMirror Allowance { get; }
    internal SemanticResourceContributionMirror SelectedPayload { get; }

    internal static RepositoryTargetResourceInputMirror Create(
        SemanticResourceAllowanceMirror allowance,
        SemanticResourceContributionMirror selectedPayload)
    {
        ArgumentNullException.ThrowIfNull(allowance);
        ArgumentNullException.ThrowIfNull(selectedPayload);
        if (selectedPayload.KindRank != 0 ||
            !Equal(selectedPayload.Usage, allowance.SelectedBaseline))
        {
            throw new ArgumentException(
                "The selected payload must match the baseline.",
                nameof(selectedPayload));
        }
        return new(allowance, selectedPayload);
    }

    private static bool Equal(
        SemanticResourceUsageMirror left,
        SemanticResourceUsageMirror right) =>
        left.Bytes == right.Bytes &&
        left.MaxDepth == right.MaxDepth &&
        left.Nodes == right.Nodes &&
        left.Complexity == right.Complexity;
}

internal sealed class RepositoryTargetResourceShapeMirror
{
    private RepositoryTargetResourceShapeMirror(
        int layerDepth,
        long layerNodes,
        string invocationDigest)
    {
        LayerDepth = layerDepth;
        LayerNodes = layerNodes;
        InvocationDigest = invocationDigest;
    }

    internal int LayerDepth { get; }
    internal long LayerNodes { get; }
    internal string InvocationDigest { get; }

    internal static RepositoryTargetResourceShapeMirror Create(
        int layerDepth,
        long layerNodes,
        string invocationDigest)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(layerDepth);
        ArgumentOutOfRangeException.ThrowIfNegative(layerNodes);
        if (layerDepth > 4)
        {
            throw new ArgumentOutOfRangeException(nameof(layerDepth));
        }
        if ((layerDepth == 0) != (layerNodes == 0))
        {
            throw new ArgumentException("Layer depth and nodes must be coherent.");
        }
        ArgumentException.ThrowIfNullOrEmpty(invocationDigest);
        if (invocationDigest.Length != 64 ||
            invocationDigest.Any(character =>
                character is not (>= '0' and <= '9') and
                not (>= 'A' and <= 'F')))
        {
            throw new ArgumentException(
                "The invocation digest must be uppercase SHA-256.",
                nameof(invocationDigest));
        }
        return new(layerDepth, layerNodes, invocationDigest);
    }
}

internal interface ISemanticResourceMeterMirror<TInput, TValue>
{
    SemanticResourceLocalUsageMirror MeasureLocal(
        TInput input,
        TValue value,
        CancellationToken cancellationToken);
}

internal enum ResourceFailureMirror
{
    ProducerRejected,
    RegistrationMismatch,
    IntentInvalid,
}

internal abstract class ResourceProducerIntentMirror<TValue>
{
    private ResourceProducerIntentMirror()
    {
    }

    internal static ResourceProducerIntentMirror<TValue> Produced(
        TValue value,
        SemanticResourceLocalUsageMirror claimedLocalUsage) =>
        new ProducedIntent(
            value ?? throw new ArgumentNullException(nameof(value)),
            claimedLocalUsage ??
                throw new ArgumentNullException(nameof(claimedLocalUsage)));

    internal static ResourceProducerIntentMirror<TValue> Rejected(
        ResourceFailureMirror failure) =>
        new RejectedIntent(failure);

    internal abstract TResult Accept<TResult>(
        IResourceProducerIntentMirrorVisitor<TValue, TResult> visitor);

    private sealed class ProducedIntent : ResourceProducerIntentMirror<TValue>
    {
        private readonly TValue _value;
        private readonly SemanticResourceLocalUsageMirror _claimed;

        internal ProducedIntent(
            TValue value,
            SemanticResourceLocalUsageMirror claimed)
        {
            _value = value;
            _claimed = claimed;
        }

        internal override TResult Accept<TResult>(
            IResourceProducerIntentMirrorVisitor<TValue, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitProduced(_value, _claimed);
    }

    private sealed class RejectedIntent : ResourceProducerIntentMirror<TValue>
    {
        private readonly ResourceFailureMirror _failure;

        internal RejectedIntent(ResourceFailureMirror failure)
        {
            _failure = failure;
        }

        internal override TResult Accept<TResult>(
            IResourceProducerIntentMirrorVisitor<TValue, TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitRejected(_failure);
    }
}

internal interface IResourceProducerIntentMirrorVisitor<TValue, TResult>
{
    TResult VisitProduced(
        TValue value,
        SemanticResourceLocalUsageMirror claimedLocalUsage);

    TResult VisitRejected(ResourceFailureMirror failure);
}

internal abstract class ResourceQualificationMirrorResult
{
    private ResourceQualificationMirrorResult()
    {
    }

    internal static ResourceQualificationMirrorResult Qualified(
        SemanticResourceLocalUsageMirror measuredLocalUsage,
        SemanticResourceLedgerMirror ledger) =>
        new QualifiedResult(
            measuredLocalUsage ??
                throw new ArgumentNullException(nameof(measuredLocalUsage)),
            ledger ?? throw new ArgumentNullException(nameof(ledger)));

    internal static ResourceQualificationMirrorResult Rejected(
        ResourceFailureMirror failure) =>
        new RejectedResult(failure);

    internal abstract TResult Accept<TResult>(
        IResourceQualificationMirrorVisitor<TResult> visitor);

    private sealed class QualifiedResult : ResourceQualificationMirrorResult
    {
        private readonly SemanticResourceLocalUsageMirror _measured;
        private readonly SemanticResourceLedgerMirror _ledger;

        internal QualifiedResult(
            SemanticResourceLocalUsageMirror measured,
            SemanticResourceLedgerMirror ledger)
        {
            _measured = measured;
            _ledger = ledger;
        }

        internal override TResult Accept<TResult>(
            IResourceQualificationMirrorVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitQualified(_measured, _ledger);
    }

    private sealed class RejectedResult : ResourceQualificationMirrorResult
    {
        private readonly ResourceFailureMirror _failure;

        internal RejectedResult(ResourceFailureMirror failure)
        {
            _failure = failure;
        }

        internal override TResult Accept<TResult>(
            IResourceQualificationMirrorVisitor<TResult> visitor) =>
            (visitor ?? throw new ArgumentNullException(nameof(visitor)))
                .VisitRejected(_failure);
    }
}

internal interface IResourceQualificationMirrorVisitor<TResult>
{
    TResult VisitQualified(
        SemanticResourceLocalUsageMirror measuredLocalUsage,
        SemanticResourceLedgerMirror ledger);

    TResult VisitRejected(ResourceFailureMirror failure);
}

internal sealed class RepositoryTargetResourceCoordinatorMirror
{
    internal ResourceQualificationMirrorResult Qualify(
        RepositoryTargetResourceInputMirror input,
        ResourceProducerIntentMirror<RepositoryTargetResourceShapeMirror> intent,
        ISemanticResourceMeterMirror<RepositoryTargetResourceInputMirror,
            RepositoryTargetResourceShapeMirror>? meter,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(intent);
        cancellationToken.ThrowIfCancellationRequested();
        return intent.Accept(new IntentVisitor(input, meter, cancellationToken));
    }

    private sealed class IntentVisitor :
        IResourceProducerIntentMirrorVisitor<RepositoryTargetResourceShapeMirror,
            ResourceQualificationMirrorResult>
    {
        private readonly RepositoryTargetResourceInputMirror _input;
        private readonly ISemanticResourceMeterMirror<
            RepositoryTargetResourceInputMirror,
            RepositoryTargetResourceShapeMirror>? _meter;
        private readonly CancellationToken _token;

        internal IntentVisitor(
            RepositoryTargetResourceInputMirror input,
            ISemanticResourceMeterMirror<RepositoryTargetResourceInputMirror,
                RepositoryTargetResourceShapeMirror>? meter,
            CancellationToken token)
        {
            _input = input;
            _meter = meter;
            _token = token;
        }

        public ResourceQualificationMirrorResult VisitRejected(
            ResourceFailureMirror failure) =>
            ResourceQualificationMirrorResult.Rejected(failure);

        public ResourceQualificationMirrorResult VisitProduced(
            RepositoryTargetResourceShapeMirror value,
            SemanticResourceLocalUsageMirror claimedLocalUsage)
        {
            if (_meter is null)
            {
                return ResourceQualificationMirrorResult.Rejected(
                    ResourceFailureMirror.RegistrationMismatch);
            }
            var measured = _meter.MeasureLocal(_input, value, _token);
            if (!Equal(claimedLocalUsage, measured))
            {
                return ResourceQualificationMirrorResult.Rejected(
                    ResourceFailureMirror.IntentInvalid);
            }
            var fit = _input.Allowance.FitLocal(measured);
            if (!fit.Fits)
            {
                return ResourceQualificationMirrorResult.Rejected(
                    ResourceFailureMirror.IntentInvalid);
            }
            try
            {
                var contributions = new List<SemanticResourceContributionMirror>
                {
                    _input.SelectedPayload,
                };
                if (measured.GeneratedBytes > 0)
                {
                    contributions.Add(
                        SemanticResourceContributionMirror.GeneratedBytes(
                            "1|protocol.codec.repository-target-resolution|1|" +
                                value.InvocationDigest,
                            measured.GeneratedBytes));
                }
                if (measured.LayerNodes > 0)
                {
                    contributions.Add(SemanticResourceContributionMirror.Layer(
                        "2|protocol.codec.repository-target-resolution|1|" +
                            value.InvocationDigest,
                        measured.LayerDepth,
                        measured.LayerNodes));
                }
                if (measured.AdditionalComplexity > 0)
                {
                    contributions.Add(
                        SemanticResourceContributionMirror.ComplexityTerm(
                            "3|protocol.codec.repository-target-resolution|1|" +
                                value.InvocationDigest,
                            measured.AdditionalComplexity));
                }
                var ledger = SemanticResourceLedgerMirror.Create(contributions);
                if (fit.Aggregate is null || !Equal(fit.Aggregate, ledger.Usage))
                {
                    return ResourceQualificationMirrorResult.Rejected(
                        ResourceFailureMirror.IntentInvalid);
                }
                return ResourceQualificationMirrorResult.Qualified(
                    measured,
                    ledger);
            }
            catch (ResourceLedgerCollisionMirrorException)
            {
                return ResourceQualificationMirrorResult.Rejected(
                    ResourceFailureMirror.IntentInvalid);
            }
            catch (OverflowException)
            {
                return ResourceQualificationMirrorResult.Rejected(
                    ResourceFailureMirror.IntentInvalid);
            }
        }

        private static bool Equal(
            SemanticResourceLocalUsageMirror left,
            SemanticResourceLocalUsageMirror right) =>
            left.GeneratedBytes == right.GeneratedBytes &&
            left.LayerDepth == right.LayerDepth &&
            left.LayerNodes == right.LayerNodes &&
            left.AdditionalComplexity == right.AdditionalComplexity;

        private static bool Equal(
            SemanticResourceUsageMirror left,
            SemanticResourceUsageMirror right) =>
            left.Bytes == right.Bytes &&
            left.MaxDepth == right.MaxDepth &&
            left.Nodes == right.Nodes &&
            left.Complexity == right.Complexity;
    }
}

internal sealed class ResourceLedgerCollisionMirrorException : Exception
{
    internal ResourceLedgerCollisionMirrorException(string rowKey)
        : base($"Conflicting resource row: {rowKey}.")
    {
        ArgumentException.ThrowIfNullOrEmpty(rowKey);
        RowKey = rowKey;
    }

    internal string RowKey { get; }
}
