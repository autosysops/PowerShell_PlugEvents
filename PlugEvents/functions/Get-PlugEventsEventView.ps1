function Get-PlugEventsEventView {
    <#
    .SYNOPSIS
        Get the full event view for a specific event in Plug.Events.

    .DESCRIPTION
        Sends a GetEventView request over the Plug.Events websocket and returns
        the result object for the specified event slug.

    .PARAMETER Id
        Slug of the event to retrieve the view for.

    .EXAMPLE
        Get the event view for "my-event-2026":

        PS> Get-PlugEventsEventView -Id "my-event-2026"
    #>

    [CmdLetBinding()]
    [OutputType([Object])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Id
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Get-PlugEventsEventView"

    # Set up the message
    $message = '{"target":"GetEventView","arguments":["' + $Id + '"],"invocationId":"1","type":1}'

    # Send the message
    Send-PlugEventsMessage -Message $message

    # Receive the response
    $response = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive

    # Convert the response from JSON
    ($response | ConvertFrom-Json).result
}
