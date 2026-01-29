function Send-PlugEventsMessage {
    <#
    .SYNOPSIS
        Send a message to the plug.events back-end.

    .DESCRIPTION
        Send a message to the plug.events back-end.

    .PARAMETER Message
        The message to send in string format. If the end-of-message marker is not added this will be added automatically.

    .PARAMETER Connection
        Connection object for the websocket connection. Default this will be the connection set up via Connect-PlugEvents

    .PARAMETER Timeout
        Maximum time in seconds to wait for a response before cancelling the request (this will close the connection). Default is 5 seconds.

    .PARAMETER Async
        Dont wait on confirmation that the message has been send.

    .EXAMPLE
        Send the message

        PS> $Message = '{"target":"GetLocalesBySlug","arguments":[["netherlands"]],"invocationId":"1","type":1}'
        PS> Send-PlugEventsMessage -Message $Message -Timeout 10 -Async
    #>

    [CmdLetBinding()]
    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Message,

        [Parameter(Mandatory = $false, Position = 2)]
        [Object] $Connection = $Script:websocket,

        [Parameter(Mandatory = $false, Position = 3)]
        [Int] $Timeout = 5,

        [Parameter(Mandatory = $false, Position = 4)]
        [Switch] $Async
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Receive-PlugEventsMessage" -PropertiesHash @{Timeout = $Timeout; Async = $Async}

    # Check if a connection is create
    if ($Connection.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
        throw "Plug-Events: no open connection was detected. Please run Connect-PlugEvents first."
    }

    # Check if end of message marker is added (0x1e = 30)
    if ([int]$Message[-1] -ne 30) {
        $Message += [char]0x1e
    }

    # Create byte array
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
    $seg = [ArraySegment[byte]]::new($bytes)

    # Send the message
    $cancellationToken = [System.Threading.CancellationTokenSource]::new($Timeout * 1000)
    $await = $Connection.SendAsync(
        $seg,
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        $cancellationToken.Token
    )

    if ( -not $Async) {
        # Extra variable to prevent unending loop
        $time = Get-Date

        # Wait untill the message is semd
        while ($await.Status -ne "RanToCompletion") {
            # Check if the timeout has been reached
            if ($await.Status -eq "Canceled") {
                throw "Plug-Events: the timeout of $Timeout seconds has been exceeded while waiting for a response from the server."
            }

            # Check if not in unending loop
            if ((Get-Date) -gt $time.AddSeconds($Timeout)) {
                $null = $cancellationToken.Cancel()
                throw "Plug-Events: waiting for more then $Timeout seconds for a reply of server. request has been cancelled."
            }
        }
    }
}