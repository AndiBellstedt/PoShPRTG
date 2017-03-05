function Remove-PRTGObject {
    <#
    .Synopsis
       Remove-PRTGObject
    .DESCRIPTION
       Remove an object from PRTGserver and returns.
       Difference to Get-PRTGObject is, that "Get-PRTGObject" is working on a modfified sensortree variable in the memory and not on livedata from PRTGServer
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell
    .EXAMPLE
       Receive-PRTGObject -ObjectId 1
       Receive-PRTGObject -ID 1
       Receive-PRTGObject 1
    .EXAMPLE
       Receive-PRTGObject -ObjectId 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
       Receive-PRTGObject -ID 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
       Receive-PRTGObject 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                  SupportsShouldProcess=$true, 
                  ConfirmImpact='high')]
    [OutputType([Boolean])]
    Param(
        # ID of the object to delete
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('objID', 'ID')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
            [int[]]$ObjectID,

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
            [String]$Pass = $global:PRTGPass,

        # sensortree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree,

        # returns the deleted object 
        [Parameter(Mandatory=$false)]
            [Switch]$PassThru
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name
        $body =  @{
            id = 0
            approve = 1
            username= $User 
            passhash= $Pass
        }
    }
    
    Process {
        $Deleted = @()
        foreach($ID in $ObjectID) { 
            $body.id = $ID
            
            # Check for object on sensor tree
            try {
                $Object = Get-PRTGObject -ObjectID $id -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
            } catch {
                Write-Log -LogText "Cannot find object ID $ID" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
                break
            }

            if ($pscmdlet.ShouldProcess("$($Object.name) objID $ID", "Remove PRTG object")) {
                #Remove in PRTG
                try{
                    Write-Log -LogText "Remove object ID $ID ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/deleteobject.htm " -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop                
                } catch {
                    Write-Error "Failed to delete object $($_.exception.message)"
                    break
                }
                
                #Remove on SensorTree
                if($Result.StatusCode -eq 200){
                    $ToDelete = $SensorTree.SelectSingleNode("//*[id='$ID']")
                    while ($ToDelete  -ne $null) {
                        $Deleted = $ToDelete.ParentNode.RemoveChild($ToDelete)
                        $ToDelete = $SensorTree.SelectSingleNode("//*[id='$ID']")
                    }
                    Write-Log -LogText "Remove object ID $($ID) with name ""$($Deleted.name)"". ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                } else {
                    Write-Log -LogText "Failed to delete object ID $($Deleted.ObjID). ($($Server)) Message:$($Result.StatusCode) $($Result.StatusDescription)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
                    break
                }

                #Write-Uutput
                if($PassThru) { Write-Output (Set-TypesNamesToPRTGObject -PRTGObject $Deleted) }
            }
        }
    }

    End {
    }
}