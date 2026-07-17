. "$PSScriptRoot\TestHelpers.ps1"

Describe "Connect-PlugEvents" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}

        InModuleScope plugEvents {
            $Script:PlugEventsWebsocketFactory = { [MockPlugWebSocket]::new() }
            $Script:PlugEventsCancellationTokenFactory = { [System.Threading.CancellationTokenSource]::new() }
        }

        Mock -CommandName Get-PlugEventsEndpoint -ModuleName plugEvents {
            [pscustomobject]@{ Types = @([pscustomobject]@{ Type = "p"; Endpoint = "p-test01.plugevents.test" }) }
        }
        Mock -CommandName Open-PlugEventsWebsocket -ModuleName plugEvents {
            [pscustomobject]@{ connectionToken = "ctok" }
        }

        $script:sentMessages = @()
        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:sentMessages += $Message
        }
    }

    It "connects anonymously and performs handshake" {
        $script:receiveQueue = @('{}')
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            $next = $script:receiveQueue[0]
            if ($script:receiveQueue.Count -gt 1) {
                $script:receiveQueue = $script:receiveQueue[1..($script:receiveQueue.Count - 1)]
            }
            else {
                $script:receiveQueue = @()
            }
            $next
        }

        { Connect-PlugEvents } | Should -Not -Throw

        $script:sentMessages[0] | Should -Be '{"protocol":"json","version":1}'
        InModuleScope plugEvents { $Script:isAuthenticated } | Should -BeFalse
        InModuleScope plugEvents { $Script:websocket.GetType().Name } | Should -Be "MockPlugWebSocket"
    }

    It "connects and authenticates with credential and skip warning" {
        $script:receiveQueue = @(
            '{}',
            '{"result":{"isSuccess":true,"errorCode":0,"message":null}}'
        )
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            $next = $script:receiveQueue[0]
            if ($script:receiveQueue.Count -gt 1) {
                $script:receiveQueue = $script:receiveQueue[1..($script:receiveQueue.Count - 1)]
            }
            else {
                $script:receiveQueue = @()
            }
            $next
        }

        $password = ConvertTo-SecureString "secret" -AsPlainText -Force
        $cred = [System.Management.Automation.PSCredential]::new("user@example.org", $password)

        Connect-PlugEvents -Credential $cred -SkipWarning

        $script:sentMessages.Count | Should -Be 2
        $script:sentMessages[1] | Should -BeLike '*"Authenticate2"*'
        $script:sentMessages[1] | Should -BeLike '*"user@example.org","secret",null*'
        InModuleScope plugEvents { $Script:isAuthenticated } | Should -BeTrue
    }

    It "connects and authenticates when warning is confirmed" {
        $script:receiveQueue = @(
            '{}',
            '{"result":{"isSuccess":true,"errorCode":0,"message":null}}'
        )
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            $next = $script:receiveQueue[0]
            if ($script:receiveQueue.Count -gt 1) {
                $script:receiveQueue = $script:receiveQueue[1..($script:receiveQueue.Count - 1)]
            }
            else {
                $script:receiveQueue = @()
            }
            $next
        }
        Mock -CommandName Write-Warning -ModuleName plugEvents {}
        Mock -CommandName Read-Host -ModuleName plugEvents { 'yes' }

        $password = ConvertTo-SecureString "secret" -AsPlainText -Force
        $cred = [System.Management.Automation.PSCredential]::new("user@example.org", $password)

        Connect-PlugEvents -Credential $cred

        Should -Invoke Write-Warning -ModuleName plugEvents -Times 1
        Should -Invoke Read-Host -ModuleName plugEvents -Times 1
        InModuleScope plugEvents { $Script:isAuthenticated } | Should -BeTrue
    }

    It "aborts authentication when warning is rejected" {
        $script:receiveQueue = @('{}')
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            $script:receiveQueue[0]
        }
        Mock -CommandName Write-Warning -ModuleName plugEvents {}
        Mock -CommandName Read-Host -ModuleName plugEvents { 'no' }
        Mock -CommandName Disconnect-PlugEvents -ModuleName plugEvents {}

        $password = ConvertTo-SecureString "secret" -AsPlainText -Force
        $cred = [System.Management.Automation.PSCredential]::new("user@example.org", $password)

        { Connect-PlugEvents -Credential $cred } | Should -Throw "*authentication aborted by the user*"
        Should -Invoke Disconnect-PlugEvents -ModuleName plugEvents -Times 1
    }

    It "throws when handshake response is not empty object" {
        $script:receiveQueue = @('{"type":3}')
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            $script:receiveQueue[0]
        }

        { Connect-PlugEvents } | Should -Throw "*could not be established*"
    }

    It "throws and disconnects on authentication failure" {
        $script:receiveQueue = @(
            '{}',
            '{"result":{"isSuccess":false,"errorCode":401,"message":"Invalid credentials"}}'
        )
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            $next = $script:receiveQueue[0]
            if ($script:receiveQueue.Count -gt 1) {
                $script:receiveQueue = $script:receiveQueue[1..($script:receiveQueue.Count - 1)]
            }
            else {
                $script:receiveQueue = @()
            }
            $next
        }
        Mock -CommandName Disconnect-PlugEvents -ModuleName plugEvents {}

        $password = ConvertTo-SecureString "wrong" -AsPlainText -Force
        $cred = [System.Management.Automation.PSCredential]::new("user@example.org", $password)

        { Connect-PlugEvents -Credential $cred -SkipWarning } | Should -Throw "*authentication failed*"
        Should -Invoke Disconnect-PlugEvents -ModuleName plugEvents -Times 1
    }
}
