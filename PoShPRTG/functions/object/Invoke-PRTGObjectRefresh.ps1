﻿function Invoke-PRTGObjectRefresh {
    <#
    .Synopsis
       Invoke-PRTGObjectRefresh

    .DESCRIPTION
       Enables an (paused) PRTG object

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Invoke-PRTGObjectRefresh -ObjectId 1

       Refreshes objct with ID 1
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    Param(
        # ID of the object to resume
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if (($_.StartsWith("http"))) {$true} else {$false} } )]
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

    Begin {
        $body = @{
            id       = 0
            username = $User
            passhash = $Pass
        }
    }

    Process {
        foreach ($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Call scan now procedure on object")) {
                try {
                    Write-Log -LogText "Call scan now procedure on object ID $id ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/scannow.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to Call scan now procedure on object ID $id. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                }
            }
        }
    }

    End {}
}
