function Rename-PRTGObject {
    <#
    .Synopsis
       Rename-PRTGObject

    .DESCRIPTION
       Rename an PRTG object

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Rename-PRTGObject -ObjectId 1

    .EXAMPLE
       Rename-PRTGObject -ObjectId 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium')]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {$_ -gt 0})]
        [int]$ObjectId,

        # Message to associate with the pause event
        [Parameter(Mandatory = $false)]
        [string]$NewName,

        # Url for PRTG Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {if ( ($_.StartsWith("http")) ) {$true}else {$false}})]
        [String]$Server = $script:PRTGServer,

        # User for PRTG Authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$User = $script:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Pass = $script:PRTGPass,

        # SensorTree from PRTG Server
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [xml]$SensorTree = $script:PRTGSensorTree
    )
    $body = @{
        id       = $ObjectId
        value    = $NewName
        username = $User
        passhash = $Pass
    }

    Write-Log -LogText "Get object details from object ID $ObjectId. ($Server)" -LogType Query -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
    try {
        $object = Get-PRTGObject -ID $ObjectId -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    } catch {
        Write-Log -LogText $_.exception.message -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
        return
    }

    if ($pscmdlet.ShouldProcess("objID $ObjectId", "Rename PRTG object to '$NewName'")) {
        #Set in PRTG
        try {
            Write-Log -LogText "Set new name ""$($NewName)"" on object ID $ObjectId. ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
            $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/rename.htm" -Method Get -Body $body -Verbose:$false
        } catch {
            Write-Log -LogText "Failed to rename object ID $ObjectId. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
            return
        }

        #Set in object to return
        #$object.Name = $NewName

        #Set on SensorTree variable
        $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ObjectId)]/name").InnerText = $object.Name

        #Write output
        return (Get-PRTGObject -ID $ObjectId -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop)
    }
}
