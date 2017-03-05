function Set-PRTGModuleLogging {
    <#
    .Synopsis
       Kurzbeschreibung
    .DESCRIPTION
       Lange Beschreibung
    .EXAMPLE
       Beispiel für die Verwendung dieses Cmdlets
    .EXAMPLE
       Ein weiteres Beispiel für die Verwendung dieses Cmdlets
    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='Medium')]
    Param(
        # Enables or disables logging of warning messages to $WarnLogFile
        [Parameter(Mandatory=$false)]
            [bool]$WarningLogging = $false,

        # Logfile for warning messages
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path (Split-Path $_)})]
            [String]$WarnLogFile = "$($PWD.Path)PRTG_$(Get-Date -Format "yyyy-MM-dd")_Warning.log",


        # Enables or disables logging of error messages to $ErrorLogFile
        [Parameter(Mandatory=$false)]
            [bool]$ErrorLogging = $false,

        # Logfile for error messages
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path (Split-Path $_)})]
            [String]$ErrorLogFile = "$($PWD.Path)PRTG_$(Get-Date -Format "yyyy-MM-dd")_Error.log",


        # Enables or disables logging of verbose messages to $VerboseLogFile
        [Parameter(Mandatory=$false)]
            [bool]$VerboseLogging = $false,

        # Logfile for Verbose messages
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path (Split-Path $_)})]
            [String]$VerboseLogFile = "$($PWD.Path)PRTG_$(Get-Date -Format "yyyy-MM-dd")_Verbose.log",

        
        # Enables or disables logging of debug messages to $DebugLogFile
        [Parameter(Mandatory=$false)]
            [bool]$DebugLogging = $false,

        # Logfile for debug messages
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path (Split-Path $_)})]
            [String]$DebugLogFile = "$($PWD.Path)PRTG_$(Get-Date -Format "yyyy-MM-dd")_Verbose.log",
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name
    }
    
    Process {
        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
            Write-Log -LogText "Doing Use-Template..." -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput

        }
    }

    End {
    }
}