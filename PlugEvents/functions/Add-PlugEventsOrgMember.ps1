function Add-PlugEventsOrgMember {
    <#
    .SYNOPSIS
        Add an organization as a member of another organization in Plug.Events.

    .DESCRIPTION
        Sends an InviteRoleFilledByOrg request over the Plug.Events websocket to
        add an organization to another organization with a specified role.
        Requires an authenticated connection (see Connect-PlugEvents -Credential).

    .PARAMETER Id
        Slug of the organization to add the member to.

    .PARAMETER Role
        Role the added organization will receive (e.g. "teacher", "performer").

    .PARAMETER Org
        Slug of the organization to add as a member. Only available in the default
        "Org" parameter set.

    .EXAMPLE
        Add "yourorg" to "balfolk-nl" with the role "teacher":

        PS> Add-PlugEventsOrgMember -Id "balfolk-nl" -Role "teacher" -Org "yourorg"
    #>

    [CmdLetBinding(DefaultParameterSetName = 'Org')]
    [OutputType([Object])]
    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [String] $Id,

        [Parameter(Mandatory = $true, Position = 2)]
        [String] $Role,

        [Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'Org')]
        [String] $Org
    )

    # Check if the user is authenticated
    if (-not $Script:isAuthenticated) {
        throw "Plug Events: you must be authenticated to use this function. Please run Connect-PlugEvents with the -Credential parameter."
    }

    # Send telemetry data
    Send-THEvent -ModuleName "plugEvents" -EventName "Add-PlugEventsOrgMember" -PropertiesHash @{Role = $Role; ParameterSet = $PSCmdlet.ParameterSetName}

    # Set up the message
    $message = '{"target":"InviteRoleFilledByOrg","arguments":["' + $Id + '","' + $Role + '","' + $Org + '"],"invocationId":"28","type":1}'

    # Send the message
    Send-PlugEventsMessage -Message $message

    # Receive the response
    $response = Receive-PlugEventsMessage -Timeout 30 -IgnoreKeepAlive

    # Convert the response from JSON
    $result = ($response | ConvertFrom-Json).result

    if (-not $result.isSuccess) {
        throw "Plug Events: Add-PlugEventsOrgMember failed. Error $($result.errorCode): $($result.message)"
    }

    $result
}
