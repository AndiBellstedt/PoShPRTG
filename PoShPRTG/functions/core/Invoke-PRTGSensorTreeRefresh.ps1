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
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'medium')]
    Param(
        # Url for PRTG Server
        [Parameter(Mandatory = $false,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {if ( ($_.StartsWith("http")) ) {$true}else {$false}})]
        [String]$Server = $script:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]$User = $script:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory = $false,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [String]$Pass = $script:PRTGPass,

        [Parameter(Mandatory = $false)]
        [Switch]$PassThru
    )

    Write-Log -LogText "Refresh PRTG SensorTree in Memory" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
    $Result = Get-PRTGSensorTree -Server $Server -User $User -Pass $Pass -Verbose:$false
    $script:PRTGSensorTree = $Result

    if ($PassThru) { return $Result }
}
