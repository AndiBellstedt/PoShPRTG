function Use-NewFunction {
    <#
    .Synopsis
       %ToDo%

    .DESCRIPTION
       %ToDo%

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       %ToDo%

    .EXAMPLE
       %ToDo% -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default', 
        SupportsShouldProcess = $true, 
        ConfirmImpact = 'Low')]
    Param(
        # Hilfebeschreibung zu Param1
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('group', 'device', 'sensor', 'probenode')]
        [ValidateScript( {$true})]
        [Alias('objID', 'ID')]
        $Param1,

        # SensorTree from PRTG Server 
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [xml]$SensorTree = $global:PRTGSensorTree,

        # Url for PRTG Server 
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {if ( ($_.StartsWith("http")) ) {$true}else {$false}})]
        [String]$Server = $global:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$User = $global:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Pass = $global:PRTGPass
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