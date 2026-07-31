using MeAndAI.Protocol.Conformance.Abstractions;

namespace MeAndAI.Protocol.Conformance;

public sealed class CatalogIntegrityException : InvalidOperationException
{
    internal CatalogIntegrityException(CatalogIntegrityCode code)
        : base(code?.Value)
    {
        ArgumentNullException.ThrowIfNull(code);
        Code = code;
    }

    public CatalogIntegrityCode Code { get; }
}
