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
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='medium')]
    Param(
        # Url for PRTG Server 
        [Parameter(Mandatory=$false,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if( ($_.StartsWith("http")) ){$true}else{$false}})]
            [String]$Server = $SCRIPT:PRTGServer, 

        # User for PRTG Authentication
        [Parameter(Mandatory=$false,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
            [String]$User = $SCRIPT:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory=$false,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
            [String]$Pass = $SCRIPT:PRTGPass,

        [Parameter(Mandatory=$false)]
            [Switch]$PassThru
    )
    $Local:logscope = $MyInvocation.MyCommand.Name

    Write-Log -LogText "Refresh PRTG SensorTree in Memory" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
    $Result = Get-PRTGSensorTree -Server $Server -User $User -Pass $Pass -Verbose:$false
    $SCRIPT:PRTGSensorTree = $Result

    if($PassThru) { return $Result }
}
