function Remove-PRTGObjectTAG {
    <#
    .Synopsis
       Remove-PRTGObjectTAG

    .DESCRIPTION
       Remove a text from the tags property of an PRTG object

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       PS C:\>Remove-PRTGObjectTAG -ObjectId 1 -TAGName "MyTAG"

       Remove "MyTAG" from an object with ID 1
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [Alias('ObjID', 'ID')]
        [int]
        $ObjectId,

        # Name of the object's property to set
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $TAGName,

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

        # sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree,

        # Skip errors if an tag is not present
        [Switch]
        $Force,

        # Output the deleted object
        [Switch]
        $PassThru
    )

    Begin {}

    Process {
        foreach ($ID in $ObjectId) {
            $break = $false

            #Get the object
            Write-Log -LogText "Gather object tags from object ID $ID." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            try {
                $Object = Get-PRTGObject -ID $ID -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
            } catch {
                Write-Log -LogText $_.exception.message -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                return
            }

            #Build and check TAG lists
            $TAGListExisting = $Object.tags.Split(' ')
            $TAGListToSet = $Object.tags
            $TAGListCount = 0

            foreach ($TAG in $TAGName) {
                if ($TAG -in $TAGListExisting) {
                    $TAGListToSet = $TAGListToSet -replace [regex]::Escape($TAG), ''
                    $TAGListCount++
                } else {
                    if ($Force) {
                        Write-Log -LogText "Skipping tag ""$($TAG)"", because it is not present on object id $ID" -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Warning
                    } else {
                        Write-Log -LogText "Tag ""$($TAG)"" is not present on object id $ID" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                        $break = $true
                        break
                    }
                }
            }

            $TAGListToSet = $TAGListToSet.Trim()
            if ($break) { break }

            #set TAG list to PRTG object
            $MessageText = "Remove $($TAGListCount) $(if($TAGListCount -eq 1) {"tag"} else {"tags"})"
            if ($pscmdlet.ShouldProcess("objID $ID", $MessageText)) {
                Write-Log -LogText $MessageText -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                try {
                    #Set in PRTG
                    Set-PRTGObjectProperty -ObjectId $ID -PropertyName tags -PropertyValue $TAGListToSet -Server $Server -User $User -Pass $Pass -ErrorAction Stop -Verbose:$false

                    #Set on object to return
                    $Object.tags = $TAGListToSet

                    #Set in SensorTree variable
                    $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/tags").InnerText = $TAGListToSet
                } catch {
                    Write-Log -LogText $_.exception.message -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                    if (-not $Force) { break }
                }
            }

            #output the object
            if ($PassThru) { $Object }

            #clear up the variable mess
            Remove-Variable TAG, TAGListExisting, TAGListToSet, Object, MessageText -Force -ErrorAction Ignore -Confirm:$false -Verbose:$false -Debug:$false -WhatIf:$false
        }
    }

    End {}
}
