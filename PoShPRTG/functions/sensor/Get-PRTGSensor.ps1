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

    .EXAMPLE
       Get-PRTGSensor -Name "Sensor01", "Sensor*"

       Multiple names are possible

    .EXAMPLE
       "Sensor01" | Get-PRTGSensor

       Piping is also possible

    .EXAMPLE
       Get-PRTGSensor -ObjectId 1

       Query sensors by object ID

    .EXAMPLE
       1 | Get-PRTGSensor

       Piping is also possible
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'ReturnAll',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low'
    )]
    Param(
        # ID of the PRTG object
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'ID', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 })]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # Name of the sensor
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Name', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]
        $Name,

        # Sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    begin {
        $queryParam = @{
            "Type" = "sensor"
            "SensorTree" = $SensorTree
            "Verbose" = $false
        }
    }

    process {
        $result = @()

        switch ($PsCmdlet.ParameterSetName) {
            'ID' {
                foreach ($item in $ObjectId) {
                    $result += Get-PRTGObject -ObjectID $item @queryParam
                }
            }

            'Name' {
                foreach ($item in $Name) {
                    $result += Get-PRTGObject -Name $item @queryParam
                }
            }

            Default {
                $result = Get-PRTGObject @queryParam
            }
        }

        $result
    }

    end {}
}
