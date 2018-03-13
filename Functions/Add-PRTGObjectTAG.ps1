function Add-PRTGObjectTAG {
    <#
    .Synopsis
       Add-PRTGObjectTAG

    .DESCRIPTION
       Add a text to the tags property of an PRTG object

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Add-PRTGObjectTAG -ObjectId 1 -TAGName "NewName"

    .EXAMPLE
       Add-PRTGObjectTAG -ObjectId 1 -TAGName "NewName" -PassThru
    
    .EXAMPLE
       Add-PRTGObjectTAG -ObjectId 1 -TAGName "NewName" -Server "https://prtg.corp.customer.com" -User "admin -Pass "1111111" -SensorTree $PRTGSensorTree -PassThru

    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$true, 
                   ConfirmImpact='medium')]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('ObjID', 'ID')]
            [int]$ObjectId,
        
        # Name of the object's property to set
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
            [string[]]$TAGName,

        # Url for PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if( ($_.StartsWith("http")) ){$true}else{$false}})]
            [String]$Server = $SCRIPT:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$User = $SCRIPT:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$Pass = $SCRIPT:PRTGPass,

        # sensortree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $SCRIPT:PRTGSensorTree,

        # skip errors if an tag is not present
        [Parameter(Mandatory=$false)]
            [Switch]$Force,

        # returns the changed object 
        [Parameter(Mandatory=$false)]
            [Switch]$PassThru
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name    
    }

    Process {
        foreach($ID in $ObjectId) {
            $break = $false
            #Get the object
            Write-Log -LogText "Gather object tags from object ID $ID." -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput 
            try {
                $Object = Get-PRTGObject -ID $ID -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
            } catch {
                Write-Log -LogText $_.exception.message -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                break
            }
            
            #Build and check TAG lists
            if($Object.tags) {
                [array]$TAGListExisting = $Object.tags.Split(' ')
            }
            $TAGListToAdd = @()
            foreach($TAG in $TAGName) { 
                if($TAG.Contains(' ')) {
                    Write-Log -LogText "The tag ""$($TAG)"" contains invalid space characters! Space characters will be removed." -LogType Warning -LogScope $Local:logscope -NoFileStatus -Warning
                    $TAG = $TAG.Replace(' ','')
                }
                if($TAG -in $TAGListExisting) {
                    if($Force) {
                        Write-Log -LogText "Skipping tag ""$($TAG)"", because it is already set on object id $ID" -LogType Warning -LogScope $Local:logscope -NoFileStatus -Warning
                    } else {
                        Write-Log -LogText "Tag ""$($TAG)"" is already set on object id $ID" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                        $break = $true
                        break
                    }
                } else {
                    $TAGListToAdd += $TAG
                }
            }
            if($break) { break }
            if($TAGListExisting) {
                $TAGListToSet = "$($TAGListExisting) $([string]::Join(' ',$TAGListToAdd))"
            } else {
                $TAGListToSet = [string]::Join(' ',$TAGListToAdd)
            }
            $TAGListToSet = $TAGListToSet.Trim()

            #set TAG list to PRTG object
            if($TAGListToAdd) {
                $MessageText = "Add $($TAGListToAdd.count) $(if($TAGListToAdd.count -eq 1) {"tag"} else {"tags"}) ($([string]::Join(' ',$TAGListToAdd)))"
                if($pscmdlet.ShouldProcess("objID $ID", $MessageText)) {
                    Write-Log -LogText $MessageText -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    try {
                        #Set in PRTG
                        Set-PRTGObjectProperty -ObjectId $ID -PropertyName tags -PropertyValue $TAGListToSet -Server $Server -User $User -Pass $Pass -ErrorAction Stop -Verbose:$false

                        #Set on object to return
                        $Object.tags = $TAGListToSet
                        
                        #Set in SensorTree variable
                        $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/tags").InnerText = $TAGListToSet
                    } catch {
                        Write-Log -LogText $_.exception.message -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                        if(-not $Force) { break }
                    }
                }
            } else {
                Write-Log -LogText "No tags to set. Skipping object ID $($Object.objId)" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
            }
            
            #output the object
            if($PassThru) { Write-Output $Object }

            #clear up the variable mess
            Remove-Variable TAG, TAGListExisting, TAGListToAdd, TAGListToSet, Object,MessageText -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
        }
    }

    End {
    }
}
