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

       Get-PRTGDevice -Name "Device01", "Device*"
       # Multiple names are possible

       "Device01" | Get-PRTGDevice
       # Piping is also possible

    .EXAMPLE
       Get-PRTGDevice -ObjectId 1

       Query devices by object ID

       Get-PRTGDevice -ObjID 1, 100
       Get-PRTGDevice -ID 1, 100 -SensorTree $SensorTree
       # Multiple names are possible

       1 | Get-PRTGDevice
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

        # sensortree from PRTG Server
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
                    $result += Get-PRTGObject -ObjectID $item -Type device -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            'Name' {
                foreach ($item in $Name) {
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
