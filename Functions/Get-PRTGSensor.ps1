function Get-PRTGSensor {
    <#
    .Synopsis
       Get-PRTGSensor
    .DESCRIPTION
       Returns one or more sensors from sensortree
       Author: Andreas Bellstedt

    .EXAMPLE
       # Query all sensors from the default sensortree (global variable after connect to PRTG server)
       Get-PRTGSensor

       # Query sensors by name from a non default sensortree
       Get-PRTGSensor -SensorTree $SensorTree 

    .EXAMPLE
       # Query sensors by name
       Get-PRTGSensor -Name "Sensor01"

       # Multiple names are possible
       Get-PRTGSensor -Name "Sensor01", "Sensor*"
       
       #Piping is also possible 
       "Sensor01" | Get-PRTGSensor
    
    .EXAMPLE
       # Query sensors by object ID
       Get-PRTGSensor -ObjectId 1
       Get-PRTGSensor -ObjID 1, 100
       Get-PRTGSensor -ID 1, 100 -SensorTree $SensorTree 
       
       #Piping is also possible 
       1 | Get-PRTGSensor
       
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
                    $result += Get-PRTGObject -ObjectID $item -Type sensor -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }
            
            'Name' {
                foreach($item in $Name) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -Name     $item -Type sensor -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            Default {
                New-Variable -Name result -Force
                $result = Get-PRTGObject -Type sensor -SensorTree $SensorTree -Verbose:$false
                Write-Output $result
            }
        }
    }

    End {
    }
}
