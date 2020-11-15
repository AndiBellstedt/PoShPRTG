function Set-PRTGObjectAlarmAcknowledgement {
    <#
    .Synopsis
       Set-PRTGObjectAlarmAcknowledgement

    .DESCRIPTION
       Acknowledge an alarm on a PRTG object

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Set-PRTGObjectAlarmAcknowledgement -ObjectId 1

    .EXAMPLE
       Set-PRTGObjectAlarmAcknowledgement -ObjectId 1 -Message "Done by User01"

    .EXAMPLE
       Set-PRTGObjectAlarmAcknowledgement -ObjectId 1 -Message "Done by User01" -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    [Alias('Set-PRTGObjectAlamAcknowledgement')] # in because of typo in cmdletname in previous version, not to produce a breaking change with the typo fix
    Param(
        # ID of the object to resume
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # Message to associate with the pause event]
        [string]
        $Message,

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
        $Pass = $script:PRTGPass
    )

    Begin {}

    Process {
        foreach ($id in $ObjectId) {
            $body = @{
                id       = $id
                username = $User
                passhash = $Pass
            }
            if ($Message) { $body.Add("ackmsg", $Message) }

            if ($pscmdlet.ShouldProcess("objID $Id", "Acknowledge alarm on object")) {
                try {
                    Write-Log -LogText "Acknowledge alarm on object ID $id ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/acknowledgealarm.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to acknowledge alarm on object ID $id. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                }
            }
        }
    }

    End {}
}
