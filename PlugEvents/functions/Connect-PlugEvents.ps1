function Connect-PlugEvents {
    <#
    .SYNOPSIS
        Connect to Plug.Events

    .DESCRIPTION
        Connect to Plug.Events

    .PARAMETER Endpoint
        Endpoint to connect to. When not entered it will retrieve the first production endpoint by default.

    .PARAMETER ConnectionToken
        Token to use in the connection. When not entered it will retrieve this automatically.

    .EXAMPLE
        Connect to Plug-Events

        PS> Connect-PlugEvents
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Its the name of the product')]

    [CmdLetBinding()]
    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Endpoint = (Get-PlugEventsEndpoint -Type p -First 1).Types.Endpoint,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $ConnectionToken = (Open-PlugEventsWebsocket -Endpoint $Endpoint).connectionToken
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Connect-PlugEvents"

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
}