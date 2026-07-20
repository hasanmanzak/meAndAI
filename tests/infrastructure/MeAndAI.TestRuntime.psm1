Set-StrictMode -Version Latest

function Compare-MeAndAIExactScenarioId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Expected,
        [Parameter(Mandatory)][object[]]$Observed
    )

    $expectedIds = @($Expected | ForEach-Object { [string]$_ })
    $observedIds = @($Observed | ForEach-Object { [string]$_ })
    $expectedSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    $observedSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($testId in $expectedIds) {
        if ($testId -cnotmatch '^TEST-[0-9]{4}$' -or -not $expectedSet.Add($testId)) {
            return [pscustomobject]@{
                Valid = $false
                Message = "expected scenario set contains invalid or duplicate identity '$testId'"
            }
        }
    }
    foreach ($testId in $observedIds) {
        if ($testId -cnotmatch '^TEST-[0-9]{4}$' -or -not $observedSet.Add($testId)) {
            return [pscustomobject]@{
                Valid = $false
                Message = "observed scenario set contains invalid or duplicate identity '$testId'"
            }
        }
    }
    if ($expectedIds.Count -ne $observedIds.Count -or
        -not $expectedSet.SetEquals($observedSet)) {
        $missing = @($expectedIds | Where-Object { -not $observedSet.Contains($_) })
        $unexpected = @($observedIds | Where-Object { -not $expectedSet.Contains($_) })
        return [pscustomobject]@{
            Valid = $false
            Message = "scenario result mismatch; missing=[$($missing -join ', ')]; unexpected=[$($unexpected -join ', ')]"
        }
    }
    return [pscustomobject]@{ Valid = $true; Message = '' }
}

function Read-MeAndAIScenarioResultRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Output,
        [Parameter(Mandatory)][string]$ExpectedOwner,
        [Parameter(Mandatory)][object[]]$ExpectedTestIds
    )

    $lines = @($Output | ForEach-Object { [string]$_ })
    $nonEmptyLines = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $resultLines = @($nonEmptyLines | Where-Object {
        $_.StartsWith('MEANDAI_SCENARIO_RESULTS=', [StringComparison]::Ordinal)
    })
    if ($resultLines.Count -ne 1) {
        return [pscustomobject]@{
            Valid = $false
            Message = "expected exactly one scenario result line, found $($resultLines.Count)"
        }
    }
    if ($nonEmptyLines.Count -eq 0 -or $nonEmptyLines[-1] -cne $resultLines[0]) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'scenario result line is not the final successful suite output'
        }
    }

    try {
        $json = $resultLines[0].Substring('MEANDAI_SCENARIO_RESULTS='.Length)
        $record = $json | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Valid = $false
            Message = "scenario result JSON is invalid: $($_.Exception.Message)"
        }
    }
    $properties = @($record.PSObject.Properties | ForEach-Object { $_.Name })
    if ($properties.Count -ne 3 -or
        $properties -cnotcontains 'schema' -or
        $properties -cnotcontains 'owner' -or
        $properties -cnotcontains 'passed' -or
        ($record.schema -isnot [int] -and $record.schema -isnot [long]) -or
        [long]$record.schema -ne 1 -or
        [string]$record.owner -cne $ExpectedOwner -or
        $record.passed -isnot [array]) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'scenario result record has the wrong schema, owner, or property types'
        }
    }

    return Compare-MeAndAIExactScenarioId -Expected $ExpectedTestIds `
        -Observed @($record.passed)
}

function Read-MeAndAICompatibilityShardResultRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Output,
        [Parameter(Mandatory)][string]$ExpectedSuite,
        [Parameter(Mandatory)][string]$ExpectedShard
    )

    $lines = @($Output | ForEach-Object { [string]$_ })
    $nonEmptyLines = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $canonicalLines = @($nonEmptyLines | Where-Object {
        $_.StartsWith('MEANDAI_SCENARIO_RESULTS=', [StringComparison]::Ordinal)
    })
    $resultLines = @($nonEmptyLines | Where-Object {
        $_.StartsWith('MEANDAI_COMPATIBILITY_SHARD_RESULT=', [StringComparison]::Ordinal)
    })
    if ($canonicalLines.Count -ne 0 -or $resultLines.Count -ne 1 -or
        $nonEmptyLines.Count -eq 0 -or $nonEmptyLines[-1] -cne $resultLines[0]) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'partial execution must end with exactly one compatibility result and no canonical scenario result'
        }
    }
    try {
        $json = $resultLines[0].Substring('MEANDAI_COMPATIBILITY_SHARD_RESULT='.Length)
        $record = $json | ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Valid = $false
            Message = "compatibility result JSON is invalid: $($_.Exception.Message)"
        }
    }
    $properties = @($record.PSObject.Properties | ForEach-Object { $_.Name })
    if ($properties.Count -ne 4 -or
        $properties -cnotcontains 'schema' -or
        $properties -cnotcontains 'suite' -or
        $properties -cnotcontains 'shard' -or
        $properties -cnotcontains 'passed' -or
        ($record.schema -isnot [int] -and $record.schema -isnot [long]) -or
        [long]$record.schema -ne 1 -or
        [string]$record.suite -cne $ExpectedSuite -or
        [string]$record.shard -cne $ExpectedShard -or
        $record.passed -isnot [bool] -or -not [bool]$record.passed) {
        return [pscustomobject]@{
            Valid = $false
            Message = 'compatibility result has the wrong schema, identity, or success value'
        }
    }
    return [pscustomobject]@{ Valid = $true; Message = '' }
}

function Invoke-MeAndAITestSuiteProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$EnginePath,
        [Parameter(Mandatory)][string]$SuitePath,
        [string[]]$Arguments = @()
    )

    $processArguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $SuitePath
    ) + @($Arguments)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $output = @(& $EnginePath @processArguments 2>&1)
        $exitCode = [int]$LASTEXITCODE
    }
    finally {
        $stopwatch.Stop()
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $output
        ElapsedMilliseconds = [long]$stopwatch.ElapsedMilliseconds
    }
}

function Format-MeAndAITestSuiteObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Owner,
        [Parameter(Mandatory)][object]$ElapsedMilliseconds
    )

    if ([string]::IsNullOrWhiteSpace($Owner)) {
        throw 'Suite observation owner must not be empty.'
    }
    if ($ElapsedMilliseconds -isnot [long] -or
        [long]$ElapsedMilliseconds -lt 0) {
        throw 'Suite observation elapsed milliseconds must be a non-negative Int64.'
    }
    $record = [ordered]@{
        schema = 1
        owner = $Owner
        elapsedMs = [long]$ElapsedMilliseconds
    }
    return 'MEANDAI_SUITE_OBSERVATION=' +
        ($record | ConvertTo-Json -Compress)
}

Export-ModuleMember -Function @(
    'Compare-MeAndAIExactScenarioId',
    'Read-MeAndAIScenarioResultRecord',
    'Read-MeAndAICompatibilityShardResultRecord',
    'Invoke-MeAndAITestSuiteProcess',
    'Format-MeAndAITestSuiteObservation'
)
