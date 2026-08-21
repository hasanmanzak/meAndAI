using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance.Abstractions;

internal static class ProtectedPolicyFrame
{
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);

    internal static ExactSha256Digest Hash(string separator, Action<MemoryStream> write)
    {
        var (digest, _) = HashWithLength(separator, write);
        return digest;
    }

    internal static (ExactSha256Digest Digest, long ByteLength) HashWithLength(
        string separator,
        Action<MemoryStream> write)
    {
        using var stream = new MemoryStream();
        stream.Write(Encoding.ASCII.GetBytes(separator));
        write(stream);
        return (
            ExactSha256Digest.FromHashBytes(SHA256.HashData(stream.ToArray())),
            stream.Length);
    }

    internal static void String(MemoryStream stream, string value)
    {
        var bytes = StrictUtf8.GetBytes(value);
        UInt32(stream, checked((uint)bytes.Length));
        stream.Write(bytes);
    }

    internal static void Digest(MemoryStream stream, ExactSha256Digest value) =>
        stream.Write(Convert.FromHexString(value.Value));

    internal static void UInt32(MemoryStream stream, uint value)
    {
        Span<byte> bytes = stackalloc byte[4];
        BinaryPrimitives.WriteUInt32BigEndian(bytes, value);
        stream.Write(bytes);
    }

    internal static void Int64(MemoryStream stream, long value)
    {
        Span<byte> bytes = stackalloc byte[8];
        BinaryPrimitives.WriteInt64BigEndian(bytes, value);
        stream.Write(bytes);
    }

    internal static void Bool(MemoryStream stream, bool value) =>
        stream.WriteByte(value ? (byte)1 : (byte)0);

    internal static void OptionalDigest(MemoryStream stream, ExactSha256Digest? value)
    {
        Bool(stream, value is not null);
        if (value is not null)
        {
            Digest(stream, value);
        }
    }

    internal static void OptionalTicks(MemoryStream stream, DateTimeOffset? value)
    {
        Bool(stream, value.HasValue);
        if (value.HasValue)
        {
            Int64(stream, value.Value.Ticks);
        }
    }

    internal static void RequireDigest(ExactSha256Digest value, string paramName)
    {
        ArgumentNullException.ThrowIfNull(value, paramName);
        if (value.Value.All(static c => c == '0'))
        {
            throw new ArgumentException("A zero digest is not valid here.", paramName);
        }
    }

    internal static string Text(
        string value,
        string paramName,
        int maximumBytes,
        bool allowEmpty = false)
    {
        ArgumentNullException.ThrowIfNull(value, paramName);
        if (!TryUtf8ByteCount(value, out var byteCount) ||
            (!allowEmpty && byteCount == 0) ||
            value.Contains('\0') || value.Contains('\r'))
        {
            throw new ArgumentException("The text is outside its canonical bounds.", paramName);
        }
        if (byteCount > maximumBytes)
        {
            throw new ArgumentOutOfRangeException(paramName);
        }

        return value;
    }

    internal static bool TryUtf8ByteCount(string value, out int byteCount)
    {
        try
        {
            byteCount = StrictUtf8.GetByteCount(value);
            return true;
        }
        catch (EncoderFallbackException)
        {
            byteCount = 0;
            return false;
        }
    }

    internal static string LowerAsciiToken(
        string value,
        string paramName,
        int maximumBytes)
    {
        Text(value, paramName, maximumBytes);
        foreach (var character in value)
        {
            if (character is not (>= 'a' and <= 'z') and not (>= '0' and <= '9') and
                not ('.' or '-'))
            {
                throw new ArgumentException("The value is not a lowercase ASCII token.", paramName);
            }
        }

        return value;
    }

    internal static string ParameterKey(string value, string paramName)
    {
        var token = LowerAsciiToken(value, paramName, 64);
        if (!IsAlphaNumeric(token[0]) || !IsAlphaNumeric(token[^1]))
        {
            throw new ArgumentException(
                "A parameter key must start and end with lowercase ASCII alphanumeric characters.",
                paramName);
        }

        return token;
    }

    internal static byte[] ExactBytes(
        IEnumerable<byte> values,
        int expectedLength,
        string paramName)
    {
        ArgumentNullException.ThrowIfNull(values, paramName);
        if (expectedLength < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(expectedLength));
        }

        var result = new byte[expectedLength];
        var count = 0;
        foreach (var value in values)
        {
            if (count == expectedLength)
            {
                throw new ArgumentOutOfRangeException(paramName);
            }

            result[count++] = value;
        }

        if (count != expectedLength)
        {
            throw new ArgumentException(
                $"The input requires exactly {expectedLength} bytes.",
                paramName);
        }

        return result;
    }

    private static bool IsAlphaNumeric(char value) =>
        value is >= 'a' and <= 'z' or >= '0' and <= '9';

    internal static string GitObjectId(string value, string paramName)
    {
        ArgumentNullException.ThrowIfNull(value, paramName);
        if (value.Length != 40 || value.Any(static c =>
                c is not (>= '0' and <= '9') and not (>= 'a' and <= 'f')))
        {
            throw new ArgumentException("The value is not an exact Git object identity.", paramName);
        }

        return value;
    }

    internal static IReadOnlyList<T> SortedUnique<T>(
        IEnumerable<T> values,
        Func<T, string> key,
        string paramName,
        int maximum = int.MaxValue,
        bool requireInputOrder = false,
        Action<T>? beforeRetain = null)
        where T : class
    {
        ArgumentNullException.ThrowIfNull(values, paramName);
        var materialized = new List<T>(Math.Min(maximum, 256));
        foreach (var value in values)
        {
            if (value is null)
            {
                throw new ArgumentException("Null collection elements are not allowed.", paramName);
            }
            if (materialized.Count == maximum)
            {
                throw new ArgumentOutOfRangeException(paramName);
            }

            beforeRetain?.Invoke(value);
            materialized.Add(value);
        }

        var ordered = materialized.OrderBy(key, StringComparer.Ordinal).ToArray();
        if (ordered.Select(key).Distinct(StringComparer.Ordinal).Count() != ordered.Length)
        {
            throw new ArgumentException("Duplicate canonical identities are not allowed.", paramName);
        }
        if (requireInputOrder && !ordered.Select(key)
                .SequenceEqual(materialized.Select(key), StringComparer.Ordinal))
        {
            throw new ArgumentException("The collection is not in canonical ordinal order.", paramName);
        }

        return Array.AsReadOnly(ordered);
    }
}

