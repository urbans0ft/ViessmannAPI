# Module-scoped variable - accessible to all functions within the module but not externally
$script:ViessmannConfigPath = Join-Path -Path $env:USERPROFILE '.ViessmanPs' 'config.json'
$script:ViessmannOauthPath  = Join-Path -Path $env:USERPROFILE '.ViessmanPs' 'oauth.json'

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

function Connect-Viessmann {
    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .NOTES
        
    .LINK
        
    .EXAMPLE
        Connect-Viessmann
    .EXAMPLE
        Connect-Viessmann `
            -Credential (Get-Credential -Message "Viesmann Developer Portal Login") `
            -ClientId 'aebc6f7fb5e546628395e57a85211e00' `
            -RedirectUri 'http://localhost:4200/'
    .EXAMPLE
        Connect-Viessmann `
            -UserName "my-login@mail.com" `
            -ClientId 'aebc6f7fb5e546628395e57a85211e00' `
            -RedirectUri 'http://localhost:4200/'
    .EXAMPLE
        Connect-Viessmann `
            -UserName "my-login@mail.com" `
            -SecurePassword (Read-Host "Password" -AsSecureString) `
            -ClientId 'aebc6f7fb5e546628395e57a85211e00' `
            -RedirectUri 'http://localhost:4200/'
    .EXAMPLE
        Connect-Viessmann `
            -UserName "my-login@mail.com" `
            -SecurePassword (Read-Host "Password" -AsSecureString) `
            -ClientId 'aebc6f7fb5e546628395e57a85211e00' `
            -RedirectUri 'http://localhost:4200/' `
            -Persist
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None', DefaultParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Credential', Mandatory)]
        [pscredential]$Credential,
        [Parameter(ParameterSetName = 'Login', Mandatory)]
        [string]$UserName,
        [Parameter(ParameterSetName = 'Login', Mandatory)]
        [securestring]$SecurePassword,
        [Parameter(ParameterSetName = 'Login', Mandatory)]
        [Parameter(ParameterSetName = 'Credential', Mandatory)]
        [String]$ClientId,
        [Parameter(ParameterSetName = 'Login', Mandatory)]
        [Parameter(ParameterSetName = 'Credential', Mandatory)]
        [String]$RedirectUri,
        [Parameter(ParameterSetName = 'Credential', Mandatory)]
        [Parameter(ParameterSetName = 'Login')]
        [switch]$Persist
    )
    Write-Debug "`$script:ViessmannConfigPath = '$script:ViessmannConfigPath'"
    # Test if parameter set is or Login to create $Credential
    Write-Debug "Parameter set is '$($PSCmdlet.ParameterSetName)'"
    if ($PSCmdlet.ParameterSetName -eq 'Login') {
        $Credential = [System.Management.Automation.PSCredential]::new($UserName, $SecurePassword)
    }
    # If set is Credential or Login get (re)assign $UserName and $Password
    if ($PSCmdlet.ParameterSetName -in @('Login', 'Credential')) {
        $UserName = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password
    }
    else {
        # try to get login information from persisted store
        Write-Debug "Attempting to use persisted configuration from: $script:ViessmannConfigPath"
        if (-not $script:ViessmannConfig -or 
            -not $script:ViessmannConfig.account -or
            -not $script:ViessmannConfig.account.name -or
            -not $script:ViessmannConfig.account.password -or
            -not $script:ViessmannConfig.client -or
            -not $script:ViessmannConfig.client.id -or
            -not $script:ViessmannConfig.client.uri) {
            
            throw "Configuration is incomplete or missing. Please provide credentials via parameters or ensure all required values are set in the configuration file at: $script:ViessmannConfigPath"
        }
        
        # Use values from persisted configuration
        $UserName    = $script:ViessmannConfig.account.name
        $Password    = $script:ViessmannConfig.account.password
        $ClientId    = $script:ViessmannConfig.client.id
        $RedirectUri = $script:ViessmannConfig.client.uri
        Write-Debug "Using persisted information for user: $UserName"
    }
    # Persist configuration if requested
    if ($Persist.IsPresent) {
        Write-Debug "Try to persist configuration to: $script:ViessmannConfigPath"
        # overwrite configuration object with template
        $script:ViessmannConfig = $script:ViessmannConfigTemplate
        # assign values
        $script:ViessmannConfig.account.name     = $UserName
        $script:ViessmannConfig.account.password = $Password
        $script:ViessmannConfig.client.id        = $ClientId
        $script:ViessmannConfig.client.uri       = $RedirectUri
        # write object to viessmann config path
        if ($PSCmdlet.ShouldProcess("$script:ViessmannConfigPath", "Writing user information to configuration file!")) {
            $script:ViessmannConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $script:ViessmannConfigPath -Encoding UTF8 -Force
            Write-Host "Configuration persisted to: $script:ViessmannConfigPath" -ForegroundColor Green
        }
    }
    Write-Debug "`$UserName    = '$UserName'"
    Write-Debug "`$Password    = '********'"
    Write-Debug "`$ClientId    = '$ClientId'"
    Write-Debug "`$RedirectUri = '$RedirectUri'"

    # https://tonyxu-io.github.io/pkce-generator/
    #codeChallenge='CDJmhfp54ZsvkmsvJEhACXKFJVCv7lbwyHVs7PlMV2s'
    #codeVerifier='d_2EdIcbf~ZkX_CnAa9bA25.2RxOof6v.27ESHG0WJEnOQUJKHTZiTqu9x1-a65KbXht7KJrE.bBQREFr0_wbrKk-C-X2WbikF-Va~nqY4qCdycxBhQ9ZwTJmFHGjEW4'
    $codeChallenge = $Authorization.challenge
    $codeVerifier  = $Authorization.verifier
    Write-Debug "`$codeChallenge   = '$($Authorization.challenge)'"
    Write-Debug "`$codeVerifier    = '$($Authorization.verifier)'"

    $authorizationScheme = 'https'
    $authorizationServer = 'iam.viessmann-climatesolutions.com'
    $authorizationPath   = '/idp/v2/authorize'
    $authorizationQuery  = "client_id=$ClientId"
    $authorizationQuery += "&redirect_uri=$RedirectUri"
    $authorizationQuery += "&scope=IoT%20User%20offline_access"
    $authorizationQuery += "&response_type=code"
    #$authorizationQuery+="&code_challenge_method=S256"
    $authorizationQuery += "&code_challenge=$codeChallenge"
    $authorizationUrl = "${authorizationScheme}://${authorizationServer}${authorizationPath}?${authorizationQuery}"

    $tokenPath = '/idp/v2/token'
    $tokenUrl  = "${authorizationScheme}://${authorizationServer}${tokenPath}"

    Write-Verbose "`$authorizationUrl = '$authorizationUrl'"
    Write-Verbose "`$tokenUrl         = '$tokenUrl'"

    [string]$authorizationCode = $null
    if ($PSCmdlet.ShouldProcess("$authorizationUrl", "Invoke-WebRequest")) {

        $response = Invoke-WebRequest `
            -Uri $authorizationUrl `
            -Headers @{ 'Content-Type' = 'application/x-www-form-urlencoded' } `
            -Method Post `
            -Body @{
                'isiwebuserid'     = $UserName
                'hidden-password'  = '00'
                'isiwebpasswd'     = $Password
                'submitbtn'        = 'LOGIN'
            } `
            -SkipHttpErrorCheck `
            -AllowInsecureRedirect `
            -MaximumRedirection 0 `
            -ErrorAction Ignore

        $authorizationCode = [System.Web.HttpUtility]::ParseQueryString([uri]::new($response.Headers.Location).Query)['code']
        Write-Verbose "`$authorizationCode = '$authorizationCode'"
    }

    if ($PSCmdlet.ShouldProcess("$tokenUrl", "Invoke-WebRequest")) {
        $response = Invoke-WebRequest `
            -Uri $tokenUrl `
            -Headers @{ 'Content-Type' = 'application/x-www-form-urlencoded' } `
            -Method Post `
            -Body @{
                'client_id'     = $ClientId
                'redirect_uri'  = $RedirectUri
                'grant_type'    = 'authorization_code'
                'code_verifier' = $codeVerifier
                'code'          = $authorizationCode
            } `
            -SkipHttpErrorCheck
        
        # create oauth object
        $oauth             = $response.Content | ConvertFrom-Json
        $responseDate      = Get-Date $response.Headers.Date[0]
        $expiryDate        = $responseDate.AddSeconds($oauth.expires_in)
        $refreshExpiryDate = $responseDate.AddDays(180)
        $oauth | Add-Member -MemberType NoteProperty -Name "expiry_date" -Value $expiryDate
        $oauth | Add-Member -MemberType NoteProperty -Name "refresh_expiry_date" -Value $refreshExpiryDate
        # write oauth object to viessmann oauth path
        if ($PSCmdlet.ShouldProcess("$script:ViessmannOauthPath", "Writing OAuth information to file!")) {
            $oauth | ConvertTo-Json -Depth 3 | Set-Content -Path $script:ViessmannOauthPath -Encoding UTF8 -Force
            Write-Host "OAuth information persisted to: $script:ViessmannOauthPath" -ForegroundColor Green
        }
    }
}


function Update-ViessmannToken {
    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .NOTES
        
    .LINK
        
    .EXAMPLE
        Update-ViessmannToken
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'None')]
    param ()

    # read in oauth file (they might have changed since module load)
    $script:ViessmannOauth  = Get-Content -Path $script:ViessmannOauthPath | ConvertFrom-Json

    if (-not $script:ViessmannOauth -or 
        -not $script:ViessmannOauth.access_token -or
        -not $script:ViessmannOauth.refresh_token) {
        throw "$script:ViessmannOauthPath is missing or incomplete. Please run Connect-Viessmann first to obtain valid tokens."
    }

    $authorizationScheme = 'https'
    $authorizationServer = 'iam.viessmann-climatesolutions.com'
    $tokenPath = '/idp/v2/token'
    $tokenUrl  = "${authorizationScheme}://${authorizationServer}${tokenPath}"
    Write-Debug "`$tokenUrl         = '$tokenUrl'"
    if ($PSCmdlet.ShouldProcess("$tokenUrl", "Invoke-WebRequest")) {
        $response = Invoke-WebRequest `
            -Uri $tokenUrl `
            -Headers @{ 'Content-Type' = 'application/x-www-form-urlencoded' } `
            -Method Post `
            -Body @{
                'grant_type'    = 'refresh_token'
                'client_id'     = $script:ViessmannConfig.client.id
                'refresh_token' = $script:ViessmannOauth.refresh_token
            } `
            -SkipHttpErrorCheck
        
        # update oauth object (access token and expiry_date)
        $oauth             = $response.Content | ConvertFrom-Json
        $responseDate      = Get-Date $response.Headers.Date[0]
        $expiryDate        = $responseDate.AddSeconds($oauth.expires_in)
        $refreshExpiryDate = $script:ViessmannOauth.refresh_expiry_date
        $oauth | Add-Member -MemberType NoteProperty -Name "expiry_date" -Value $expiryDate
        $oauth | Add-Member -MemberType NoteProperty -Name "refresh_expiry_date" -Value $refreshExpiryDate
        # write oauth object to viessmann oauth path
        if ($PSCmdlet.ShouldProcess("$script:ViessmannOauthPath", "Writing OAuth information to file!")) {
            $oauth | ConvertTo-Json -Depth 3 | Set-Content -Path $script:ViessmannOauthPath -Encoding UTF8 -Force
            Write-Host "OAuth information persisted to: $script:ViessmannOauthPath" -ForegroundColor Green
        }
    }
}
