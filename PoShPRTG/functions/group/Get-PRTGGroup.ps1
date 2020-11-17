function Get-PRTGGroup {
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

    .EXAMPLE
       Get-PRTGGroup -Name "Group01", "Group*"

       Multiple names are possible

    .EXAMPLE
        "Group01" | Get-PRTGGroup

        Piping is also possible

    .EXAMPLE
       Get-PRTGGroup -ObjectId 1

       Query groups by object ID

    .EXAMPLE
       1 | Get-PRTGGroup

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

        # Name of the group
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
            "Type" = "group"
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
