function New-PRTGDefaultFolderStructureToProbe {
    <#
    .Synopsis
       New-PRTGDefaultFolderStructureToProbe

    .DESCRIPTION
       Copy a new folder/group structure to a destination
       Primary intension is to copy a tempalte folderstructure to a new probe

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       New-PRTGDefaultFolderStructureToProbe
       Required values will be queried by gridview-selection

    .EXAMPLE
       New-PRTGDefaultFolderStructureToProbe -TemplateFolderStructureID (Get-PRTGObject -Name "Template_group_name") -ProbeID (Get-PRTGProbes | Out-GridView -Title "Please select destination probe" -OutputMode Single)

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        #ID of the group that contains the structure to be copied to the destination probe
        [ValidateNotNullOrEmpty()]
        [int]
        $TemplateFolderStructureID = (Get-PRTGObject -Name "Groups for new customer" -Type group -SensorTree $script:PRTGSensorTree -Verbose:$false | Select-Object -ExpandProperty ObjID),

        #ID of the destination probe
        [ValidateNotNullOrEmpty()]
        [int]
        $ProbeID = (Get-PRTGProbe -SensorTree $script:PRTGSensorTree -Verbose:$false | Sort-Object fullname | Select-Object Name, objID | Out-GridView -Title "Please select destination probe" -OutputMode Single | Select-Object -ExpandProperty ObjID),

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if ( ($_.StartsWith("http")) ) { $true }else { $false } })]
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

        # SensorTree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    $logscope = $MyInvocation.MyCommand.Name

    #Get tempalte to copy
    $TemplateFolderStructure = Get-PRTGObject -ID $TemplateFolderStructureID -Type group -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    if (-not $TemplateFolderStructure.group) {
        Write-Log -LogText "Template folder not found or no groups under structure." -LogType Error -LogScope $logscope -NoFileStatus -Error
        return
    }

    #Get target object
    $ProbeNewCustomer = Get-PRTGObject -ID $ProbeID -Type probenode -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    if (-not $ProbeNewCustomer) {
        Write-Log -LogText "No Probe specified." -LogType Error -LogScope $logscope -NoFileStatus -Error
        return
    }

    $count = 0
    $TotalCount = $TemplateFolderStructure.group.count
    $Copied = @()
    foreach ($item in $TemplateFolderStructure.group) {
        $count++
        Write-Progress -Activity "Copy data structure" -Status "Progress: $count of $($TotalCount)" -PercentComplete ($count / $TotalCount * 100)
        if ($pscmdlet.ShouldProcess($ProbeNewCustomer.name, "Deploy ""$($item.name)")) {
            Write-Log -LogText "Deploy objID $($item.ID[0]) ""$($item.name)"" to objID $($ProbeNewCustomer.objID) ""$($ProbeNewCustomer.name)""" -LogType Set -LogScope $logscope -NoFileStatus
            Remove-Variable ErrorEvent -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false -Confirm:$false
            try {
                $CopyObject = Copy-PRTGObject -ObjectId $item.ID[0] -TargetID $ProbeNewCustomer.ObjID -Name $item.name -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                Enable-PRTGObject -ObjectId $CopyObject.objid -Force -NoWaitOnStatus -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                $Copied += $CopyObject
                Remove-Variable CopyObject -Scope script -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false -Confirm:$false
            } catch {
                Write-Log -LogText "Error occured while deploying new folder structure! $($_.exception.message)" -LogType Error -LogScope $logscope -Error -NoFileStatus
                return
            }
        }
        Remove-Variable item -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false -Confirm:$false
    }
    Write-Log -LogText "$($Copied.count) objects copied" -LogType Info -LogScope $logscope -NoFileStatus

    Write-Log -LogText "Refresh PRTG SensorTree" -LogType Query -LogScope $logscope -NoFileStatus
    $SensorTree = Invoke-PRTGSensorTreeRefresh -Server $Server -User $User -Pass $Pass -PassThru -Verbose:$false
}
