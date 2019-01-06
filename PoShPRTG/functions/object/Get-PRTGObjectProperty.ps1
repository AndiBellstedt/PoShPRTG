function Get-PRTGObjectProperty {
    <#
    .Synopsis
       Get-PRTGObjectProperty

    .DESCRIPTION
       Get a specific property from an PRTG object out of the sensor tree

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGObjectProperty -ObjectId 1 -PropertyName Name, tags

    .EXAMPLE
       Get-PRTGObjectProperty -ID 1 -Name Name, status

    #>
    [CmdletBinding(DefaultParameterSetName = 'ReturnAll',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {$_ -gt 0})]
        [Alias('objID', 'ID')]
        [int[]]$ObjectID,

        # Name of the object's property to get
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Name',
            Position = 1)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]$PropertyName,

        # SensorTree from PRTG Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [xml]$SensorTree = $script:PRTGSensorTree
    )
    Begin {
    }

    Process {
        foreach ($ID in $ObjectID) {
            Write-Log -LogText "Get object details from object ID $ID." -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            try {
                $Object = Get-PRTGObject -ID $ID -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
            } catch {
                Write-Log -LogText $_.exception.message -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                return
            }

            $ObjectProperty = $Object | Get-Member -MemberType Property, NoteProperty | Select-Object -ExpandProperty Name
            $hash = @{}
            if ($PropertyName) {
                #Parameterset: Name
                foreach ($item in $PropertyName) {
                    $PropertiesToQuery = $ObjectProperty | Where-Object { $_ -like $item }
                    foreach ($PropertyItem in $PropertiesToQuery) {
                        if ($hash.$PropertyItem) {
                            Write-Log -LogText "Property $PropertyItem already existis! Skipping this one." -LogType Warning -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                        } else {
                            Write-Log -LogText "Get property $PropertyItem from object ID $ID" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                            $hash.Add($PropertyItem, $object.$PropertyItem)
                        }
                    }
                }
                $result = New-Object -TypeName PSCustomObject -Property $hash
            } else {
                #Parameterset: ReturnAll
                Write-Log -LogText "Get all properties from object ID $ID" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                foreach ($PropertyItem in $ObjectProperty) {
                    $hash.Add($PropertyItem, $object.$PropertyItem)
                }
            }
            $result = New-Object -TypeName PSCustomObject -Property $hash

            Write-Log -LogText "Found $($result.count) $(if($result.count -eq 1){"property"}else{"properties"}) in object ID $ID" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            Write-Output $result
        }
    }

    End {
    }
}
