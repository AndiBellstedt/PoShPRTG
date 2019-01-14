function Get-PRTGSensor {
    <#
    .Synopsis
       Get-PRTGSensor

    .DESCRIPTION
       Returns one or more sensors from sensortree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGSensor
       Query all sensors from the default sensortree (global variable after connect to PRTG server)

    .EXAMPLE
       Get-PRTGSensor -SensorTree $SensorTree
       Query sensors by name from a non default sensortree

    .EXAMPLE
       Get-PRTGSensor -Name "Sensor01"
       Query sensors by name

       Get-PRTGSensor -Name "Sensor01", "Sensor*"
       # Multiple names are possible

       "Sensor01" | Get-PRTGSensor
       # Piping is also possible

    .EXAMPLE
       Get-PRTGSensor -ObjectId 1
       Query sensors by object ID

       Get-PRTGSensor -ObjID 1, 100
       Get-PRTGSensor -ID 1, 100 -SensorTree $SensorTree
       # Multiple IDs are possible

       1 | Get-PRTGSensor
       # Piping is also possible

    #>
    [CmdletBinding(DefaultParameterSetName = 'ReturnAll',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low')]
    Param(
        [Parameter(Mandatory = $true,
            ParameterSetName = 'ID',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {$_ -gt 0})]
        [Alias('ObjID', 'ID')]
        [int[]]$ObjectId,

        [Parameter(Mandatory = $true,
            ParameterSetName = 'Name',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String[]]$Name,

        # Sensortree from PRTG Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [xml]$SensorTree = $script:PRTGSensorTree
    )
    Begin {
        $result = @()
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'ID' {
                foreach ($item in $ObjectId) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -ObjectID $item -Type sensor -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            'Name' {
                foreach ($item in $Name) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -Name $item -Type sensor -SensorTree $SensorTree -Verbose:$false
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
