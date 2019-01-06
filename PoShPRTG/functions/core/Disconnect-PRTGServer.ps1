function Disconnect-PRTGServer {
    <#
    .Synopsis
       Disconnect-PRTGServer

    .DESCRIPTION
       Clears globale variables from memory
       Globale Variablen:
            $script:PRTGServer
            $script:PRTGUser
            $script:PRTGPass

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Disconnect-PRTGServer

    #>
    [CmdletBinding(SupportsShouldProcess = $false,
        ConfirmImpact = 'medium')]
    Param(
        [Switch]$Force
    )
    if ($Force) { $ErrorAction = "SilentlyContinue" } else { $ErrorAction = "Continue" }

    Write-Log -LogText "Removing PRTG variables from memory" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus
    "PRTGServer", "PRTGUser", "PRTGPass", "PRTGSensorTree" | ForEach-Object {
        Get-Variable $_ -Scope global -ErrorAction $ErrorAction | Remove-Variable -Scope global -Force -ErrorAction $ErrorAction -Verbose:$false -Debug:$false -WhatIf:$false
    }

}
