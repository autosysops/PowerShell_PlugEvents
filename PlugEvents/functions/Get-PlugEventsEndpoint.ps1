function Get-PlugEventsEndpoint {
    <#
    .SYNOPSIS
        Return the endpoints for plug.events backend servers.

    .DESCRIPTION
        Return the endpoints for plug.events backend servers.

    .PARAMETER Type
        Type of the server. Can be p or i.

    .PARAMETER First
        Amount of entries to return.

    .EXAMPLE
        Get all endpoints

        PS> Get-PlugEventsEndpoint
        Id                 Types
        --                 -----
        639009792141241401 {@{Type=p; Endpoint=pi31.plug.events}, @{Type=i; Endpoint=ii31.plug.events}}
        639003195191559039 {@{Type=p; Endpoint=pi30.plug.events}, @{Type=i; Endpoint=ii30.plug.events}}

    .EXAMPLE
        Get first endpoint

        PS> Get-PlugEventsEndpoint -First 1
        Id                 Types
        --                 -----
        639009792141241401 {@{Type=p; Endpoint=pi31.plug.events}, @{Type=i; Endpoint=ii31.plug.events}}

    .EXAMPLE
        Get first endpoint of type p

        PS> Get-PlugEventsEndpoint -Type p -First 1
        Id                 Types
        --                 -----
        639009792141241401 {@{Type=p; Endpoint=pi31.plug.events}}
    #>

    [CmdLetBinding()]
    [OutputType([Array])]

    Param (
        [Parameter(Mandatory = $false, Position = 1)]
        [String] $Type = "none",

        [Parameter(Mandatory = $false, Position = 2)]
        [Int] $First = 0
    )

    # Get all the endpoints from the txt file
    $nodemap = Invoke-RestMethod -uri "https://www.plug.events/nodemap.txt" -Method GET

    # Parse the endpoints
    $endpoints = @()
    $nodemap | ConvertFrom-Csv -Header "id", "endpoints" | ForEach-Object {
        # Create an object
        $node = [PSCustomObject]@{
            Id = $_.Id
            Types = @()
        }

        # Split the different types
        foreach ($endpoint in $_.endpoints.split("|")) {
            # Check for the type
            if($Type -ne "none") {
                if($Type -ne $endpoint[0]) {
                    Continue
                }
            }

            $node.Types += [PSCustomObject]@{
                Type = $endpoint[0]
                Endpoint = $endpoint
            }
        }

        # Add the node to the endpoint array
        $endpoints += $node
    }

    # Filter amount
    if($First -gt 0) {
        $endpoints = $endpoints | Select-Object -First $First
    }

    $endpoints
}