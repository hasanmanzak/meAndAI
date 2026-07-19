Set-StrictMode -Version Latest

function Test-MeAndAIReparsePoint {
    param([Parameter(Mandatory)][System.IO.FileSystemInfo]$Item)

    if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        return $true
    }
    $linkType = $Item.PSObject.Properties['LinkType']
    return $null -ne $linkType -and $null -ne $linkType.Value
}

function Assert-MeAndAIExactKeys {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Context
    )

    $actual = @($Value.Keys | ForEach-Object { [string]$_ })
    if ($actual.Count -ne $Expected.Count) {
        throw "$Context has the wrong property inventory."
    }
    foreach ($name in $Expected) {
        if ($actual -cnotcontains $name) {
            throw "$Context is missing property '$name'."
        }
    }
}

function ConvertTo-MeAndAISafeRelativePath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Context
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or
        [IO.Path]::IsPathRooted($Path) -or
        $Path.StartsWith('/', [StringComparison]::Ordinal) -or
        $Path.StartsWith('\', [StringComparison]::Ordinal)) {
        throw "$Context is unsafe: '$Path'."
    }

    $normalized = $Path.Replace('\', '/')
    $segments = @($normalized.Split('/'))
    if ($segments.Count -eq 0) {
        throw "$Context is unsafe: '$Path'."
    }
    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or
            $segment -ceq '.' -or $segment -ceq '..' -or
            $segment.EndsWith('.', [StringComparison]::Ordinal) -or
            $segment.EndsWith(' ', [StringComparison]::Ordinal) -or
            $segment.IndexOfAny([char[]]'*:?' + [char[]]'"<>|') -ge 0) {
            throw "$Context is unsafe: '$Path'."
        }
        foreach ($character in $segment.ToCharArray()) {
            if ([char]::IsControl($character)) {
                throw "$Context is unsafe: '$Path'."
            }
        }
    }
    return $normalized
}

