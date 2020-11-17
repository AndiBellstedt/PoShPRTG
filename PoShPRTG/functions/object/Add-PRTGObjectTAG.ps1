function Add-PRTGObjectTAG {
    <#
    .Synopsis
        Add-PRTGObjectTAG

    .DESCRIPTION
        Add a text to the tags property of an PRTG object

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
        Add-PRTGObjectTAG -ObjectId 1 -TAGName "NewName"

        Add TAG "NewName" to object 1
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
        [ValidateScript( { $_ -gt 0 })]
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
        [ValidateScript( { if ( ($_.StartsWith("http")) ) { $true } else { $false } } )]
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

        # skip errors if an tag is not present
        [Switch]
        $Force,

        # returns the changed object
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
                break
            }

            #Build and check TAG lists
            if ($Object.tags) {
                [array]$TAGListExisting = $Object.tags.Split(' ')
            }
            $TAGListToAdd = @()
            foreach ($TAG in $TAGName) {
                if ($TAG.Contains(' ')) {
                    Write-Log -LogText "The tag ""$($TAG)"" contains invalid space characters! Space characters will be removed." -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Warning
                    $TAG = $TAG.Replace(' ', '')
                }
                if ($TAG -in $TAGListExisting) {
                    if ($Force) {
                        Write-Log -LogText "Skipping tag ""$($TAG)"", because it is already set on object id $ID" -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Warning
                    } else {
                        Write-Log -LogText "Tag ""$($TAG)"" is already set on object id $ID" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                        $break = $true
                        break
                    }
                } else {
                    $TAGListToAdd += $TAG
                }
            }
            if ($break) { break }
            if ($TAGListExisting) {
                $TAGListToSet = "$($TAGListExisting) $([string]::Join(' ',$TAGListToAdd))"
            } else {
                $TAGListToSet = [string]::Join(' ', $TAGListToAdd)
            }
            $TAGListToSet = $TAGListToSet.Trim()

            #set TAG list to PRTG object
            if ($TAGListToAdd) {
                $MessageText = "Add $($TAGListToAdd.count) $(if($TAGListToAdd.count -eq 1) {"tag"} else {"tags"}) ($([string]::Join(' ',$TAGListToAdd)))"
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
            } else {
                Write-Log -LogText "No tags to set. Skipping object ID $($Object.objId)" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            }

            #output the object
            if ($PassThru) { $Object }

            #clear up the variable mess
            Remove-Variable TAG, TAGListExisting, TAGListToAdd, TAGListToSet, Object, MessageText -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
        }
    }

    End {}
}
