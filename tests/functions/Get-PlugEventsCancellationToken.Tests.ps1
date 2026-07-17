Describe "Get-PlugEventsCancellationToken" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "returns current script-level token object" {
        $token = [System.Threading.CancellationTokenSource]::new()

        InModuleScope plugEvents {
            param($tokenIn)
            $Script:cancellationToken = $tokenIn
        } -Parameters @{ tokenIn = $token }

        (Get-PlugEventsCancellationToken).GetType().Name | Should -Be "CancellationTokenSource"
    }
}
