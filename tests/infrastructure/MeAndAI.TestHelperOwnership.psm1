Set-StrictMode -Version Latest

function Get-MeAndAIHelperOwnershipProperty {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Label
    )

    if ($Value -is [System.Collections.IDictionary]) {
        if (-not $Value.Contains($Name)) {
            throw "$Label is missing '$Name'."
        }
        return ,$Value[$Name]
    }

    $property = $Value.PSObject.Properties[$Name]
    if ($null -eq $property) {
        throw "$Label is missing '$Name'."
    }
    return ,$property.Value
}

function ConvertTo-MeAndAIHelperOwnershipPath {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Label
    )

    $path = $Value.Replace('\', '/').Trim('/')
    if ($path -cnotmatch '^(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+$' -or
        $path.Contains('../') -or $path.StartsWith('.')) {
        throw "$Label is not one safe repository-relative path."
    }
    return $path
}

function ConvertTo-MeAndAIHelperOwnershipNames {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string]$Label
    )

    $names = @($Value | ForEach-Object { [string]$_ })
    if ($names.Count -eq 0) {
        throw "$Label must not be empty."
    }
    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($name in $names) {
        if ($name -cnotmatch '^[A-Za-z][A-Za-z0-9]*(?:-[A-Za-z][A-Za-z0-9]*)+$' -or
            -not $seen.Add($name)) {
            throw "$Label contains an invalid or duplicate command '$name'."
        }
    }
    return [string[]]$names
}

function Import-MeAndAITestHelperOwnership {
    param([Parameter(Mandatory)][string]$LiteralPath)

    $raw = Import-PowerShellDataFile -LiteralPath $LiteralPath
    $schema = Get-MeAndAIHelperOwnershipProperty -Value $raw `
        -Name SchemaVersion -Label 'Helper ownership contract'
    $identity = Get-MeAndAIHelperOwnershipProperty -Value $raw `
        -Name ContractId -Label 'Helper ownership contract'
    if ([int]$schema -ne 1 -or
        [string]$identity -cne 'MEANDAI-TEST-HELPER-OWNERSHIP-0001') {
        throw 'Helper ownership contract has an unsupported identity.'
    }

    $rawScanRoots = Get-MeAndAIHelperOwnershipProperty -Value $raw `
        -Name ScanRoots -Label 'Helper ownership contract'
    $scanRoots = @($rawScanRoots | ForEach-Object {
        ConvertTo-MeAndAIHelperOwnershipPath -Value ([string]$_) `
            -Label 'Helper ownership scan root'
    })
    if ($scanRoots.Count -eq 0) {
        throw 'Helper ownership contract has no scan roots.'
    }

    $owners = [System.Collections.Generic.List[object]]::new()
    $ownerIds = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    $allGuardedNames = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $rawOwners = Get-MeAndAIHelperOwnershipProperty -Value $raw `
        -Name Owners -Label 'Helper ownership contract'
    foreach ($rawOwner in @($rawOwners)) {
        $contractId = [string](Get-MeAndAIHelperOwnershipProperty `
            -Value $rawOwner -Name ContractId -Label 'Helper owner')
        if ($contractId -cnotmatch '^THO-[0-9]{4}$' -or
            -not $ownerIds.Add($contractId)) {
            throw "Helper owner identity '$contractId' is invalid or duplicated."
        }

        $ownerPathValue = Get-MeAndAIHelperOwnershipProperty -Value $rawOwner `
            -Name OwnerPath -Label $contractId
        $ownerPath = ConvertTo-MeAndAIHelperOwnershipPath `
            -Value ([string]$ownerPathValue) -Label "$contractId owner path"
        $canonical = ConvertTo-MeAndAIHelperOwnershipNames `
            -Value (Get-MeAndAIHelperOwnershipProperty -Value $rawOwner `
                -Name CanonicalCommands -Label $contractId) `
            -Label "$contractId canonical commands"
        $guarded = ConvertTo-MeAndAIHelperOwnershipNames `
            -Value (Get-MeAndAIHelperOwnershipProperty -Value $rawOwner `
                -Name GuardedNames -Label $contractId) `
            -Label "$contractId guarded names"
        $guardedSet = [System.Collections.Generic.HashSet[string]]::new(
            [string[]]$guarded,
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($name in $canonical) {
            if (-not $guardedSet.Contains($name)) {
                throw "$contractId canonical command '$name' is not guarded."
            }
        }
        foreach ($name in $guarded) {
            if (-not $allGuardedNames.Add($name)) {
                throw "Guarded helper '$name' belongs to more than one owner."
            }
        }

        $exceptions = [System.Collections.Generic.List[object]]::new()
        $rawExceptions = Get-MeAndAIHelperOwnershipProperty -Value $rawOwner `
            -Name ReviewedExceptions -Label $contractId
        foreach ($rawException in @($rawExceptions)) {
            $exceptionPath = ConvertTo-MeAndAIHelperOwnershipPath `
                -Value ([string](Get-MeAndAIHelperOwnershipProperty `
                    -Value $rawException -Name Path -Label "$contractId exception")) `
                -Label "$contractId exception path"
            $exceptionNames = ConvertTo-MeAndAIHelperOwnershipNames `
                -Value (Get-MeAndAIHelperOwnershipProperty -Value $rawException `
                    -Name Names -Label "$contractId exception") `
                -Label "$contractId exception names"
            foreach ($name in $exceptionNames) {
                if (-not $guardedSet.Contains($name)) {
                    throw "$contractId exception '$name' is not guarded."
                }
            }
            foreach ($propertyName in @('Reason', 'ReviewAuthority', 'RemovalSlice')) {
                $propertyValue = Get-MeAndAIHelperOwnershipProperty `
                    -Value $rawException -Name $propertyName `
                    -Label "$contractId exception"
                if ([string]::IsNullOrWhiteSpace([string]$propertyValue)) {
                    throw "$contractId exception '$exceptionPath' lacks $propertyName."
                }
            }
            $exceptions.Add([pscustomobject][ordered]@{
                Path = $exceptionPath
                Names = [string[]]$exceptionNames
                Reason = [string]$rawException.Reason
                ReviewAuthority = [string]$rawException.ReviewAuthority
                RemovalSlice = [string]$rawException.RemovalSlice
            })
        }

        $owners.Add([pscustomobject][ordered]@{
            ContractId = $contractId
            SemanticKind = [string](Get-MeAndAIHelperOwnershipProperty `
                -Value $rawOwner -Name SemanticKind -Label $contractId)
            OwnerPath = $ownerPath
            CanonicalCommands = [string[]]$canonical
            GuardedNames = [string[]]$guarded
            ReviewedExceptions = @($exceptions)
        })
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 1
        ContractId = 'MEANDAI-TEST-HELPER-OWNERSHIP-0001'
        ScanRoots = [string[]]$scanRoots
        Owners = @($owners)
    }
}

