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
                    $result += Get-PRTGObject -ObjectID $item -Type probenode -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }
            
            'Name' {
                foreach($item in $Name) {
                    New-Variable -Name result -Force
                    $result += Get-PRTGObject -Name     $item -Type probenode -SensorTree $SensorTree -Verbose:$false
                    Write-Output $result
                }
            }

            Default {
                New-Variable -Name result -Force
                $result = Get-PRTGObject -Type probenode -SensorTree $SensorTree -Verbose:$false
                Write-Output $result
            }
        }
    }

    End {
    }
}
