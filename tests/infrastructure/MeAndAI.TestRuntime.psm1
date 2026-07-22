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

function Get-MeAndAITestRuntimeClass {
    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSEdition -ceq 'Desktop' -and
        $PSVersionTable.PSVersion.Major -eq 5) {
        return 'WindowsPowerShell5.1'
    }
    if ($PSVersionTable.PSEdition -ceq 'Core' -and
        $PSVersionTable.PSVersion.Major -ge 7) {
        return 'PowerShell7'
    }
    throw "Unsupported PowerShell runtime '$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)'."
}

function Get-MeAndAITestRuntimePropertyNames {
    param([Parameter(Mandatory)][object]$Value)

    if ($Value -is [System.Collections.IDictionary]) {
        return @($Value.Keys | ForEach-Object { [string]$_ })
    }
    return @($Value.PSObject.Properties | ForEach-Object { [string]$_.Name })
}

function Get-MeAndAITestRuntimePropertyValue {
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string]$Name
    )

    $propertyValue = $null
    if ($Value -is [System.Collections.IDictionary]) {
        $propertyValue = $Value[$Name]
    }
    else {
        $propertyValue = $Value.PSObject.Properties[$Name].Value
    }
    if ($propertyValue -is [array]) {
        return ,$propertyValue
    }
    return $propertyValue
}

function Assert-MeAndAITestRuntimeExactProperties {
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string[]]$Expected,
        [Parameter(Mandatory)][string]$Context,
        [switch]$RequireOrder
    )

    $actual = @(Get-MeAndAITestRuntimePropertyNames -Value $Value)
    $valid = $actual.Count -eq $Expected.Count
    for ($index = 0; $valid -and $index -lt $Expected.Count; $index++) {
        if ($RequireOrder) {
            $valid = $actual[$index] -ceq $Expected[$index]
        }
        else {
            $valid = $actual -ccontains $Expected[$index]
        }
    }
    if (-not $valid) {
        throw "$Context must contain exactly [$($Expected -join ', ')]."
    }
}

function Assert-MeAndAITestRuntimeOwner {
    param([Parameter(Mandatory)][object]$Owner)

    if ($Owner -isnot [string] -or
        [string]$Owner -cnotmatch '^tests/capabilities/[a-z0-9]+(?:-[a-z0-9]+)*/[a-z0-9][a-z0-9.-]*\.tests\.ps1$') {
        throw "Operation observation owner '$Owner' is invalid."
    }
}

function Assert-MeAndAITestRuntimeRoute {
    param([Parameter(Mandatory)][object]$Route)

    if ($Route -isnot [string] -or
        ([string]$Route -cne 'default' -and
         [string]$Route -cnotmatch '^Shard=[A-Z][A-Za-z0-9]*$')) {
        throw "Operation observation route '$Route' is invalid."
    }
}

function Assert-MeAndAITestRuntimeClassValue {
    param([Parameter(Mandatory)][object]$Runtime)

    if ($Runtime -isnot [string] -or
        @('WindowsPowerShell5.1', 'PowerShell7') -cnotcontains
            [string]$Runtime) {
        throw "Operation observation runtime '$Runtime' is invalid."
    }
}

function Assert-MeAndAITestRuntimeCounterName {
    param([Parameter(Mandatory)][object]$Name)

    if ($Name -isnot [string] -or
        [string]$Name -cnotmatch '^[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*$') {
        throw "Operation counter name '$Name' is invalid."
    }
}

function Get-MeAndAITestRuntimeArgumentSignature {
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Arguments)

    $normalized = [System.Collections.Generic.List[string]]::new()
    foreach ($argument in $Arguments) {
        if ($argument -isnot [string] -or
            [string]::IsNullOrWhiteSpace([string]$argument) -or
            [string]$argument -cne ([string]$argument).Trim() -or
            [string]$argument -cmatch '[\r\n]') {
            throw 'Suite arguments must be exact non-empty single-line strings.'
        }
        $token = [string]$argument
        if ($token.StartsWith('-', [StringComparison]::Ordinal)) {
            if ($token -cnotmatch '^-[A-Za-z][A-Za-z0-9]*$') {
                throw "Suite parameter token '$token' is invalid."
            }
            $token = '-' + $token.Substring(1).ToLowerInvariant()
        }
        $normalized.Add($token)
    }
    return $normalized -join "`0"
}

