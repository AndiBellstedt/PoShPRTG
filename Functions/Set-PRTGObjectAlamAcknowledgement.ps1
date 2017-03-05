﻿function Set-PRTGObjectAlamAcknowledgement {
    <#
    .Synopsis
       Set-PRTGObjectAlamAcknowledgement
    .DESCRIPTION
       Acknowledge an alarm on a PRTG object 
       Author: Andreas Bellstedt

    .EXAMPLE
       Set-PRTGObjectAlamAcknowledgement -ObjectId 1 
       Set-PRTGObjectAlamAcknowledgement -ObjectId 1 -Message "Done by User01"
       Set-PRTGObjectAlamAcknowledgement -ObjectId 1 -Message "Done by User01" -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$true, 
                   ConfirmImpact='medium')]
    Param(
        # ID of the object to resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('ObjID', 'ID')]
            [int[]]$ObjectId,

        # Message to associate with the pause event
        [Parameter(Mandatory=$false)]
            [string]$Message,

        # Url for PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({if( ($_.StartsWith("http")) ){$true}else{$false}})]
            [String]$Server = $global:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$User = $global:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [String]$Pass = $global:PRTGPass
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name    
        $body =  @{
            id = 0
            username= $User 
            passhash= $Pass
        }
        if($Message) { $body.Add("ackmsg",$Message) }
    }

    Process {
        foreach($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Acknowledge alarm on object")) {
                try {
                    Write-Log -LogText "Acknowledge alarm on object ID $id ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/acknowledgealarm.htm" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
                } catch {
                    Write-Log -LogText "Failed to acknowledge alarm on object ID $id. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                }
            }
        }
    }

    End {
    }
}
