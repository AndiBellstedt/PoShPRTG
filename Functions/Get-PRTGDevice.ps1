﻿function Get-PRTGDevice {
    <#
    .Synopsis
       Get-PRTGDevice
    .DESCRIPTION
       Returns one or more devices from sensortree
       Author: Andreas Bellstedt

    .EXAMPLE
       # Query all devices from the default sensortree (global variable after connect to PRTG server)
       Get-PRTGDevice

       # Query devices by name from a non default sensortree
       Get-PRTGDevice -SensorTree $SensorTree 

    .EXAMPLE
       # Query devices by name
       Get-PRTGDevice -Name "Device01"

       # Multiple names are possible
       Get-PRTGDevice -Name "Device01", "Device*"
       
       #Piping is also possible 
       "Device01" | Get-PRTGDevice
    
    .EXAMPLE
       # Query devices by object ID
       Get-PRTGDevice -ObjectId 1
       Get-PRTGDevice -ObjID 1, 100
       Get-PRTGDevice -ID 1, 100 -SensorTree $SensorTree 
       
       #Piping is also possible 
       1 | Get-PRTGDevice
       
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
            [xml]$SensorTree = $global:PRTGSensorTree 
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name
        $result = @()
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'ID' {
                foreach($item in $ObjectId) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -ObjectID $item -Type device -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }
            
            'Name' {
                foreach($item in $Name) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -Name     $item -Type device -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            Default {
                New-Variable -Name result -Force
                $result += Get-PRTGObject -Type device -SensorTree $SensorTree -Verbose:$false
                Write-Output $result
            }
        }
    }

    End {
    }
}