function Resolve-MeAndAITestOwnerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Owner
    )

    $exact = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $caseFolded = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $normalizedOwners = [System.Collections.Generic.List[string]]::new()

    foreach ($candidate in $Owner) {
        $normalized = ConvertTo-MeAndAISafeRelativePath -Path $candidate `
            -Context 'Test suite owner path'
        if ($normalized -cnotmatch (
                '^tests/capabilities/' +
                '[a-z0-9]+(?:-[a-z0-9]+)*' +
                '(?:/[a-z0-9]+(?:-[a-z0-9]+)*)*/' +
                '[a-z0-9]+(?:-[a-z0-9]+)*\.tests\.ps1$'
            )) {
            throw "Test suite owner path is unsafe or noncanonical: '$candidate'."
        }
        if (-not $exact.Add($normalized)) {
            throw "Test suite owner set contains duplicate owner '$normalized'."
        }
        if (-not $caseFolded.Add($normalized)) {
            throw "Test suite owner set contains a case collision at '$normalized'."
        }
        $normalizedOwners.Add($normalized)
    }

    $result = [string[]]$normalizedOwners.ToArray()
    [Array]::Sort($result, [System.StringComparer]::Ordinal)
    return $result
}

function Resolve-MeAndAICapabilityRoot {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $resolvedRepository = Resolve-Path -LiteralPath $RepositoryRoot `
        -ErrorAction Stop
    $repositoryItem = Get-Item -LiteralPath $resolvedRepository.Path `
        -Force -ErrorAction Stop
    if (-not $repositoryItem.PSIsContainer) {
        throw "Repository root is not a directory: '$RepositoryRoot'."
    }
    if (Test-MeAndAIReparsePoint -Item $repositoryItem) {
        throw "Repository root is a reparse point: '$RepositoryRoot'."
    }

    $normalized = ConvertTo-MeAndAISafeRelativePath -Path $RelativePath `
        -Context 'Capability root relative path'
    $current = $repositoryItem
    foreach ($segment in $normalized.Split('/')) {
        $matches = @(Get-ChildItem -LiteralPath $current.FullName -Force `
            -ErrorAction Stop | Where-Object {
                $_.Name.Equals($segment, [StringComparison]::OrdinalIgnoreCase)
            })
        if ($matches.Count -eq 0) {
            throw "Capability root does not exist: '$normalized'."
        }
        if ($matches.Count -ne 1) {
            throw "Capability root contains a case collision at '$segment'."
        }
        if ($matches[0].Name -cne $segment) {
            throw "Capability root case does not match '$normalized'."
        }
        if (-not $matches[0].PSIsContainer) {
            throw "Capability root component is not a directory: '$segment'."
        }
        if (Test-MeAndAIReparsePoint -Item $matches[0]) {
            throw "Capability root contains a reparse point at '$segment'."
        }
        $current = $matches[0]
    }

    return [pscustomobject][ordered]@{
        Repository = $repositoryItem
        Capability = $current
        Relative = $normalized
    }
}

function Test-MeAndAISupportMasquerade {
    param([Parameter(Mandatory)][string]$Owner)

    $segments = @($Owner.Split('/'))
    $supportDirectories = @(
        'adapter', 'adapters', 'fixture', 'fixtures', 'helper', 'helpers',
        'infrastructure', 'support', 'supports'
    )
    for ($index = 2; $index -lt ($segments.Count - 1); $index++) {
        if ($supportDirectories -icontains $segments[$index]) {
            return 'Path'
        }
    }

    $leaf = $segments[-1]
    $stem = $leaf.Substring(0, $leaf.Length - '.tests.ps1'.Length)
    if ($stem -match (
            '(?i)(^|[-.])' +
            '(adapter|adapters|fixture|fixtures|helper|helpers|support|supports)' +
            '([-.]|$)'
        )) {
        return 'Filename'
    }
    return ''
}

function Assert-MeAndAIParseableSuite {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Owner
    )

    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $LiteralPath,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if (@($parseErrors).Count -gt 0) {
        throw "Canonical test suite '$Owner' does not parse: $($parseErrors[0].Message)"
    }
}

function Get-MeAndAITestSuite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [string]$CapabilityRootRelativePath = 'tests/capabilities'
    )

    $roots = Resolve-MeAndAICapabilityRoot -RepositoryRoot $RepositoryRoot `
        -RelativePath $CapabilityRootRelativePath
    $pending = [System.Collections.Generic.Stack[System.IO.DirectoryInfo]]::new()
    $pending.Push([System.IO.DirectoryInfo]$roots.Capability)
    $candidateByOwner = [System.Collections.Generic.Dictionary[string,string]]::new(
        [System.StringComparer]::Ordinal
    )

    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        $entries = @(Get-ChildItem -LiteralPath $directory.FullName -Force `
            -ErrorAction Stop)
        $names = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )
        foreach ($entry in $entries) {
            if (-not $names.Add($entry.Name)) {
                $relativeDirectory = $directory.FullName.Substring(
                    $roots.Repository.FullName.Length
                ).TrimStart([IO.Path]::DirectorySeparatorChar,
                    [IO.Path]::AltDirectorySeparatorChar).Replace('\', '/')
                throw "Capability tree contains a case collision under '$relativeDirectory'."
            }
        }

        foreach ($entry in $entries) {
            if (Test-MeAndAIReparsePoint -Item $entry) {
                $relativeEntry = $entry.FullName.Substring(
                    $roots.Repository.FullName.Length
                ).TrimStart([IO.Path]::DirectorySeparatorChar,
                    [IO.Path]::AltDirectorySeparatorChar).Replace('\', '/')
                throw "Capability tree contains a reparse point at '$relativeEntry'."
            }
            if ($entry.PSIsContainer) {
                $pending.Push([System.IO.DirectoryInfo]$entry)
                continue
            }
            $canonicalSuffix = $entry.Name.EndsWith(
                '.tests.ps1', [StringComparison]::Ordinal
            )
            if (-not $canonicalSuffix -and $entry.Name.EndsWith(
                    '.tests.ps1', [StringComparison]::OrdinalIgnoreCase
                )) {
                throw "Canonical test suite suffix case does not match: '$($entry.Name)'."
            }
            if (-not $canonicalSuffix) {
                continue
            }

            $relative = $entry.FullName.Substring(
                $roots.Repository.FullName.Length
            ).TrimStart([IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar).Replace('\', '/')
            $owner = @(Resolve-MeAndAITestOwnerSet -Owner @($relative))[0]
            $masquerade = Test-MeAndAISupportMasquerade -Owner $owner
            if ($masquerade -ceq 'Path') {
                throw "Support path masquerades as a canonical suite: '$owner'."
            }
            if ($masquerade -ceq 'Filename') {
                throw "Support filename masquerades as a canonical suite: '$owner'."
            }
            Assert-MeAndAIParseableSuite -LiteralPath $entry.FullName -Owner $owner
            if ($candidateByOwner.ContainsKey($owner)) {
                throw "Capability tree contains duplicate owner '$owner'."
            }
            $candidateByOwner.Add($owner, $entry.FullName)
        }
    }

    $owners = @(Resolve-MeAndAITestOwnerSet -Owner @($candidateByOwner.Keys))
    if ($owners.Count -eq 0) {
        throw "Capability root '$($roots.Relative)' contains no canonical test suites."
    }
    foreach ($owner in $owners) {
        [pscustomobject][ordered]@{
            Owner = $owner
            FullName = $candidateByOwner[$owner]
        }
    }
}

function Import-MeAndAITestExecutionProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$DiscoveredSuite
    )

    if ($DiscoveredSuite.Count -eq 0) {
        throw 'Execution profiles require at least one discovered canonical suite.'
    }
    $profileItem = Get-Item -LiteralPath $LiteralPath -Force -ErrorAction Stop
    if ($profileItem.PSIsContainer -or (Test-MeAndAIReparsePoint -Item $profileItem)) {
        throw "Execution profile path is not a regular non-link file: '$LiteralPath'."
    }

    $suiteOwners = @($DiscoveredSuite | ForEach-Object { [string]$_.Owner })
    $normalizedSuiteOwners = @(Resolve-MeAndAITestOwnerSet -Owner $suiteOwners)
    $suiteByOwner = [System.Collections.Generic.Dictionary[string,object]]::new(
        [System.StringComparer]::Ordinal
    )
    $suiteOwnerCaseMap = [System.Collections.Generic.Dictionary[string,string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($suite in $DiscoveredSuite) {
        $owner = [string]$suite.Owner
        if ($null -eq $suite.PSObject.Properties['FullName'] -or
            [string]::IsNullOrWhiteSpace([string]$suite.FullName)) {
            throw "Discovered suite '$owner' has no full path."
        }
        $suiteByOwner.Add($owner, $suite)
        $suiteOwnerCaseMap.Add($owner, $owner)
    }
    if ($suiteByOwner.Count -ne $normalizedSuiteOwners.Count) {
        throw 'Discovered suite objects do not match their normalized owners.'
    }

    try {
        $data = Import-PowerShellDataFile -LiteralPath $profileItem.FullName
    }
    catch {
        throw "Execution profile data does not parse: $($_.Exception.Message)"
    }
    if ($data -isnot [System.Collections.IDictionary]) {
        throw 'Execution profile data must be a hashtable.'
    }
    Assert-MeAndAIExactKeys -Value $data `
        -Expected @('SchemaVersion', 'Profiles') -Context 'Execution profile data'
    if (($data.SchemaVersion -isnot [int] -and
        $data.SchemaVersion -isnot [long]) -or [long]$data.SchemaVersion -ne 1) {
        throw 'Execution profile schema version must be 1.'
    }

    $rawProfiles = @($data.Profiles)
    if ($rawProfiles.Count -eq 0) {
        throw 'Execution profile data contains no profiles.'
    }
    $profileNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $profileNamesCaseFolded = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $resolvedByName = [System.Collections.Generic.Dictionary[string,object]]::new(
        [System.StringComparer]::Ordinal
    )

    foreach ($rawProfile in $rawProfiles) {
        if ($rawProfile -isnot [System.Collections.IDictionary]) {
            throw 'Execution profile entry must be a hashtable.'
        }
        Assert-MeAndAIExactKeys -Value $rawProfile `
            -Expected @('Name', 'Selection', 'Suites') `
            -Context 'Execution profile entry'
        $name = [string]$rawProfile.Name
        if ($rawProfile.Name -isnot [string] -or
            $name -cnotmatch '^[A-Z][A-Za-z0-9]*$') {
            throw "Execution profile name is invalid: '$name'."
        }
        if (-not $profileNames.Add($name)) {
            throw "Execution profiles contain duplicate name '$name'."
        }
        if (-not $profileNamesCaseFolded.Add($name)) {
            throw "Execution profiles contain a case collision at '$name'."
        }
        $selection = [string]$rawProfile.Selection
        if ($rawProfile.Selection -isnot [string] -or
            $selection -cnotin @('All', 'Explicit')) {
            throw "Execution profile '$name' has invalid selection '$selection'."
        }

        $rawSuiteEntries = @($rawProfile.Suites)
        if ($selection -ceq 'All' -and $rawSuiteEntries.Count -ne 0) {
            throw "All-suite execution profile '$name' must not list suites."
        }
        if ($selection -ceq 'Explicit' -and $rawSuiteEntries.Count -eq 0) {
            throw "Explicit execution profile '$name' must list suites."
        }

        $argumentsByOwner = [System.Collections.Generic.Dictionary[string,object]]::new(
            [System.StringComparer]::Ordinal
        )
        $explicitOwners = [System.Collections.Generic.List[string]]::new()
        foreach ($rawSuiteEntry in $rawSuiteEntries) {
            if ($rawSuiteEntry -isnot [System.Collections.IDictionary]) {
                throw "Execution profile '$name' suite entry must be a hashtable."
            }
            Assert-MeAndAIExactKeys -Value $rawSuiteEntry `
                -Expected @('Owner', 'Arguments') `
                -Context "Execution profile '$name' suite entry"
            if ($rawSuiteEntry.Owner -isnot [string]) {
                throw "Execution profile '$name' suite owner must be a string."
            }
            $entryOwner = @(
                Resolve-MeAndAITestOwnerSet -Owner @([string]$rawSuiteEntry.Owner)
            )[0]
            if (-not $suiteByOwner.ContainsKey($entryOwner)) {
                if ($suiteOwnerCaseMap.ContainsKey($entryOwner)) {
                    throw "Execution profile '$name' owner case does not match discovered owner '$($suiteOwnerCaseMap[$entryOwner])'."
                }
                throw "Execution profile '$name' owner '$entryOwner' is not a discovered canonical suite."
            }
            if ($rawSuiteEntry.Arguments -isnot [array]) {
                throw "Execution profile '$name' arguments for '$entryOwner' must be an array."
            }
            $arguments = @($rawSuiteEntry.Arguments)
            foreach ($argument in $arguments) {
                if ($argument -isnot [string] -or
                    [string]::IsNullOrWhiteSpace([string]$argument) -or
                    [string]$argument -match '[\x00\r\n]') {
                    throw "Execution profile '$name' has an invalid argument for '$entryOwner'."
                }
            }
            if ($argumentsByOwner.ContainsKey($entryOwner)) {
                throw "Execution profile '$name' contains duplicate owner '$entryOwner'."
            }
            $argumentsByOwner.Add($entryOwner, [string[]]$arguments)
            $explicitOwners.Add($entryOwner)
        }

        $selectedOwners = if ($selection -ceq 'All') {
            $normalizedSuiteOwners
        }
        else {
            @(Resolve-MeAndAITestOwnerSet -Owner $explicitOwners.ToArray())
        }
        $selectedSuites = [System.Collections.Generic.List[object]]::new()
        foreach ($selectedOwner in $selectedOwners) {
            $arguments = if ($selection -ceq 'All') {
                [string[]]@()
            }
            else {
                [string[]]$argumentsByOwner[$selectedOwner]
            }
            $selectedSuites.Add([pscustomobject][ordered]@{
                Owner = $selectedOwner
                FullName = [string]$suiteByOwner[$selectedOwner].FullName
                Arguments = $arguments
            })
        }
        $resolvedByName.Add($name, [pscustomobject][ordered]@{
            Name = $name
            Selection = $selection
            Suites = [object[]]$selectedSuites.ToArray()
        })
    }

    $orderedNames = [string[]]@($resolvedByName.Keys)
    [Array]::Sort($orderedNames, [System.StringComparer]::Ordinal)
    foreach ($name in $orderedNames) {
        $resolvedByName[$name]
    }
}

Export-ModuleMember -Function @(
    'Get-MeAndAITestSuite',
    'Import-MeAndAITestExecutionProfile',
    'Resolve-MeAndAITestOwnerSet'
)
