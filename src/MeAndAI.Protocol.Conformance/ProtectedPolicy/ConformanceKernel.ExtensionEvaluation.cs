using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Domain;

namespace MeAndAI.Protocol.Conformance;

public sealed partial class ConformanceKernel
{
    internal IReadOnlyList<ExtensionEvaluation> EvaluateExtensions(
        ActivatedExtensionPolicy activePolicy,
        ExecutionProfile profile,
        IReadOnlyCollection<string> sealedSlotKeys,
        IRuleInputAccess access,
        IReadOnlyDictionary<QualifiedEvidenceHandle, QualifiedEvidenceReference>
            references,
        CancellationToken cancellationToken = default) =>
        ExtensionEvaluationCore.Evaluate(
            activePolicy,
            profile,
            sealedSlotKeys,
            access,
            references,
            cancellationToken);
}
