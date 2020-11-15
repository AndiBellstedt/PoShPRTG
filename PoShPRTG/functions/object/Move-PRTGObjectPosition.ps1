function Move-PRTGObjectPosition {
    <#
    .Synopsis
       Move-PRTGObjectPosition

    .DESCRIPTION
       Moves an object in PRTG hierarchy

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Move-PRTGObject -ObjectId 1 -Direction up

       Move-PRTGObject -ObjectId 1 -Direction down -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

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

        # Message to associate with the pause event
        [Parameter(Mandatory = $true)]
        [ValidateSet("up", "down", "top", "bottom")]
        [string]
        $Direction,

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

    Begin {
        $body = @{
            id       = 0
            newpos   = $Direction
            username = $User
            passhash = $Pass
        }
    }

    Process {
        foreach ($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Move $Direction")) {
                try {
                    Write-Log -LogText "Move object ID $id $Direction ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/setposition.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to move object ID $id. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                }
            }
        }
    }

    End {}
}
