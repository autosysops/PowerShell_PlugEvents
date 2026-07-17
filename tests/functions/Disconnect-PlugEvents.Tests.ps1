. "$PSScriptRoot\TestHelpers.ps1"

Describe "Disconnect-PlugEvents" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "resets authentication and closes/disposes websocket and token" {
        InModuleScope plugEvents {
            $Script:websocket = [MockPlugWebSocket]::new()
            $Script:cancellationToken = [System.Threading.CancellationTokenSource]::new()
            $Script:isAuthenticated = $true
        }

        Disconnect-PlugEvents

        InModuleScope plugEvents { $Script:isAuthenticated } | Should -BeFalse
        InModuleScope plugEvents { $Script:websocket.State } | Should -Be ([System.Net.WebSockets.WebSocketState]::Closed)
    }
}
