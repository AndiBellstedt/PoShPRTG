function Connect-PRTGServer {
    <#
    .Synopsis
       Connect-PRTGServer

    .DESCRIPTION
       Connect to PRTG Server, creates global variables with connection data and the current sensor tree from PRTG Core Server.
       The global variables are used as default parameters in other PRTG-module cmdlets to interact with PRTG.

       Connect-PRTGServer needs to be run at first when starting to work.

    .NOTES
       Author: Andreas Bellstedt

       Created global Variables by the cmdlet:
            $script:PRTGServer
            $script:PRTGUser
            $script:PRTGPass
            $script:PRTGSensorTree (created through cmdlet Invoke-PRTGSensorTreeRefresh)

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       $ServerName = "PRTG.CORP.COMPANY.COM"
       $Credential = Get-Credential "prtgadmin"

       Connect-PRTGServer -Server $ServerName -protocol HTTPS -Credential $Credential

       #with output the connection data
       $connection = Connect-PRTGServer -Server $ServerName -protocol HTTPS -Credential $Credential -PassThru

    .EXAMPLE
       $ServerName = "PRTG.CORP.COMPANY.COM"
       $User = "prtgadmin"
       $Password = "SecretP@ssw0rd"
       Connect-PRTGServer -Server $ServerName -protocol HTTPS -User $User -PlainTextPassword $Password -Force

       #with output the connection data
       $connection = Connect-PRTGServer -Server $servername -protocol HTTPS -User $user -PlainTextPassword $pass -Force -PassThru
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    [CmdletBinding(DefaultParameterSetName='Credential',
                   SupportsShouldProcess=$false,
                   ConfirmImpact='Low')]
    [OutputType([XML])]
    Param(
        # Url for PRTG Server
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if($_ -match '//'){$false}else{$true}})]
        [String]
        $Server,

        [Parameter(Mandatory=$false)]
        [ValidateSet("HTTP", "HTTPS")]
        [ValidateNotNullOrEmpty()]
        [String]
        $protocol = "HTTPS",

        [Parameter(Mandatory=$false,ParameterSetName='Credential',Position=1)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory=$true,ParameterSetName='PlainTextPassword',Position=1)]
        [Parameter(Mandatory=$true,ParameterSetName='Hash',Position=1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $User,

        [Parameter(Mandatory=$true,ParameterSetName='PlainTextPassword',Position=2)]
        [String]
        $PlainTextPassword,

        [Parameter(Mandatory=$false,ParameterSetName='PlainTextPassword')]
        [Switch]
        $Force,

        [Parameter(Mandatory=$true,ParameterSetName='Hash',Position=2)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hash,

        [Alias('QuickConnect', 'NoSensorTree')]
        [Switch]
        $DoNotQuerySensorTree,

        [Switch]
        $PassThru
    )

    switch ($protocol) {
        'HTTP'  { $Prefix = 'http://' ; Write-Log -LogText "Unsecure $($protocol) connection detected. This is a security risk. Consider switch to HTTPS! Continue..." -LogType Warning -LogScope $MyInvocation.MyCommand.Name -Warning}
        'HTTPS' { $Prefix = 'https://'; Write-Log -LogText "Secure $($protocol) connection. OK." -LogType Info -LogScope $MyInvocation.MyCommand.Name -DebugOutput }
    }

    if($PsCmdlet.ParameterSetName -eq 'Credential'){
        if(-not $Credential) {
            Write-Log -LogText "No credential specified! Credential is needed..." -LogType Warning -LogScope $MyInvocation.MyCommand.Name -Warning -NoFileStatus
            $Credential = Get-Credential -Message "Please specify logon cedentials for PRTG" -UserName $User
        }
        if(($credential.UserName.Split('\')).count -gt 1) {
            $User = $credential.UserName.Split('\')[1]
        } else {
            $User = $credential.UserName
        }
        $pass = $credential.GetNetworkCredential().Password
    }

    if($PsCmdlet.ParameterSetName -eq 'PlainTextPassword'){
        if($Force) {
            $pass = $PlainTextPassword
        } else {
            Write-Log -LogText "Plaintextpasswords without force parameter are not permitted!" -LogType Error -LogScope $MyInvocation.MyCommand.Name -Error -NoFileStatus
            return
        }
    }

    if($PsCmdlet.ParameterSetName -ne 'Hash'){
        $Hash = Invoke-WebRequest -Uri "$Prefix$server/api/getpasshash.htm?username=$User&password=$Pass" -Verbose:$false -Debug:$false -ErrorAction Stop | Select-Object -ExpandProperty content
        Remove-Variable pass -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
    }

    $script:PRTGServer = $Prefix + $server
    $script:PRTGUser = $User
    $script:PRTGPass = $Hash
    Write-Log -LogText "Connection to PRTG ($($script:PRTGServer)) as user $($script:PRTGUser)" -LogType Info -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Console

    if(-not $DoNotQuerySensorTree) {
        Invoke-PRTGSensorTreeRefresh -Server $script:PRTGServer -User $script:PRTGUser -Pass $script:PRTGPass -Verbose:$false
    }

    if($PassThru) {
        $Result = New-Object -TypeName psobject -Property @{
            Server = $Prefix + $server
            User = $User
            Pass = $Hash
            Authentication = "&username=$User&passhash=$Hash"
        }
        $Result
    }
}