public sealed class ExtensionParameter
{
    private ExtensionParameter(string key, string value)
    {
        Key = key;
        Value = value;
    }

    public string Key { get; }
    public string Value { get; }

    public static ExtensionParameter Create(string key, string value) =>
        new(
            ProtectedPolicyFrame.ParameterKey(key, nameof(key)),
            ProtectedPolicyFrame.Text(value, nameof(value), 4096, allowEmpty: true));
}

public sealed class ExtensionRuleDeclaration
{
    private ExtensionRuleDeclaration(
        ExtensionId extensionId,
        RuleRevision revision,
        string evaluatorKind,
        string evaluatorVersion,
        IReadOnlyList<ExtensionParameter> parameters,
        IReadOnlyList<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IReadOnlyList<SnapshotKind> snapshotKinds,
        IReadOnlyList<ProtocolOperation> operations,
        ExactSha256Digest definitionDigest)
    {
        ExtensionId = extensionId;
        Revision = revision;
        EvaluatorKind = evaluatorKind;
        EvaluatorVersion = evaluatorVersion;
        Parameters = parameters;
        SubjectRoles = subjectRoles;
        Surfaces = surfaces;
        SnapshotKinds = snapshotKinds;
        Operations = operations;
        DefinitionDigest = definitionDigest;
    }

