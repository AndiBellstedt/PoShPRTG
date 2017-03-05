function Compare-PRTGDeviceSensorsFromTemplateTAG {
    <#
    .Synopsis
       Compare-PRTGDeviceSensorsFromTemplateTAG
    
    .DESCRIPTION
       Display  
    
    .NOTES
       Author: Andreas Bellstedt

    .EXAMPLE
       Compare-PRTGDeviceSensorsFromTemplateTAG
       Display 

    .EXAMPLE
       Compare-PRTGDeviceSensorsFromTemplateTAG -TemplateBaseID 100
       

    .EXAMPLE
       Compare-PRTGDeviceSensorsFromTemplateTAG -TemplateBaseID 100 -TemplateTAGNameIdentifier "MyPersonalTemplate-"
       
    
    .EXAMPLE
       Compare-PRTGDeviceSensorsFromTemplateTAG -TemplateBaseID (Get-PRTGProbe -Name "MyTemplateProbe").ObjID
    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='Low')]
    Param(
        # ID of the object to copy
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('objID', 'ID', 'ObjectId')]
            [int]$DeviceID,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [int]$TemplateBaseID = 1,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$TemplateTAGNameIdentifier = "Template_",
        
        [Parameter(Mandatory=$false)]    
            [switch]$ComparePropertiesInObject,
        
        [Parameter(Mandatory=$false)]
            [switch]$IncludeEqual,
        
        # SensorTree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name
        
    }
    
    Process {
        #foreach($ID in $DeviceID) {
            
            $DevicesToValidate = Get-PRTGDevice -ObjectId $DeviceID -SensorTree $SensorTree
        
            Write-Log -LogText "Getting role summary table from templatebase object ID $($TemplateBaseID)" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
            $TemplateTAGSummary = Show-PRTGTemplateSummaryFromObjectTAG -TemplateBaseID $TemplateBaseID -TemplateTAGNameIdentifier $TemplateTAGNameIdentifier -SensorTree $SensorTree 
            #$TemplateTAGSummary | ft
            #($TemplateTAGSummary | select -Last 1).sensor
            
            foreach($Device in $DevicesToValidate) { 
                Write-Log -LogText "Getting roles summary table for object ""$($device.name)"" (objID $($device.ObjID))" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
                $DeviceTAGSummary = Show-PRTGTemplateSummaryFromObjectTAG -TemplateBaseID $Device.ObjID -TemplateTAGNameIdentifier $TemplateTAGNameIdentifier -SensorTree $SensorTree -IncludeNonMatching

                $result = @()
                foreach($DeviceTAGSummaryItem in $DeviceTAGSummary) { 
                    if($DeviceTAGSummaryItem.rolename) { 
                        #if item is a "named" role
                        $Reference = ($DeviceTAGSummaryItem).sensor
                        $Difference = ($TemplateTAGSummary | Where-Object rolename -eq "$($DeviceTAGSummaryItem.RoleName)").sensor
                        if($Reference -and $Difference) {
                            $ResultItem = Compare-Object -ReferenceObject $Reference -DifferenceObject $Difference -Property Name -PassThru -IncludeEqual
                            
                            if($ComparePropertiesInObject) {
                                #if comparision on objectdetails/-properties is requested -> compare properties against template
                                foreach($SensorItem in ($ResultItem | Where-Object SideIndicator -eq "==")) { 
                                    #get the reference sensor
                                    $ReferenceSensor = $Reference | Where-Object name -like $SensorItem.name 
                                    
                                    #compare properties on sensor against template
                                    $differentProperty = Compare-ObjectProperty -ReferenceObject $SensorItem -DifferenceObject $ReferenceSensor -PropertyFilter "sensortype","priority","sensorkind","interval","tags","Type","IntervalText","name"
                                    if($differentProperty) {
                                        $SensorItem.SideIndicator += "!"
                                        Add-Member -InputObject $SensorItem -MemberType NoteProperty -Force -Name "PropertyDifferenceReport" -Value ( [string]::Join(", ",($differentProperty | foreach { "Difference on property $($_.property)=""$($_.Value)"" on $(if($_.SideIndicator -eq '<='){"device"}else{"template"})" })) )
                                    } else {
                                        Add-Member -InputObject $SensorItem -MemberType NoteProperty -Force -Name "PropertyDifferenceReport" -Value $null
                                    }
                                }
                            }
            
                            $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force -Name SideIndicatorStatus `
                                              -Value (.{   
                                                  switch ($_.SideIndicator) {
                                                      '<='  {"WARNING"}
                                                      '=>'  {"WARNING"}
                                                      '==!' {"WARNING"}
                                                      '=='  {"OK"}
                                                  }
                                              })
                                          }
                            $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force -Name "SideIndicatorDescription" `
                                              -Value (.{   
                                                  switch ($_.SideIndicator) {
                                                      '<='  {"In device but not in template"}
                                                      '=>'  {"In template but not in device"}
                                                      '==!' {"Match in device and template, but difference in Properties! Look at PropertyDifferenceReport"}
                                                      '=='  {"Match in device and template"}
                                                  }
                                              })
                                          }
                        } else {
                            #no sensors in device or no sensors in template
                            if(-not $Reference -and $Difference) { 
                                #no sensors in device but some sensors in template
                                $ResultItem = $Difference
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "=>" }
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "In template but not in device"}
                            } elseif($Reference -and -not $Difference) {
                                #no sensors in template but some sensors in device
                                $ResultItem = $Reference
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "<=" }
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "In device but not in template"}
                            } elseif(-not $Reference -and -not $Difference) {
                                #no sensors in device and no sensors in template
                                $ResultItem = ""
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "!!" }
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                                $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "No objects found"}
                            }
                        }
                    } else { 
                        #if item is a "NonMatching"-object (without a name in RoleName property)
                        $ResultItem = $DeviceTAGSummaryItem.Sensor 
                        $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicator"            -Value "!!" }
                        $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorStatus"      -Value "WARNING" }
                        $ResultItem | foreach { $_ | Add-Member -MemberType NoteProperty -Force  -Name "SideIndicatorDescription" -Value "Object not matching any template"}
                    }
                    
                    $ResultItem | foreach { if($_.pstypenames[0] -ne "PRTG.Object.Compare") { $_.pstypenames.Insert(0,"PRTG.Object.Compare") } }
            
                    $result += $ResultItem
                }
                
                if(-not $IncludeEqual) {
                    $result = $result | Where-Object SideIndicator -ne '=='
                }
                
                Write-Output $result
            }
        #}
    }
}