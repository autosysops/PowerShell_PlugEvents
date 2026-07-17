Describe "Get-PlugEventsOrgView" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "returns org view result" {
        $fixtureOrgView = Get-Content (Join-Path $PSScriptRoot "..\fixtures\org-view-balfolk-zuid-holland.json") -Raw | ConvertFrom-Json
        $script:capturedMessage = $null

        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:capturedMessage = $Message
        }
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            (@{ result = $fixtureOrgView } | ConvertTo-Json -Depth 10 -Compress)
        }

        $result = Get-PlugEventsOrgView -Id "test-org-zuid"

        $result.mainSlug | Should -Be "test-org-zuid"
        $script:capturedMessage | Should -BeLike '*"GetOrgView"*'
        $script:capturedMessage | Should -BeLike '*"test-org-zuid"*'
    }

    It "declares mandatory Id" {
        $parameter = (Get-Command Get-PlugEventsOrgView).Parameters["Id"]
        $parameter.Attributes.Mandatory | Should -Contain $true
    }
}
