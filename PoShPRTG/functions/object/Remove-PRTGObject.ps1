function Remove-PRTGObject {
    <#
    .Synopsis
       Remove-PRTGObject

    .DESCRIPTION
       Remove an object from PRTGserver and returns.
       Difference to Get-PRTGObject is, that "Get-PRTGObject" is working on a modfified sensortree variable in the memory and not on livedata from PRTGServer

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       PS C:\>Remove-PRTGObject -ObjectId 1

       Remove object with ID 1

    .EXAMPLE
       PS C:\>Get-PRTGObject -ObjectId 1 | Remove-PRTGObject

       Remove object with ID 1
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'high'
    )]
    [OutputType([Boolean])]
    Param(
        # ID of the object to delete
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('objID', 'ID')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -gt 0 } )]
        [int[]]
        $ObjectID,

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
        $SensorTree = $script:PRTGSensorTree,

        # returns the deleted object
        [Switch]
        $PassThru
    )

    Begin {}

    Process {
        $Deleted = @()

        foreach ($ID in $ObjectID) {
            $body = @{
                id       = $ID
                approve  = 1
                username = $User
                passhash = $Pass
            }

            # Check for object on sensor tree
            try {
                $Object = Get-PRTGObject -ObjectID $id -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
            } catch {
                Write-Log -LogText "Cannot find object ID $ID" -LogType Error -LogScope $MyInvocation.MyCommand.Name -Error -NoFileStatus
                break
            }

            if ($pscmdlet.ShouldProcess("$($Object.name) objID $ID", "Remove PRTG object")) {
                #Remove in PRTG
                try {
                    Write-Log -LogText "Remove object ID $ID ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/deleteobject.htm " -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to delete object $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -Error -NoFileStatus
                    break
                }

                #Remove on SensorTree
                if ($Result.StatusCode -eq 200) {
                    $ToDelete = $SensorTree.SelectSingleNode("//*[id='$ID']")
                    while ($ToDelete -ne $null) {
                        $Deleted = $ToDelete.ParentNode.RemoveChild($ToDelete)
                        $ToDelete = $SensorTree.SelectSingleNode("//*[id='$ID']")
                    }
                    Write-Log -LogText "Remove object ID $($ID) with name ""$($Deleted.name)"". ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                } else {
                    Write-Log -LogText "Failed to delete object ID $($Deleted.ObjID). ($($Server)) Message:$($Result.StatusCode) $($Result.StatusDescription)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
                    break
                }

                #Write-Uutput
                if ($PassThru) { Set-TypesNamesToPRTGObject -PRTGObject $Deleted }
            }
        }
    }

    End {}
}