function Get-PlugEventsUmbrellaEvent {
    <#
    .SYNOPSIS
        Get all events under a specific umbrella in Plug.Events

    .DESCRIPTION
        Get all events under a specific umbrella in Plug.Events

    .PARAMETER Id
        Id of the umbrella org

    .PARAMETER StartDate
        DateTime object containing the date to start filtering from. Default is 30 days in the past.

    .PARAMETER EndDate
        DateTime object containing the date to stop filtering from. Default is today.

    .PARAMETER Top
        Maximum amount of items to return. Default is 999.

    .EXAMPLE
        Get the events

        PS> Get-PlugEventsUmbrellaEvent -Id "balfolk-nl" -StartDate (Get-Date "2025-01-01") -EndDate (Get-Date "2025-12-31") -Top 200
    #>

    [CmdLetBinding()]
    [OutputType([Array])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Id,

        [Parameter(Mandatory = $false, Position = 2)]
        [DateTime] $StartDate = (Get-Date).AddDays(-30),

        [Parameter(Mandatory = $false, Position = 3)]
        [DateTime] $EndDate = (Get-Date),

        [Parameter(Mandatory = $false, Position = 4)]
        [Int] $Top = 999
    )
    # Set up the message
    $message = '{"target":"GetNetworkViewPage2","arguments":[{"recKind":1,"slug":"'+$Id+'","slugs":null,"direction":103,"startAt":0,"maxCount":'+$Top+',"nameContains":"","roleSlugFilters":null,"isClaimed":null,"seq1Filter":null,"seq1InverseFilter":null,"minEventTime":"'+($StartDate | Get-Date -Format "yyyyMMdd0000")+'","maxEventTime":"'+($EndDate | Get-Date -Format "yyyyMMdd0000")+'","interestSlug":null,"subinterest":null,"localeSlug":null,"toRoleNameContains":""}],"invocationId":"9","type":1}'

    # Send the message
    Send-PlugEventsMessage -Message $message

    # Receive the response
    $response = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive

    # Convert the response from JSON
    ($response | ConvertFrom-Json).result.directionSets.items
}