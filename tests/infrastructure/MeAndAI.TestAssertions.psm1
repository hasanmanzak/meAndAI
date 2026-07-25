Set-StrictMode -Version Latest

function Assert-MeAndAITestTrue {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) { throw $Message }
}

function Assert-MeAndAITestEqual {
    param(
        $Actual,
        $Expected,
        [string]$Message
    )

    if ($Actual -cne $Expected) {
        throw "$Message Expected '$Expected', observed '$Actual'."
    }
}

function Assert-MeAndAITestSequenceEqual {
    param(
        [object[]]$Actual,
        [object[]]$Expected,
        [string]$Message
    )

    if ($Actual.Count -ne $Expected.Count) {
        throw "$Message Count differs: $($Actual.Count) != $($Expected.Count)."
    }
    for ($index = 0; $index -lt $Actual.Count; $index++) {
        if ([string]$Actual[$index] -cne [string]$Expected[$index]) {
            throw "$Message Element $index differs: '$($Actual[$index])' != '$($Expected[$index])'."
        }
    }
}

function Assert-MeAndAITestThrowsLike {
    param(
        [scriptblock]$Action,
        [string]$Pattern,
        [string]$Message
    )

    try {
        & $Action
    }
    catch {
        if ($_.Exception.Message -like $Pattern) { return }
        throw "$Message Unexpected error: $($_.Exception.Message)"
    }
    throw "$Message No error was thrown."
}

Set-Alias -Name 'Assert-True' -Value 'Assert-MeAndAITestTrue' -Scope Script
Set-Alias -Name 'Assert-Equal' -Value 'Assert-MeAndAITestEqual' -Scope Script
Set-Alias -Name 'Assert-SequenceEqual' `
    -Value 'Assert-MeAndAITestSequenceEqual' -Scope Script
Set-Alias -Name 'Assert-ThrowsLike' `
    -Value 'Assert-MeAndAITestThrowsLike' -Scope Script

Export-ModuleMember -Function @(
    'Assert-MeAndAITestTrue',
    'Assert-MeAndAITestEqual',
    'Assert-MeAndAITestSequenceEqual',
    'Assert-MeAndAITestThrowsLike'
) -Alias @(
    'Assert-True',
    'Assert-Equal',
    'Assert-SequenceEqual',
    'Assert-ThrowsLike'
)
