function Set-PRTGObjectProperty {
    <#
    .Synopsis
       Set-PRTGObjectProperty

    .DESCRIPTION
       Set the property of an PRTG object

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Set-PRTGObjectProperty -ObjectId 1 -PropertyName "Name" -PropertyValue "NewValue"

    .EXAMPLE
       Set-PRTGObjectProperty -ObjectId 1 -PropertyName "Name" -PropertyValue "NewValue" -Server "https://prtg.corp.customer.com" -User "admin -Pass "1111111"

    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'medium'
    )]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { $_ -ge 0 } )]
        [Alias('ObjID', 'ID')]
        [int[]]
        $ObjectId,

        # Name of the object's property to set
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PropertyName,

        # Value to which to set the property of the object
        [string]
        $PropertyValue,

        # returns the changed object
        [Switch]
        $PassThru,

        # Url for PRTG Server
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { if ($_.StartsWith("http")) { $true } else { $false } } )]
        [String]
        $Server = $script:PRTGServer,

        # User for PRTG Authentication
        [ValidateNotNullOrEmpty()]
        [String]
        $User = $script:PRTGUser,

        # Password or PassHash for PRTG Authentication
        [ValidateNotNullOrEmpty()]
        [String]
        $Pass = $script:PRTGPass,

        # sensortree from PRTG Server
        [ValidateNotNullOrEmpty()]
        [xml]
        $SensorTree = $script:PRTGSensorTree
    )

    Begin {}

    Process {
        foreach ($id in $ObjectId) {
            $body = @{
                id       = $id
                action   = 1
                name     = $PropertyName
                value    = $PropertyValue
                username = $User
                passhash = $Pass
            }

            if ($pscmdlet.ShouldProcess("objID $Id", "Set property '$PropertyName' to '$PropertyValue' on PRTG object")) {
                # Set property in PRTG
                try {
                    Write-Log -LogText "Set property ""$PropertyName"" to ""$PropertyValue"" on object ID $id ($Server)" -LogType Set -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -DebugOutput
                    $null = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/setobjectproperty.htm" -Method Get -Body $body -Verbose:$false
                } catch {
                    Write-Log -LogText "Failed to set value $PropertyValue on property $PropertyName. $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -Error -NoFileStatus
                }

                # Set property in SensorTree Variable
                if ($PropertyName -eq "id") {
                    $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($id)]").SetAttribute($PropertyName, $PropertyValue)
                }
                $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($id)]/$PropertyName").InnerText = $PropertyValue

                # Write-Output
                if ($PassThru) { Get-PRTGObject -ObjectID $id -SensorTree $SensorTree -Verbose:$false }
            }
        }
    }

    End {}
}
