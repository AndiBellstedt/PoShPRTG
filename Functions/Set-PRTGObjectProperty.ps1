﻿function Set-PRTGObjectProperty {
    <#
    .Synopsis
       Set-PRTGObjectProperty
    .DESCRIPTION
       Set the property of an PRTG object
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell
    .EXAMPLE
       Set-PRTGObjectProperty -ObjectId 1 -TargetID 2 -Name "NewName" -Server "https://prtg.corp.customer.com" -User "admin -Pass "1111111"
    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$true, 
                   ConfirmImpact='medium')]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -ge 0})]
        [Alias('ObjID', 'ID')]
            [int[]]$ObjectId,
        
        # Name of the object's property to set
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
            [string]$PropertyName,

        # Value to which to set the property of the object
        [Parameter(Mandatory=$false)]
            [string]$PropertyValue,

        # returns the changed object 
        [Parameter(Mandatory=$false)]
            [Switch]$PassThru,

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
            [xml]$SensorTree = $global:PRTGSensorTree
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name    
        $body =  @{
            id = 0
            action = 1
            name=$PropertyName
            value=$PropertyValue
            username= $User
            passhash= $Pass
        }
    }

    Process {
        foreach($id in $ObjectId) {
            $body.id = $id
            if ($pscmdlet.ShouldProcess("objID $Id", "Set property '$PropertyName' to '$PropertyValue' on PRTG object")) {
                #Set property in PRTG
                try {
                    Write-Log -LogText "Set property ""$PropertyName"" to ""$PropertyValue"" on object ID $id ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/setobjectproperty.htm" -Method Get -Body $body -Verbose:$false
                } catch {
                    Write-Log -LogText "Failed to set value $PropertyValue on property $PropertyName. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
                }

                #set property in SensorTree Variable
                if($PropertyName -eq "id") {
                    $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($id)]").SetAttribute($PropertyName, $PropertyValue)
                }
                $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($id)]/$PropertyName").InnerText = $PropertyValue
                
                #Write-Output
                if($PassThru) {
                    write-output (Get-PRTGObject -ObjectID $id -SensorTree $SensorTree -Verbose:$false)
                }
            }
        }
    }

    End {
    }
}
