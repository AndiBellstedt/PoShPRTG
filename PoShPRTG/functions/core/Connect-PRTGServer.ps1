function Connect-PRTGServer {
    <#
    .Synopsis
       Connect-PRTGServer

    .DESCRIPTION
       Connect to PRTG Server, creates global variables with connection data and the current sensor tree from PRTG Core Server.
       The global variables are used as default parameters in other PRTG-module cmdlets to interact with PRTG.

       Connect-PRTGServer needs to be run at first when starting to work.

    .PARAMETER Server
        Name of the PRTG server to connect to

    .EXAMPLE
       Connect-PRTGServer -Server "PRTG.CORP.COMPANY.COM" -Credential (Get-Credential "prtgadmin")

       Connects to "PRTG.CORP.COMPANY.COM" via HTTPS protocol and the specified credentials.
       Connection will be set as default PRTG Connection for any further action.

    .EXAMPLE
       $connection = Connect-PRTGServer -Server "PRTG.CORP.COMPANY.COM" -Credential (Get-Credential "prtgadmin") -DoNotRegisterConnection -DoNotQuerySensorTree -PassThru

       Connects to "PRTG.CORP.COMPANY.COM" via HTTPS protocol and output the connection/session object the the variale $connection,
       but does not register the PRTG Connection for automatically useage with other commands. Instead the commands can be triggered
       against this connection by using the -Session Parameter.

       This enables to work with multiple PRTG servers at a time.

    .EXAMPLE
       Connect-PRTGServer -Server "PRTG.CORP.COMPANY.COM" -User "prtgadmin" -Hash 123456789 -Protocol HTTP

       Connects to "PRTG.CORP.COMPANY.COM" via unencrypted HTTP protocal and with a previously queried loginhash.
       The Hash is NOT the users password! The hash has to be queried from PRTG logon service.

       Due to this exposes security related data/ login credentials, this is not the recommended login method.

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
    [CmdletBinding(
        DefaultParameterSetName = 'Credential',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([XML])]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("ComputerName", "Hostname", "Host", "ServerName")]
        [String]
        $Server,

        # The credentials to login to PRTG
        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        $Credential,

        # The user name to login to PRTG
        [Parameter(Mandatory = $true, ParameterSetName = 'Hash')]
        [String]
        $User,

        # A PRTG login hash value
        [Parameter(Mandatory = $true, ParameterSetName = 'Hash')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hash,

        # Specifies if the connection is done with http or https
        [ValidateSet("HTTP", "HTTPS")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Protocol = "HTTPS",

        # Only login. No query of sensortree object
        [Alias('QuickConnect', 'NoSensorTree')]
        [Switch]
        $DoNotQuerySensorTree,

        # Do not register the connection/session as default PRTG server connection
        [Alias('NoRegistration')]
        [Switch]
        $DoNotRegisterConnection,

        # Output the sensortree object after login
        [Switch]
        $PassThru
    )

    begin {}

    process {
        if ($Server -match '//') {
            if ($Server -match '\/\/(?<Server>(\w+|\.)+)') { $Server = $Matches["Server"] }
            Remove-Variable -Name Matches -Force -Verbose:$false -Debug:$false -Confirm:$false
        }

        if ($protocol -eq 'HTTP') {
            Write-PSFMessage -Level Important -Message "Unsecure $($protocol) connection  with possible security risk detected. Please consider switch to HTTPS!" -Tag "Connection"
            $prefix = 'http://'
        } else {
            Write-PSFMessage -Level System -Message "Using secure $($protocol) connection." -Tag "Connection"
            $prefix = 'https://'
        }

        if ($PsCmdlet.ParameterSetName -eq 'Credential') {
            if (($credential.UserName.Split('\')).count -gt 1) {
                $User = $credential.UserName.Split('\')[1]
            } else {
                $User = $credential.UserName
            }
            $pass = $credential.GetNetworkCredential().Password

            Write-PSFMessage -Level Verbose -Message "Authenticate user '$($User)' to PRTG server '$($Prefix)$($server)'" -Tag "Connection"
            $Hash = Invoke-WebRequest -Uri "$($prefix)$($server)/api/getpasshash.htm?username=$($User)&password=$($Pass)" -UseBasicParsing -Verbose:$false -Debug:$false -ErrorAction Stop | Select-Object -ExpandProperty content
        }

        Write-PSFMessage -Level System -Message "Creating PoShPRTG.Connection" -Tag "Connection"
        $session = [PSCustomObject]@{
            PSTypeName        = "PoShPRTG.Connection"
            Server            = $Prefix + $server
            UserName          = $User
            Hash              = ($Hash | ConvertTo-SecureString -AsPlainText -Force)
            DefaultConnection = $false
            SensorTree        = $null
            TimeStampCreated  = Get-Date
            TimeStampModified = Get-Date
        }

        if (-not $DoNotQuerySensorTree) {
            $sensorTree = Invoke-PRTGSensorTreeRefresh -Server $session.Server -User $session.UserName -Pass ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $script:PRTGSession.Hash ))) -PassThru

            $session.SensorTree = $sensorTree
            $session.TimeStampModified = Get-Date
        }

        if (-not $DoNotRegisterConnection) {
            # Make the connection the default connection for further commands
            $session.DefaultConnection = $true
            $session.TimeStampModified = Get-Date

            $script:PRTGSession = $session
            $script:PRTGServer = $script:PRTGSession.Server
            $script:PRTGUser = $script:PRTGSession.UserName
            $script:PRTGPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $script:PRTGSession.Hash ))

            Write-PSFMessage -Level Significant -Message "Connected to PRTG '($($script:PRTGSession.Server))' as '$($script:PRTGSession.UserName)' as default connection" -Tag "Connection"
        }

        if ($PassThru) {
            Write-PSFMessage -Level System -Message "Outputting PoShPRTG.Connection object" -Tag "Connection"
            $session
        }
    }

    end {}
}
