function Get-PRTGSensorTree {
    <#
    .Synopsis
       Get-PRTGSensorTree
    .DESCRIPTION
       Ruft den aktuellen SensorTree vom PRTG Server ab

    .EXAMPLE
       Get-PRTGSensorTree

    .EXAMPLE
       Get-PRTGSensorTree -Server "https://prtg.corp.customer.com"
    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='Low')]
    Param(
        # Url for PRTG Server 
        [Parameter(Mandatory=$false,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if( ($_.StartsWith("http")) ){$true}else{$false}})]
            [String]$Server = $global:PRTGServer, 

        # User for PRTG Authentication
        [Parameter(Mandatory=$false,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
            [String]$User = $global:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory=$false,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
            [String]$Pass = $global:PRTGPass
    )
    $Local:logscope = $MyInvocation.MyCommand.Name
    $body =  @{
        username= $User 
        passhash= $Pass
    }

    Write-Log -LogText "Getting PRTG SensorTree from PRTG Server $($Server)" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
    [xml]$Result = Invoke-RestMethod -Uri "$Server/api/table.xml?content=sensortree" -Body $body -ErrorAction Stop -Verbose:$false

    $Result.pstypenames.Insert(0,"PRTG.SensorTree")
    $Result.pstypenames.Insert(1,"PRTG")
    
    return $Result
}