function ConvertTo-MeAndAITestRuntimeCounterExpectations {
    param(
        [Parameter(Mandatory)][object]$Counters,
        [Parameter(Mandatory)][string]$Context
    )

    if ($Counters -isnot [array] -or @($Counters).Count -eq 0) {
        throw "$Context counters must be a non-empty array."
    }
    $result = [System.Collections.Generic.List[object]]::new()
    $previous = $null
    foreach ($counter in @($Counters)) {
        Assert-MeAndAITestRuntimeExactProperties -Value $counter `
            -Expected @('Name', 'Maximum') -Context "$Context counter"
        $name = Get-MeAndAITestRuntimePropertyValue -Value $counter -Name Name
        $maximum = Get-MeAndAITestRuntimePropertyValue -Value $counter `
            -Name Maximum
        Assert-MeAndAITestRuntimeCounterName -Name $name
        if ($maximum -isnot [long] -or [long]$maximum -lt 0) {
            throw "$Context counter '$name' maximum must be a non-negative Int64."
        }
        if ($null -ne $previous -and
            [StringComparer]::Ordinal.Compare([string]$previous,
                [string]$name) -ge 0) {
            throw "$Context counters must be unique and ordinally sorted."
        }
        $result.Add([pscustomobject][ordered]@{
            Name = [string]$name
            Maximum = [long]$maximum
        })
        $previous = [string]$name
    }
    return @($result)
}

