function Remove-PRTGObjectTAG {
    <#
    .Synopsis
       Remove-PRTGObjectTAG

    .DESCRIPTION
       Remove a text from the tags property of an PRTG object

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Remove-PRTGObjectTAG -ObjectId 1 -TAGName "NewName" -Server "https://prtg.corp.customer.com" -User "admin -Pass "1111111"

    #>
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium')]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {$_ -gt 0})]
        [Alias('ObjID', 'ID')]
        [int]$ObjectId,

        # Name of the object's property to set
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $false,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$TAGName,

        # Url for PRTG Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {if ( ($_.StartsWith("http")) ) {$true}else {$false}})]
        [String]$Server = $script:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$User = $script:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Pass = $script:PRTGPass,

        # sensortree from PRTG Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [xml]$SensorTree = $script:PRTGSensorTree,

        # skip errors if an tag is not present
        [Parameter(Mandatory = $false)]
        [Switch]$Force,

        # returns the changed object
        [Parameter(Mandatory = $false)]
        [Switch]$PassThru
    )
    Begin {
    }

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
            if ($PassThru) { Write-Output $Object }

            #clear up the variable mess
            Remove-Variable TAG, TAGListExisting, TAGListToSet, Object, MessageText -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
        }
    }

    End {
    }
}
