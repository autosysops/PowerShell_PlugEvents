function Get-PlugEventsConnection {
    <#
    .SYNOPSIS
        Get the object that contains the websocketconnection to plug.events

    .DESCRIPTION
        Get the object that contains the websocketconnection to plug.events

    .EXAMPLE
        Get the connection

        PS> Get-PlugEventsConnection
    #>

    [CmdLetBinding()]
    Param ()

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Get-PlugEventsConnection"

    # Return the websocket object
    $Script:websocket
}