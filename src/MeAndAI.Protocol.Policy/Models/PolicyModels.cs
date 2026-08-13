using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Policy.Models;

internal sealed class SourceTextModel : IProtocolSemanticModel;

internal sealed class RepositoryTreeModel : IProtocolSemanticModel;

internal sealed class RepositoryTargetResolutionModel : IProtocolSemanticModel;

internal sealed class MarkdownDocumentModel : IProtocolSemanticModel;

internal sealed class RepositoryTargetMarkdownDocumentSetModel :
    IProtocolSemanticModel;
