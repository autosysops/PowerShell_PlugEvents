Describe "Get-PlugEventsEventView" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "returns event view result" {
        $fixtureEventView = Get-Content (Join-Path $PSScriptRoot "..\fixtures\event-view-balfolk-den-haag.json") -Raw | ConvertFrom-Json
        $script:capturedMessage = $null

        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:capturedMessage = $Message
        }
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            (@{ result = $fixtureEventView } | ConvertTo-Json -Depth 10 -Compress)
        }

        $result = Get-PlugEventsEventView -Id "test-event-under-umbrella-1"

        $result.mainSlug | Should -Be "test-event-under-umbrella-1"
        $script:capturedMessage | Should -BeLike '*"GetEventView"*'
        $script:capturedMessage | Should -BeLike '*"test-event-under-umbrella-1"*'
    }

    It "declares mandatory Id" {
        $parameter = (Get-Command Get-PlugEventsEventView).Parameters["Id"]
        $parameter.Attributes.Mandatory | Should -Contain $true
    }
}
