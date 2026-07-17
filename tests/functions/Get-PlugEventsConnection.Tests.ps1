. "$PSScriptRoot\TestHelpers.ps1"

Describe "Get-PlugEventsConnection" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "returns current script-level websocket object" {
        $connection = [MockPlugWebSocket]::new()

        InModuleScope plugEvents {
            param($connectionIn)
            $Script:websocket = $connectionIn
        } -Parameters @{ connectionIn = $connection }

        (Get-PlugEventsConnection).GetType().Name | Should -Be "MockPlugWebSocket"
    }
}
