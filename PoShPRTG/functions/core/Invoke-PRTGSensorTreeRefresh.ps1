function Invoke-PRTGSensorTreeRefresh {
    <#
    .Synopsis
       Invoke-PRTGSensorTreeRefresh

    .DESCRIPTION
       Get the sensortree from prtg server and refesh the global variable PRTGSensorTree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGSensorTree

    .EXAMPLE
       Get-PRTGSensorTree -Server "https://prtg.corp.customer.com" -User "prtgadmin" -Pass "111111"

    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false, ConfirmImpact = 'medium')]
    Param(
        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ if ( ($_.StartsWith("http")) ) { $true } else { $false } })]
        [String]
        $Server = $script:PRTGServer,

        # User for PRTG Authentication
        [ValidateNotNullOrEmpty()]
        [String]
        $User = $script:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [ValidateNotNullOrEmpty()]
        [String]
        $Pass = $script:PRTGPass,

        # Output the sensor tree
        [Switch]
        $PassThru
    )

    Write-Log -LogText "Refresh PRTG SensorTree in Memory" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
    $Result = Get-PRTGSensorTree -Server $Server -User $User -Pass $Pass -Verbose:$false
    $script:PRTGSensorTree = $Result

    if ($PassThru) { $Result }
}
