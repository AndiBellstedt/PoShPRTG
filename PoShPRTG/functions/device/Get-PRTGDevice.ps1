function Get-PRTGDevice {
    <#
    .Synopsis
       Get-PRTGDevice

    .DESCRIPTION
       Returns one or more devices from sensortree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGDevice

       Query all devices from the default sensortree (global variable after connect to PRTG server)

    .EXAMPLE
       Get-PRTGDevice -SensorTree $SensorTree

       Query devices by name from a non default sensortree

    .EXAMPLE
       Get-PRTGDevice -Name "Device01"

       Query devices by name

    .EXAMPLE
       Get-PRTGDevice -Name "Device01", "Device*"

       Multiple names are possible

    .EXAMPLE
       "Device01" | Get-PRTGDevice

       Piping is also possible

    .EXAMPLE
       Get-PRTGDevice -ObjectId 1

       Query devices by object ID

    .EXAMPLE
       1 | Get-PRTGDevice

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

        # Name of the device
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Name', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]]
        $Name,

        # sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    begin {
        $queryParam = @{
            "Type" = "device"
            "SensorTree" = $SensorTree
            "Verbose" = $false
        }
    }

    process {
        $result = @()

        switch ($PsCmdlet.ParameterSetName) {
            'ID' {
                New-Variable -Name result -Force
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