function Get-MeAndAIHelperOwnershipRelativePath {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$LiteralPath
    )

    $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $full = [IO.Path]::GetFullPath($LiteralPath)
    $prefix = $root + [IO.Path]::DirectorySeparatorChar
    if (-not $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Helper source '$LiteralPath' escapes the repository root."
    }
    return $full.Substring($prefix.Length).Replace('\', '/')
}

function Get-MeAndAIStaticAliasName {
    param([Parameter(Mandatory)]$CommandAst)

    if ($CommandAst.GetCommandName() -cnotin @('Set-Alias', 'New-Alias')) {
        return ''
    }
    $elements = @($CommandAst.CommandElements)
    for ($index = 1; $index -lt ($elements.Count - 1); $index++) {
        $element = $elements[$index]
        if ($element -is [Management.Automation.Language.CommandParameterAst] -and
            [string]$element.ParameterName -ieq 'Name') {
            $value = $elements[$index + 1]
            if ($value -is [Management.Automation.Language.StringConstantExpressionAst]) {
                return [string]$value.Value
            }
            return ''
        }
    }
    return ''
}

function Test-MeAndAITestHelperOwnership {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$ContractPath
    )

    $contract = Import-MeAndAITestHelperOwnership -LiteralPath $ContractPath
    $violations = [System.Collections.Generic.List[string]]::new()
    $ownerByName = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $expected = [System.Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )

    foreach ($owner in @($contract.Owners)) {
        foreach ($name in @($owner.GuardedNames)) {
            $ownerByName.Add([string]$name, $owner)
        }
        foreach ($name in @($owner.CanonicalCommands)) {
            $key = "$($name.ToLowerInvariant())|$([string]$owner.OwnerPath)"
            $expected.Add($key, [pscustomobject]@{
                Name = [string]$name
                Path = [string]$owner.OwnerPath
                Count = 0
            })
        }
        foreach ($exception in @($owner.ReviewedExceptions)) {
            foreach ($name in @($exception.Names)) {
                $key = "$($name.ToLowerInvariant())|$([string]$exception.Path)"
                if ($expected.ContainsKey($key)) {
                    throw "Helper ownership expectation '$key' is duplicated."
                }
                $expected.Add($key, [pscustomobject]@{
                    Name = [string]$name
                    Path = [string]$exception.Path
                    Count = 0
                })
            }
        }
    }

    $sources = [System.Collections.Generic.List[object]]::new()
    foreach ($scanRoot in @($contract.ScanRoots)) {
        $fullRoot = Join-Path $RepositoryRoot `
            ($scanRoot -replace '/', [IO.Path]::DirectorySeparatorChar)
        if (-not (Test-Path -LiteralPath $fullRoot -PathType Container)) {
            $violations.Add("Helper ownership scan root is missing: '$scanRoot'.")
            continue
        }
        foreach ($file in @(Get-ChildItem -LiteralPath $fullRoot -Recurse -File |
            Where-Object { $_.Extension -iin @('.ps1', '.psm1') })) {
            $sources.Add($file)
        }
    }

    foreach ($file in @($sources | Sort-Object FullName -Unique)) {
        $relativePath = Get-MeAndAIHelperOwnershipRelativePath `
            -RepositoryRoot $RepositoryRoot -LiteralPath $file.FullName
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile(
            $file.FullName,
            [ref]$tokens,
            [ref]$parseErrors
        )
        foreach ($parseError in @($parseErrors)) {
            $violations.Add((
                "Helper source parse failed at '{0}:{1}': {2}" -f
                    $relativePath,
                    $parseError.Extent.StartLineNumber,
                    $parseError.Message
            ))
        }

        $definitions = [System.Collections.Generic.List[object]]::new()
        foreach ($functionAst in @($ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.FunctionDefinitionAst]
        }, $true))) {
            $definitions.Add([pscustomobject]@{
                Name = [string]$functionAst.Name
                Line = [int]$functionAst.Extent.StartLineNumber
            })
        }
        foreach ($commandAst in @($ast.FindAll({
            param($node)
            $node -is [Management.Automation.Language.CommandAst]
        }, $true))) {
            $aliasName = Get-MeAndAIStaticAliasName -CommandAst $commandAst
            if ($aliasName) {
                $definitions.Add([pscustomobject]@{
                    Name = $aliasName
                    Line = [int]$commandAst.Extent.StartLineNumber
                })
            }
        }

        foreach ($definition in @($definitions)) {
            $name = [string]$definition.Name
            if (-not $ownerByName.ContainsKey($name)) {
                continue
            }
            $key = "$($name.ToLowerInvariant())|$relativePath"
            if (-not $expected.ContainsKey($key)) {
                $violations.Add((
                    "Guarded helper '{0}' is redefined without authority at '{1}:{2}'." -f
                        $name, $relativePath, [int]$definition.Line
                ))
                continue
            }
            $expected[$key].Count = [int]$expected[$key].Count + 1
        }
    }

    foreach ($entry in @($expected.Values | Sort-Object Path, Name)) {
        if ([int]$entry.Count -ne 1) {
            $violations.Add((
                "Expected helper '{0}' must be declared exactly once at '{1}'; observed {2}." -f
                    [string]$entry.Name,
                    [string]$entry.Path,
                    [int]$entry.Count
            ))
        }
    }

    $orderedViolations = @($violations | Sort-Object -Unique)
    return [pscustomobject][ordered]@{
        Valid = $orderedViolations.Count -eq 0
        Violations = [string[]]$orderedViolations
    }
}

function Assert-MeAndAITestHelperOwnership {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$ContractPath
    )

    $result = Test-MeAndAITestHelperOwnership `
        -RepositoryRoot $RepositoryRoot -ContractPath $ContractPath
    if (-not $result.Valid) {
        throw ($result.Violations -join [Environment]::NewLine)
    }
}

Export-ModuleMember -Function @(
    'Assert-MeAndAITestHelperOwnership'
    'Import-MeAndAITestHelperOwnership'
    'Test-MeAndAITestHelperOwnership'
)
