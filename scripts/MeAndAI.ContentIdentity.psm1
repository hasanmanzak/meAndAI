Set-StrictMode -Version Latest

function Get-MeAndAIGitBlobSha1 {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $header = [Text.Encoding]::ASCII.GetBytes("blob $($Bytes.Length)`0")
    $payload = [byte[]]::new($header.Length + $Bytes.Length)
    [Array]::Copy($header, 0, $payload, 0, $header.Length)
    [Array]::Copy($Bytes, 0, $payload, $header.Length, $Bytes.Length)
    $algorithm = [Security.Cryptography.SHA1]::Create()
    try {
        return -join @($algorithm.ComputeHash($payload) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-MeAndAISha256 {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return -join @($algorithm.ComputeHash($Bytes) | ForEach-Object {
            $_.ToString('x2', [Globalization.CultureInfo]::InvariantCulture)
        })
    }
    finally {
        $algorithm.Dispose()
    }
}

function Test-MeAndAIByteArrayEqual {
    param(
        [AllowNull()][byte[]]$Left,
        [AllowNull()][byte[]]$Right
    )

    if ($null -eq $Left -or $null -eq $Right) {
        return $null -eq $Left -and $null -eq $Right
    }
    if ($Left.Length -ne $Right.Length) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }
    return $true
}

Export-ModuleMember -Function @(
    'Get-MeAndAIGitBlobSha1',
    'Get-MeAndAISha256',
    'Test-MeAndAIByteArrayEqual'
)
