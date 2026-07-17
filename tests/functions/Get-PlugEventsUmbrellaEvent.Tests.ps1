Describe "Get-PlugEventsUmbrellaEvent" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "builds request and returns direction set items" {
        $fixtureEvents = Get-Content (Join-Path $PSScriptRoot "..\fixtures\umbrella-events-balfolk-nl.json") -Raw | ConvertFrom-Json

        $script:capturedMessage = $null
        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:capturedMessage = $Message
        }
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            (@{ result = @{ directionSets = @{ items = $fixtureEvents } } } | ConvertTo-Json -Depth 10 -Compress)
        }

        $result = Get-PlugEventsUmbrellaEvent -Id "balfolk-nl" -StartDate ([datetime]"2030-01-01") -EndDate ([datetime]"2030-12-31") -Top 3

        $result.Count | Should -Be 3
        $result[0].fromSlug | Should -Be "balfolk-nl"
        $script:capturedMessage | Should -BeLike '*"slug":"balfolk-nl"*'
        $script:capturedMessage | Should -BeLike '*"maxCount":3*'
        $script:capturedMessage | Should -BeLike '*"minEventTime":"203001010000"*'
        $script:capturedMessage | Should -BeLike '*"maxEventTime":"203012310000"*'
    }

    It "declares Id as mandatory" {
        $parameter = (Get-Command Get-PlugEventsUmbrellaEvent).Parameters["Id"]
        $parameter.Attributes.Mandatory | Should -Contain $true
    }
}
