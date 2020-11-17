function Get-PRTGSensorTree {
    <#
    .Synopsis
       Get-PRTGSensorTree

    .DESCRIPTION
       Return the current sensortree from PRTG Server

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGSensorTree

       Query the sensortree for caching prtg current object configuration.

    .EXAMPLE
       Get-PRTGSensorTree -Server "https://prtg.corp.customer.com" -User "prtgadmin" -Pass "1111111"

       Query the sensortree with custom credentials for caching prtg current object configuration.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $false, ConfirmImpact = 'Low')]
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
        $Pass = $script:PRTGPass
    )
    $body = @{
        username = $User
        passhash = $Pass
    }

    Write-Log -LogText "Getting PRTG SensorTree from PRTG Server $($Server)" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
    [xml]$Result = Invoke-RestMethod -Uri "$Server/api/table.xml?content=sensortree" -Body $body -ErrorAction Stop -Verbose:$false

    $Result.pstypenames.Insert(0, "PRTG.SensorTree")
    $Result.pstypenames.Insert(1, "PRTG")

    return $Result
}
