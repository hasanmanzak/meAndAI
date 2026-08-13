using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;

namespace MeAndAI.Protocol.Policy.Parsers;

internal sealed class SourceTextInput : IComponentInput;

internal sealed class RepositoryTargetInput : IComponentInput;

internal sealed class MarkdownDocumentParser :
    ISemanticModelParser<SourceTextInput, MarkdownDocumentModel>;

internal sealed class RepositoryTargetMarkdownDocumentParser :
    ISemanticModelParser<RepositoryTargetInput,
        RepositoryTargetMarkdownDocumentSetModel>;
