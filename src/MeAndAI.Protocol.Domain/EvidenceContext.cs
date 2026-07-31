namespace MeAndAI.Protocol.Domain;

public sealed class EvidenceContext : IEquatable<EvidenceContext>
{
    private readonly IReadOnlyList<RequirementAcquisition>
        _requirementAcquisitions;
    private readonly IReadOnlyList<EvidenceBinding> _bindings;
    private readonly IReadOnlyList<AcquisitionPage> _pages;
    private readonly IReadOnlyList<RootEvidenceReference> _references;

    private EvidenceContext(
        AcquisitionRequest request,
        EvidenceScope scope,
        RequirementAcquisition[] requirementAcquisitions,
        EvidenceBinding[] bindings,
        AcquisitionPage[] pages,
        long sourceObjectCount,
        AcquisitionStatus status,
        RootEvidenceReference[] references)
    {
        Request = request;
        Scope = scope;
        _requirementAcquisitions = EvidenceContractValidation.ReadOnly(
            requirementAcquisitions);
        _bindings = EvidenceContractValidation.ReadOnly(bindings);
        _pages = EvidenceContractValidation.ReadOnly(pages);
        SourceObjectCount = sourceObjectCount;
        Status = status;
        _references = EvidenceContractValidation.ReadOnly(references);
    }

    public AcquisitionRequest Request { get; }

    public EvidenceScope Scope { get; }

    public IReadOnlyList<RequirementAcquisition> RequirementAcquisitions =>
        _requirementAcquisitions;

    public IReadOnlyList<EvidenceBinding> Bindings => _bindings;

    public IReadOnlyList<AcquisitionPage> Pages => _pages;

    public long SourceObjectCount { get; }

    public AcquisitionStatus Status { get; }

    public IReadOnlyList<RootEvidenceReference> References => _references;

    public static EvidenceContext Create(
        AcquisitionRequest request,
        EvidenceScope scope,
        IEnumerable<RequirementAcquisition> requirementAcquisitions,
        IEnumerable<EvidenceBinding> bindings,
        IEnumerable<AcquisitionPage> pages,
        long sourceObjectCount)
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(scope);

        if (!scope.Target.Equals(request.Target))
        {
            throw new ArgumentException(
                "The evidence scope target must equal the request target.",
                nameof(scope));
        }

