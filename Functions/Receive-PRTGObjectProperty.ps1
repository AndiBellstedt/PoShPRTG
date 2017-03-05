function Receive-PRTGObjectProperty {
    <#
    .Synopsis
       Receive-PRTGObject

    .DESCRIPTION
       Query an object property directly from PRTGserver and returns.
       Difference to Get-PRTGObjectProperty is, that "Get-PRTGObjectProperty" is working on a modfified sensortree variable in the memory and not on livedata from PRTGServer

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Receive-PRTGObject -ObjectId 1 -PropertyName "staus"
       Receive-PRTGObject -ID 1 -Name "staus"

    .EXAMPLE
       Receive-PRTGObject -ObjectId 1 -PropertyName "staus" -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                  SupportsShouldProcess=$false, 
                  ConfirmImpact='low')]
    param(
        # ID of the object to pause/resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('ObjId','ID')]
            [int[]]$ObjectId,
        
        # Name of the object's property to get
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
            [string]$PropertyName,

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
        $body =  @{
            id = 0
            name = $PropertyName
            username = $User 
            passhash = $Pass
        }
    }

    Process {
        foreach($ID in $ObjectID) {
            $body.id = $ID
            # Try to get objectproperty from PRTG
            Write-Log -LogText "Get objectproperty for object ID $ID. ($Server)" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
            try{
                $Result = (Invoke-RestMethod -UseBasicParsing -Uri "$Server/api/getobjectstatus.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop).prtg.result
                return $result
            }catch{
                Write-Log -LogText "Failed to get objectproperty from prtg. ($Server) Message:$($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
            }
        }
    }

    End {
    }
}
