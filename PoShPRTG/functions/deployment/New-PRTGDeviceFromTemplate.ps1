function New-PRTGDeviceFromTemplate {
    <#
    .Synopsis
       New-PRTGDeviceFromTemplate

    .DESCRIPTION
       Creates a new device out of a template structure, where operatingsystems and operatingsystem roles are separates in different templates.

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       New-PRTGDeviceFromTemplate
       Required values will be queried by gridview-selection

    .EXAMPLE
       New-PRTGDeviceFromTemplate -TemplateFolderStructure (Get-PRTGObject -Name "Template_group_name") -Destination (Get-PRTGProbes | Out-GridView -Title "Please select destination for new system" -OutputMode Single)

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    Param(
        [ValidateNotNullOrEmpty()]
        [String]
        $DeviceName = (Read-Host -Prompt "Name of new system"),

        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname = (Read-Host -Prompt "Hostname for new system (leave empty, if same as name of new system)"),

        [ValidateNotNullOrEmpty()]
        [int]
        $TemplateSystem = (Get-PRTGObject -Name "Basic operatingsystem" -Recursive -Type device -SensorTree $script:PRTGSensorTree | Sort-Object Fullname | Select-Object fullname, objID | Out-GridView -Title "Please specify operatingsystem for new system" -OutputMode Single | Select-Object -ExpandProperty ObjID),

        [int[]]
        $TemplateRole = (Get-PRTGObject -Name "Specific roles" -Recursive -Type device -SensorTree $script:PRTGSensorTree | Sort-Object Fullname | Select-Object FullName, objID | Out-GridView -Title "Please select roles for new system" -OutputMode Multiple | Select-Object -ExpandProperty ObjID),

        [string[]]
        $TemplateSensorFilter = "MUSS MANUELL*",

        [ValidateNotNullOrEmpty()]
        [int]
        $Destination = (Get-PRTGObject -Type group -SensorTree $script:PRTGSensorTree | Sort-Object Fullname | Select-Object FullName, objID | Out-GridView -Title "Please select destination for new system" -OutputMode Single  | Select-Object -ExpandProperty ObjID),

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if ( ($_.StartsWith("http")) ) { $true } else { $false } })]
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
        $SensorTree = $script:PRTGSensorTree
    )

    [array]$CopyObjectCollection = @()
    if (-not $Hostname) { $Hostname = $DeviceName }
    [String]$TemplateTAGName = "Template_*"

    #check if device currently existis in the destination
    Write-Log -LogText "Check if device already existis in the destination" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
    $DestinationContent = Get-PRTGObject -ID $Destination -Recursive -SensorTree $SensorTree -Verbose:$false -ErrorAction SilentlyContinue | Where-Object Type -like "device"
    $Device = Get-PRTGObject -Name $DeviceName -Type device -SensorTree $SensorTree -Verbose:$false -ErrorAction SilentlyContinue
    if ($Device -and ($Device.name -in $DestinationContent.name)) {
        Write-Log -LogText "$DeviceName ist unter ""$((Get-PRTGObject -ID $Destination -SensorTree $SensorTree -Verbose:$false).fullname)"" bereits vorhanden!" -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Warning
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", ""
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", ""
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $caption = "Warning!"
        $message = "$DeviceName`nist unter `n$((Get-PRTGObject -ID $Destination -SensorTree $SensorTree -Verbose:$false).fullname)`nbereits vorhanden!`n`nSoll das Device wirklich doppelt angelegt werden?"
        $result = $Host.UI.PromptForChoice($caption, $message, $choices, 1)
        if ($result -eq 1) {
            Write-Log -LogText "Abbruch..." -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Warning
            return
        }
    }
    Remove-Variable result, message, caption, choices, no, yes, device, DestinationContent -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false

    #Start cloning
    # Get "OS"-Device
    Write-Log -LogText "Start cloning devicetemplate to destination ID $Destination" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
    $TemplateSystemDevice = Get-PRTGObject -ID $TemplateSystem -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    if (-not $TemplateSystemDevice) { Write-Log -LogText "Template not found!" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error; return }

    #clone to destination group and set hostname
    if ($pscmdlet.ShouldProcess("Object with ID $($Destination)", "Deploy new device ""$($DeviceName)"" from template ""$($TemplateSystemDevice.name)""")) {
        $NewCustomerServer = Copy-PRTGObject -ObjectId $TemplateSystemDevice.ObjID -TargetID $Destination -Name $DeviceName -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
        if ($NewCustomerServer) {
            Set-PRTGObjectProperty -ObjectId $NewCustomerServer.ObjID -PropertyName host -PropertyValue $Hostname -Server $Server -User $User -Pass $Pass -Verbose:$false -ErrorAction Stop
        } else {
            Write-Log -LogText "Error after copy "
        }
        $CopyObjectCollection += $NewCustomerServer
    }

    #if there are roles specified, query sensors from role-templates and clone them to the new system
    if ($TemplateRole) {
        #Query roles and select the sensors
        Write-Log -LogText "Query role specific sensor(s) from $($TemplateRole.count) role template(s)" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
        [array]$TemplateSensorsToCopy = Get-PRTGObject -ID $TemplateRole -Recursive -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop | Where-Object Type -like "sensor"
        Write-Log -LogText "Found $($TemplateSensorsToCopy.count) role specific sensor(s)" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus

        #Filtering out sensors excluded from deployment process
        if ($TemplateSensorFilter) {
            Write-Log -LogText "Filtering out role specific sensor(s) from (Filter: $([string]::Join(", ",$TemplateSensorFilter)))" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
            foreach ($filter in $TemplateSensorFilter) {
                $TemplateSensorsToCopy = $TemplateSensorsToCopy | Where-Object name -NotLike $filter
            }
            Write-Log -LogText "$($TemplateSensorsToCopy.count) role specific sensor(s) left to clone after filtering" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
        }

        #Start deployment of role sensors
        if ($TemplateSensorsToCopy) {
            Write-Log -LogText "Start deployment of $($TemplateSensorsToCopy.count) role specific sensor(s)" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
            $script:count = 0
            $script:TotalCount = $TemplateSensorsToCopy.count
            $ProgressID = 16364  #random choosen number to produce a new progress bar

            foreach ($item in $TemplateSensorsToCopy) {
                $script:count++
                Write-Progress -Activity "Copy role sensors" -Status "Progress: $script:count of $($script:TotalCount)" -PercentComplete ($script:count / $script:TotalCount * 100) -id $ProgressID
                if ($pscmdlet.ShouldProcess($NewCustomerServer.name, "Deploy ""$($item.name)")) {
                    Write-Log -LogText "Deploy ""$($item.name)"" to ""$($NewCustomerServer.name)""" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
                    Remove-Variable ErrorEvent -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
                    try {
                        #copy object
                        $SensorCopy = Copy-PRTGObject -ObjectId $item.ObjID -TargetID $NewCustomerServer.ObjID -Name $item.name -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                        Write-Log -LogText "New sensor copied (objID:$($SensorCopy.objid) name:""$($SensorCopy.name))""" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput

                        #enable object
                        Write-Log -LogText "Activate / unpause new sensor" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                        Enable-PRTGObject -ObjectId $SensorCopy.objid -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Force -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop

                        #Add tags from template to new device
                        Write-Log -LogText "Setting tags from role template to ""$($NewCustomerServer.name)""" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                        [Array]$DeviceTAG = Get-PRTGObjectTAG -ObjectID $item.ParentNode.id[0] -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop | Where-Object { $_ -like $TemplateTAGName }
                        [Array]$DeviceTAG += Get-PRTGObjectTAG -ObjectID $item.ObjID            -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop | Where-Object { $_ -like $TemplateTAGName }
                        if ($DeviceTAG) {
                            #$SensorTree = Get-PRTGSensorTree -Server $Server -User $User -Pass $Pass
                            #Write TAG to Device
                            Add-PRTGObjectTAG -ObjectId $NewCustomerServer.ObjID -TAGName $DeviceTAG -Force -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                            #Write TAG to Sensor
                            Add-PRTGObjectTAG -ObjectId $SensorCopy.ObjID        -TAGName $DeviceTAG -Force -Server $Server -User $User -Pass $Pass -SensorTree $SensorTree -Verbose:$false -ErrorVariable ErrorEvent -ErrorAction Stop
                        }

                        #status output
                        [array]$CopyObjectCollection += $SensorCopy
                        Write-Log -LogText "$($CopyObjectCollection.Count) sensors created until now." -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
                        Remove-Variable x -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
                    } catch {
                        #Write-Log -LogText $ErrorEvent.Message -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                        Write-Log -LogText $_.exception.message -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                    }
                }
                Write-Progress -Activity "Copy role sensors" -id $ProgressID -Completed
            }
        } else {
            Write-Log -LogText "No role specific sensors to deploy" -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
        }
    } else {
        Write-Log -LogText "No role template selected" -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
    }

    if ($pscmdlet.ShouldProcess($NewCustomerServer.name, "Resume from pause status")) {
        Write-Log -LogText "Resume ""$($NewCustomerServer.name)"" from pause status" -LogType set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
        Enable-PRTGObject -ObjectId $NewCustomerServer.ObjID -Server $Server -User $User -Pass $Pass -Force -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
        Invoke-PRTGObjectRefresh -ObjectId $NewCustomerServer.ObjID -Server $Server -User $User -Pass $Pass -Verbose:$false -ErrorAction Stop
    }

    if ($SensorTree) {
        Write-Log -LogText "Refresh SensorTree" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
        Invoke-PRTGSensorTreeRefresh -Server $Server -User $User -Pass $Pass -Verbose:$false
    }

    return $CopyObjectCollection
}
