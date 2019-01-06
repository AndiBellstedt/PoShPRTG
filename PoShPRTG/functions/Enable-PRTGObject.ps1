function Enable-PRTGObject {
    <#
    .Synopsis
       Enable-PRTGObject

    .DESCRIPTION
       Enables an (paused) PRTG object 

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Enable-PRTGObject -ObjectId 1
       Enable-PRTGObject -ObjectId 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

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
        
        # do action regardless of current status of sensor
        [Parameter(Mandatory=$false)]
            [Switch]$Force,

        # Not waiting for sensor status update in PRTG server (faster reply on large batch jobs)
        [Parameter(Mandatory=$false)]
            [Switch]$NoWaitOnStatus,

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
        
        # Sensortree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name    
        $body =  @{
            id = 0
            action = 1
            username = $User 
            passhash = $Pass
        }
    }

    Process {
        foreach($id in $ObjectId) {
            $body.id = $id

            $StatusBefore = Receive-PRTGObjectStatus -ObjectID $id -Server $Server -User $User -Pass $Pass -Verbose:$false
            if(-not $StatusBefore) {
                Write-Log "Failed to current status for object ID $id. Skipping object" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                break
            }

            if ($pscmdlet.ShouldProcess("objID $Id", "Enable PRTG object")) {
                try {
                    #Enable in PRTG
                    Write-Log -LogText "Enable object ID $id ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    if( ($StatusBefore.status_raw -in (7, 8, 9, 12)) -or $Force ) {
                        $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/pause.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                    } else {
                        Write-Log -LogText "Object ID $id is already enabled" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                        break
                    }                    
                } catch {
                    Write-Log -LogText "Failed to enable object ID $id. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                    break
                }

                #Receive new status
                $SafeguardBreakCount = 15
                $count = 0
                if($NoWaitOnStatus) { $break = $true } else { $break = $false }
                do {
                    $StatusAfter = Receive-PRTGObjectStatus -ObjectID $id -Server $Server -User $User -Pass $Pass -Verbose:$false
                    if($StatusBefore.status_raw -ne $StatusAfter.status_raw) { $break = $true }
                    if($count -ge $SafeguardBreakCount) { 
                        Write-Log -LogText "Error receiving enable-status from object $id! break status query." -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                        $break = $true 
                    }
                    Start-Sleep -Seconds 1
                    $count ++
                } until($break)
                
                #Set in SensorTree variable
                $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/status_raw").InnerText = $StatusAfter.status_raw
            }
        }
    }

    End {
    }
}
