function New-PRTGDefaultFolderStructureToProbe {
    <#
    .Synopsis
       New-PRTGDefaultFolderStructureToProbe
    .DESCRIPTION
       Vorlagen-Ordnerstruktur auf Neukunde deployen
    .EXAMPLE
       New-PRTGDefaultFolderStructureToProbe
       -> Benötigte Werte werden abgefragt
    .EXAMPLE
       New-PRTGDefaultFolderStructureToProbe -TemplateFolderStructure (Get-PRTGObject -Name "Name_Ordner_Vorlage") -ProbeNewCustomer (Get-PRTGProbes | Out-GridView -Title "Bitte Ziel-Probe auswählen" -OutputMode Single)
    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$true, 
                   ConfirmImpact='Medium')]
    Param(
        #ID of the group that contains the structure to be copied to the destination probe
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [int]$TemplateFolderStructureID = (Get-PRTGObject -Name "Groups for new customer" -Type group -SensorTree $global:PRTGSensorTree -Verbose:$false | Select-Object -ExpandProperty ObjID),
        
        #ID of the destination probe
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [int]$ProbeID = (Get-PRTGProbe -SensorTree $global:PRTGSensorTree -Verbose:$false | Sort-Object fullname | Select-Object Name, objID | Out-GridView -Title "Please select destination probe" -OutputMode Single | Select-Object -ExpandProperty ObjID),

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

        # SensorTree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree
    )
    $Local:logscope = $MyInvocation.MyCommand.Name
    
    #Get tempalte to copy 
    $TemplateFolderStructure = Get-PRTGObject -ID $TemplateFolderStructureID -Type group -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop 
    if(-not $TemplateFolderStructure.group) { 
        Write-Log -LogText "Template folder not found or no groups under structure." -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
        return
    }
    
    #Get target object
    $ProbeNewCustomer = Get-PRTGObject -ID $ProbeID -Type probenode -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    if(-not $ProbeNewCustomer) { 
        Write-Log -LogText "No Probe specified." -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
        return
    }
    
    $script:count = 0
    $script:TotalCount = $TemplateFolderStructure.group.count
    $script:Copied = @()
    foreach($item in $TemplateFolderStructure.group) { 
        $script:count++
        Write-Progress -Activity "Copy data structure" -Status "Progress: $script:count of $($script:TotalCount)" -PercentComplete ($script:count/$script:TotalCount*100)
        if ($pscmdlet.ShouldProcess($ProbeNewCustomer.name, "Deploy ""$($item.name)")) {
            Write-Log -LogText "Deploy objID $($item.ID[0]) ""$($item.name)"" to objID $($ProbeNewCustomer.objID) ""$($ProbeNewCustomer.name)""" -LogType Set -LogScope $Local:logscope -NoFileStatus
            Remove-Variable ErrorEvent -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false -Confirm:$false
            try {
                $script:CopyObject = Copy-PRTGObject -ObjectId $item.ID[0] -TargetID $ProbeNewCustomer.ObjID -Name $item.name -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                Enable-PRTGObject -ObjectId $script:CopyObject.objid -Force -NoWaitOnStatus -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                $script:Copied += $script:CopyObject
                Remove-Variable CopyObject -Scope script -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false -Confirm:$false
            } catch {
                Write-Log -LogText "Error occured while deploying new folder structure! $($_.exception.message)" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
                return
            }
        }
        Remove-Variable item -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false -Confirm:$false
    }
    Write-Log -LogText "$($script:Copied.count) objects copied" -LogType Info -LogScope $Local:logscope -NoFileStatus

    Write-Log -LogText "Refresh PRTG SensorTree" -LogType Query -LogScope $Local:logscope -NoFileStatus
    $SensorTree = Invoke-PRTGSensorTreeRefresh -Server $Server -User $User -Pass $Pass -PassThru -Verbose:$false
}
