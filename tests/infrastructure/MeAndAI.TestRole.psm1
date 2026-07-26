Set-StrictMode -Version Latest

function Add-MeAndAITestRoleViolation {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]]$Violation,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$Detail,
        [Parameter(Mandatory)][int]$Line
    )

    [void]$Violation.Add(('{0}:{1}:line {2}' -f $Code, $Detail, $Line))
}

function Test-MeAndAIAssertionCommandName {
    param([AllowEmptyString()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    return $Name -match '^(?i:Assert-|Add-Failure$|Add-MeAndAITestFailure$)'
}

function Test-MeAndAICaseCompletionCommandName {
    param([AllowEmptyString()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    return $Name -match
        '^(?i:(?:Confirm|Complete|New)-MeAndAI.*(?:ScenarioEvidence|ScenarioResult))'
}

function Resolve-MeAndAIStaticStringExpression {
    param([Parameter(Mandatory)]$Ast)

    if ($Ast -is [Management.Automation.Language.StringConstantExpressionAst]) {
        return [pscustomobject]@{ Resolved = $true; Value = [string]$Ast.Value }
    }
    if ($Ast -is [Management.Automation.Language.ExpandableStringExpressionAst] -and
        @($Ast.NestedExpressions).Count -eq 0) {
        return [pscustomobject]@{ Resolved = $true; Value = [string]$Ast.Value }
    }
    if ($Ast -is [Management.Automation.Language.BinaryExpressionAst] -and
        $Ast.Operator -eq [Management.Automation.Language.TokenKind]::Plus) {
        $left = Resolve-MeAndAIStaticStringExpression -Ast $Ast.Left
        $right = Resolve-MeAndAIStaticStringExpression -Ast $Ast.Right
        if ($left.Resolved -and $right.Resolved) {
            return [pscustomobject]@{
                Resolved = $true
                Value = [string]$left.Value + [string]$right.Value
            }
        }
    }

    return [pscustomobject]@{ Resolved = $false; Value = $null }
}

function Get-MeAndAIStaticStringValue {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Ast)

    $values = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($node in @($Ast.FindAll({
        param($candidate)
        $candidate -is
            [Management.Automation.Language.StringConstantExpressionAst] -or
            $candidate -is
            [Management.Automation.Language.ExpandableStringExpressionAst] -or
            ($candidate -is
                [Management.Automation.Language.BinaryExpressionAst] -and
                $candidate.Operator -eq
                    [Management.Automation.Language.TokenKind]::Plus)
    }, $true))) {
        $resolved = Resolve-MeAndAIStaticStringExpression -Ast $node
        if ($resolved.Resolved) {
            [void]$values.Add([string]$resolved.Value)
        }
    }

    [string[]]$ordered = @($values)
    [Array]::Sort($ordered, [StringComparer]::Ordinal)
    return $ordered
}

function Test-MeAndAICanonicalSuiteDispatch {
    param([Parameter(Mandatory)]$CommandAst)

    $commandName = [string]$CommandAst.GetCommandName()
    if ($commandName -match '(?i)(?:^|[\\/])[^\\/]+\.tests\.ps1$' -or
        $commandName -ieq 'Invoke-MeAndAITestSuiteProcess') {
        return $true
    }

    if ($commandName -notmatch '^(?i:powershell|powershell\.exe|pwsh|pwsh\.exe)$') {
        return $false
    }
    $extent = [string]$CommandAst.Extent.Text
    if ($extent -notmatch '(?i)(?:^|\s)-File(?:\s|:)') { return $false }
    return @(Get-MeAndAIStaticStringValue -Ast $CommandAst | Where-Object {
        $_ -match '(?i)(?:^|[\\/])[^\\/]+\.tests\.ps1$'
    }).Count -gt 0
}

function Test-MeAndAITestRoleSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)]
        [ValidateSet('Runner', 'Harness', 'Case', 'Support', 'Fixture', 'Mock')]
        [string]$Role,
        [string[]]$AllowedAssertionCommand = @()
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        throw "Test-role source does not exist: '$LiteralPath'."
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path -LiteralPath $LiteralPath).Path,
        [ref]$tokens,
        [ref]$parseErrors
    )
    $observations = [System.Collections.Generic.List[object]]::new()
    foreach ($parseError in @($parseErrors)) {
        $observations.Add([pscustomobject]@{
            Code = 'ParseError'
            Detail = [string]$parseError.Message
            Line = [int]$parseError.Extent.StartLineNumber
        })
    }

    foreach ($stringAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.StringConstantExpressionAst] -or
            $node -is [Management.Automation.Language.ExpandableStringExpressionAst]
    }, $true))) {
        $value = [string]$stringAst.Value
        foreach ($match in [regex]::Matches(
            $value,
            '(?<![A-Za-z0-9-])TEST-[0-9]{4}(?![A-Za-z0-9-])'
        )) {
            $observations.Add([pscustomobject]@{
                Code = 'ConcreteTestIdentity'
                Detail = [string]$match.Value
                Line = [int]$stringAst.Extent.StartLineNumber
            })
        }
        if ($value.Contains('MEANDAI_SCENARIO_RESULTS=')) {
            $observations.Add([pscustomobject]@{
                Code = 'ScenarioResultEmission'
                Detail = 'MEANDAI_SCENARIO_RESULTS'
                Line = [int]$stringAst.Extent.StartLineNumber
            })
        }
    }

    foreach ($functionAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst]
    }, $true))) {
        if (Test-MeAndAIAssertionCommandName -Name ([string]$functionAst.Name)) {
            $observations.Add([pscustomobject]@{
                Code = 'Assertion'
                Detail = [string]$functionAst.Name
                Line = [int]$functionAst.Extent.StartLineNumber
            })
        }
    }

    foreach ($commandAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.CommandAst]
    }, $true))) {
        $commandName = [string]$commandAst.GetCommandName()
        if (Test-MeAndAIAssertionCommandName -Name $commandName) {
            $observations.Add([pscustomobject]@{
                Code = 'Assertion'
                Detail = $commandName
                Line = [int]$commandAst.Extent.StartLineNumber
            })
        }
        if (Test-MeAndAICaseCompletionCommandName -Name $commandName) {
            $observations.Add([pscustomobject]@{
                Code = 'CaseCompletion'
                Detail = $commandName
                Line = [int]$commandAst.Extent.StartLineNumber
            })
        }
        if ($commandName -cin @(
            'New-MeAndAITestContext',
            'Set-MeAndAITestContext',
            'Get-MeAndAITestFailures',
            'Add-MeAndAITestFailure'
        )) {
            $observations.Add([pscustomobject]@{
                Code = 'FailureAggregation'
                Detail = $commandName
                Line = [int]$commandAst.Extent.StartLineNumber
            })
        }
        if (Test-MeAndAICanonicalSuiteDispatch -CommandAst $commandAst) {
            $observations.Add([pscustomobject]@{
                Code = 'CanonicalSuiteDispatch'
                Detail = if ($commandName) { $commandName } else { 'dynamic command' }
                Line = [int]$commandAst.Extent.StartLineNumber
            })
        }
    }

    foreach ($variableAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.VariableExpressionAst] -and
            [string]$node.VariablePath.UserPath -ieq 'failures'
    }, $true))) {
        $observations.Add([pscustomobject]@{
            Code = 'FailureAggregation'
            Detail = '$failures'
            Line = [int]$variableAst.Extent.StartLineNumber
        })
    }
    foreach ($memberAst in @($ast.FindAll({
        param($node)
        $node -is [Management.Automation.Language.MemberExpressionAst] -and
            $node.Member -is
                [Management.Automation.Language.StringConstantExpressionAst] -and
            [string]$node.Member.Value -ieq 'Failures'
    }, $true))) {
        $observations.Add([pscustomobject]@{
            Code = 'FailureAggregation'
            Detail = '.Failures'
            Line = [int]$memberAst.Extent.StartLineNumber
        })
    }

    $prohibited = switch ($Role) {
        'Runner' {
            @(
                'ConcreteTestIdentity', 'Assertion', 'CaseCompletion',
                'ScenarioResultEmission'
            )
        }
        'Harness' { @('ConcreteTestIdentity') }
        'Case' { @() }
        default {
            @(
                'ConcreteTestIdentity', 'Assertion', 'FailureAggregation',
                'CaseCompletion', 'ScenarioResultEmission',
                'CanonicalSuiteDispatch'
            )
        }
    }

    $violations = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($observation in $observations) {
        if ($observation.Code -ceq 'Assertion' -and
            @($AllowedAssertionCommand | Where-Object {
                [string]$_ -ceq [string]$observation.Detail
            }).Count -eq 1) {
            continue
        }
        if ($observation.Code -cin $prohibited -or
            $observation.Code -ceq 'ParseError') {
            Add-MeAndAITestRoleViolation -Violation $violations `
                -Code ([string]$observation.Code) `
                -Detail ([string]$observation.Detail) `
                -Line ([int]$observation.Line)
        }
    }

    [string[]]$orderedViolations = @($violations)
    [Array]::Sort($orderedViolations, [StringComparer]::Ordinal)
    return [pscustomobject]@{
        Valid = $orderedViolations.Count -eq 0
        Violations = $orderedViolations
    }
}

Export-ModuleMember -Function @(
    'Get-MeAndAIStaticStringValue'
    'Test-MeAndAITestRoleSource'
)
