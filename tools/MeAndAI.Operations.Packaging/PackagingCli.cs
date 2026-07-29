using System.Text.Json;
using MeAndAI.Operations.Domain.Identity;
using MeAndAI.Operations.Infrastructure.Execution;

namespace MeAndAI.Operations.Packaging;

internal static class PackagingCli
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    internal static async Task<int> RunAsync(
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(arguments);
        try
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (arguments.Count == 0)
            {
                return Usage();
            }

            return arguments[0] switch
            {
                "pack" => await PackAsync(
                        ParseOptions(arguments, allowExecute: false),
                        cancellationToken)
                    .ConfigureAwait(false),
                "verify" => await VerifyAsync(
                        ParseOptions(arguments, allowExecute: true),
                        cancellationToken)
                    .ConfigureAwait(false),
                _ => Usage(),
            };
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            Console.Error.WriteLine("Packaging operation was canceled.");
            return 130;
        }
        catch (Exception exception) when (
            exception is ArgumentException or
            InvalidDataException or
            InvalidOperationException or
            IOException or
            OperationalDependencyException)
        {
            Console.Error.WriteLine(exception.Message);
            return 1;
        }
    }

    private static async Task<int> PackAsync(
        CommandOptions options,
        CancellationToken cancellationToken)
    {
        var repositoryRoot = options.Require("--repository-root");
        var inventoryPath = options.Require("--inventory");
        var outputDirectory = options.Require("--output");
        var sourceCommit = options.Require("--source-commit");
        options.RequireExactCount(4);

        var repository = await ValidateRepositoryAsync(
                repositoryRoot,
                sourceCommit,
                cancellationToken)
            .ConfigureAwait(false);
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

        await AssertTrackedRegularFileAsync(
                repository.FullName,
                canonicalInventoryPath,
                cancellationToken)
            .ConfigureAwait(false);
        var resolvedOutput = Path.GetFullPath(
            outputDirectory,
            repository.FullName);
        if (IsContainedOrEqual(repository.FullName, resolvedOutput))
        {
            throw new InvalidDataException(
                "Package output must remain outside the clean source repository.");
        }

        var inventory = OperationsPackageInventory.Read(resolvedInventoryPath);
        var temporaryDirectory = PackagingTemporaryDirectory.Create(
            "meandai-portable-publish-");
        var temporaryRoot = temporaryDirectory.FullName;

        try
        {
            var publishDirectories = new Dictionary<string, string>(
                StringComparer.Ordinal);
            foreach (var package in inventory.Packages)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var projectPath = ResolveContainedFile(
                    repository.FullName,
                    package.ProjectPath,
                    "Package project");
                await AssertTrackedRegularFileAsync(
                        repository.FullName,
                        package.ProjectPath,
                        cancellationToken)
                    .ConfigureAwait(false);
                var publishDirectory = Path.Combine(
                    temporaryRoot,
                    package.Application);
                Directory.CreateDirectory(publishDirectory);
                var result = await BoundedProcessRunner.ExecuteAsync(
                        PackagingProcessPolicy.CreateTextRequest(
                            "dotnet",
                            CreatePublishArguments(
                                package,
                                projectPath,
                                publishDirectory,
                                sourceCommit),
                            repository.FullName,
                            PackagingProcessPolicy.PublishTimeout),
                        cancellationToken)
                    .ConfigureAwait(false);
                if (result.ExitCode != 0)
                {
                    throw new InvalidOperationException(
                        $"Publish for '{package.Application}' failed.");
                }

                publishDirectories.Add(package.Application, publishDirectory);
            }

            cancellationToken.ThrowIfCancellationRequested();
            var manifest = PortablePackageBuilder.Build(
                new PortablePackageBuildRequest(
                    sourceCommit,
                    inventory,
                    publishDirectories,
                    resolvedOutput));
            cancellationToken.ThrowIfCancellationRequested();
            var response = JsonSerializer.Serialize(
                new
                {
                    manifest = PortableReleaseContract.ManifestFileName,
                    sourceCommit = manifest.SourceCommit,
                    assets = manifest.Assets.Select(asset => asset.AssetName),
                },
                SerializerOptions);
            cancellationToken.ThrowIfCancellationRequested();
            temporaryDirectory.DeleteOrThrow();
            cancellationToken.ThrowIfCancellationRequested();
            Console.WriteLine(response);
            return 0;
        }
        finally
        {
            temporaryDirectory.Dispose();
        }
    }

    internal static string[] CreatePublishArguments(
        OperationsPackageDefinition package,
        string projectPath,
        string publishDirectory,
        string validatedSourceCommit)
    {
        ArgumentNullException.ThrowIfNull(package);
        ArgumentException.ThrowIfNullOrWhiteSpace(projectPath);
        ArgumentException.ThrowIfNullOrWhiteSpace(publishDirectory);
        ArgumentException.ThrowIfNullOrWhiteSpace(validatedSourceCommit);

        var arguments = new List<string>
        {
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
        };
        if (string.Equals(
                package.Application,
                OperationalApplicationId.Governance.Value,
                StringComparison.Ordinal))
        {
            arguments.Add(
                "-p:MeAndAIGovernancePolicySourceCommit=" +
                validatedSourceCommit);
        }

        return [.. arguments];
    }

    private static async Task<int> VerifyAsync(
        CommandOptions options,
        CancellationToken cancellationToken)
    {
        var inventoryPath = options.Require("--inventory");
        var manifestPath = options.Require("--manifest");
        var assetDirectory = options.Require("--assets");
        options.RequireExactCount(options.Execute ? 4 : 3);
        var inventory = OperationsPackageInventory.Read(inventoryPath);
        var runtimes = await BoundedProcessRunner.ExecuteAsync(
                PackagingProcessPolicy.CreateTextRequest(
                    "dotnet",
                    ["--list-runtimes"],
                    Directory.GetCurrentDirectory(),
                    PackagingProcessPolicy.VerificationTimeout),
                cancellationToken)
            .ConfigureAwait(false);
        if (runtimes.ExitCode != 0)
        {
            throw new InvalidOperationException(
                "The installed .NET runtime inventory could not be read.");
        }

        cancellationToken.ThrowIfCancellationRequested();
        var release = PortablePackageVerifier.Verify(
            new PortablePackageVerificationRequest(
                inventory,
                manifestPath,
                assetDirectory,
                StrictUtf8.Decode(runtimes.StandardOutput)));
        cancellationToken.ThrowIfCancellationRequested();
        IReadOnlyList<ExecutedPortableAsset> executed = options.Execute
            ? await PortablePackageExecutor.ExecuteAsync(
                    release,
                    cancellationToken: cancellationToken)
                .ConfigureAwait(false)
            : [];
        cancellationToken.ThrowIfCancellationRequested();
        var response = JsonSerializer.Serialize(
            new
            {
                sourceCommit = release.Manifest.SourceCommit,
                verifiedAssets = release.Assets.Select(asset => asset.Application),
                executedAssets = executed.Select(asset => asset.Application),
            },
            SerializerOptions);
        cancellationToken.ThrowIfCancellationRequested();
        Console.WriteLine(response);
        return 0;
    }

    private static async Task<DirectoryInfo> ValidateRepositoryAsync(
        string repositoryRoot,
        string sourceCommit,
        CancellationToken cancellationToken)
    {
        PortablePackageBuilder.ValidateSourceCommit(sourceCommit);
        var repository = new DirectoryInfo(Path.GetFullPath(repositoryRoot));
        if (!repository.Exists ||
            (repository.Attributes & FileAttributes.ReparsePoint) != 0)
        {
            throw new InvalidDataException(
                "Package source must be one ordinary repository directory.");
        }

        var topLevel = await RunGitAsync(
                repository.FullName,
                ["rev-parse", "--show-toplevel"],
                cancellationToken)
            .ConfigureAwait(false);
        if (!string.Equals(
                Path.GetFullPath(topLevel),
                repository.FullName,
                StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidDataException(
                "Package source root does not match the Git repository root.");
        }

        var head = await RunGitAsync(
                repository.FullName,
                ["rev-parse", "--verify", "HEAD^{commit}"],
                cancellationToken)
            .ConfigureAwait(false);
        if (!string.Equals(head, sourceCommit, StringComparison.Ordinal))
        {
            throw new InvalidDataException(
                "Package source commit does not match repository HEAD.");
        }

        var status = await BoundedProcessRunner.ExecuteAsync(
                PackagingProcessPolicy.CreateTextRequest(
                    "git",
                    [
                        "-C",
                        repository.FullName,
                        "status",
                        "--porcelain=v1",
                        "--untracked-files=all",
                    ],
                    repository.FullName,
                    PackagingProcessPolicy.GitTimeout),
                cancellationToken)
            .ConfigureAwait(false);
        if (status.ExitCode != 0 ||
            !StrictUtf8.IsNullOrWhiteSpace(status.StandardOutput) ||
            !StrictUtf8.IsNullOrWhiteSpace(status.StandardError))
        {
            throw new InvalidDataException(
                "Package construction requires one clean exact-HEAD source tree.");
        }

        return repository;
    }

    private static async Task<string> RunGitAsync(
        string repositoryRoot,
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken)
    {
        var result = await BoundedProcessRunner.ExecuteAsync(
                PackagingProcessPolicy.CreateTextRequest(
                    "git",
                    ["-C", repositoryRoot, .. arguments],
                    repositoryRoot,
                    PackagingProcessPolicy.GitTimeout),
                cancellationToken)
            .ConfigureAwait(false);
        if (result.ExitCode != 0 ||
            !StrictUtf8.IsNullOrWhiteSpace(result.StandardError))
        {
            throw new InvalidDataException(
                "Package source Git identity could not be verified.");
        }

        var output = StrictUtf8.Decode(result.StandardOutput).Trim();
        if (string.IsNullOrWhiteSpace(output))
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

    private static async Task AssertTrackedRegularFileAsync(
        string repositoryRoot,
        string relativePath,
        CancellationToken cancellationToken)
    {
        var evidence = await RunGitAsync(
                repositoryRoot,
                [
                    "ls-files",
                    "--stage",
                    "--error-unmatch",
                    "--",
                    relativePath,
                ],
                cancellationToken)
            .ConfigureAwait(false);
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
