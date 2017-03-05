function Move-PRTGObjectPosition {
    <#
    .Synopsis
       Move-PRTGObjectPosition

    .DESCRIPTION
       Moves an object in PRTG hierarchy

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Move-PRTGObject -ObjectId 1 -Direction up
       
       Move-PRTGObject -ObjectId 1 -Direction down -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$true, 
                   ConfirmImpact='medium')]
    Param(
        # ID of the object to resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('ObjID', 'ID')]
            [int[]]$ObjectId,

        # Message to associate with the pause event
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateSet("up", "down", "top", "bottom")]
            [string]$Direction,

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
            [String]$Pass = $global:PRTGPass,
        
        # sensortree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name    
        $body =  @{
            id = 0
            newpos = $Direction
            username= $User 
            passhash= $Pass
        }
    }

    Process {
        foreach($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Move $Direction")) {
                try {
                    Write-Log -LogText "Move object ID $id $Direction ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/setposition.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to move object ID $id. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                }
            }
        }
    }

    End {
    }
}
