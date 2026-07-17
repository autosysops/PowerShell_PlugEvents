. "$PSScriptRoot\TestHelpers.ps1"

Describe "Receive-PlugEventsMessage" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "throws when the websocket is not open" {
        $connection = [MockPlugWebSocket]::new()
        $connection.State = [System.Net.WebSockets.WebSocketState]::Closed

        { Receive-PlugEventsMessage -Connection $connection } | Should -Throw "*no open connection*"
    }

    It "returns normal response and trims end-of-message marker" {
        $connection = [MockPlugWebSocket]::new()
        $connection.ReceiveMessages.Enqueue('{"result":{"ok":true}}' + [char]0x1e)

        $message = Receive-PlugEventsMessage -Connection $connection -Timeout 2

        $message | Should -Be '{"result":{"ok":true}}'
    }

    It "ignores keepalive messages when requested" {
        $connection = [MockPlugWebSocket]::new()
        $connection.ReceiveMessages.Enqueue('{"type":6}')
        $connection.ReceiveMessages.Enqueue('{"result":{"ok":true}}' + [char]0x1e)

        $message = Receive-PlugEventsMessage -Connection $connection -Timeout 2 -IgnoreKeepAlive

        $message | Should -Be '{"result":{"ok":true}}'
    }

}