    public ExtensionId ExtensionId { get; }
    public RuleRevision Revision { get; }
    public string EvaluatorKind { get; }
    public string EvaluatorVersion { get; }
    public IReadOnlyList<ExtensionParameter> Parameters { get; }
    public IReadOnlyList<SubjectRole> SubjectRoles { get; }
    public SurfaceSet Surfaces { get; }
    public IReadOnlyList<SnapshotKind> SnapshotKinds { get; }
    public IReadOnlyList<ProtocolOperation> Operations { get; }
    public ExactSha256Digest DefinitionDigest { get; }

    public static ExtensionRuleDeclaration Create(
        ExtensionId extensionId,
        RuleRevision revision,
        string evaluatorKind,
        string evaluatorVersion,
        IEnumerable<ExtensionParameter> parameters,
        IEnumerable<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IEnumerable<SnapshotKind> snapshotKinds,
        IEnumerable<ProtocolOperation> operations,
        ExactSha256Digest definitionDigest)
    {
        ArgumentNullException.ThrowIfNull(extensionId);
        ArgumentNullException.ThrowIfNull(revision);
        ArgumentNullException.ThrowIfNull(surfaces);
        ProtectedPolicyFrame.RequireDigest(definitionDigest, nameof(definitionDigest));
        var parameterRows = ProtectedPolicyFrame.SortedUnique(
            parameters, static value => value.Key, nameof(parameters), 64,
            requireInputOrder: true);

        var roles = ProtectedPolicyFrame.SortedUnique(
            subjectRoles, static value => value.Value, nameof(subjectRoles));
        var snapshots = ProtectedPolicyFrame.SortedUnique(
            snapshotKinds, static value => value.Value, nameof(snapshotKinds));
        var operationRows = ProtectedPolicyFrame.SortedUnique(
            operations, static value => value.Value, nameof(operations));
        if (roles.Count == 0 || surfaces.Values.Count == 0 || snapshots.Count == 0 ||
            operationRows.Count == 0)
        {
            throw new ArgumentException("Every declaration category must be nonempty.");
        }

        var kind = ProtectedPolicyFrame.LowerAsciiToken(evaluatorKind, nameof(evaluatorKind), 128);
        var version = ProtectedPolicyFrame.Text(evaluatorVersion, nameof(evaluatorVersion), 32);
        var computed = ComputeDefinition(
            extensionId, revision, kind, version, parameterRows, roles, surfaces,
            snapshots, operationRows);
        if (!computed.Equals(definitionDigest))
        {
            throw new ArgumentException("The definition digest does not match the declaration.", nameof(definitionDigest));
        }

        return new ExtensionRuleDeclaration(
            extensionId, revision, kind, version, parameterRows, roles, surfaces,
            snapshots, operationRows, computed);
    }

    internal static ExactSha256Digest ComputeDefinition(
        ExtensionId extensionId,
        RuleRevision revision,
        string evaluatorKind,
        string evaluatorVersion,
        IReadOnlyList<ExtensionParameter> parameters,
        IReadOnlyList<SubjectRole> subjectRoles,
        SurfaceSet surfaces,
        IReadOnlyList<SnapshotKind> snapshotKinds,
        IReadOnlyList<ProtocolOperation> operations) =>
        ProtectedPolicyFrame.Hash("protocol.extension-declaration/1\n", stream =>
        {
            ProtectedPolicyFrame.String(stream, extensionId.Value);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)revision.Value));
            ProtectedPolicyFrame.String(stream, evaluatorKind);
            ProtectedPolicyFrame.String(stream, evaluatorVersion);
            WriteTokens(stream, parameters, static row => row.Key, static row => row.Value);
            WriteTokens(stream, subjectRoles, static row => row.Value);
            WriteTokens(stream, surfaces.Values, static row => row.Value);
            WriteTokens(stream, snapshotKinds, static row => row.Value);
            WriteTokens(stream, operations, static row => row.Value);
        });

    private static void WriteTokens<T>(MemoryStream stream, IReadOnlyList<T> rows, params Func<T, string>[] selectors)
    {
        ProtectedPolicyFrame.UInt32(stream, checked((uint)rows.Count));
        foreach (var row in rows)
        {
            foreach (var selector in selectors)
            {
                ProtectedPolicyFrame.String(stream, selector(row));
            }
        }
    }
}

