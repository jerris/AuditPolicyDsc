<#
.Synopsis
   Template for creating DSC Resource Integration Tests

.DESCRIPTION
   To Use:
     1. Copy to \Tests\Integration\ folder and rename MSFT_x<ResourceName>.Integration.tests.ps1
     2. Customize TODO sections.
     3. Create test DSC Configurtion file MSFT_x<ResourceName>.config.ps1 from integration_config_template.ps1 file.

.NOTES
   Code in HEADER, FOOTER and DEFAULT TEST regions are standard and may be moved into
   DSCResource.Tools in Future and therefore should not be altered if possible.
#>

$Global:DSCModuleName      = 'xAuditPolicy'
$Global:DSCResourceName    = 'MSFT_xAuditOption'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Integration 
#endregion

# Other Init Code Goes Here...
$optionName  = 'AuditBaseDirectories'
$optionValue = 'Enabled'

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($Global:DSCResourceName).config.ps1"
    . $ConfigFile

    Describe "$($Global:DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                Invoke-Expression -Command "$($Global:DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path $TestEnvironment.WorkingFolder `
                    -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { 
                Get-DscConfiguration -Verbose -ErrorAction Stop
            } | Should Not throw
        }
        #endregion

        Context 'Should have set the resource and all the parameters should match' {
            
            Get-DscConfiguration -OutVariable DscConfiguration

            It "AuditOption configured is $optionName " {
                $DscConfiguration.Name | Should Be $optionName
            }

            It "$optionName is set to $optionValue"{
                $DscConfiguration.Value | Should Be $optionValue
            }

        }

        It 'Test-DscConfiguration should equal True' {
            { Test-DscConfiguration -Path $TestEnvironment.WorkingFolder } | Should Be $true
        }
    }
    #endregion

}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

    # Other Optional Cleanup Code Goes Here...
}
