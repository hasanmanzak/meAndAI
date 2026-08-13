using MeAndAI.Protocol.Conformance.Abstractions;
using MeAndAI.Protocol.Policy.Models;
using System.Text;

namespace MeAndAI.Protocol.Policy.Parsers;

internal sealed class SourceTextInput : IComponentInput
{
    internal SourceTextInput(SealedModelHandle<SourceTextModel> source) =>
        Source = source ?? throw new ArgumentNullException(nameof(source));

    internal SealedModelHandle<SourceTextModel> Source { get; }
}

internal sealed class RepositoryTargetInput : IComponentInput
{
    internal RepositoryTargetInput(
        SealedModelHandle<RepositoryTargetResolutionModel> source) =>
        Source = source ?? throw new ArgumentNullException(nameof(source));

    internal SealedModelHandle<RepositoryTargetResolutionModel> Source { get; }
}

internal sealed class MarkdownDocumentParser :
    ISemanticModelParser<SourceTextInput, MarkdownDocumentModel>
{
    private static readonly UTF8Encoding StrictUtf8 = new(false, true);

    public SemanticModelIntent<MarkdownDocumentModel> Parse(
        SemanticModelInput<SourceTextInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var source = input.Value.Source;
        var text = StrictUtf8.GetString(source.Value.Body.Span);
        var model = new MarkdownDocumentModel(source.Evidence, text);
        return SemanticModelIntent<MarkdownDocumentModel>.Produced(
            SemanticModelProduct<MarkdownDocumentModel>.Create(
                model,
                source.Evidence,
                "markdown-document",
                source.Value.Binding.Payload.ContentDigest.Value,
                source.Value.Binding.Location,
                Usage(model)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        SemanticModelInput<SourceTextInput> input,
        MarkdownDocumentModel value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value);
    }

    private static SemanticResourceLocalUsage Usage(MarkdownDocumentModel value) =>
        SemanticResourceLocalUsage.Create(
            Encoding.UTF8.GetByteCount(value.CanonicalText),
            1,
            1,
            value.CanonicalText.Length);
}

internal sealed class RepositoryTargetMarkdownDocumentParser :
    ISemanticModelParser<RepositoryTargetInput,
        RepositoryTargetMarkdownDocumentSetModel>
{
    public SemanticModelIntent<RepositoryTargetMarkdownDocumentSetModel> Parse(
        SemanticModelInput<RepositoryTargetInput> input,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        cancellationToken.ThrowIfCancellationRequested();
        var source = input.Value.Source;
        var model = new RepositoryTargetMarkdownDocumentSetModel(
            source.Evidence,
            []);
        return SemanticModelIntent<RepositoryTargetMarkdownDocumentSetModel>.Produced(
            SemanticModelProduct<RepositoryTargetMarkdownDocumentSetModel>.Create(
                model,
                source.Evidence,
                "repository-target-markdown-document-set",
                source.Value.Binding.Payload.ContentDigest.Value,
                source.Value.Binding.Location,
                Usage(model)));
    }

    public SemanticResourceLocalUsage MeasureLocal(
        SemanticModelInput<RepositoryTargetInput> input,
        RepositoryTargetMarkdownDocumentSetModel value,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(input);
        ArgumentNullException.ThrowIfNull(value);
        cancellationToken.ThrowIfCancellationRequested();
        return Usage(value);
    }

    private static SemanticResourceLocalUsage Usage(
        RepositoryTargetMarkdownDocumentSetModel value) =>
        SemanticResourceLocalUsage.Create(
            value.CanonicalDocuments.Sum(Encoding.UTF8.GetByteCount),
            value.CanonicalDocuments.Count == 0 ? 0 : 1,
            value.CanonicalDocuments.Count,
            value.CanonicalDocuments.Sum(item => item.Length));
}
