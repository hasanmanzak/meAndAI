namespace MeAndAI.Operations.Packaging;

internal sealed class PackagingTemporaryDirectory : IDisposable
{
    private const int DeleteAttemptCount = 3;
    private static readonly TimeSpan DeleteRetryDelay =
        TimeSpan.FromMilliseconds(50);
    private bool _deleted;

    private PackagingTemporaryDirectory(string fullName)
    {
        FullName = fullName;
    }

    internal string FullName { get; }

    internal static PackagingTemporaryDirectory Create(string prefix)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(prefix);
        var fullName = Path.Combine(
            Path.GetTempPath(),
            prefix + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(fullName);
            return new PackagingTemporaryDirectory(fullName);
        }
        catch (Exception exception) when (
            exception is IOException or UnauthorizedAccessException)
        {
            if (!TryDelete(fullName))
            {
                throw new InvalidOperationException(
                    "Packaging temporary workspace cleanup could not be confirmed.");
            }

            throw new InvalidOperationException(
                "Packaging temporary workspace could not be created.");
        }
    }

    internal void DeleteOrThrow()
    {
        if (_deleted)
        {
            return;
        }

        if (!TryDelete(FullName))
        {
            throw new InvalidOperationException(
                "Packaging temporary workspace cleanup could not be confirmed.");
        }

        _deleted = true;
    }

    public void Dispose() => DeleteOrThrow();

    private static bool TryDelete(string path)
    {
        for (var attempt = 1; attempt <= DeleteAttemptCount; attempt++)
        {
            if (IsAbsent(path))
            {
                return true;
            }

            try
            {
                Directory.Delete(path, recursive: true);
            }
            catch (Exception exception) when (
                exception is IOException or
                UnauthorizedAccessException or
                System.Security.SecurityException)
            {
            }

            if (IsAbsent(path))
            {
                return true;
            }

            if (attempt < DeleteAttemptCount)
            {
                Thread.Sleep(DeleteRetryDelay);
            }
        }

        return false;
    }

    private static bool IsAbsent(string path)
    {
        try
        {
            _ = File.GetAttributes(path);
            return false;
        }
        catch (FileNotFoundException)
        {
            return true;
        }
        catch (DirectoryNotFoundException)
        {
            return true;
        }
        catch (Exception exception) when (
            exception is IOException or
            UnauthorizedAccessException or
            System.Security.SecurityException)
        {
            return false;
        }
    }
}
