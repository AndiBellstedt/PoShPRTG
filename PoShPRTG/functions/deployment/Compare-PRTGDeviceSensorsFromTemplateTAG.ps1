function Compare-PRTGDeviceSensorsFromTemplateTAG {
    <#
    .Synopsis
       Compare-PRTGDeviceSensorsFromTemplateTAG

    .DESCRIPTION
       Compares all sensors on a device by all the tags on the device against a (template) object.
       In default all tags starting with "Template_" are used for comparing.

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Compare-PRTGDeviceSensorsFromTemplateTAG -DeviceID 200 -TemplateBaseID 100

       Invokes comparisan of device with ID 200 against template device with ID 100

    .EXAMPLE
       Compare-PRTGDeviceSensorsFromTemplateTAG -DeviceID 200 -TemplateBaseID 100 -TemplateTAGNameIdentifier "MyPersonalTemplate_"

       Invokes comparisan of device with ID 200 against template device with ID 100 and use "MyPersonalTemplate_" as identifier for templates

    .EXAMPLE
       Get-PRTGDevice -Name "MyDevice" | Compare-PRTGDeviceSensorsFromTemplateTAG -TemplateBaseID (Get-PRTGProbe -Name "MyTemplateProbe").ObjID -IncludeEqual

        Invokes comparisan of "MyDevice" against all template devices beneath MyTemplateProbe
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        # ID of the object to copy
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 })]
        [Alias('objID', 'ID', 'ObjectId')]
        [int]
        $DeviceID,

        # Base id of the template
        [ValidateNotNullOrEmpty()]
        [int]
        $TemplateBaseID = 1,

        # Filter text identifier for template tags in a device
        [ValidateNotNullOrEmpty()]
        [String]
        $TemplateTAGNameIdentifier = "Template_",

        # Compare properties inside a sensor as well as the existence inside the template
        [switch]
        $ComparePropertiesInObject,

        # Output objects that meet the template, as well as diffs to template
        [switch]
        $IncludeEqual,

        # SensorTree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    begin {}

    process {
        Write-Log -LogText "Getting device to validate with object ID $($DeviceID)" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
        $DevicesToValidate = Get-PRTGDevice -ObjectId $DeviceID -SensorTree $SensorTree

        Write-Log -LogText "Getting role summary table from templatebase object ID $($TemplateBaseID)" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
        $TemplateTAGSummary = Show-PRTGTemplateSummaryFromObjectTAG -TemplateBaseID $TemplateBaseID -TemplateTAGNameIdentifier $TemplateTAGNameIdentifier -SensorTree $SensorTree

        foreach ($Device in $DevicesToValidate) {
            Write-Log -LogText "Getting roles summary table for object ""$($device.name)"" (objID $($device.ObjID))" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            $DeviceTAGSummary = Show-PRTGTemplateSummaryFromObjectTAG -TemplateBaseID $Device.ObjID -TemplateTAGNameIdentifier $TemplateTAGNameIdentifier -SensorTree $SensorTree -IncludeNonMatching

            $result = @()
            foreach ($DeviceTAGSummaryItem in $DeviceTAGSummary) {
                if ($DeviceTAGSummaryItem.rolename) {
                    #if item is a "named" role
                    $Reference = ($DeviceTAGSummaryItem).sensor
                    $Difference = ($TemplateTAGSummary | Where-Object rolename -eq "$($DeviceTAGSummaryItem.RoleName)").sensor
                    if ($Reference -and $Difference) {
                        $ResultItem = Compare-Object -ReferenceObject $Reference -DifferenceObject $Difference -Property Name -PassThru -IncludeEqual

                        if ($ComparePropertiesInObject) {
                            #if comparision on objectdetails/-properties is requested -> compare properties against template
                            foreach ($SensorItem in ($ResultItem | Where-Object SideIndicator -eq "==")) {
                                #get the reference sensor
                                $ReferenceSensor = $Reference | Where-Object name -like $SensorItem.name

                                #compare properties on sensor against template
                                $differentProperty = Compare-ObjectProperty -ReferenceObject $SensorItem -DifferenceObject $ReferenceSensor -PropertyFilter "sensortype", "priority", "sensorkind", "interval", "tags", "Type", "IntervalText", "name"
                                if ($differentProperty) {
                                    $SensorItem.SideIndicator += "!"
                                    Add-Member -InputObject $SensorItem -MemberType NoteProperty -Force -Name "PropertyDifferenceReport" -Value ( [string]::Join(", ", ($differentProperty | ForEach-Object { "Difference on property $($_.property)=""$($_.Value)"" on $(if($_.SideIndicator -eq '<='){"device"}else{"template"})" })) )
                                } else {
                                    Add-Member -InputObject $SensorItem -MemberType NoteProperty -Force -Name "PropertyDifferenceReport" -Value $null
                                }
                            }
                        }

                        $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force -Name SideIndicatorStatus `
                                -Value (. {
                                    switch ($_.SideIndicator) {
                                        '<=' { "WARNING" }
                                        '=>' { "WARNING" }
                                        '==!' { "WARNING" }
                                        '==' { "OK" }
                                    }
                                })
                        }

                        $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force -Name "SideIndicatorDescription" `
                                -Value (. {
                                    switch ($_.SideIndicator) {
                                        '<=' { "In device but not in template" }
                                        '=>' { "In template but not in device" }
                                        '==!' { "Match in device and template, but difference in Properties! Look at PropertyDifferenceReport" }
                                        '==' { "Match in device and template" }
                                    }
                                })
                        }
                    } else {
                        #no sensors in device or no sensors in template
                        if (-not $Reference -and $Difference) {
                            #no sensors in device but some sensors in template
                            $ResultItem = $Difference
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "=>" }
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "In template but not in device" }
                        } elseif ($Reference -and -not $Difference) {
                            #no sensors in template but some sensors in device
                            $ResultItem = $Reference
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "<=" }
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "In device but not in template" }
                        } elseif (-not $Reference -and -not $Difference) {
                            #no sensors in device and no sensors in template
                            $ResultItem = ""
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "!!" }
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                            $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "No objects found" }
                        }
                    }
                } else {
                    #if item is a "NonMatching"-object (without a name in RoleName property)
                    $ResultItem = $DeviceTAGSummaryItem.Sensor
                    $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "!!" }
                    $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                    $ResultItem | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "Object not matching any template" }
                }

                $ResultItem | ForEach-Object { if ($_.pstypenames[0] -ne "PRTG.Object.Compare") { $_.pstypenames.Insert(0, "PRTG.Object.Compare") } }

                $result += $ResultItem
            }

            if (-not $IncludeEqual) {
                $result = $result | Where-Object SideIndicator -ne '=='
            }

            $result
        }
    }

    end {}
}