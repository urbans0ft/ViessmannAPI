function Protect-Text {
    param (
        [Parameter(Mandatory)]
        [string]$Text
    )
    $encoded = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $encrypted = [Security.Cryptography.ProtectedData]::Protect($encoded, $Null, [Security.Cryptography.DataProtectionScope]::LocalMachine)
    $encryptedBase64 = [System.Convert]::ToBase64String($encrypted)
    return $encryptedBase64
}