public sealed class ExtensionCatalogSnapshot
{
    private ExtensionCatalogSnapshot(
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        ExactSha256Digest snapshotDigest,
        IReadOnlyList<ExtensionRuleDeclaration> extensions)
    {
        RepositoryNamespace = repositoryNamespace;
        PolicyBlobDigest = policyBlobDigest;
        SnapshotDigest = snapshotDigest;
        Extensions = extensions;
    }

    public string RepositoryNamespace { get; }
    public ExactSha256Digest PolicyBlobDigest { get; }
    public ExactSha256Digest SnapshotDigest { get; }
    public IReadOnlyList<ExtensionRuleDeclaration> Extensions { get; }

    public static ExtensionCatalogSnapshot Create(
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        ExactSha256Digest snapshotDigest,
        IEnumerable<ExtensionRuleDeclaration> extensions)
    {
        var repository = ProtectedPolicyFrame.LowerAsciiToken(
            repositoryNamespace, nameof(repositoryNamespace), 96);
        ProtectedPolicyFrame.RequireDigest(policyBlobDigest, nameof(policyBlobDigest));
        ProtectedPolicyFrame.RequireDigest(snapshotDigest, nameof(snapshotDigest));
        long aggregateParameterBytes = 0;
        var rows = ProtectedPolicyFrame.SortedUnique(
            extensions,
            static row => row.ExtensionId.Value,
            nameof(extensions),
            10_000,
            beforeRetain: row =>
            {
                foreach (var parameter in row.Parameters)
                {
                    ProtectedPolicyFrame.TryUtf8ByteCount(parameter.Value, out var valueBytes);
                    var parameterBytes = (long)parameter.Key.Length + valueBytes;
                    if (aggregateParameterBytes > 8_388_608 - parameterBytes)
                    {
                        throw new ArgumentException(
                            "The aggregate extension parameter payload exceeds its canonical bound.",
                            nameof(extensions));
                    }

                    aggregateParameterBytes += parameterBytes;
                }
            });

        var computed = ComputeDigest(repository, policyBlobDigest, rows);
        if (!computed.Equals(snapshotDigest))
        {
            throw new ArgumentException("The snapshot digest does not match the snapshot.", nameof(snapshotDigest));
        }

        return new ExtensionCatalogSnapshot(repository, policyBlobDigest, computed, rows);
    }

    internal static ExactSha256Digest ComputeDigest(
        string repositoryNamespace,
        ExactSha256Digest policyBlobDigest,
        IReadOnlyList<ExtensionRuleDeclaration> extensions) =>
        ProtectedPolicyFrame.Hash("protocol.extension-snapshot/1\n", stream =>
        {
            ProtectedPolicyFrame.String(stream, repositoryNamespace);
            ProtectedPolicyFrame.Digest(stream, policyBlobDigest);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)extensions.Count));
            foreach (var row in extensions)
            {
                ProtectedPolicyFrame.String(stream, row.ExtensionId.Value);
                ProtectedPolicyFrame.UInt32(stream, checked((uint)row.Revision.Value));
                ProtectedPolicyFrame.Digest(stream, row.DefinitionDigest);
            }
        });
}

public sealed class ProposedExtensionChange
{
    private ProposedExtensionChange(
        ExtensionId extensionId,
        ExtensionTransitionKind kind,
        ExactSha256Digest? previousDefinitionDigest,
        ExactSha256Digest? proposedDefinitionDigest)
    {
        ExtensionId = extensionId;
        Kind = kind;
        PreviousDefinitionDigest = previousDefinitionDigest;
        ProposedDefinitionDigest = proposedDefinitionDigest;
    }