        if (sourceObjectCount < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(sourceObjectCount),
                sourceObjectCount,
                "A source-object count cannot be negative.");
        }

        var acquisitions = EvidenceContractValidation.Materialize(
            requirementAcquisitions,
            nameof(requirementAcquisitions));
        var materializedBindings = EvidenceContractValidation.Materialize(
            bindings,
            nameof(bindings));
        var materializedPages = EvidenceContractValidation.Materialize(
            pages,
            nameof(pages));

        EvidenceContractValidation.NoNullElements(
            acquisitions,
            nameof(requirementAcquisitions));
        EvidenceContractValidation.NoNullElements(
            materializedBindings,
            nameof(bindings));
        EvidenceContractValidation.NoNullElements(
            materializedPages,
            nameof(pages));

        ValidateRequirementAcquisitions(request, acquisitions);
        ValidateBindings(request, scope, materializedBindings);
        ValidatePayloadIdentity(materializedBindings);

        Array.Sort(
            acquisitions,
            static (left, right) => StringComparer.Ordinal.Compare(
                left.Requirement.Key,
                right.Requirement.Key));
        Array.Sort(materializedBindings, CompareBindings);
        Array.Sort(
            materializedPages,
            static (left, right) => left.Sequence.CompareTo(right.Sequence));

        ValidatePages(
            materializedPages,
            sourceObjectCount,
            acquisitions);

        var references = materializedBindings
            .Select(RootEvidenceReference.Create)
            .ToArray();
        var paginationIsComplete = materializedPages.Length == 0 ||
            materializedPages[^1].NextCursorDigest is null;
        var status = paginationIsComplete &&
            acquisitions.All(acquisition =>
                acquisition.Status.Equals(AcquisitionStatus.Complete))
                ? AcquisitionStatus.Complete
                : AcquisitionStatus.Incomplete;

        return new EvidenceContext(
            request,
            scope,
            acquisitions,
            materializedBindings,
            materializedPages,
            sourceObjectCount,
            status,
            references);
    }

    public bool Equals(EvidenceContext? other) =>
        other is not null &&
        Request.Equals(other.Request) &&
        Scope.Equals(other.Scope) &&
        _requirementAcquisitions.SequenceEqual(
            other._requirementAcquisitions) &&
        _bindings.SequenceEqual(other._bindings) &&
        _pages.SequenceEqual(other._pages) &&
        SourceObjectCount == other.SourceObjectCount &&
        Status.Equals(other.Status) &&
        _references.SequenceEqual(other._references);

    public override bool Equals(object? obj) =>
        Equals(obj as EvidenceContext);

    public override int GetHashCode()
    {
        var hash = new HashCode();
        hash.Add(Request);
        hash.Add(Scope);
        foreach (var acquisition in _requirementAcquisitions)
        {
            hash.Add(acquisition);
        }

        foreach (var binding in _bindings)
        {
            hash.Add(binding);
        }

        foreach (var page in _pages)
        {
            hash.Add(page);
        }

        hash.Add(SourceObjectCount);
        hash.Add(Status);
        foreach (var reference in _references)
        {
            hash.Add(reference);
        }

        return hash.ToHashCode();
    }

    private static void ValidateRequirementAcquisitions(
        AcquisitionRequest request,
        RequirementAcquisition[] acquisitions)
    {
        if (acquisitions.Length != request.RequestedRequirements.Count)
        {
            throw new ArgumentException(
                "Every requested requirement requires exactly one acquisition.",
                nameof(acquisitions));
        }

        var requestedByKey = request.RequestedRequirements.ToDictionary(
            requirement => requirement.Key,
            StringComparer.Ordinal);
        var coveredKeys = new HashSet<string>(StringComparer.Ordinal);

        foreach (var acquisition in acquisitions)
        {
            if (!requestedByKey.TryGetValue(
                    acquisition.Requirement.Key,
                    out var requestedRequirement) ||
                !requestedRequirement.Equals(acquisition.Requirement))
            {
                throw new ArgumentException(
                    "Requirement acquisitions must match the full requested requirements.",
                    nameof(acquisitions));
            }

            if (!coveredKeys.Add(acquisition.Requirement.Key))
            {
                throw new ArgumentException(
                    "A requested requirement cannot have multiple acquisitions.",
                    nameof(acquisitions));
            }
        }
    }

    private static void ValidateBindings(
        AcquisitionRequest request,
        EvidenceScope scope,
        EvidenceBinding[] bindings)
    {
        var requirementsByKey = request.RequestedRequirements.ToDictionary(
            requirement => requirement.Key,
            StringComparer.Ordinal);
        var physicalObservations =
            new HashSet<(EvidenceLocation, string, string)>();

        foreach (var binding in bindings)
        {
            if (!binding.Location.Scope.Equals(scope))
            {
                throw new ArgumentException(
                    "Every binding must belong to the evidence context scope.",
                    nameof(bindings));
            }

            foreach (var requirementKey in binding.RequirementKeys)
            {
                if (!requirementsByKey.TryGetValue(
                        requirementKey,
                        out var requirement))
                {
                    throw new ArgumentException(
                        "Every binding requirement key must be requested.",
                        nameof(bindings));
                }

                if (!StringComparer.Ordinal.Equals(
                        binding.Payload.SchemaKey,
                        requirement.PayloadSchemaKey) ||
                    !StringComparer.Ordinal.Equals(
                        binding.Payload.SchemaVersion,
                        requirement.PayloadSchemaVersion))
                {
                    throw new ArgumentException(
                        "A binding payload schema must match every contributed requirement.",
                        nameof(bindings));
                }
            }

            if (!physicalObservations.Add((
                    binding.Location,
                    binding.Payload.SchemaKey,
                    binding.Payload.SchemaVersion)))
            {
                throw new ArgumentException(
                    "A physical observation must be supplied exactly once.",
                    nameof(bindings));
            }
        }
    }

    private static void ValidatePayloadIdentity(EvidenceBinding[] bindings)
    {
        for (var leftIndex = 0;
             leftIndex < bindings.Length;
             leftIndex++)
        {
            var left = bindings[leftIndex].Payload;
            for (var rightIndex = leftIndex + 1;
                 rightIndex < bindings.Length;
                 rightIndex++)
            {
                var right = bindings[rightIndex].Payload;
                if (StringComparer.Ordinal.Equals(
                        left.SchemaKey,
                        right.SchemaKey) &&
                    StringComparer.Ordinal.Equals(
                        left.SchemaVersion,
                        right.SchemaVersion) &&
                    left.ContentDigest.Equals(right.ContentDigest) &&
                    !left.CanonicalBytes.SequenceEqual(right.CanonicalBytes))
                {
                    throw new ArgumentException(
                        "Equal payload identities must have byte-identical content.",
                        nameof(bindings));
                }
            }
        }
    }

    private static void ValidatePages(
        AcquisitionPage[] pages,
        long sourceObjectCount,
        RequirementAcquisition[] acquisitions)
    {
        if (pages.Length == 0)
        {
            return;
        }

        var requestCursors = new HashSet<ExactSha256Digest>();
        var nextCursors = new HashSet<ExactSha256Digest>();
        long observedSourceObjectCount = 0;

        for (var index = 0; index < pages.Length; index++)
        {
            var page = pages[index];
            var requestCursor = page.RequestCursorDigest;
            var nextCursor = page.NextCursorDigest;
            if (page.Sequence != index + 1)
            {
                throw new ArgumentException(
                    "Page sequences must be contiguous from one.",
                    nameof(pages));
            }

            if (index == 0)
            {
                if (requestCursor is not null)
                {
                    throw new ArgumentException(
                        "The first page cannot have a request cursor.",
                        nameof(pages));
                }
            }
            else
            {
                var previousNextCursor =
                    pages[index - 1].NextCursorDigest;
                if (requestCursor is null ||
                    previousNextCursor is null ||
                    !requestCursor.Equals(previousNextCursor))
                {
                    throw new ArgumentException(
                        "Adjacent page cursors must form one exact chain.",
                        nameof(pages));
                }

                if (!requestCursors.Add(requestCursor))
                {
                    throw new ArgumentException(
                        "Page request cursors must be unique.",
                        nameof(pages));
                }
            }

            if (index < pages.Length - 1 &&
                nextCursor is null)
            {
                throw new ArgumentException(
                    "Every non-final page requires a next cursor.",
                    nameof(pages));
            }

            if (nextCursor is not null &&
                !nextCursors.Add(nextCursor))
            {
                throw new ArgumentException(
                    "Page next cursors must be unique.",
                    nameof(pages));
            }

            observedSourceObjectCount = checked(
                observedSourceObjectCount + page.SourceObjectCount);
        }

        if (observedSourceObjectCount != sourceObjectCount)
        {
            throw new ArgumentException(
                "The page source-object sum must equal the context count.",
                nameof(sourceObjectCount));
        }

        if (pages[^1].NextCursorDigest is not null &&
            acquisitions.Any(acquisition =>
                !acquisition.Status.Equals(AcquisitionStatus.Incomplete) ||
                acquisition.Failures.Count == 0))
        {
            throw new ArgumentException(
                "Interrupted pagination requires a scoped incomplete failure for every requirement.",
                nameof(pages));
        }
    }

    private static int CompareBindings(
        EvidenceBinding left,
        EvidenceBinding right)
    {
        var comparison = CompareLocations(left.Location, right.Location);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Payload.SchemaKey,
            right.Payload.SchemaKey);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Payload.SchemaVersion,
            right.Payload.SchemaVersion);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Payload.ContentDigest.Value,
            right.Payload.ContentDigest.Value);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = left.CapturedAtUtc.CompareTo(right.CapturedAtUtc);
        return comparison != 0
            ? comparison
            : CompareStrings(
                left.RequirementKeys,
                right.RequirementKeys);
    }

    private static int CompareLocations(
        EvidenceLocation left,
        EvidenceLocation right)
    {
        var comparison = LocationRank(left).CompareTo(LocationRank(right));
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = CompareScopes(left.Scope, right.Scope);
        if (comparison != 0)
        {
            return comparison;
        }

        return (left, right) switch
        {
            (RepositoryEvidenceLocation leftRepository,
                RepositoryEvidenceLocation rightRepository) =>
                CompareRepositoryLocations(
                    leftRepository,
                    rightRepository),
            (ProviderEvidenceLocation leftProvider,
                ProviderEvidenceLocation rightProvider) =>
                CompareProviderLocations(leftProvider, rightProvider),
            (ReleaseAssetEvidenceLocation leftRelease,
                ReleaseAssetEvidenceLocation rightRelease) =>
                CompareReleaseLocations(leftRelease, rightRelease),
            (SnapshotEvidenceLocation, SnapshotEvidenceLocation) => 0,
            _ => throw new InvalidOperationException(
                "The evidence location family is not closed."),
        };
    }

    private static int CompareScopes(EvidenceScope left, EvidenceScope right)
    {
        var comparison = StringComparer.Ordinal.Compare(
            left.Target.SubjectIdentity,
            right.Target.SubjectIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Target.SourceIdentity,
            right.Target.SourceIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Target.Surface.Value,
            right.Target.Surface.Value);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Target.SnapshotKind.Value,
            right.Target.SnapshotKind.Value);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Target.TargetIdentity,
            right.Target.TargetIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Boundary.SnapshotKind.Value,
            right.Boundary.SnapshotKind.Value);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.Boundary.BoundaryIdentity,
            right.Boundary.BoundaryIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = left.Boundary.StartedAtUtc.CompareTo(
            right.Boundary.StartedAtUtc);
        return comparison != 0
            ? comparison
            : left.Boundary.CompletedAtUtc.CompareTo(
                right.Boundary.CompletedAtUtc);
    }

    private static int CompareRepositoryLocations(
        RepositoryEvidenceLocation left,
        RepositoryEvidenceLocation right)
    {
        var comparison = StringComparer.Ordinal.Compare(
            left.RepositoryRelativePath,
            right.RepositoryRelativePath);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.BlobIdentity,
            right.BlobIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = CompareNullableIntegers(left.Line, right.Line);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(left.Anchor, right.Anchor);
        return comparison != 0
            ? comparison
            : StringComparer.Ordinal.Compare(left.Property, right.Property);
    }

    private static int CompareProviderLocations(
        ProviderEvidenceLocation left,
        ProviderEvidenceLocation right)
    {
        var comparison = StringComparer.Ordinal.Compare(
            left.ProviderServiceIdentity,
            right.ProviderServiceIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.ObjectType,
            right.ObjectType);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.StableObjectIdentity,
            right.StableObjectIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.VersionIdentity,
            right.VersionIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(left.Field, right.Field);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = CompareNullableIntegers(left.Line, right.Line);
        return comparison != 0
            ? comparison
            : StringComparer.Ordinal.Compare(left.Fragment, right.Fragment);
    }

    private static int CompareReleaseLocations(
        ReleaseAssetEvidenceLocation left,
        ReleaseAssetEvidenceLocation right)
    {
        var comparison = StringComparer.Ordinal.Compare(
            left.ReleaseObjectIdentity,
            right.ReleaseObjectIdentity);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(left.Tag, right.Tag);
        if (comparison != 0)
        {
            return comparison;
        }

        comparison = StringComparer.Ordinal.Compare(
            left.AssetName,
            right.AssetName);
        return comparison != 0
            ? comparison
            : StringComparer.Ordinal.Compare(
                left.AssetDigest.Value,
                right.AssetDigest.Value);
    }

    private static int CompareStrings(
        IReadOnlyList<string> left,
        IReadOnlyList<string> right)
    {
        var sharedLength = Math.Min(left.Count, right.Count);
        for (var index = 0; index < sharedLength; index++)
        {
            var comparison = StringComparer.Ordinal.Compare(
                left[index],
                right[index]);
            if (comparison != 0)
            {
                return comparison;
            }
        }

        return left.Count.CompareTo(right.Count);
    }

    private static int CompareNullableIntegers(int? left, int? right)
    {
        if (!left.HasValue)
        {
            return right.HasValue ? -1 : 0;
        }

        return right.HasValue ? left.Value.CompareTo(right.Value) : 1;
    }

    private static int LocationRank(EvidenceLocation location) =>
        location switch
        {
            RepositoryEvidenceLocation => 0,
            ProviderEvidenceLocation => 1,
            ReleaseAssetEvidenceLocation => 2,
            SnapshotEvidenceLocation => 3,
            _ => throw new InvalidOperationException(
                "The evidence location family is not closed."),
        };
}
