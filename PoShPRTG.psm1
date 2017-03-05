﻿#region basic functions
    <#
    Basic functions are mostly adopted from the PRTG API documentation.

    Some of the basic functions are adopted from PSGallery Module "PSPRTG"
    Author: Sam-Martin
    Github: https://github.com/Sam-Martin/prtg-powershell
    #>
. $psscriptroot\Functions\Connect-PRTGServer.ps1
. $psscriptroot\Functions\Get-PRTGSensorTree.ps1
. $psscriptroot\Functions\Get-PRTGProbe.ps1
. $psscriptroot\Functions\Get-PRTGObject.ps1
. $psscriptroot\Functions\Receive-PRTGObject.ps1
. $psscriptroot\Functions\Copy-PRTGObject.ps1
. $psscriptroot\Functions\Set-PRTGObjectProperty.ps1
. $psscriptroot\Functions\Disable-PRTGObject.ps1
. $psscriptroot\Functions\Enable-PRTGObject.ps1
. $psscriptroot\Functions\Remove-PRTGObject.ps1
. $psscriptroot\Functions\Rename-PRTGObject.ps1
. $psscriptroot\Functions\Get-PRTGObjectProperty.ps1
. $psscriptroot\Functions\Receive-PRTGObjectProperty.ps1
. $psscriptroot\Functions\Receive-PRTGObjectStatus.ps1
. $psscriptroot\Functions\Get-PRTGDevice.ps1
. $psscriptroot\Functions\Get-PRTGSensor.ps1
. $psscriptroot\Functions\Get-PRTGGroup.ps1
. $psscriptroot\Functions\Disconnect-PRTGServer.ps1
. $psscriptroot\Functions\Set-PRTGObjectPriority.ps1
. $psscriptroot\Functions\Invoke-PRTGSensorTreeRefresh.ps1
. $psscriptroot\Functions\Test-PRTGObjectNotification.ps1
. $psscriptroot\Functions\Receive-PRTGObjectDetail.ps1
. $psscriptroot\Functions\Invoke-PRTGObjectRefresh.ps1
. $psscriptroot\Functions\Set-PRTGObjectAlamAcknowledgement.ps1
. $psscriptroot\Functions\Move-PRTGObjectPosition.ps1
. $psscriptroot\Functions\Get-PRTGObjectTAG.ps1
. $psscriptroot\Functions\Add-PRTGObjectTAG.ps1
. $psscriptroot\Functions\Remove-PRTGObjectTAG.ps1
. $psscriptroot\Functions\Find-PRTGObject.ps1
. $psscriptroot\Functions\Show-PRTGTemplateSummaryFromObjectTAG.ps1
. $psscriptroot\Functions\Compare-PRTGDeviceSensorsFromTemplateTAG.ps1

#endregion


#region Rollout- / Deployment functions
. $psscriptroot\Functions\New-PRTGDefaultFolderStructureToProbe.ps1
. $psscriptroot\Functions\New-PRTGDeviceFromTemplate.ps1

#endregion


#region Helper functions
#----------------
#. $psscriptroot\Helper\Initialize-Datastructure.ps1
#. $psscriptroot\Helper\Add-TypesNamesToPRTGObject.ps1
. $psscriptroot\Helper\Write-Log.ps1
. $psscriptroot\Helper\Set-TypesNamesToPRTGObject.ps1
. $psscriptroot\Helper\Compare-ObjectProperty.ps1

#endregion


#region TypeData Definition
#-------------------
. $psscriptroot\TypeDefinition\TypeDefinition.ps1

#endregion


#region function template for new cmdlets

#function Use-Template {
#    <#
#    .Synopsis
#       Kurzbeschreibung
#    .DESCRIPTION
#       Lange Beschreibung
#    .EXAMPLE
#       Beispiel für die Verwendung dieses Cmdlets
#    .EXAMPLE
#       Ein weiteres Beispiel für die Verwendung dieses Cmdlets
#    #>
#    [CmdletBinding(DefaultParameterSetName='Default', 
#                  SupportsShouldProcess=$true, 
#                  ConfirmImpact='Low')]
#    Param(
#        # Hilfebeschreibung zu Param1
#        [Parameter(Mandatory=$false,
#                  ValueFromPipelineByPropertyName=$true,
#                  Position=0)]
#        [ValidateNotNullOrEmpty()]
#        [ValidateSet('group', 'device', 'sensor', 'probenode')]
#        [ValidateScript({$true})]
#        [Alias('objID', 'ID')]
#        $Param1,
#
#        # SensorTree from PRTG Server 
#        [Parameter(Mandatory=$false)]
#        [ValidateNotNullOrEmpty()]
#            [xml]$SensorTree = $global:PRTGSensorTree,
#
#        # Url for PRTG Server 
#        [Parameter(Mandatory=$false)]
#        [ValidateNotNullOrEmpty()]
#        [ValidateScript({if( ($_.StartsWith("http")) ){$true}else{$false}})]
#            [String]$Server = $global:PRTGServer,
#
#        # User for PRTG Authentication
#        [Parameter(Mandatory=$false)]
#        [ValidateNotNullOrEmpty()]
#            [String]$User = $global:PRTGUser,
#
#        # Password or PassHash for PRTG Authentication
#        [Parameter(Mandatory=$false)]
#        [ValidateNotNullOrEmpty()]
#            [String]$Pass = $global:PRTGPass
#    )
#    Begin {
#        $Local:logscope = $MyInvocation.MyCommand.Name
#    }
#    
#    Process {
#        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
#       Write-Log -LogText "Doing Use-Template..." -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
#
#       }
#    }
#
#    End {
#    }
#}

#endregion 


Export-ModuleMember -Function *-PRTG*