    public ExtensionId ExtensionId { get; }
    public ExtensionTransitionKind Kind { get; }
    public ExactSha256Digest? PreviousDefinitionDigest { get; }
    public ExactSha256Digest? ProposedDefinitionDigest { get; }

    public static ProposedExtensionChange Create(
        ExtensionId extensionId,
        ExtensionTransitionKind kind,
        ExactSha256Digest? previousDefinitionDigest,
        ExactSha256Digest? proposedDefinitionDigest)
    {
        ArgumentNullException.ThrowIfNull(extensionId);
        ArgumentNullException.ThrowIfNull(kind);
        if (previousDefinitionDigest is not null)
        {
            ProtectedPolicyFrame.RequireDigest(
                previousDefinitionDigest,
                nameof(previousDefinitionDigest));
        }
        if (proposedDefinitionDigest is not null)
        {
            ProtectedPolicyFrame.RequireDigest(
                proposedDefinitionDigest,
                nameof(proposedDefinitionDigest));
        }

        var valid = kind.Equals(ExtensionTransitionKind.Added)
            ? previousDefinitionDigest is null && proposedDefinitionDigest is not null
            : kind.Equals(ExtensionTransitionKind.Removed)
                ? previousDefinitionDigest is not null && proposedDefinitionDigest is null
                : previousDefinitionDigest is not null && proposedDefinitionDigest is not null &&
                  !previousDefinitionDigest.Equals(proposedDefinitionDigest);
        if (!valid)
        {
            throw new ArgumentException("The transition digest tuple does not match its kind.");
        }

        return new ProposedExtensionChange(
            extensionId, kind, previousDefinitionDigest, proposedDefinitionDigest);
    }
}

public sealed class ProposedExtensionTransition
{
    private ProposedExtensionTransition(
        ExtensionCatalogSnapshot activeSnapshot,
        ExtensionCatalogSnapshot proposedSnapshot,
        string targetCommit,
        ExactSha256Digest rationaleDigest,
        IReadOnlyList<ProposedExtensionChange> changes,
        ExactSha256Digest transitionDigest)
    {
        ActiveSnapshot = activeSnapshot;
        ProposedSnapshot = proposedSnapshot;
        TargetCommit = targetCommit;
        RationaleDigest = rationaleDigest;
        Changes = changes;
        TransitionDigest = transitionDigest;
    }

    public ExtensionCatalogSnapshot ActiveSnapshot { get; }
    public ExtensionCatalogSnapshot ProposedSnapshot { get; }
    public string TargetCommit { get; }
    public ExactSha256Digest RationaleDigest { get; }
    public IReadOnlyList<ProposedExtensionChange> Changes { get; }
    public ExactSha256Digest TransitionDigest { get; }

    public static ProposedExtensionTransition Create(
        ExtensionCatalogSnapshot activeSnapshot,
        ExtensionCatalogSnapshot proposedSnapshot,
        string targetCommit,
        ExactSha256Digest rationaleDigest,
        IEnumerable<ProposedExtensionChange> changes)
    {
        ArgumentNullException.ThrowIfNull(activeSnapshot);
        ArgumentNullException.ThrowIfNull(proposedSnapshot);
        ProtectedPolicyFrame.RequireDigest(rationaleDigest, nameof(rationaleDigest));
        var target = ProtectedPolicyFrame.GitObjectId(targetCommit, nameof(targetCommit));
        if (!string.Equals(activeSnapshot.RepositoryNamespace, proposedSnapshot.RepositoryNamespace, StringComparison.Ordinal))
        {
            throw new ArgumentException("Active and proposed namespaces must match.", nameof(proposedSnapshot));
        }

        var rows = ProtectedPolicyFrame.SortedUnique(
            changes, static row => row.ExtensionId.Value, nameof(changes), 10_000);
        if (rows.Count == 0)
        {
            throw new ArgumentException("A proposed transition must change at least one extension.", nameof(changes));
        }

        ValidateExactDiff(activeSnapshot, proposedSnapshot, rows);
        var digest = ComputeDigest(
            activeSnapshot.SnapshotDigest,
            proposedSnapshot.SnapshotDigest,
            target,
            rationaleDigest,
            rows);
        return new ProposedExtensionTransition(
            activeSnapshot, proposedSnapshot, target, rationaleDigest, rows, digest);
    }

