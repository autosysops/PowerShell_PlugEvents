function Get-PlugEventsOrgView {
    <#
    .SYNOPSIS
        Get the full organization view for a specific organization in Plug.Events.

    .DESCRIPTION
        Sends a GetOrgView request over the Plug.Events websocket and returns
        the result object for the specified organization slug.

    .PARAMETER Id
        Slug of the organization to retrieve the view for.

    .EXAMPLE
        Get the organization view for "balfolk-nl":

        PS> Get-PlugEventsOrgView -Id "balfolk-nl"
    #>

    [CmdLetBinding()]
    [OutputType([Object])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Id
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Get-PlugEventsOrgView"

    # Set up the message
    $message = '{"target":"GetOrgView","arguments":["' + $Id + '"],"invocationId":"1","type":1}'

    # Send the message
    Send-PlugEventsMessage -Message $message

    # Receive the response
    $response = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive

    # Convert the response from JSON
    ($response | ConvertFrom-Json).result
}
