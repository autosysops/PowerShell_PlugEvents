function Open-PlugEventsWebsocket {
    <#
    .SYNOPSIS
        Open a websocket connection to plug.events and return the connectionToken.

    .DESCRIPTION
        Open a websocket connection to plug.events and return the connectionToken.

    .PARAMETER Endpoint
        Endpoint to connect to. When not entered it will retrieve the first production endpoint by default.

    .EXAMPLE
        Open the connection

        PS> Open-PlugEventsWebsocket
        negotiateVersion connectionId           connectionToken        availableTransports
        ---------------- ------------           ---------------        -------------------
                       1 abcdefabcdefabcdefabcd abcdefabcdefabcdefabcd {@{transport=WebSockets; transferFormats=System.Object[]}, @{transport=ServerSentEvents; transferFormats=System…

    .EXAMPLE
        Open the connection for a specific endpoint

        PS> Open-PlugEventsWebsocket -Endpoint "pi31.plug.events"
        negotiateVersion connectionId           connectionToken        availableTransports
        ---------------- ------------           ---------------        -------------------
                       1 abcdefabcdefabcdefabcd abcdefabcdefabcdefabcd {@{transport=WebSockets; transferFormats=System.Object[]}, @{transport=ServerSentEvents; transferFormats=System…

    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Endpoint = (Get-PlugEventsEndpoint -Type p -First 1).Types.Endpoint
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Open-PlugEventsWebsocket"

    # Open the connection
    Invoke-RestMethod -Uri "https://$Endpoint/hub1/negotiate?negotiateVersion=1" -Method POST
}