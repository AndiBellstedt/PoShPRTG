function Set-PRTGObjectPriority {
    <#
    .Synopsis
       Set-PRTGObjectPriority
    .DESCRIPTION
       Set priority value on a PRTG object

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Set-PRTGObjectPriority -ObjectId 1 -Priority 3

    .EXAMPLE
       Set-PRTGObjectPriority -ObjectId 1 -Priority 3 -PassThru

    .EXAMPLE
       Set-PRTGObjectPriority -ObjectId 1 -Priority 3 -Server "https://prtg.corp.customer.com" -User "admin -Pass "1111111"

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    Param(
        # ID of the object to resume
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # Priority value to set
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[1-5]")]
        [int]
        $Priority,

        # returns the changed object
        [Switch]
        $PassThru,

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if ($_.StartsWith("http")) { $true } else { $false } } )]
        [String]
        $Server = $script:PRTGServer,

        # User for PRTG Authentication
        [ValidateNotNullOrEmpty()]
        [String]
        $User = $script:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [ValidateNotNullOrEmpty()]
        [String]
        $Pass = $script:PRTGPass,

        # sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    Begin {}

    Process {
        foreach ($id in $ObjectId) {
            $body = @{
                id       = $id
                prio     = $Priority
                username = $User
                passhash = $Pass
            }

            if ($pscmdlet.ShouldProcess("objID $Id", "Set priority $Priority to object")) {
                #Set in PRTG
                try {
                    Write-Log -LogText "Set priority $Priority to object ID $id ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/setpriority.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to set priortiy object ID $id. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                }

                #Set on SensorTree Variable
                $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ID)]/priority").InnerText = $Priority

                #Write-Output
                if ($PassThru) { Get-PRTGObject -ObjectID $id -SensorTree $SensorTree -Verbose:$false }
            }
        }
    }

    End {}
}