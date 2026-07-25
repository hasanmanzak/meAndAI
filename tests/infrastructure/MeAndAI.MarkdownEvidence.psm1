Set-StrictMode -Version Latest

function Test-MeAndAIContainsExactDocumentTitle {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Title
    )

    return [regex]::IsMatch(
        $Text,
        '(?i)(?<![A-Za-z0-9])' + [regex]::Escape($Title) +
            '(?![A-Za-z0-9])'
    )
}

Export-ModuleMember -Function 'Test-MeAndAIContainsExactDocumentTitle'