function Import-MeAndAITestOperationContract {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $data = Import-PowerShellDataFile -LiteralPath $resolved
    Assert-MeAndAITestRuntimeExactProperties -Value $data -Expected @(
        'SchemaVersion', 'Capability', 'Measurement', 'ObservationOwners',
        'ClosureTargets'
    ) -Context 'Operation contract'
    if ($data.SchemaVersion -isnot [long] -or
        [long]$data.SchemaVersion -ne 1 -or
        $data.Capability -isnot [string] -or
        [string]$data.Capability -cne 'test-runtime-efficiency') {
        throw 'Operation contract identity is invalid.'
    }
    Assert-MeAndAITestRuntimeExactProperties -Value $data.Measurement `
        -Expected @('BaseCommit', 'ObserverDigest') `
        -Context 'Operation contract measurement'
    if ($data.Measurement.BaseCommit -isnot [string] -or
        [string]$data.Measurement.BaseCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $data.Measurement.ObserverDigest -isnot [string] -or
        [string]$data.Measurement.ObserverDigest -cnotmatch
            '^sha256:[0-9a-f]{64}$') {
        throw 'Operation contract measurement identity is invalid.'
    }
    if ($data.ObservationOwners -isnot [array] -or
        @($data.ObservationOwners).Count -eq 0 -or
        $data.ClosureTargets -isnot [array] -or
        @($data.ClosureTargets).Count -eq 0) {
        throw 'Operation contract owners and closure targets must be non-empty arrays.'
    }

    $owners = [System.Collections.Generic.List[object]]::new()
    $ownerIndex = @{}
    foreach ($ownerEntry in @($data.ObservationOwners)) {
        Assert-MeAndAITestRuntimeExactProperties -Value $ownerEntry `
            -Expected @('Owner', 'Routes') -Context 'Observation owner'
        $owner = Get-MeAndAITestRuntimePropertyValue -Value $ownerEntry `
            -Name Owner
        Assert-MeAndAITestRuntimeOwner -Owner $owner
        if ($ownerIndex.ContainsKey([string]$owner)) {
            throw "Observation owner '$owner' is duplicated."
        }
        $routesValue = Get-MeAndAITestRuntimePropertyValue -Value $ownerEntry `
            -Name Routes
        if ($routesValue -isnot [array] -or @($routesValue).Count -eq 0) {
            throw "Observation owner '$owner' routes must be a non-empty array."
        }
        $routes = [System.Collections.Generic.List[object]]::new()
        $routeNames = @{}
        $argumentSignatures = @{}
        foreach ($routeEntry in @($routesValue)) {
            Assert-MeAndAITestRuntimeExactProperties -Value $routeEntry `
                -Expected @(
                    'Route', 'Arguments', 'RequiresObservation', 'Counters'
                ) `
                -Context "Observation owner '$owner' route"
            $route = Get-MeAndAITestRuntimePropertyValue -Value $routeEntry `
                -Name Route
            $arguments = Get-MeAndAITestRuntimePropertyValue -Value $routeEntry `
                -Name Arguments
            $requiresObservation = Get-MeAndAITestRuntimePropertyValue `
                -Value $routeEntry -Name RequiresObservation
            Assert-MeAndAITestRuntimeRoute -Route $route
            if ($arguments -isnot [array]) {
                throw "Observation route '$owner|$route' arguments must be an array."
            }
            if ($requiresObservation -isnot [bool]) {
                throw "Observation route '$owner|$route' requirement must be Boolean."
            }
            $signature = Get-MeAndAITestRuntimeArgumentSignature `
                -Arguments @($arguments)
            if ($routeNames.ContainsKey([string]$route) -or
                $argumentSignatures.ContainsKey($signature)) {
                throw "Observation route '$owner|$route' is duplicated or ambiguous."
            }
            $counterValue = Get-MeAndAITestRuntimePropertyValue `
                -Value $routeEntry -Name Counters
            if ([bool]$requiresObservation) {
                $counters = @(ConvertTo-MeAndAITestRuntimeCounterExpectations `
                    -Counters $counterValue `
                    -Context "Observation route '$owner|$route'")
            }
            else {
                if ($counterValue -isnot [array] -or
                    @($counterValue).Count -ne 0) {
                    throw "Reviewed non-observing route '$owner|$route' counters must be an empty array."
                }
                $counters = @()
            }
            $normalizedRoute = [pscustomobject][ordered]@{
                Route = [string]$route
                Arguments = @($arguments | ForEach-Object { [string]$_ })
                RequiresObservation = [bool]$requiresObservation
                Counters = $counters
            }
            $routes.Add($normalizedRoute)
            $routeNames[[string]$route] = $normalizedRoute
            $argumentSignatures[$signature] = $true
        }
        $normalizedOwner = [pscustomobject][ordered]@{
            Owner = [string]$owner
            Routes = @($routes)
        }
        $owners.Add($normalizedOwner)
        $ownerIndex[[string]$owner] = $routeNames
    }

    $targets = [System.Collections.Generic.List[object]]::new()
    $targetIdentities = @{}
    foreach ($target in @($data.ClosureTargets)) {
        Assert-MeAndAITestRuntimeExactProperties -Value $target -Expected @(
            'Owner', 'Route', 'Counter', 'Baseline', 'Maximum',
            'Instrumented', 'WorkId'
        ) -Context 'Operation closure target'
        $owner = Get-MeAndAITestRuntimePropertyValue -Value $target -Name Owner
        $route = Get-MeAndAITestRuntimePropertyValue -Value $target -Name Route
        $counter = Get-MeAndAITestRuntimePropertyValue -Value $target `
            -Name Counter
        $baseline = Get-MeAndAITestRuntimePropertyValue -Value $target `
            -Name Baseline
        $maximum = Get-MeAndAITestRuntimePropertyValue -Value $target `
            -Name Maximum
        $instrumented = Get-MeAndAITestRuntimePropertyValue -Value $target `
            -Name Instrumented
        $workId = Get-MeAndAITestRuntimePropertyValue -Value $target -Name WorkId
        Assert-MeAndAITestRuntimeOwner -Owner $owner
        Assert-MeAndAITestRuntimeRoute -Route $route
        Assert-MeAndAITestRuntimeCounterName -Name $counter
        if ($baseline -isnot [long] -or $maximum -isnot [long] -or
            [long]$baseline -lt 0 -or [long]$maximum -lt 0 -or
            [long]$maximum -gt [long]$baseline -or
            $instrumented -isnot [bool] -or $workId -isnot [string] -or
            [string]$workId -cnotmatch '^SUBF-[0-9]{4}$') {
            throw "Operation closure target '$owner|$route|$counter' is invalid."
        }
        if (-not $ownerIndex.ContainsKey([string]$owner) -or
            -not $ownerIndex[[string]$owner].ContainsKey([string]$route)) {
            throw "Operation closure target '$owner|$route|$counter' has no observation route."
        }
        $routeContract = $ownerIndex[[string]$owner][[string]$route]
        $counterContract = @($routeContract.Counters | Where-Object {
            $_.Name -ceq [string]$counter
        })
        if ($counterContract.Count -ne 1 -or
            [long]$counterContract[0].Maximum -ne [long]$maximum) {
            throw "Operation closure target '$owner|$route|$counter' does not match its observation maximum."
        }
        $identity = "$owner|$route|$counter"
        if ($targetIdentities.ContainsKey($identity)) {
            throw "Operation closure target '$identity' is duplicated."
        }
        $targetIdentities[$identity] = $true
        $targets.Add([pscustomobject][ordered]@{
            Owner = [string]$owner
            Route = [string]$route
            Counter = [string]$counter
            Baseline = [long]$baseline
            Maximum = [long]$maximum
            Instrumented = [bool]$instrumented
            WorkId = [string]$workId
        })
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = [long]1
        Capability = 'test-runtime-efficiency'
        Measurement = [pscustomobject][ordered]@{
            BaseCommit = [string]$data.Measurement.BaseCommit
            ObserverDigest = [string]$data.Measurement.ObserverDigest
        }
        ObservationOwners = @($owners)
        ClosureTargets = @($targets)
    }
}

