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
        [String]$RedirectUri
    )

    # Test if parameter set is or Login to create $Credential
    Write-Debug "Parameter set is '$($PSCmdlet.ParameterSetName)'"
    if ($PSCmdlet.ParameterSetName -eq 'Login') {
        $Credential = [System.Management.Automation.PSCredential]::new($UserName, $SecurePassword)
    }
    # If set is Credential or Login get (re)assign $UserName and $Password
    if ($PSCmdlet.ParameterSetName -in @('Login', 'Credential')) {
        $UserName = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password
        Write-Debug "`$UserName = '$UserName'"
        Write-Debug "`$Password = '********'"
    }

    if (-not (Test-Path -Path '.account.json')) {
        Throw "File '.account.json' not found. Please create this file with your Viessmann account details."
    }

    $account = Get-Content -Path '.account.json' | ConvertFrom-Json

    $acccountName    = $account.account.name
    $accountPassword = $account.account.password
    $clientId        = $account.client.id
    $redirectUri     = $account.client.uri
    Write-Debug "`$acccountName    = '$($account.account.name)'"
    Write-Debug "`$accountPassword = '$($account.account.password)'"
    Write-Debug "`$clientId        = '$($account.client.id)'"
    Write-Debug "`$redirectUri     = '$($account.client.uri)'"

    # https://tonyxu-io.github.io/pkce-generator/
    #codeChallenge='CDJmhfp54ZsvkmsvJEhACXKFJVCv7lbwyHVs7PlMV2s'
    #codeVerifier='d_2EdIcbf~ZkX_CnAa9bA25.2RxOof6v.27ESHG0WJEnOQUJKHTZiTqu9x1-a65KbXht7KJrE.bBQREFr0_wbrKk-C-X2WbikF-Va~nqY4qCdycxBhQ9ZwTJmFHGjEW4'
    $codeChallenge = $account.authorization.challenge
    $codeVerifier  = $account.authorization.verifier
    Write-Debug "`$codeChallenge   = '$codeChallenge'"
    Write-Debug "`$codeVerifier    = '$codeVerifier'"

    $authorizationScheme = 'https'
    $authorizationServer = 'iam.viessmann-climatesolutions.com'
    $authorizationPath   = '/idp/v2/authorize'
    $authorizationQuery  = "client_id=$clientId"
    $authorizationQuery += "&redirect_uri=$redirectUri"
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
                'isiwebuserid'     = $acccountName
                'hidden-password'  = '00'
                'isiwebpasswd'     = $accountPassword
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
        Invoke-WebRequest `
            -Uri $tokenUrl `
            -Headers @{ 'Content-Type' = 'application/x-www-form-urlencoded' } `
            -Method Post `
            -Body @{
                'client_id'     = $clientId
                'redirect_uri'  = $redirectUri
                'grant_type'    = 'authorization_code'
                'code_verifier' = $codeVerifier
                'code'          = $authorizationCode
            } `
            -SkipHttpErrorCheck
    }
    # https://iam.viessmann-climatesolutions.com/idp/v2/authorize?client_id=fc567f39f9db31dddfa2158fe88e591c&redirect_uri=http://localhost:4200/&scope=IoT%20User%20offline_access&response_type=code&code_challenge=2e21faa1-db2c-4d0b-a10f-575fd372bc8c-575fd372bc8c
}   # https://iam.viessmann-climatesolutions.com/idp/v2/authorize?client_id=fc567f39f9db31dddfa2158fe88e591c&redirect_uri=http://localhost:4200/&scope=IoT%20User%20offline_access&response_type=code&code_challenge=2e21faa1-db2c-4d0b-a10f-575fd372bc8c-575fd372bc8c