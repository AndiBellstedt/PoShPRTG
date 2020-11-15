function Disable-PRTGObject {
    <#
    .Synopsis
       Disable-PRTGObject

    .DESCRIPTION
       Pause an PRTG object

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Disable-PRTGObject -ObjectId 1
       Disable-PRTGObject -ObjectId 1 -Message "Done by User01"
       Disable-PRTGObject -ObjectId 1 -Message "Done by User01" -Minutes 1
       Disable-PRTGObject -ObjectId 1 -Message "Done by User01" -Minutes 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    Param(
        # ID of the object to pause
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 })]
        [Alias('ObjID')]
        [int[]]
        $ObjectId,

        # Message to associate with the pause event
        [string]$Message,

        # Length of time in minutes to pause the object, $null for indefinite
        [int]
        $Minutes = $null,

        # do action regardless of current status of sensor
        [Switch]
        $Force,

        # Not waiting for sensor status update in PRTG server (faster reply on large batch jobs)
        [Switch]
        $NoWaitOnStatus,

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if (($_.StartsWith("http"))) { $true } else { $false } })]
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

        # Sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    Begin {
        $body = @{
            id       = 0
            action   = 0
            username = $User
            passhash = $Pass
        }

        if ($Minutes) { $body.Add("duration", $Minutes) }
        if ($Message) { $body.Add("pausemsg", $Message) }
    }

    Process {
        foreach ($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Disable PRTG object")) {
                try {
                    if ($Minutes) {
                        Write-Log -LogText "Disable object ID $id for $Minutes minutes. $(if($Message){"Message:$Message "})($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    } else {
                        Write-Log -LogText "Permanent disable object ID $id. $(if($Message){"Message:$Message "})($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    }
                    $StatusBefore = Receive-PRTGObjectStatus -ObjectID $id -Server $Server -User $User -Pass $Pass -Verbose:$false
                    if ( ($StatusBefore.status_raw -notin (7, 8, 9, 12)) -or $Force ) {
                        $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/pause$(if($Minutes){"objectfor"}).htm" -Method Get -Body $body -Verbose:$false -Debug:$false -ErrorAction Stop
                    } else {
                        Write-Log -LogText "Object ID $id is already disabled" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                        break
                    }

                    if ($NoWaitOnStatus) {
                        if ($Minutes) {
                            $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/status_raw").InnerText = 12
                        } else {
                            $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/status_raw").InnerText = 7
                        }
                    } else {
                        $break = $false
                        do {
                            $StatusAfter = Receive-PRTGObjectStatus -ObjectID $id -Server $Server -User $User -Pass $Pass -Verbose:$false
                            if ($StatusBefore.status_raw -ne $StatusAfter.status_raw) {
                                $break = $true
                            }
                            Start-Sleep -Seconds 1
                        } until ($break)

                        $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/status_raw").InnerText = $StatusAfter.status_raw
                    }
                } catch {
                    Write-Log -LogText "Failed to disable object ID $id. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                    break
                }
            }
        }
    }

    End {}
}
