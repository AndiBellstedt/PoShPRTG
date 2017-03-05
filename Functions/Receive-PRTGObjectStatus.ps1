﻿Function Receive-PRTGObjectStatus {
    <#
    .Synopsis
       Receive-PRTGObjectStatus
    .DESCRIPTION
       Query the status of an object directly from PRTGserver and returns.
       Difference to Get-PRTGObject is, that "Get-PRTGObject" is working on a modfified sensortree variable in the memory and not on livedata from PRTGServer
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell
    .EXAMPLE
       Receive-PRTGObjectStatus -ObjectId 1
       Receive-PRTGObjectStatus -ID 1
    .EXAMPLE
       Receive-PRTGObjectStatus -ObjectId 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                  SupportsShouldProcess=$false, 
                  ConfirmImpact='low')]
    [OutputType([PSCustomObject])]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('ID')]
        [ValidateScript({$_ -gt 0})]
            [int[]]$ObjectID,

        # Url for PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if( ($_.StartsWith("http")) ){$true}else{$false}})]
            [String]$Server = $global:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$User = $global:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$Pass = $global:PRTGPass
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name
        $StatusMapping = @{
            1="Unknown" 
            2="Scanning"
            3="Up"
            4="Warning"
            5="Down"
            6="No Probe"
            7="Paused by User"
            8="Paused by Dependency"
            9="Paused by Schedule"
            10="Unusual"
            11="Not Licensed" 
            12="Paused Until"
        }
    }

    Process {
        foreach($ID in $ObjectId) {
            try{
                $statusID = (Receive-PRTGObjectProperty -ObjectId $ID -PropertyName 'status' -Server $Server -User $User -Pass $Pass -ErrorAction Stop -Verbose:$false)
            } catch {
                Write-Log -LogText "Unable to get object status from prtg. ($Server) Message:$($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                return
            }
            $hash= @{
                'objid'=$ID
                "status"=$StatusMapping[[int]$statusID]
                "status_raw"=$statusID
            }
            $result = New-Object -TypeName PSCustomObject -Property $hash
            return $result
        }
    }
}