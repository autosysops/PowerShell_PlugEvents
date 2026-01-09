function Disconnect-PlugEvents {
    <#
    .SYNOPSIS
        Disconnect from Plug.Events

    .DESCRIPTION
        Disconnect from Plug.Events

    .EXAMPLE
        Disconnect

        PS> Disconnect-PlugEvents
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Its the name of the product')]

    [CmdLetBinding()]
    Param ()

    # Close the connection
    $null = $Script:websocket.CloseAsync(
        [System.Net.WebSockets.WebSocketCloseStatus]::Empty,
        "",
        $Script:cancellationToken.Token
    )

    # Dispose of the objects
    $Script:websocket.Dispose()
    $Script:cancellationToken.Dispose()
}