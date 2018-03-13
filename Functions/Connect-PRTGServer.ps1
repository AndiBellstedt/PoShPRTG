function Connect-PRTGServer {
    <#
    .Synopsis
       Connect-PRTGServer

    .DESCRIPTION
       Connect to PRTG Server, creates module-scope variables with connection data and the current sensor tree from PRTG Core Server.
       The module-scope variables are used as default parameters in other PRTG-module cmdlets to interact with PRTG.
       
       Connect-PRTGServer needs to be run at first when starting to work.
    
    .NOTES
       Author: Andreas Bellstedt

       Created global Variables by the cmdlet:
            $SCRIPT:PRTGServer
            $SCRIPT:PRTGUser
            $SCRIPT:PRTGPass
            $SCRIPT:PRTGSensorTree (created through cmdlet Invoke-PRTGSensorTreeRefresh)

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
    [CmdletBinding(DefaultParameterSetName='Credential', 
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='Low')]
    [OutputType([XML])]

    Param(
        # Url for PRTG Server
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if($_ -match '//'){$false}else{$true}})]
            [String]$Server, 
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("HTTP", "HTTPS")]
        [ValidateNotNullOrEmpty()]
            [String]$protocol = "HTTPS",

        [Parameter(Mandatory=$false,
                   ParameterSetName='Credential',
                   Position=1)]
            [System.Management.Automation.PSCredential]$Credential, 

        [Parameter(Mandatory=$true,
                   ParameterSetName='PlainTextPassword',
                   Position=1)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Hash',
                   Position=1)]
        [ValidateNotNullOrEmpty()]
            [String]$User,

        [Parameter(Mandatory=$true,
                   ParameterSetName='PlainTextPassword',
                   Position=2)]
            [String]$PlainTextPassword,

        [Parameter(Mandatory=$false,
                   ParameterSetName='PlainTextPassword')]
            [Switch]$Force,

        [Parameter(Mandatory=$true,
                   ParameterSetName='Hash',
                   Position=2)]
        [ValidateNotNullOrEmpty()]
            [String]$Hash, 

        [Parameter(Mandatory=$false)]
            [Switch]$PassThru
    )
    $Local:logscope = $MyInvocation.MyCommand.Name

    switch ($protocol) {
        'HTTP'  { $Prefix = 'http://' ; Write-Log -LogText "Unsecure $($protocol) connection detected. This is a security risk. Consider switch to HTTPS! Continue..." -LogType Warning -LogScope $Local:logscope -Warning}
        'HTTPS' { $Prefix = 'https://'; Write-Log -LogText "Secure $($protocol) connection. OK." -LogType Info -LogScope $Local:logscope -DebugOutput }
    }

    if($PsCmdlet.ParameterSetName -eq 'Credential'){
        if(-not $Credential) { 
            Write-Log -LogText "No credential specified! Credential is needed..." -LogType Warning -LogScope $Local:logscope -Warning -NoFileStatus
            $Credential = Get-Credential -Message "Please specify logon cedentials for PRTG" -UserName $User
        }
        #If a user entered domain credentials, strip off the domain
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
            Write-Log -LogText "Plaintextpasswords without force parameter are not permitted!" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
            return
        }
    }

    if($PsCmdlet.ParameterSetName -ne 'Hash'){
        $Hash = Invoke-WebRequest -Uri "$Prefix$server/api/getpasshash.htm?username=$User&password=$Pass" -Verbose:$false -Debug:$false -ErrorAction Stop | Select-Object -ExpandProperty content
        Remove-Variable pass -Force -ErrorAction Ignore -Verbose:$false -Debug:$false -WhatIf:$false
    }    

    $SCRIPT:PRTGServer = $Prefix + $server
    $SCRIPT:PRTGUser = $User
    $SCRIPT:PRTGPass = $Hash
    
    Write-Log -LogText "Connection to PRTG ($PRTGServer) as user $PRTGUser" -LogType Info -LogScope $Local:logscope -NoFileStatus -Console
    Invoke-PRTGSensorTreeRefresh -Server $PRTGServer -User $PRTGUser -Pass $PRTGPass -Verbose:$false
    if($PassThru) {
        $Result = New-Object -TypeName psobject -Property @{
            Server = $Prefix + $server
            User = $User
            Pass = $Hash
            Authentication = "&username=$User&passhash=$Hash"        
        }
        Write-Output $Result
    }
}
