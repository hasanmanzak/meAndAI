using System.Text.Json;
using System.ComponentModel;

namespace MeAndAI.Operations.Packaging;

internal static class PackagingCli
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    internal static int Run(IReadOnlyList<string> arguments)
    {
        ArgumentNullException.ThrowIfNull(arguments);
        try
        {
            if (arguments.Count == 0)
            {
                return Usage();
            }

            return arguments[0] switch
            {
                "pack" => Pack(ParseOptions(arguments, allowExecute: false)),
                "verify" => Verify(ParseOptions(arguments, allowExecute: true)),
                _ => Usage(),
            };
        }
        catch (Exception exception) when (
            exception is ArgumentException or
            InvalidDataException or
            InvalidOperationException or
            IOException or
            Win32Exception or
            TimeoutException)
        {
            Console.Error.WriteLine(exception.Message);
            return 1;
        }
    }

    private static int Pack(CommandOptions options)
    {
        var repositoryRoot = options.Require("--repository-root");
        var inventoryPath = options.Require("--inventory");
        var outputDirectory = options.Require("--output");
        var sourceCommit = options.Require("--source-commit");
        options.RequireExactCount(4);

        var repository = ValidateRepository(repositoryRoot, sourceCommit);
        const string canonicalInventoryPath =
            "packaging/operations-packages.json";
        var resolvedInventoryPath = ResolveContainedFile(
            repository.FullName,
            canonicalInventoryPath,
            "Package inventory");
        var suppliedInventoryPath = Path.GetFullPath(
            inventoryPath,
            repository.FullName);
        if (!string.Equals(
                suppliedInventoryPath,
                resolvedInventoryPath,
                StringComparison.Ordinal))
        {
            throw new InvalidDataException(
                "Pack must consume the canonical repository-owned inventory path.");
        }

        AssertTrackedRegularFile(repository.FullName, canonicalInventoryPath);
        var resolvedOutput = Path.GetFullPath(
            outputDirectory,
            repository.FullName);
        if (IsContainedOrEqual(repository.FullName, resolvedOutput))
        {
            throw new InvalidDataException(
                "Package output must remain outside the clean source repository.");
        }

        var inventory = OperationsPackageInventory.Read(resolvedInventoryPath);
        var temporaryRoot = Path.Combine(
            Path.GetTempPath(),
            $"meandai-portable-publish-{Guid.NewGuid():N}");
        Directory.CreateDirectory(temporaryRoot);

        try
        {
            var publishDirectories = new Dictionary<string, string>(
                StringComparer.Ordinal);
            foreach (var package in inventory.Packages)
            {
                var projectPath = ResolveContainedFile(
                    repository.FullName,
                    package.ProjectPath,
                    "Package project");
                AssertTrackedRegularFile(
                    repository.FullName,
                    package.ProjectPath);
                var publishDirectory = Path.Combine(
                    temporaryRoot,
                    package.Application);
                Directory.CreateDirectory(publishDirectory);
                var result = BoundedProcess.Run(
                    "dotnet",
                    [
                        "publish",
                        projectPath,
                        "--configuration",
                        "Release",
                        "--no-restore",
                        "--nologo",
                        "--output",
                        publishDirectory,
                        "--self-contained",
                        "false",
                        "-p:UseAppHost=false",
                        "-p:DebugSymbols=false",
                        "-p:DebugType=None",
                    ],
                    repository.FullName,
                    TimeSpan.FromMinutes(3));
                if (result.ExitCode != 0)
                {
                    throw new InvalidOperationException(
                        $"Publish for '{package.Application}' failed: " +
                        result.StandardError.Trim());
                }

                publishDirectories.Add(package.Application, publishDirectory);
            }

            var manifest = PortablePackageBuilder.Build(
                new PortablePackageBuildRequest(
                    sourceCommit,
                    inventory,
                    publishDirectories,
                    resolvedOutput));
            Console.WriteLine(JsonSerializer.Serialize(
                new
                {
                    manifest = PortableReleaseContract.ManifestFileName,
                    sourceCommit = manifest.SourceCommit,
                    assets = manifest.Assets.Select(asset => asset.AssetName),
                },
                SerializerOptions));
            return 0;
        }
        finally
        {
            if (Directory.Exists(temporaryRoot))
            {
                Directory.Delete(temporaryRoot, recursive: true);
            }
        }
    }

    private static int Verify(CommandOptions options)
    {
        var inventoryPath = options.Require("--inventory");
        var manifestPath = options.Require("--manifest");
        var assetDirectory = options.Require("--assets");
        options.RequireExactCount(options.Execute ? 4 : 3);
        var inventory = OperationsPackageInventory.Read(inventoryPath);
        var runtimes = BoundedProcess.Run(
            "dotnet",
            ["--list-runtimes"],
            Directory.GetCurrentDirectory(),
            TimeSpan.FromSeconds(30));
        if (runtimes.ExitCode != 0)
        {
            throw new InvalidOperationException(
                "The installed .NET runtime inventory could not be read.");
        }

        var release = PortablePackageVerifier.Verify(
            new PortablePackageVerificationRequest(
                inventory,
                manifestPath,
                assetDirectory,
                runtimes.StandardOutput));
        var executed = options.Execute
            ? PortablePackageExecutor.Execute(release)
            : [];
        Console.WriteLine(JsonSerializer.Serialize(
            new
            {
                sourceCommit = release.Manifest.SourceCommit,
                verifiedAssets = release.Assets.Select(asset => asset.Application),
                executedAssets = executed.Select(asset => asset.Application),
            },
            SerializerOptions));
        return 0;
    }

    private static DirectoryInfo ValidateRepository(
        string repositoryRoot,
        string sourceCommit)
    {
        PortablePackageBuilder.ValidateSourceCommit(sourceCommit);
        var repository = new DirectoryInfo(Path.GetFullPath(repositoryRoot));
        if (!repository.Exists ||
            (repository.Attributes & FileAttributes.ReparsePoint) != 0)
        {
            throw new InvalidDataException(
                "Package source must be one ordinary repository directory.");
        }

        var topLevel = RunGit(repository.FullName, "rev-parse", "--show-toplevel");
        if (!string.Equals(
                Path.GetFullPath(topLevel),
                repository.FullName,
                StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidDataException(
                "Package source root does not match the Git repository root.");
        }

        var head = RunGit(repository.FullName, "rev-parse", "--verify", "HEAD^{commit}");
        if (!string.Equals(head, sourceCommit, StringComparison.Ordinal))
        {
            throw new InvalidDataException(
                "Package source commit does not match repository HEAD.");
        }

        var status = BoundedProcess.Run(
            "git",
            [
                "-C",
                repository.FullName,
                "status",
                "--porcelain=v1",
                "--untracked-files=all",
            ],
            repository.FullName,
            TimeSpan.FromSeconds(30));
        if (status.ExitCode != 0 ||
            !string.IsNullOrWhiteSpace(status.StandardOutput) ||
            !string.IsNullOrWhiteSpace(status.StandardError))
        {
            throw new InvalidDataException(
                "Package construction requires one clean exact-HEAD source tree.");
        }

        return repository;
    }

    private static string RunGit(string repositoryRoot, params string[] arguments)
    {
        var result = BoundedProcess.Run(
            "git",
            ["-C", repositoryRoot, .. arguments],
            repositoryRoot,
            TimeSpan.FromSeconds(30));
        var output = result.StandardOutput.Trim();
        if (result.ExitCode != 0 ||
            string.IsNullOrWhiteSpace(output) ||
            !string.IsNullOrWhiteSpace(result.StandardError))
        {
            throw new InvalidDataException(
                "Package source Git identity could not be verified.");
        }

        return output;
    }

    private static string ResolveContainedFile(
        string root,
        string relativePath,
        string surface)
    {
        var fullPath = Path.GetFullPath(
            relativePath.Replace('/', Path.DirectorySeparatorChar),
            root);
        var relative = Path.GetRelativePath(root, fullPath);
        var file = new FileInfo(fullPath);
        if (relative.StartsWith(".." + Path.DirectorySeparatorChar, StringComparison.Ordinal) ||
            Path.IsPathRooted(relative) ||
            !file.Exists ||
            (file.Attributes & FileAttributes.ReparsePoint) != 0)
        {
            throw new InvalidDataException(
                $"{surface} is absent, linked, or outside the repository.");
        }

        return file.FullName;
    }

    private static void AssertTrackedRegularFile(
        string repositoryRoot,
        string relativePath)
    {
        var evidence = RunGit(
            repositoryRoot,
            "ls-files",
            "--stage",
            "--error-unmatch",
            "--",
            relativePath);
        if (!evidence.StartsWith("100644 ", StringComparison.Ordinal) ||
            !evidence.EndsWith("\t" + relativePath, StringComparison.Ordinal) ||
            evidence.Contains('\n') ||
            evidence.Contains('\r'))
        {
            throw new InvalidDataException(
                "Package source must be one exact tracked regular Git blob.");
        }
    }

    private static bool IsContainedOrEqual(string root, string path)
    {
        var relative = Path.GetRelativePath(root, path);
        return string.Equals(relative, ".", StringComparison.Ordinal) ||
            (!Path.IsPathRooted(relative) &&
             !string.Equals(relative, "..", StringComparison.Ordinal) &&
             !relative.StartsWith(
                 ".." + Path.DirectorySeparatorChar,
                 StringComparison.Ordinal));
    }

    private static CommandOptions ParseOptions(
        IReadOnlyList<string> arguments,
        bool allowExecute)
    {
        var values = new Dictionary<string, string>(StringComparer.Ordinal);
        var execute = false;
        for (var index = 1; index < arguments.Count; index++)
        {
            var option = arguments[index];
            if (allowExecute && string.Equals(option, "--execute", StringComparison.Ordinal))
            {
                if (execute)
                {
                    throw new ArgumentException("--execute cannot be repeated.");
                }

                execute = true;
                continue;
            }

            if (!option.StartsWith("--", StringComparison.Ordinal) ||
                index + 1 >= arguments.Count ||
                arguments[index + 1].StartsWith("--", StringComparison.Ordinal) ||
                !values.TryAdd(option, arguments[++index]))
            {
                throw new ArgumentException("Packaging command options are malformed.");
            }
        }

        return new CommandOptions(values, execute);
    }

    private static int Usage()
    {
        Console.Error.WriteLine(
            "Use 'pack' with --repository-root, --inventory, --output, and " +
            "--source-commit; or 'verify' with --inventory, --manifest, " +
            "--assets, and optional --execute.");
        return 64;
    }

    private sealed class CommandOptions(
        IReadOnlyDictionary<string, string> values,
        bool execute)
    {
        public bool Execute { get; } = execute;

        public string Require(string name) =>
            values.TryGetValue(name, out var value) &&
            !string.IsNullOrWhiteSpace(value)
                ? value
                : throw new ArgumentException($"Required option '{name}' is absent.");

        public void RequireExactCount(int count)
        {
            if (values.Count + (Execute ? 1 : 0) != count)
            {
                throw new ArgumentException(
                    "Packaging command contains unexpected options.");
            }
        }
    }
}
