. "$PSScriptRoot\TestHelpers.ps1"

Describe "Get-PlugEventsEndpoint" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "parses endpoint nodemap entries" {
        $nodemap = Get-Content (Join-Path $PSScriptRoot "..\fixtures\endpoint-nodemap.txt")
        Mock -CommandName Invoke-RestMethod -ModuleName plugEvents { $nodemap }

        $result = Get-PlugEventsEndpoint

        $result.Count | Should -Be 2
        $result[0].Types.Count | Should -Be 2
        $result[0].Types[0].Endpoint | Should -Be "p-test01.plugevents.test"
    }

    It "filters by type and first" {
        $nodemap = Get-Content (Join-Path $PSScriptRoot "..\fixtures\endpoint-nodemap.txt")
        Mock -CommandName Invoke-RestMethod -ModuleName plugEvents { $nodemap }

        $result = Get-PlugEventsEndpoint -Type p -First 1

        $result.Count | Should -Be 1
        $result[0].Types.Count | Should -Be 1
        $result[0].Types[0].Type | Should -Be "p"
    }

    It "validates integer parameters" {
        { Get-PlugEventsEndpoint -First "abc" } | Should -Throw
    }
}
