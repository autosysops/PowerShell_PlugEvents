function Get-PlugEventsOrg {
    <#
    .SYNOPSIS
        Search and return organizations from Plug.Events.

    .DESCRIPTION
        Sends a search request over the Plug.Events websocket and returns
        the matching organization items. Use `-Filter` to search
        by name or description, and optional slugs to narrow by interest,
        sub-interest, or locale. The function returns the raw items array
        from the websocket response.

    .PARAMETER Filter
        Search term to match organization names or descriptions. Optional.

    .PARAMETER Interest
        Slug of the interest category to filter organizations. Optional.

    .PARAMETER SubInterest
        Slug of the sub-interest category to filter organizations. Optional.

    .PARAMETER Locale
        Locale slug to filter organizations. Optional.

    .PARAMETER Top
        Maximum number of organization items to return. Default is 999.

    .EXAMPLE
        Retrieve up to 50 organization results matching "balfolk":

        PS> Get-PlugEventsOrg -Filter "balfolk" -Top 50

    .NOTES
        This function requires an active Plug.Events websocket connection
        and uses the module's websocket messaging helpers (Send-PlugEventsMessage
        / Receive-PlugEventsMessage).
    #>

    [CmdLetBinding()]
    [OutputType([Array])]
    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Filter ,

        [Parameter(Mandatory = $false, Position = 2)]
        [String] $Interest ,

        [Parameter(Mandatory = $false, Position = 3)]
        [String] $SubInterest ,

        [Parameter(Mandatory = $false, Position = 4)]
        [String] $Locale ,

        [Parameter(Mandatory = $false, Position = 5)]
        [Int] $Top = 999
    )

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Get-PlugEventsOrg" -PropertiesHash @{Filter = ($Filter -ne $null); Interest = ($Interest -ne $null); SubInterest = ($SubInterest -ne $null); Locale = ($Locale -ne $null); Top = $Top; Expand = $Expand.IsPresent}

    # Set up the message
    $si = if ($SubInterest) { """$SubInterest""" } else { "null" }
    $li = if ($Locale) { """$Locale""" } else { "null" }
    $ii = if ($Interest) { """$Interest""" } else { "null" }
    $fi = if ($Filter) { """$Filter""" } else { "null" }
    $message = '{"target":"CapitalInSpaceSearch","arguments":[{"sortOrder":"AlphaByName","mode":"Single","criteria":{"subinterest":' + $si + ',"localeSlug":' + $li + ',"interestSlug":' + $ii + ',"ultracollapseCode":null,"ccKind":1,"minTime":null,"maxTime":null,"searchTerm":' + $fi + '},"nExpandedResults":' + $Top + ',"nCollapsedResults": 0}],"invocationId":"32","type":1}'

    # Send the message
    Send-PlugEventsMessage -Message $message

    # Receive the response
    $response = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive

    # Convert the response from JSON
    ($response | ConvertFrom-Json).result.items
}