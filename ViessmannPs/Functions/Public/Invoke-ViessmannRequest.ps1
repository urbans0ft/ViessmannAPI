function Invoke-ViessmannRequest {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Method = 'Get',

        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory = $false)]
        [object]$Body = @{}
    )

    # get oauth token
    #$oauth = Get-ViessmannOauthToken | Test-ViessmannOauthToken
    $oauth = Get-Content -Path $script:ViessmannOauthPath | ConvertFrom-Json

    if ($PSCmdlet.ShouldProcess("$Path", "Invoke-WebRequest")) {

        $uri = $VIESSMANN_API_SERVER.TrimEnd('/') + "/" + $Path.TrimStart('/')
        $webRequestSplat = @{
            Uri     = $uri
            Headers = $Headers
            Method  = $Method
            SkipHttpErrorCheck = $true
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            $webRequestSplat.Body = $Body
        }
        $webRequestSplat.Headers['Authorization'] = "Bearer $($oauth.access_token)"
        $response = Invoke-WebRequest @webRequestSplat
        return $response
    }
}