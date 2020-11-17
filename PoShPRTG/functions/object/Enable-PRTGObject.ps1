function Enable-PRTGObject {
    <#
    .Synopsis
       Enable-PRTGObject

    .DESCRIPTION
        Enables an (paused) PRTG object

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .NOTES
        Author: Andreas Bellstedt

        adopted from PSGallery Module "PSPRTG"
        Author: Sam-Martin
        Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
        https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
        Enable-PRTGObject -ObjectId 1

        Enables object with ID 1
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    Param(
        # ID of the object to resume
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # do action regardless of current status of sensor
        [Switch]
        $Force,

        # Not waiting for sensor status update in PRTG server (faster reply on large batch jobs)
        [Switch]
        $NoWaitOnStatus,

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if ($_.StartsWith("http")) { $true } else { $false } } )]
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

    begin {}

    process {
        foreach ($id in $ObjectId) {
            $body = @{
                id       = $id
                action   = 1
                username = $User
                passhash = $Pass
            }

            $StatusBefore = Receive-PRTGObjectStatus -ObjectID $id -Server $Server -User $User -Pass $Pass -Verbose:$false
            if (-not $StatusBefore) {
                Write-Log "Failed to current status for object ID $id. Skipping object" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                break
            }

            if ($pscmdlet.ShouldProcess("objID $Id", "Enable PRTG object")) {
                try {
                    #Enable in PRTG
                    Write-Log -LogText "Enable object ID $id ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    if ( ($StatusBefore.status_raw -in (7, 8, 9, 12)) -or $Force ) {
                        $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/pause.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                    } else {
                        Write-Log -LogText "Object ID $id is already enabled" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                        break
                    }
                } catch {
                    Write-Log -LogText "Failed to enable object ID $id. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                    break
                }

                #Receive new status
                $SafeguardBreakCount = 15
                $count = 0
                if ($NoWaitOnStatus) { $break = $true } else { $break = $false }
                do {
                    $StatusAfter = Receive-PRTGObjectStatus -ObjectID $id -Server $Server -User $User -Pass $Pass -Verbose:$false
                    if ($StatusBefore.status_raw -ne $StatusAfter.status_raw) { $break = $true }
                    if ($count -ge $SafeguardBreakCount) {
                        Write-Log -LogText "Error receiving enable-status from object $id! break status query." -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
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

    end {}
}
