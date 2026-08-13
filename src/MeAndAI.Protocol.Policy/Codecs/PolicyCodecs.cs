using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;

namespace MeAndAI.Protocol.Policy.Codecs;

internal sealed class GovernedTextCodec :
    ICanonicalPayloadCodec<SourceTextModel>;

internal sealed class RepositoryTreeCodec :
    ICanonicalPayloadCodec<RepositoryTreeModel>;

internal sealed class RepositoryTargetResolutionCodec :
    ICanonicalPayloadCodec<RepositoryTargetResolutionModel>;
