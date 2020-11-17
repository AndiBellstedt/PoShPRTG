function Write-Log {
    <#
    .Synopsis
       Write-Log / Log
       Logs text to the console and/or to a file.

    .DESCRIPTION
       A comprehensive helper function for structured logging.
       Writes one or more messages to the different available outputchannels of the powershell and to one or more logfiles.

    .NOTES
       Version:     2.4
       Author:      Andreas Bellstedt
       History:     01.07.2016 - First Version
                    07.08.2016 - add logging to differnt output channels and more flexibility in parameters
                    14.08.2016 - changing synopsis position to powershell best practices. (before funktion block)
                    27.01.2017 - add parameters $Type and $logscope to easy logging structur and prevent the need of global variables for (status)types
                    29.01.2017 - change debug output procedure for better handling

    .EXAMPLE
       Examples without logging to a file. Only console output is done. The following examples only produces output
       if the verbosepreference in current session is set to "continue", or the -verbose switch is specified:

       Write-Log -LogText "This is a Message"
       Write-Log "This is a Message"
       Log "This is a Message"
       "This is a Message" | Write-Log
         -> VERBOSE: [2016-08-08 08:08:08] [NOFILE] This is a Message

       "This is a Message" , "This is anonther Message" | Write-Log -LogType Info
         -> VERBOSE: [2016-08-08 08:08:08] [NOFILE] [INFO   ] This is a Message
            VERBOSE: [2016-08-08 08:08:08] [NOFILE] [INFO   ] This is another Message

    .EXAMPLE
       Examples without logging to a file. Only console output is done. The following examples produces output
       irrespective of the verbosepreference:

       Write-Log -LogText "This is a Message" -LogType Warning -LogScope "Function01" -Warning
         -> WARNING: [2016-08-08 08:08:08] [NOFILE] [WARNING] [FUNCTION01] This is a Message

       Write-Log -LogText "This is a Message" -LogType Error -LogScope "Function01" -Error
         -> Write-Log : [2016-08-07 16:13:28] [NOFILE] [ERROR  ] [FUNCTION01] This is a Message
            +        Write-Log -LogText "This is a Message" -Error
            +        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
                + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Write-Log

       Write-Log -LogText "This is a Message" -Console
       Write-Log -LogText "This is a Message" -Visible
         -> [2016-08-08 08:08:08] [NOFILE] This is a Message

       Write-Log -LogText "This is a Message" -Console -Warning
         -> WARNING: [2016-08-08 08:08:08] [NOFILE] This is a Message

       Write-Log -LogText "This is a Message" -Console -NoFileStatus
         -> [2016-08-08 08:08:08] This is a Message

       Write-Log -LogText "This is a Message" -Console -NoFileStatus -NoTimeStamp
         -> This is a Message

    .EXAMPLE
       Examples without logging to a file. Only console output is done. The following examples produces output
       to the debug channel:

       Write-Log -LogText "This is a Message" -DebugOutput
         -> DEBUG: [2016-08-08 08:08:08] [NOFILE] This is a Message

       Write-Log -LogText "This is a Message" -DebugOutput -Warning
         -> DEBUG: WARNING: [2016-08-08 08:08:08] [NOFILE] This is a Message

    .EXAMPLE
       Examples without logging to a file.

       Write-Log -LogText "This is a Message" -LogFile 'C:\Administration\Logs\Logfile.log'
         -> VERBOSE: [2016-08-08 08:08:08] [FILE  ] This is a Message

       Write-Log -LogText "This is a Message" -LogFile 'C:\Administration\Logs\Logfile.log', 'C:\Administration\Logs\Logfile-Errors.log' -Warning
         -> WARNING: [2016-08-08 08:08:08] [FILE  ] This is a Message

       Write-Log -LogText "This is a Message" -LogFile 'C:\Administration\Logs\Logfile.log', 'C:\Administration\Logs\Logfile-Errors.log' -Error
         -> Write-Log : [2016-08-08 08:08:08]  [FILE  ] This is a Message
            In Zeile:1 Zeichen:1
            + Write-Log -LogText "This is a Message" -LogFile 'C:\Administration\Lo ...
            + ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                + CategoryInfo          : NotSpecified: (:) [Write-Error], WriteErrorException
                + FullyQualifiedErrorId : Microsoft.PowerShell.Commands.WriteErrorException,Write-Log
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]

    [CmdletBinding(
        DefaultParameterSetName = 'VerboseOutput',
        ConfirmImpact = "Low"
    )]
    [Alias('Log')]
    Param(
        #The message to be logged
        [parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true )]
        [Alias('Text', 'Message')]
        [string]$LogText,

        #The kind of event/action what is happening while the message is logged
        [parameter( Mandatory = $false,
            Position = 1)]
        [Alias('Type')]
        [ValidateSet('Warning', 'Info', 'Query', 'Set', 'Error')]
        [string]$LogType,

        #The name of the function or the scriptpart where the log event happens
        [parameter( Mandatory = $false,
            Position = 2 )]
        [Alias('Scope')]
        [string]$LogScope,

        #The name of the logfile(s) where the message should be logged
        [parameter( Mandatory = $false )]
        [Alias('File')]
        [string[]]$LogFile,

        #Suppress the timestamp in the logged output
        [parameter( Mandatory = $false )]
        [switch]$NoTimeStamp,

        #Suppress the info, wether the logged output is written to file or only displayed in the outputchannel
        [parameter( Mandatory = $false )]
        [switch]$NoFileStatus,

        #Specifies that LogText is displayed as text in the debug-channel, not in the verbose-channel
        [parameter( Mandatory = $false,
            ParameterSetName = 'DebugOutput' )]
        [switch]$DebugOutput,

        #Specifies that LogText is displayed as text in the console window, not in the verbose-channel
        [parameter( Mandatory = $false,
            ParameterSetName = 'ConsoleOutput' )]
        [Alias('Visible')]
        [switch]$Console,

        #Specifies that LogText is displayed as (red) error message in the console window, not in the verbose-channel
        [parameter( Mandatory = $false,
            ParameterSetName = 'ErrorOutput' )]
        [switch]$Error,

        #Logs the LogText as warrning message to the console
        [parameter( Mandatory = $false,
            ParameterSetName = 'VerboseOutput' )]
        [parameter( Mandatory = $false,
            ParameterSetName = 'DebugOutput' )]
        [parameter( Mandatory = $false,
            ParameterSetName = 'ConsoleOutput' )]
        [switch]$Warning
    )

    begin {
        switch ($LogType) {
            'Warning' { $Type = '[WARNING] ' }
            'Info' { $Type = '[INFO   ] ' }
            'Query' { $Type = '[QUERY  ] ' }
            'Set' { $Type = '[SET    ] ' }
            'Error' { $Type = '[ERROR  ] ' }
            Default { $Type = '[INFO   ] ' }
        }

        if ($logScope) { $LogScope = "[$($LogScope.ToUpper())] " }
        if ($NoFileStatus) { $status = '' } else { $status = "[NOFILE] " }
        if ($NoTimeStamp) { $logDate = '' } else { $logDate = "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] " }

        #turn of confimation for debug actions
        If (($DebugPreference -eq 'Inquire') -and ($PsCmdlet.ParameterSetName -eq 'DebugOutput')) {
            $DebugPreferenceOrg = $DebugPreference
            $DebugPreference = 'Continue'
        }
    }

    process {
        if ($LogFile) {
            foreach ($File in $LogFile) {
                "$($logDate)$($Type)$($LogScope)$($LogText)" | Out-File -FilePath $File -Append
            }
        }

        $message = "$($logDate)$($status)$($Type)$($LogScope)$($LogText)"
        switch ($PsCmdlet.ParameterSetName) {
            'VerboseOutput' {
                if ($Warning) { Write-Warning $message } else { write-verbose $message }
            }

            'DebugOutput' {
                if ($Warning) { Write-Debug "WARNING: $message" } else { Write-Debug $message }
            }

            'ConsoleOutput' {
                if ($Warning) {
                    Write-Host "WARNING: $message" -ForegroundColor $Host.PrivateData.WarningForegroundColor -BackgroundColor $Host.PrivateData.WarningBackgroundColor
                } else {
                    Write-Host $message
                }
            }

            'ErrorOutput' { Write-error $message }
        }
    }

    end {
        $DebugPreference = $DebugPreferenceOrg
        Remove-Variable message, logDate, status, Type, DebugPreferenceOrg -Force -ErrorAction Ignore -WhatIf:$false -Confirm:$false -Verbose:$false -Debug:$false
    }
}