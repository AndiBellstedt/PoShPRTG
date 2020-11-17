function Get-PRTGProbe {
    <#
    .Synopsis
       Get-PRTGProbe

    .DESCRIPTION
       Returns one or more probes from sensortree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGProbe
       Query all probes from the default sensortree (global variable after connect to PRTG server)

       Get-PRTGProbe -SensorTree $SensorTree
       Query probes by name from a non default sensortree

    .EXAMPLE
       Get-PRTGProbe -Name "Probe01"
       Query probes by name

       Get-PRTGProbe -Name "Probe01", "Probe*"
       # Multiple names are possible

       "Probe01" | Get-PRTGProbe
       # Piping is also possible

    .EXAMPLE
       Get-PRTGProbe -ObjectId 1
       Query probes by object ID

       Get-PRTGProbe -ObjID 1, 100
       Get-PRTGProbe -ID 1, 100 -SensorTree $SensorTree
       # Multiple IDs are possible

       1 | Get-PRTGProbe
       # Piping is also possible
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
        [ValidateScript( {$_ -gt 0})]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # Name of the Probe
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
            "Type" = "probenode"
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