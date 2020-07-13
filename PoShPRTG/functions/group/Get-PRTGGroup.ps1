﻿function Get-PRTGGroup {
    <#
    .Synopsis
       Get-PRTGGroup

    .DESCRIPTION
       Returns one or more groups from sensortree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGGroup
       Query all groups from the default sensortree (global variable after connect to PRTG server)

    .EXAMPLE
       Get-PRTGGroup -SensorTree $SensorTree
       Query groups by name from a non default sensortree

    .EXAMPLE
       Get-PRTGGroup -Name "Group01"
       Query groups by name

       Get-PRTGGroup -Name "Group01", "Group*"
       # Multiple names are possible

       "Group01" | Get-PRTGGroup
       # Piping is also possible

    .EXAMPLE
       Get-PRTGGroup -ObjectId 1
       Query groups by object ID

       Get-PRTGGroup -ObjID 1, 100
       Get-PRTGGroup -ID 1, 100 -SensorTree $SensorTree
       # Multiple IDs are possible

       1 | Get-PRTGGroup
       # Piping is also possible
    #>
    [CmdletBinding(DefaultParameterSetName='ReturnAll',
                   SupportsShouldProcess=$false,
                   ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID',
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('ObjID', 'ID')]
            [int[]]$ObjectId,

        [Parameter(Mandatory=$true,
                   ParameterSetName='Name',
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
            [String[]]$Name,

        # sensortree from PRTG Server
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $script:PRTGSensorTree
    )
    Begin {
        $result = @()
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'ID' {
                foreach($item in $ObjectId) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -ObjectID $item -Type group -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            'Name' {
                foreach($item in $Name) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -Name     $item -Type group -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            Default {
                New-Variable -Name result -Force
                $result = Get-PRTGObject -Type group -SensorTree $SensorTree -Verbose:$false
                Write-Output $result
            }
        }
    }

    End {
    }
}