function Resolve-MeAndAITestOperationExpectation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Contract,
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$SuiteArguments
    )

    Assert-MeAndAITestRuntimeOwner -Owner $Owner
    $signature = Get-MeAndAITestRuntimeArgumentSignature `
        -Arguments $SuiteArguments
    $ownerMatches = @($Contract.ObservationOwners | Where-Object {
        $_.Owner -ceq $Owner
    })
    if ($ownerMatches.Count -eq 0) {
        return $null
    }
    if ($ownerMatches.Count -gt 1) {
        throw "Operation observation owner '$Owner' is ambiguous."
    }
    $routeMatches = @($ownerMatches[0].Routes | Where-Object {
        (Get-MeAndAITestRuntimeArgumentSignature -Arguments @($_.Arguments)) `
            -ceq $signature
    })
    if ($routeMatches.Count -eq 0) {
        throw "Operation observation owner '$Owner' has no reviewed operation route for the supplied suite arguments."
    }
    if ($routeMatches.Count -gt 1) {
        throw "Operation observation route for '$Owner' and the supplied suite arguments is ambiguous."
    }
    return [pscustomobject][ordered]@{
        Owner = $Owner
        Route = [string]$routeMatches[0].Route
        Runtime = Get-MeAndAITestRuntimeClass
        RequiresObservation = [bool]$routeMatches[0].RequiresObservation
        Counters = @($routeMatches[0].Counters | ForEach-Object {
            [pscustomobject][ordered]@{
                Name = [string]$_.Name
                Maximum = [long]$_.Maximum
            }
        })
    }
}

function Format-MeAndAITestOperationObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Owner,
        [Parameter(Mandatory)][string]$Route,
        [Parameter(Mandatory)][string]$Runtime,
        [Parameter(Mandatory)][object]$Counters
    )

    Assert-MeAndAITestRuntimeOwner -Owner $Owner
    Assert-MeAndAITestRuntimeRoute -Route $Route
    Assert-MeAndAITestRuntimeClassValue -Runtime $Runtime
    if ($Counters -isnot [array] -or @($Counters).Count -eq 0) {
        throw 'Operation observation counters must be a non-empty array.'
    }
    $normalized = [System.Collections.Generic.List[object]]::new()
    $previous = $null
    foreach ($counter in @($Counters)) {
        Assert-MeAndAITestRuntimeExactProperties -Value $counter -Expected @(
            'name', 'actual', 'maximum'
        ) -Context 'Operation observation counter' -RequireOrder
        $name = Get-MeAndAITestRuntimePropertyValue -Value $counter -Name name
        $actual = Get-MeAndAITestRuntimePropertyValue -Value $counter `
            -Name actual
        $maximum = Get-MeAndAITestRuntimePropertyValue -Value $counter `
            -Name maximum
        Assert-MeAndAITestRuntimeCounterName -Name $name
        if ($actual -isnot [long] -or $maximum -isnot [long] -or
            [long]$actual -lt 0 -or [long]$maximum -lt 0 -or
            [long]$actual -gt [long]$maximum) {
            throw "Operation observation counter '$name' values must be non-negative Int64 values within maximum."
        }
        if ($null -ne $previous -and
            [StringComparer]::Ordinal.Compare([string]$previous,
                [string]$name) -ge 0) {
            throw 'Operation observation counters must be unique and ordinally sorted.'
        }
        $normalized.Add([ordered]@{
            name = [string]$name
            actual = [long]$actual
            maximum = [long]$maximum
        })
        $previous = [string]$name
    }
    $record = [ordered]@{
        schema = 1
        owner = $Owner
        route = $Route
        runtime = $Runtime
        counters = @($normalized)
    }
    return 'MEANDAI_OPERATION_OBSERVATION=' +
        ($record | ConvertTo-Json -Compress -Depth 4)
}

function Read-MeAndAITestOperationObservationRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Output,
        [Parameter(Mandatory)][string]$ExpectedOwner,
        [Parameter(Mandatory)][string]$ExpectedRoute,
        [Parameter(Mandatory)][string]$ExpectedRuntime,
        [Parameter(Mandatory)][object]$ExpectedCounters
    )

    try {
        Assert-MeAndAITestRuntimeOwner -Owner $ExpectedOwner
        Assert-MeAndAITestRuntimeRoute -Route $ExpectedRoute
        Assert-MeAndAITestRuntimeClassValue -Runtime $ExpectedRuntime
        $expected = @(ConvertTo-MeAndAITestRuntimeCounterExpectations `
            -Counters $ExpectedCounters -Context 'Expected operation')
        $lines = @($Output | ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $prefix = 'MEANDAI_OPERATION_OBSERVATION='
        $observations = @($lines | Where-Object {
            $_.StartsWith($prefix, [StringComparison]::Ordinal)
        })
        $finals = @($lines | Where-Object {
            $_.StartsWith('MEANDAI_SCENARIO_RESULTS=',
                [StringComparison]::Ordinal) -or
            $_.StartsWith('MEANDAI_COMPATIBILITY_SHARD_RESULT=',
                [StringComparison]::Ordinal)
        })
        if ($observations.Count -ne 1 -or $finals.Count -ne 1 -or
            $lines.Count -lt 2 -or $lines[-2] -cne $observations[0] -or
            $lines[-1] -cne $finals[0]) {
            throw 'Expected exactly one penultimate operation observation before one canonical final result.'
        }
        $record = $observations[0].Substring($prefix.Length) |
            ConvertFrom-Json
        Assert-MeAndAITestRuntimeExactProperties -Value $record -Expected @(
            'schema', 'owner', 'route', 'runtime', 'counters'
        ) -Context 'Operation observation' -RequireOrder
        if (($record.schema -isnot [int] -and
             $record.schema -isnot [long]) -or
            [long]$record.schema -ne 1 -or
            $record.owner -isnot [string] -or
            [string]$record.owner -cne $ExpectedOwner -or
            $record.route -isnot [string] -or
            [string]$record.route -cne $ExpectedRoute -or
            $record.runtime -isnot [string] -or
            [string]$record.runtime -cne $ExpectedRuntime -or
            $record.counters -isnot [array] -or
            @($record.counters).Count -ne $expected.Count) {
            throw 'Operation observation identity, schema, or counter count is invalid.'
        }
        $normalized = [System.Collections.Generic.List[object]]::new()
        for ($index = 0; $index -lt $expected.Count; $index++) {
            $counter = @($record.counters)[$index]
            Assert-MeAndAITestRuntimeExactProperties -Value $counter `
                -Expected @('name', 'actual', 'maximum') `
                -Context 'Operation observation counter' -RequireOrder
            $name = $counter.name
            $actual = $counter.actual
            $maximum = $counter.maximum
            if ($name -isnot [string] -or
                [string]$name -cne [string]$expected[$index].Name -or
                ($actual -isnot [int] -and $actual -isnot [long]) -or
                ($maximum -isnot [int] -and $maximum -isnot [long]) -or
                [long]$actual -lt 0 -or [long]$maximum -lt 0 -or
                [long]$actual -gt [long]$maximum -or
                [long]$maximum -ne [long]$expected[$index].Maximum) {
                throw "Operation observation counter at ordinal $index is invalid."
            }
            $normalized.Add([pscustomobject][ordered]@{
                name = [string]$name
                actual = [long]$actual
                maximum = [long]$maximum
            })
        }
        return [pscustomobject][ordered]@{
            Valid = $true
            Message = ''
            Record = [pscustomobject][ordered]@{
                schema = [long]1
                owner = $ExpectedOwner
                route = $ExpectedRoute
                runtime = $ExpectedRuntime
                counters = @($normalized)
            }
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Valid = $false
            Message = $_.Exception.Message
            Record = $null
        }
    }
}

Export-ModuleMember -Function @(
    'Compare-MeAndAIExactScenarioId',
    'Read-MeAndAIScenarioResultRecord',
    'Read-MeAndAICompatibilityShardResultRecord',
    'Invoke-MeAndAITestSuiteProcess',
    'Format-MeAndAITestSuiteObservation',
    'Get-MeAndAITestRuntimeClass',
    'Import-MeAndAITestOperationContract',
    'Resolve-MeAndAITestOperationExpectation',
    'Format-MeAndAITestOperationObservation',
    'Read-MeAndAITestOperationObservationRecord'
)
