using System.Diagnostics.CodeAnalysis;

namespace MeAndAI.Protocol.Conformance;

public sealed class ProtectedPolicyIntegrityException : InvalidOperationException
{
    internal ProtectedPolicyIntegrityException(ProtectedPolicyIntegrityCode code)
        : base(BuildMessage(code))
    {
        Code = code;
    }

    public ProtectedPolicyIntegrityCode Code { get; }

    private static string BuildMessage(ProtectedPolicyIntegrityCode code)
    {
        ArgumentNullException.ThrowIfNull(code);
        return code.Value;
    }
}

public sealed class ProtectedPolicyIntegrityCode : IEquatable<ProtectedPolicyIntegrityCode>
{
    public static ProtectedPolicyIntegrityCode ActivationProofInvalid { get; } =
        new("protocol.policy.activation-proof-invalid");
    public static ProtectedPolicyIntegrityCode ActiveSnapshotMismatch { get; } =
        new("protocol.policy.active-snapshot-mismatch");
    public static ProtectedPolicyIntegrityCode ExtensionShadow { get; } =
        new("protocol.policy.extension-shadow");
    public static ProtectedPolicyIntegrityCode ExtensionEvaluatorUnregistered { get; } =
        new("protocol.policy.extension-evaluator-unregistered");
    public static ProtectedPolicyIntegrityCode ExtensionDefinitionInvalid { get; } =
        new("protocol.policy.extension-definition-invalid");
    public static ProtectedPolicyIntegrityCode ProposedTransitionInvalid { get; } =
        new("protocol.policy.proposed-transition-invalid");
    public static ProtectedPolicyIntegrityCode WaiverInvalid { get; } =
        new("protocol.policy.waiver-invalid");
    public static ProtectedPolicyIntegrityCode DebtInvalid { get; } =
        new("protocol.policy.debt-invalid");
    public static ProtectedPolicyIntegrityCode EvaluationContextMismatch { get; } =
        new("protocol.policy.evaluation-context-mismatch");
    public static ProtectedPolicyIntegrityCode PredecessorTrustInvalid { get; } =
        new("protocol.policy.predecessor-trust-invalid");
    public static ProtectedPolicyIntegrityCode DifferentialUnexplained { get; } =
        new("protocol.policy.differential-unexplained");
    public static ProtectedPolicyIntegrityCode CandidateSelfCertification { get; } =
        new("protocol.policy.candidate-self-certification");
    public static ProtectedPolicyIntegrityCode PolicyPackBindingInvalid { get; } =
        new("protocol.policy.policy-pack-binding-invalid");
    public static ProtectedPolicyIntegrityCode DispositionAuthorityInvalid { get; } =
        new("protocol.policy.disposition-authority-invalid");
    public static ProtectedPolicyIntegrityCode ResourceLimitExceeded { get; } =
        new("protocol.policy.resource-limit-exceeded");

    private ProtectedPolicyIntegrityCode(string value) => Value = value;

    public string Value { get; }

    public static ProtectedPolicyIntegrityCode Parse(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        return TryParse(value, out var result)
            ? result
            : throw new FormatException("The value is not a protected-policy integrity code.");
    }

    public static bool TryParse(
        string? value,
        [NotNullWhen(true)] out ProtectedPolicyIntegrityCode? result)
    {
        result = All.FirstOrDefault(code =>
            string.Equals(code.Value, value, StringComparison.Ordinal));
        return result is not null;
    }

    public bool Equals(ProtectedPolicyIntegrityCode? other) =>
        other is not null && string.Equals(Value, other.Value, StringComparison.Ordinal);

    public override bool Equals(object? obj) => Equals(obj as ProtectedPolicyIntegrityCode);
    public override int GetHashCode() => StringComparer.Ordinal.GetHashCode(Value);
    public override string ToString() => Value;

    private static IReadOnlyList<ProtectedPolicyIntegrityCode> All =>
    [
        ActivationProofInvalid,
        ActiveSnapshotMismatch,
        ExtensionShadow,
        ExtensionEvaluatorUnregistered,
        ExtensionDefinitionInvalid,
        ProposedTransitionInvalid,
        WaiverInvalid,
        DebtInvalid,
        EvaluationContextMismatch,
        PredecessorTrustInvalid,
        DifferentialUnexplained,
        CandidateSelfCertification,
        PolicyPackBindingInvalid,
        DispositionAuthorityInvalid,
        ResourceLimitExceeded,
    ];
}
