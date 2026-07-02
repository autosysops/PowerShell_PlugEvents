function Connect-PlugEvents {
    <#
    .SYNOPSIS
        Connect to Plug.Events

    .DESCRIPTION
        Connect to Plug.Events. Optionally authenticate with a Plug.Events account
        by supplying a -Credential object containing your email address and password.

    .PARAMETER Endpoint
        Endpoint to connect to. When not entered it will retrieve the first production endpoint by default.

    .PARAMETER ConnectionToken
        Token to use in the connection. When not entered it will retrieve this automatically.

    .PARAMETER Credential
        PSCredential object containing the Plug.Events account email address (username)
        and password. The password is sent in plain text over the WebSocket connection,
        which is itself secured by TLS (wss://).

    .PARAMETER SkipWarning
        Suppress the plain-text password confirmation prompt. Use this for unattended
        or automated scenarios.

    .EXAMPLE
        Connect to Plug.Events anonymously:

        PS> Connect-PlugEvents

    .EXAMPLE
        Connect and authenticate with a credential:

        PS> $cred = Get-Credential
        PS> Connect-PlugEvents -Credential $cred

    .EXAMPLE
        Connect and authenticate without the plain-text warning (unattended):

        PS> $cred = Get-Credential
        PS> Connect-PlugEvents -Credential $cred -SkipWarning
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Its the name of the product')]

    [CmdLetBinding(DefaultParameterSetName = 'Anonymous')]
    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Endpoint = (Get-PlugEventsEndpoint -Type p -First 1).Types.Endpoint,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $ConnectionToken = (Open-PlugEventsWebsocket -Endpoint $Endpoint).connectionToken,

        [Parameter(Mandatory = $true, ParameterSetName = 'Authenticated')]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory = $false, ParameterSetName = 'Authenticated')]
        [Switch] $SkipWarning
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Connect-PlugEvents" -PropertiesHash @{Authenticated = ($PSCmdlet.ParameterSetName -eq 'Authenticated')}

    # Reset authentication state on each new connection
    $Script:isAuthenticated = $false

    # Create the websocket client and cancellation token
    $Script:websocket = [System.Net.WebSockets.ClientWebSocket]::new()
    $Script:cancellationToken = [System.Threading.CancellationTokenSource]::new()

    # Add the option for json
    $Script:websocket.Options.AddSubProtocol('json')

    # Connect
    $uriObj = [Uri]"wss://$Endpoint/hub1?id=$ConnectionToken"
    $null = $Script:websocket.ConnectAsync($uriObj, $Script:cancellationToken.Token).GetAwaiter().GetResult()

    # Send a message to establish the handshake
    Send-PlugEventsMessage -Message '{"protocol":"json","version":1}'

    # Check for a message
    $message = Receive-PlugEventsMessage -IgnoreKeepAlive
    if($message -ne "{}") {
        throw "Plug Events: the connection could not be established. Error message: $message"
    }

    # Authenticate if credentials were supplied
    if ($PSCmdlet.ParameterSetName -eq 'Authenticated') {

        # Warn the user about plain-text password transmission unless suppressed
        if (-not $SkipWarning) {
            Write-Warning "Your password will be sent in plain text over the WebSocket connection. The connection is secured by TLS (wss://), so it is still protected in transit."
            $confirmation = Read-Host "Type 'yes' or 'y' to continue"
            if ($confirmation -ne 'yes' -and $confirmation -ne 'y') {
                Disconnect-PlugEvents
                throw "Plug Events: authentication aborted by the user."
            }
        }

        # Build the authentication message
        $email    = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        $authMessage = '{"target":"Authenticate2","arguments":["' + $email + '","' + $password + '",null],"invocationId":"6","type":1}'

        # Send the authentication message
        Send-PlugEventsMessage -Message $authMessage

        # Receive the authentication response
        $authResponse = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive
        $authResult   = ($authResponse | ConvertFrom-Json).result

        if (-not $authResult.isSuccess) {
            Disconnect-PlugEvents
            throw "Plug Events: authentication failed. Error $($authResult.errorCode): $($authResult.message)"
        }

        $Script:isAuthenticated = $true
    }
}