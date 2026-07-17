Describe "Add-PlugEventsOrgMember" {
    BeforeEach {
        Mock -CommandName Send-THEvent -ModuleName plugEvents {}
    }

    It "throws when not authenticated" {
        InModuleScope plugEvents { $Script:isAuthenticated = $false }
        { Add-PlugEventsOrgMember -Id "balfolk-nl" -Role "teacher" -Org "my-org" } | Should -Throw "*must be authenticated*"
    }

    It "sends invite message and returns success result" {
        InModuleScope plugEvents { $Script:isAuthenticated = $true }

        $script:capturedMessage = $null
        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {
            param($Message)
            $script:capturedMessage = $Message
        }
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            '{"result":{"isSuccess":true,"errorCode":0,"message":null}}'
        }

        $result = Add-PlugEventsOrgMember -Id "test-umbrella" -Role "teacher" -Org "test-org-member"

        $result.isSuccess | Should -BeTrue
        $script:capturedMessage | Should -BeLike '*"InviteRoleFilledByOrg"*'
        $script:capturedMessage | Should -BeLike '*"test-umbrella","teacher","test-org-member"*'
    }

    It "throws with error details when API result failed" {
        InModuleScope plugEvents { $Script:isAuthenticated = $true }
        Mock -CommandName Send-PlugEventsMessage -ModuleName plugEvents {}
        Mock -CommandName Receive-PlugEventsMessage -ModuleName plugEvents {
            '{"result":{"isSuccess":false,"errorCode":403,"message":"Denied"}}'
        }

        { Add-PlugEventsOrgMember -Id "test-umbrella" -Role "teacher" -Org "test-org-member" } | Should -Throw "*Error 403: Denied*"
    }

    It "declares Org as mandatory" {
        $parameter = (Get-Command Add-PlugEventsOrgMember).Parameters["Org"]
        $parameter.Attributes.Mandatory | Should -Contain $true
    }
}
