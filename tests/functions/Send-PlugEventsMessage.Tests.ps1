. "$PSScriptRoot\TestHelpers.ps1"

Describe "Send-PlugEventsMessage" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "throws when the websocket is not open" {
        $connection = [MockPlugWebSocket]::new()
        $connection.State = [System.Net.WebSockets.WebSocketState]::Closed

        { Send-PlugEventsMessage -Message '{"target":"x"}' -Connection $connection } | Should -Throw "*no open connection*"
    }

    It "adds end-of-message marker when missing" {
        $connection = [MockPlugWebSocket]::new()

        Send-PlugEventsMessage -Message '{"target":"x"}' -Connection $connection

        $connection.SentMessages.Count | Should -Be 1
        [int]$connection.SentMessages[0][-1] | Should -Be 30
    }

    It "does not duplicate end-of-message marker when already present" {
        $connection = [MockPlugWebSocket]::new()
        $message = '{"target":"x"}' + [char]0x1e

        Send-PlugEventsMessage -Message $message -Connection $connection

        ($connection.SentMessages[0].ToCharArray() | Where-Object { [int]$_ -eq 30 }).Count | Should -Be 1
    }

    It "supports async mode" {
        $connection = [MockPlugWebSocket]::new()

        { Send-PlugEventsMessage -Message '{"target":"x"}' -Connection $connection -Async } | Should -Not -Throw
        $connection.SentMessages.Count | Should -Be 1
    }

    It "declares Message as mandatory" {
        $parameter = (Get-Command Send-PlugEventsMessage).Parameters["Message"]
        $parameter.Attributes.Mandatory | Should -Contain $true
    }
}
