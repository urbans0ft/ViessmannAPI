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
