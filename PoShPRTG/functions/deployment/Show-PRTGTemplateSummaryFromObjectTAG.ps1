﻿function Show-PRTGTemplateSummaryFromObjectTAG {
    <#
    .Synopsis
        Show-PRTGTemplateRoles

    .DESCRIPTION
        Display a list of template roles found under a groups and devices under a prtg structure

    .NOTES
        Author: Andreas Bellstedt

    .LINK
        https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
        Show-PRTGTemplateSummaryFromObjectTAG

        Display list of tags witch began with "Template_" and can be found under PRTG Core Server object.
        This is the default set of parameters.

    .EXAMPLE
        Show-PRTGTemplateSummaryFromObjectTAG -TemplateBaseID 100

        Display a list of tags witch began with "Template_" and are based under the group or device with the object ID 100.

    .EXAMPLE
        Show-PRTGTemplateSummaryFromObjectTAG -TemplateBaseID 100 -TemplateTAGNameIdentifier "MyPersonalTemplate-"

        Display a list of tags witch began with "MyPersonalTemplate-" and are based under the group or device with the object ID 100.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        # ID of the object to copy
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {$_ -gt 0})]
        [Alias('objID', 'ID', 'ObjectId')]
        [int]
        $TemplateBaseID = 1,

        # Filter value to identify template tags
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {$_ -notcontains ("*", "?")})]
        [string]
        $TemplateTAGNameIdentifier = "Template_",

        # Include matching as non matching objects
        [switch]
        $IncludeNonMatching,

        # SensorTree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    begin {}

    process {
        #Build Template Role object for comparing against devices
        $TemplateRoleDevices = Get-PRTGObject -ObjectID $TemplateBaseID -Recursive -Type group, device -SensorTree $SensorTree | Where-Object tags -Match ([regex]::Escape($TemplateTAGNameIdentifier))
        $TemplateRoleDevicesTypeGroup = $TemplateRoleDevices | Group-Object type -NoElement | Select-Object Count, Name, @{N = "Text"; E = { "$($_.count) $($_.Name.tolower())$(if($_.count -ne 1){"s"})"}}

        #Start to create new object
        if ($TemplateRoleDevices.tags) {
            [array]$TemplateRoles = $TemplateRoleDevices.tags.split(' ') | Where-Object { $_ -Match ([regex]::Escape($TemplateTAGNameIdentifier)) } | Sort-Object -Unique | ForEach-Object { New-Object -TypeName psobject -Property @{"RoleName" = $_ } }
            Write-Log -LogText "Found $($TemplateRoles.count) role$(if($TemplateRole.count -ne 1){"s"}) from $([string]::Join("and ",$TemplateRoleDevicesTypeGroup.Text)) in templatebase object ID $TemplateBaseID" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
        } else {
            Write-Log -LogText "No template roles found in object ID $TemplateBaseID" -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            return
        }

        foreach ($TemplateRole in $TemplateRoles) {
            Write-Log -LogText "Building object for ""$($TemplateRole.RoleName)"" from $([string]::Join("and ",$TemplateRoleDevicesTypeGroup.Text)) under templatebase object ID $TemplateBaseID" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput

            [array]$device = $TemplateRoleDevices | Where-Object {$_.tags.split(' ') -eq $TemplateRole.RoleName}
            Add-Member -InputObject $TemplateRole -MemberType NoteProperty -Force -Name DeviceCount -Value ([array]($device | Where-Object objId -ne $TemplateBaseID)).count
            Add-Member -InputObject $TemplateRole -MemberType NoteProperty -Force -Name Device      -Value ([array]($device | Where-Object objId -ne $TemplateBaseID))
            if ($device.sensor) {
                [array]$sensor = $device.sensor | Where-Object {$_.tags.split(' ') -eq $TemplateRole.RoleName}
                Add-Member -InputObject $TemplateRole -MemberType NoteProperty -Force -Name SensorCount -Value $sensor.count
                Add-Member -InputObject $TemplateRole -MemberType NoteProperty -Force -Name Sensor      -Value ([array](Set-TypesNamesToPRTGObject -PRTGObject $sensor))
            } else {
                Add-Member -InputObject $TemplateRole -MemberType NoteProperty -Force -Name SensorCount -Value 0
                Add-Member -InputObject $TemplateRole -MemberType NoteProperty -Force -Name Sensor      -Value $null
            }
            Remove-Variable device, sensor -Force -ErrorAction Ignore -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false
        }

        if ($IncludeNonMatching) {
            Write-Log -LogText "Searching for objects not matching TAG-identifier ""$($TemplateTAGNameIdentifier)"" in $([string]::Join("and ",$TemplateRoleDevicesTypeGroup.Text)) under templatebase object ID $TemplateBaseID" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            [array]$device = $TemplateRoleDevices | Where-Object {$_.tags -notmatch ([regex]::Escape($TemplateTAGNameIdentifier))}
            [array]$sensor = $TemplateRoleDevices.sensor | Where-Object {$_.tags -notmatch ([regex]::Escape($TemplateTAGNameIdentifier))}
            if ( ($device | Where-Object objId -ne $TemplateBaseID) -or ($sensor) ) {
                Write-Log -LogText "found non matching objects. Inserting an empty RoleName object." -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                $TemplateRoles += New-Object -TypeName psobject -Property @{
                    "RoleName"    = ""
                    "DeviceCount" = if ($device | Where-Object objId -ne $TemplateBaseID) { ([array]($device | Where-Object objId -ne $TemplateBaseID)).count } else { 0 }
                    "Device"      = if ($device | Where-Object objId -ne $TemplateBaseID) { ([array]($device | Where-Object objId -ne $TemplateBaseID))       } else { $null }
                    "SensorCount" = if ($sensor) { $sensor.Count } else { 0 }
                    "Sensor"      = if ($sensor) { [array]([array](Set-TypesNamesToPRTGObject -PRTGObject $sensor)) } else { $null }
                }
            }
            Remove-Variable device, sensor -Force -ErrorAction Ignore -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false
        }

        $TemplateRoles
    }

    end {}
}