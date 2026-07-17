Describe "Get-PlugEventsOrg" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "returns organization search items and builds null criteria when omitted" {
        $fixtureSearch = Get-Content (Join-Path $PSScriptRoot "..\fixtures\org-search-balfolk.json") -Raw | ConvertFrom-Json

        $script:capturedMessage = $null
        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:capturedMessage = $Message
        }
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            (@{ result = @{ items = $fixtureSearch } } | ConvertTo-Json -Depth 10 -Compress)
        }

        $result = Get-PlugEventsOrg -Top 3

        $result.Count | Should -Be 3
        $script:capturedMessage | Should -BeLike '*"subinterest":null*'
        $script:capturedMessage | Should -BeLike '*"localeSlug":null*'
        $script:capturedMessage | Should -BeLike '*"interestSlug":null*'
        $script:capturedMessage | Should -BeLike '*"searchTerm":null*'
    }

    It "includes supplied filters" {
        $fixtureSearch = Get-Content (Join-Path $PSScriptRoot "..\fixtures\org-search-balfolk.json") -Raw | ConvertFrom-Json

        $script:capturedMessage = $null
        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:capturedMessage = $Message
        }
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            (@{ result = @{ items = $fixtureSearch } } | ConvertTo-Json -Depth 10 -Compress)
        }

        $null = Get-PlugEventsOrg -Filter "test filter" -Interest "test-interest" -SubInterest "test-subinterest" -Locale "test-locale" -Top 2

        $script:capturedMessage | Should -BeLike '*"subinterest":"test-subinterest"*'
        $script:capturedMessage | Should -BeLike '*"localeSlug":"test-locale"*'
        $script:capturedMessage | Should -BeLike '*"interestSlug":"test-interest"*'
        $script:capturedMessage | Should -BeLike '*"searchTerm":"test filter"*'
        $script:capturedMessage | Should -BeLike '*"nExpandedResults":2*'
    }
}
