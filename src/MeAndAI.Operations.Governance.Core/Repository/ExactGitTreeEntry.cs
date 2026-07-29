namespace MeAndAI.Operations.Governance.Core.Repository;

internal enum ExactGitObjectType
{
    Blob,
    Tree,
    Commit,
    Tag,
}

internal enum ExactGitTreeEntryMode
{
    Directory,
    RegularFile,
    ExecutableFile,
    SymbolicLink,
    GitLink,
}

internal sealed record ExactGitTreeEntry
{
    private ExactGitTreeEntry(
        RepositoryRelativePath path,
        ExactGitTreeEntryMode mode,
        ExactGitObjectType objectType,
        ExactGitObjectId objectId)
    {
        Path = path;
        Mode = mode;
        ObjectType = objectType;
        ObjectId = objectId;
    }

    internal RepositoryRelativePath Path { get; }

    internal string RelativePath => Path.Value;

    internal ExactGitTreeEntryMode Mode { get; }

    internal ExactGitObjectType ObjectType { get; }

    internal ExactGitObjectId ObjectId { get; }

    internal bool IsFileBlob =>
        ObjectType == ExactGitObjectType.Blob &&
        Mode is ExactGitTreeEntryMode.RegularFile or
            ExactGitTreeEntryMode.ExecutableFile;

    internal static ExactGitTreeEntry Create(
        RepositoryRelativePath path,
        string mode,
        string objectType,
        ExactGitObjectId objectId)
    {
        ArgumentNullException.ThrowIfNull(path);
        ArgumentNullException.ThrowIfNull(mode);
        ArgumentNullException.ThrowIfNull(objectType);
        ArgumentNullException.ThrowIfNull(objectId);

        var typed = (mode, objectType) switch
        {
            ("040000", "tree") =>
                (ExactGitTreeEntryMode.Directory, ExactGitObjectType.Tree),
            ("100644", "blob") =>
                (ExactGitTreeEntryMode.RegularFile, ExactGitObjectType.Blob),
            ("100755", "blob") =>
                (ExactGitTreeEntryMode.ExecutableFile, ExactGitObjectType.Blob),
            ("120000", "blob") =>
                (ExactGitTreeEntryMode.SymbolicLink, ExactGitObjectType.Blob),
            ("160000", "commit") =>
                (ExactGitTreeEntryMode.GitLink, ExactGitObjectType.Commit),
            _ => throw new ArgumentException(
                "The Git tree entry mode and object type are not canonical."),
        };

        return new ExactGitTreeEntry(
            path,
            typed.Item1,
            typed.Item2,
            objectId);
    }
}
