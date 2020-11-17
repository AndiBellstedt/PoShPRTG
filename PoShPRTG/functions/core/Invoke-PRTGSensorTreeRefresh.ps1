function Invoke-PRTGSensorTreeRefresh {
    <#
    .Synopsis
       Invoke-PRTGSensorTreeRefresh

    .DESCRIPTION
       Refreshes sensortree information from prtg server

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Invoke-PRTGSensorTreeRefresh

       Refreshes the sensortree for caching current prtg current object configuration.

    .EXAMPLE
       Invoke-PRTGSensorTreeRefresh -Server "https://prtg.corp.customer.com" -User "prtgadmin" -Pass "111111"

       Refreshes the sensortree with custom credentials for caching current prtg current object configuration.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'medium'
    )]
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
