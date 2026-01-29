function Receive-PlugEventsMessage {
    <#
    .SYNOPSIS
        Receive a message from the plug.events back-end.

    .DESCRIPTION
        Receive a message from the plug.events back-end. The end-of-message marker will automatically be removed from the output.

    .PARAMETER Connection
        Connection object for the websocket connection. Default this will be the connection set up via Connect-PlugEvents

    .PARAMETER Timeout
        Maximum time in seconds to wait for a response before cancelling the request (this will close the connection). Default is 21 seconds.

    .PARAMETER IgnoreKeepAlive
        Ignore the keepalive messages and only return other types of messages.

    .EXAMPLE
        Receive the data

        PS> Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive
    #>

    [CmdLetBinding()]
    [OutputType([String])]
    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [Object] $Connection = $Script:websocket,

        [Parameter(Mandatory = $false, Position = 2)]
        [Int] $Timeout = 21,

        [Parameter(Mandatory = $false, Position = 3)]
        [Switch] $IgnoreKeepAlive
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Receive-PlugEventsMessage" -PropertiesHash @{Timeout = $Timeout; IgnoreKeepAlive = $IgnoreKeepAlive}

    # Check if a connection is create
    if($Connection.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
        throw "Plug-Events: no open connection was detected. Please run Connect-PlugEvents first."
    }

    # Create a buffer to store the message
    $buffer        = New-Object byte[] 8192
    $stringbuilder = [System.Text.StringBuilder]::new()

    # Extra variable to prevent unending loop
    $time = Get-Date

    while ($Connection.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        # Create an async call
        $cancellationToken = [System.Threading.CancellationTokenSource]::new($Timeout*1000)
        $await = $Connection.ReceiveAsync([ArraySegment[byte]]::new($buffer), $cancellationToken.Token)

        # Wait untill the response is returned
        while($await.Status -ne "RanToCompletion") {
            # Check if the timeout has been reached
            if ($await.Status -eq "Canceled") {
                throw "Plug-Events: the timeout of $Timeout seconds has been exceeded while waiting for a response from the server."
            }

            # Check if not in unending loop
            if((Get-Date) -gt $time.AddSeconds($Timeout)) {
                $null = $cancellationToken.Cancel()
                throw "Plug-Events: waiting for more then $Timeout seconds for a reply of server. request has been cancelled."
            }
        }

        # Get the result from the await
        $result = $await.GetAwaiter().GetResult()

        if ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
            Disconnect-PlugEvents
            break
        }

        # Accumulate chunk(s) until EndOfMessage
        $null = $stringbuilder.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count))

        # If the message is done convert the stringbuilder to a string and stop the loop
        if ($result.EndOfMessage) {
            $text = $stringbuilder.ToString()

            # Check if the message is a keepalive
            if ($IgnoreKeepAlive -and $text -eq '{"type":6}') {
                # Continue and clear the stringbuilder
                $null = $stringbuilder.Clear()
            }
            else {
                # Break the loop
                break
            }
        }
    }

    # Check if the end of message character is still added
    if([int]$text[-1] -eq 30) {
        $text = $text.TrimEnd([char]0x1e)
    }

    # Return the message
    $text
}