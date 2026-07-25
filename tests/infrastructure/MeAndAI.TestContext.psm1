Set-StrictMode -Version Latest

$script:ActiveContext = $null

function Assert-MeAndAITestFailureContext {
    param([Parameter(Mandatory)][object]$Context)

    if ($null -eq $Context -or
        $Context.PSObject.TypeNames -cnotcontains 'MeAndAI.TestContext' -or
        $null -eq $Context.PSObject.Properties['Failures'] -or
        $Context.Failures -isnot
            [System.Collections.Generic.List[string]]) {
        throw 'The meAndAI test failure context is invalid.'
    }
}

function New-MeAndAITestContext {
    [CmdletBinding()]
    param()

    $context = [pscustomobject][ordered]@{
        Failures = [System.Collections.Generic.List[string]]::new()
    }
    $context.PSObject.TypeNames.Insert(0, 'MeAndAI.TestContext')
    return $context
}

function Set-MeAndAITestContext {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Context)

    Assert-MeAndAITestFailureContext -Context $Context
    if ($null -ne $script:ActiveContext -and
        -not [object]::ReferenceEquals($script:ActiveContext, $Context)) {
        throw 'The active meAndAI test context must be cleared before another context is activated.'
    }
    $script:ActiveContext = $Context
}

function Clear-MeAndAITestContext {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Context)

    Assert-MeAndAITestFailureContext -Context $Context
    if ($null -eq $script:ActiveContext) {
        throw 'No meAndAI test context is active.'
    }
    if (-not [object]::ReferenceEquals($script:ActiveContext, $Context)) {
        throw 'The supplied meAndAI test context is not the active context.'
    }
    $script:ActiveContext = $null
}

function Add-MeAndAITestFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Context,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Message
    )

    Assert-MeAndAITestFailureContext -Context $Context
    [void]$Context.Failures.Add($Message)
}

function Add-Failure {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Message)

    if ($null -eq $script:ActiveContext) {
        throw 'No meAndAI test context is active.'
    }
    Add-MeAndAITestFailure -Context $script:ActiveContext -Message $Message
}

function Assert-MeAndAITestCollectedTrue {
    param(
        [Parameter(Mandatory)][object]$Context,
        [bool]$Condition,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Message
    )

    Assert-MeAndAITestFailureContext -Context $Context
    if (-not $Condition) {
        Add-MeAndAITestFailure -Context $Context -Message $Message
    }
}

function Assert-MeAndAITestCollectedEqual {
    param(
        [Parameter(Mandatory)][object]$Context,
        $Expected,
        $Actual,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Message
    )

    Assert-MeAndAITestFailureContext -Context $Context
    if ($Expected -ne $Actual) {
        Add-MeAndAITestFailure -Context $Context `
            -Message "$Message; expected '$Expected', found '$Actual'"
    }
}

function Get-MeAndAITestFailures {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Context)

    Assert-MeAndAITestFailureContext -Context $Context
    return [string[]]$Context.Failures.ToArray()
}

Export-ModuleMember -Function @(
    'New-MeAndAITestContext',
    'Set-MeAndAITestContext',
    'Clear-MeAndAITestContext',
    'Add-MeAndAITestFailure',
    'Add-Failure',
    'Assert-MeAndAITestCollectedTrue',
    'Assert-MeAndAITestCollectedEqual',
    'Get-MeAndAITestFailures'
)
