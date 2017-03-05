function Set-PRTGObjectPriority {
    <#
    .Synopsis
       Set-PRTGObjectPriority
    .DESCRIPTION
       Set priority value on a PRTG object 
       Author: Andreas Bellstedt

    .EXAMPLE
       Set-PRTGObjectPriority -ObjectId 1 -Priority 3

       Set-PRTGObjectPriority -ObjectId 1 -Priority 3 -Server "https://prtg.corp.customer.com" -User "admin -Pass "1111111"
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

        # Priority value to set
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[1-5]")]
            [int]$Priority,

        # returns the changed object 
        [Parameter(Mandatory=$false)]
            [Switch]$PassThru,

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
            prio = $Priority
            username= $User 
            passhash= $Pass
        }
    }

    Process {
        foreach($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Set priority $Priority to object")) {
                #Set in PRTG
                try {
                    Write-Log -LogText "Set priority $Priority to object ID $id ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/setpriority.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to set priortiy object ID $id. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                }
                
                #Set on SensorTree Variable
                $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/priority").InnerText = $Priority
            
                #Write-Output
                if($PassThru) {
                    write-output (Get-PRTGObject -ObjectID $id -SensorTree $SensorTree -Verbose:$false)
                }
            }
        }
    }

    End {

    }
}