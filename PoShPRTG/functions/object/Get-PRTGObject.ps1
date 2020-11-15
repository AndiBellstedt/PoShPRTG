function Get-PRTGObject {
    <#
    .Synopsis
       Get-PRTGObject

    .DESCRIPTION
       Returns one more multiple types of objects from sensortree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGObject
       Query all objects from the default sensortree (global variable after connect to PRTG server)

    .EXAMPLE
       Get-PRTGObject -SensorTree $SensorTree
       Query objects by name from a non default sensortree

    .EXAMPLE
       Get-PRTGObject -Name "Object01"
       Query objects by name

    .EXAMPLE
       Get-PRTGObject -Name "Object01", "Object*" -Recursive
       Query objects by name with all subobjects

    .EXAMPLE
       Get-PRTGObject -Name "Object01", "Object*" -Type 'probenode', 'group', 'device', 'sensor'
       Query only selected type of objects by name

    .EXAMPLE
       Get-PRTGObject -Name "Object01", "Object*" -Type 'probenode', 'group', 'device', 'sensor' -Recursive
       Query only selected type of objects by name with all subobjects

       Get-PRTGObject -Name "Object01", "Object*" -SensorTree $SensorTree
       # Query objects by name from a non default sensortree

       "Object01" | PRTGObject
       # Piping is also possible

    .EXAMPLE
       Get-PRTGObject -ObjectID 1
       Query objects by object ID

       Get-PRTGObject -ObjID 1 , 100
       Get-PRTGObject -ID 1, 100
       # all the parameter combination from the example above are also possible

       1 | Get-PRTGObject
       # Piping is also possible

    .EXAMPLE
       Get-PRTGObject -FilterXPath "/prtg/sensortree/nodes/group//*[id='1']"
       #for people who know what they do... :-)
       #query objects directly by XPatch filter string

       Get-PRTGObject -FilterXPath "/prtg/sensortree/nodes/group//probenode" -SensorTree $SensorTree

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'ReturnAll',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        [Parameter(ParameterSetName = 'ID', Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(ParameterSetName = 'ReturnAll', Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [Alias('objID', 'ID')]
        [int[]]
        $ObjectID,

        [Parameter(ParameterSetName = 'Name', Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]
        $Name,

        [Parameter(ParameterSetName = 'FullName', Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]
        $FullName,

        [Parameter(ParameterSetName = 'XPath', Position = 0, Mandatory = $true)]
        [String[]]
        $FilterXPath,

        [Parameter(ParameterSetName = 'ReturnAll')]
        [Parameter(ParameterSetName = 'ID')]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'FullName')]
        [ValidateSet('group', 'device', 'sensor', 'probenode')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Type = ('group', 'device', 'sensor', 'probenode'),

        [Parameter(ParameterSetName = 'ReturnAll')]
        [Parameter(ParameterSetName = 'ID')]
        [Parameter(ParameterSetName = 'Name')]
        [Parameter(ParameterSetName = 'FullName')]
        [switch]$Recursive,

        # sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    Begin {}

    Process {
        [Array]$result = @()
        switch ($PsCmdlet.ParameterSetName) {
            'ID' { $ParameterSet = 'ID' }
            'Name' { $ParameterSet = 'Name' }
            'Fullname' { $ParameterSet = 'Fullname' }
            'XPath' { $ParameterSet = 'XPath' }
            { $_ -eq 'ReturnAll' -and $ObjectID } { $ParameterSet = 'ID' }
            Default { $ParameterSet = 'ReturnAll' }
        }
        #Write-Host "$ParameterSet - $ObjectID" -ForegroundColor Green

        switch ($ParameterSet) {
            'ID' {
                foreach ($ID in $ObjectId) {
                    Write-Log -LogText "Query logic is:$($ParameterSet). Going to find the object by ID $($ID) value." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    [string]$BasePath = "/prtg/sensortree/nodes/group//*[id=$($ID)]"
                    $SeachString = $BasePath
                    if ($Recursive) {
                        foreach ($item in $Type) {
                            Write-Log -LogText "Recursice switch detected. Compiling recursive searchstring for $($item)s unter object $ID" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                            $SeachString = $SeachString + ' | ' + $BasePath + "//" + $item
                        }
                    }
                    Write-Log -LogText "Searchstring for query on sensortree: $SeachString." -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $result += $SensorTree.SelectNodes($SeachString)
                    if ($type.count -lt 4) { $result = $result | Where-Object LocalName -In $type }
                    Write-Log -LogText "Found $($result.Count) $([string]::Join('s,',$Type))s in sensortree." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    Remove-Variable item, SeachString, BasePath -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
                }
            }

            'Name' {
                foreach ($NameItem in $Name) {
                    Write-Log -LogText "Query logic is:$($ParameterSet). Going to find the object by Name ""$($Name)"" value." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    #assume find object directly no filtering after xpath needed
                    $FilterAfterQuery = $false
                    [string]$BasePath = "/prtg/sensortree/nodes/group//*[name='$($NameItem)']"
                    if ($NameItem.contains('*') -and $NameItem.StartsWith('*') -and $NameItem.EndsWith('*') -and (-not $NameItem.Trim('*').contains('*'))) {
                        #$NameItem is something like "*machine*" -> xpath with "contains" can be used, no filtering after xpath needed
                        [string]$BasePath = "/prtg/sensortree/nodes/group//*[contains(name,'$($NameItem.Replace('*',''))')]"
                    } elseif ($NameItem.contains('*')) {
                        #$NameItem is something like "*machine*01*" or "machine*01" -> filter after xpath is needed
                        [string]$BasePath = '/prtg/sensortree/nodes/group'
                        $FilterAfterQuery = $true
                        Write-Log -LogText "Switch on FilterAfterQuery" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    }
                    $SeachString = $BasePath
                    if ($Recursive -or $FilterAfterQuery) {
                        foreach ($item in $Type) {
                            Write-Log -LogText "Recursice switch detected. Compiling recursive searchstring for $($item)s." -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                            $SeachString = $SeachString + ' | ' + $BasePath + "//" + $item
                        }
                    }
                    Write-Log -LogText "Searchstring for query on sensortree: $SeachString." -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    if ($FilterAfterQuery -and (-not $Recursive)) {
                        $result += $SensorTree.SelectNodes($SeachString) | Where-Object Name -Like $NameItem
                    } elseif ($FilterAfterQuery -and $Recursive) {
                        $group = $SensorTree.SelectNodes($SeachString) | Where-Object Name -Like $NameItem | Group-Object type
                        $subResult = @()
                        foreach ($g in $group) {
                            switch ($g.name) {
                                'sensor' { $result += $g.group }
                                Default {
                                    [int]$i = 0
                                    [int]$iComplete = $g.Group.count
                                    foreach ($h in $g.Group) {
                                        $i++
                                        Write-Progress -Activity "Recursive filtering..." -PercentComplete ($i / $iComplete * 100)
                                        $subResult += Get-PRTGObject -ObjectID $h.ObjID -Recursive -SensorTree $SensorTree -Verbose:$false
                                    }
                                }
                            }
                        }
                        $result += $subResult
                    } else {
                        $result += $SensorTree.SelectNodes($SeachString)
                    }
                    if ($Type.count -lt 4) { $result = $result | Where-Object LocalName -in $Type }
                    Write-Log -LogText "Found $($result.Count) $([string]::Join('s,',$Type))s in sensortree." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    Remove-Variable item, SeachString, BasePath -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
                }
            }

            'Fullname' {
                foreach ($FullnameItem in $Fullname) {
                    if ($Recursive) { $FullnameItem = "*$FullnameItem*" }
                    Write-Log -LogText "Query logic is:$($ParameterSet). Going to find the object by FullName ""$($FullnameItem)"" value." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    [string]$BasePath = '/prtg/sensortree/nodes/group'
                    $Count = 0
                    foreach ($item in $Type) {
                        Write-Log -LogText "Compiling searchstring for $item" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                        if ($Count -eq 0) {
                            $SeachString = $BasePath + "//" + $item
                        } else {
                            $SeachString = $SeachString + ' | ' + $BasePath + "//" + $item
                        }
                        $count ++
                    }
                    Write-Log -LogText "Final Searchstring for sensortree: $SeachString" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $objects = $SensorTree.SelectNodes($SeachString)

                    $objectsCollection = foreach ($item in $objects) {
                        $item.pstypenames.Insert(0, "PRTG.Object")
                        $item.pstypenames.Insert(1, "PRTG")
                        $item
                    }
                    Remove-Variable item -Force -ErrorAction Ignore

                    foreach ($search in $FullnameItem) {
                        $result += $objectsCollection | Where-Object fullname -Like $search
                    }
                    Write-Log -LogText "Found $($result.Count) $([string]::Join('s,',$Type))s in sensortree." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    Remove-Variable Count, item, SeachString, BasePath -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
                }
            }

            'XPath' {
                foreach ($XPath in $FilterXPath) {
                    Write-Log -LogText "Query logic is:$($ParameterSet). Returning all objects with filterstring: ""$($XPath)""" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $result = $SensorTree.SelectNodes($XPath)
                    Write-Log -LogText "Found $($result.Count) objects in sensortree." -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                }
            }

            Default {
                Write-Log -LogText "Query logic is:$($ParameterSet). Returning all objects" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                [string]$BasePath = '/prtg/sensortree/nodes/group'
                $Count = 0
                foreach ($item in $Type) {
                    Write-Log -LogText "Compiling searchstring for $item" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    if ($Count -eq 0) {
                        $SeachString = $BasePath + "//" + $item
                    } else {
                        $SeachString = $SeachString + ' | ' + $BasePath + "//" + $item
                    }
                    $count ++
                }
                Write-Log -LogText "Final Searchstring for sensortree: $SeachString." -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                $result = $SensorTree.SelectNodes($SeachString)
                Write-Log -LogText "Found $($result.Count) $([string]::Join(',',$Type)) in sensortree." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                Remove-Variable Count, item, SeachString, BasePath -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
            }
        }

        if ($result) {
            if ($PsCmdlet.ParameterSetName -ne 'ReturnAll' -and $Type.count -gt 1) {
                $result = $result | select-object * -Unique
            }
            Write-Output (Set-TypesNamesToPRTGObject -PRTGObject $result)
        } else {
            Write-Log -LogText "Error query object by $($PsCmdlet.ParameterSetName). No object found!" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
        }
    }

    End {}
}
