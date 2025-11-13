function Unprotect-Text {
    param (
        [Parameter(Mandatory)]
        [string]$EncryptedBase64
    )
    $toBeDecrypted = [System.Convert]::FromBase64String($EncryptedBase64)
    $decrypted = [Security.Cryptography.ProtectedData]::Unprotect($toBeDecrypted, $Null, [Security.Cryptography.DataProtectionScope]::LocalMachine)
    $decryptedString = [System.Text.Encoding]::UTF8.GetString($decrypted)
    return $decryptedString
}