    internal static ExactSha256Digest ComputeDigest(
        ExactSha256Digest activeSnapshotDigest,
        ExactSha256Digest proposedSnapshotDigest,
        string targetCommit,
        ExactSha256Digest rationaleDigest,
        IReadOnlyList<ProposedExtensionChange> changes) =>
        ProtectedPolicyFrame.Hash("protocol.proposed-extension-transition/1\n", stream =>
        {
            ProtectedPolicyFrame.Digest(stream, activeSnapshotDigest);
            ProtectedPolicyFrame.Digest(stream, proposedSnapshotDigest);
            ProtectedPolicyFrame.String(stream, targetCommit);
            ProtectedPolicyFrame.Digest(stream, rationaleDigest);
            ProtectedPolicyFrame.UInt32(stream, checked((uint)changes.Count));
            foreach (var row in changes)
            {
                ProtectedPolicyFrame.String(stream, row.ExtensionId.Value);
                ProtectedPolicyFrame.String(stream, row.Kind.Value);
                ProtectedPolicyFrame.OptionalDigest(stream, row.PreviousDefinitionDigest);
                ProtectedPolicyFrame.OptionalDigest(stream, row.ProposedDefinitionDigest);
            }
        });

    private static void ValidateExactDiff(
        ExtensionCatalogSnapshot active,
        ExtensionCatalogSnapshot proposed,
        IReadOnlyList<ProposedExtensionChange> supplied)
    {
        var oldRows = active.Extensions.ToDictionary(static row => row.ExtensionId.Value, StringComparer.Ordinal);
        var newRows = proposed.Extensions.ToDictionary(static row => row.ExtensionId.Value, StringComparer.Ordinal);
        var expected = new List<(string Key, ExtensionTransitionKind Kind, ExactSha256Digest? Old, ExactSha256Digest? New)>();
        foreach (var key in oldRows.Keys.Union(newRows.Keys, StringComparer.Ordinal).Order(StringComparer.Ordinal))
        {
            oldRows.TryGetValue(key, out var before);
            newRows.TryGetValue(key, out var after);
            if (before is null)
            {
                expected.Add((key, ExtensionTransitionKind.Added, null, after!.DefinitionDigest));
            }
            else if (after is null)
            {
                expected.Add((key, ExtensionTransitionKind.Removed, before.DefinitionDigest, null));
            }
            else if (!before.DefinitionDigest.Equals(after.DefinitionDigest))
            {
                if (before.Revision.Value == int.MaxValue || after.Revision.Value != before.Revision.Value + 1)
                {
                    throw new ArgumentException("A revised extension must advance exactly one revision.", nameof(proposed));
                }

                expected.Add((key, ExtensionTransitionKind.Revised, before.DefinitionDigest, after.DefinitionDigest));
            }
            else if (!before.Revision.Equals(after.Revision))
            {
                throw new ArgumentException(
                    "An unchanged definition cannot carry revision-only drift.",
                    nameof(proposed));
            }
        }

        if (expected.Count != supplied.Count || expected.Where((row, index) =>
                !string.Equals(row.Key, supplied[index].ExtensionId.Value, StringComparison.Ordinal) ||
                !row.Kind.Equals(supplied[index].Kind) ||
                !Equals(row.Old, supplied[index].PreviousDefinitionDigest) ||
                !Equals(row.New, supplied[index].ProposedDefinitionDigest)).Any())
        {
            throw new ArgumentException("The proposed change set is not the exact snapshot difference.", nameof(supplied));
        }
    }
}
