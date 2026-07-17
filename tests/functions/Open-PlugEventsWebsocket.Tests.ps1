. "$PSScriptRoot\TestHelpers.ps1"

Describe "Open-PlugEventsWebsocket" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "calls negotiate endpoint with default endpoint from Get-PlugEventsEndpoint" {
        Mock -CommandName Get-PlugEventsEndpoint -ModuleName plugEvents {
            [pscustomobject]@{ Types = @([pscustomobject]@{ Type = "p"; Endpoint = "p-test01.plugevents.test" }) }
        }
        Mock -CommandName Invoke-RestMethod -ModuleName plugEvents {
            [pscustomobject]@{ connectionToken = "token-123" }
        } -ParameterFilter { $Uri -eq "https://p-test01.plugevents.test/hub1/negotiate?negotiateVersion=1" -and $Method -eq "POST" }

        $result = Open-PlugEventsWebsocket

        $result.connectionToken | Should -Be "token-123"
        Should -Invoke Invoke-RestMethod -ModuleName plugEvents -Times 1 -Exactly
    }

    It "uses explicit endpoint" {
        Mock -CommandName Invoke-RestMethod -ModuleName plugEvents {
            [pscustomobject]@{ connectionToken = "token-abc" }
        } -ParameterFilter { $Uri -eq "https://p-test02.plugevents.test/hub1/negotiate?negotiateVersion=1" -and $Method -eq "POST" }

        $result = Open-PlugEventsWebsocket -Endpoint "p-test02.plugevents.test"

        $result.connectionToken | Should -Be "token-abc"
    }
}
