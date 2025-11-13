# Module-scoped variable - accessible to all functions within the module but not externally
$script:ViessmannConfigPath = Join-Path -Path $env:USERPROFILE '.ViessmanPs' 'config.json'
$script:ViessmannOauthPath  = Join-Path -Path $env:USERPROFILE '.ViessmanPs' 'oauth.json'

New-Variable -Name VIESSMANN_API_SERVER -Value 'https://api.viessmann-climatesolutions.com' -Scope Script -Option Constant

$script:ViessmannConfigTemplate = [PSCustomObject]@{
    "account" = [PSCustomObject]@{
        "name"     = $null
        "password" = $null
    }
    "client"  = [PSCustomObject]@{
        "id"       = $null
        "uri"      = $null
    }
}
$script:Authorization = [PSCustomObject]@{
    "challenge" = "2e21faa1-db2c-4d0b-a10f-575fd372bc8c-575fd372bc8c"
    "verifier"  = "2e21faa1-db2c-4d0b-a10f-575fd372bc8c-575fd372bc8c"
}

# Ensure config file exists
if (-not (Test-Path -Path $script:ViessmannConfigPath)) {
    New-Item -Path $script:ViessmannConfigPath -ItemType File -Force | Out-Null
}
# Ensure oauth file exists
if (-not (Test-Path -Path $script:ViessmannOauthPath)) {
    New-Item -Path $script:ViessmannOauthPath -ItemType File -Force | Out-Null
}

# Load configuration (may be null)
$script:ViessmannConfig = Get-Content -Path $script:ViessmannConfigPath | ConvertFrom-Json
$script:ViessmannOauth  = Get-Content -Path $script:ViessmannOauthPath | ConvertFrom-Json

# Load all functions from the Functions folder
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions') -Filter '*.ps1' -Recurse |
ForEach-Object {
    . $_.FullName
}

# Export all functions from public functions folder
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Functions\Public') -Filter '*.ps1' -Recurse |
ForEach-Object {
    $functionName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    Export-ModuleMember -Function $functionName
}




