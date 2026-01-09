function Get-PlugEventsCancellationToken {
    <#
    .SYNOPSIS
        Get the CancellationToken for the connection to Plug.Events

    .DESCRIPTION
        Get the CancellationToken for the connection to Plug.Events

    .EXAMPLE
        Get the token

        PS> Get-PlugEventsCancellationToken
    #>

    [CmdLetBinding()]
    Param ()

    # Return the cancellationtoken object
    $Script:cancellationToken
}