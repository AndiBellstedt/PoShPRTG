function Copy-PRTGObject {
    <#
    .Synopsis
       Copy-PRTGObject
    .DESCRIPTION
       Copy a PRTG Object 

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Copy-PRTGObject -ObjectId 1 -TargetID 2 -Name "NewName"

    .EXAMPLE
       Copy-PRTGObject -ObjectId 1 -TargetID 2 -Name "NewName" -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"

    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                   SupportsShouldProcess=$true, 
                   ConfirmImpact='Medium')]
    Param(
        # ID of the object to copy
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('SourceID', 'objID')]
            [int]$ObjectID,
        
        # ID of the target parent object
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
            [int]$TargetID,

        # Name of the newly cloned object
        [Parameter(Mandatory=$false,
                   Position=2)]
            [string]$Name,        

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

        # Sensortree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree
    )

    $Local:logscope = $MyInvocation.MyCommand.Name
    $body =  @{
        id = $ObjectId
        name = $Name
        targetid = $TargetID
        username = $User
        passhash = $Pass
    }
    
    # get source object from sensor tree
    try {
        $SourceObject = Get-PRTGObject -ObjectID $ObjectID -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
        if(-not $Name) { $body.name = $SourceObject.name }
    } catch {
        Write-Log -LogText "Cannot find object to clone. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
        return
    }

    # get target object from sensor tree
    try {
        $TargetObject = Get-PRTGObject -ObjectID $TargetID -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    } catch {
        Write-Log -LogText "Cannot find target object. $($_.exception.message)" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
        return
    }

    if ($pscmdlet.ShouldProcess("objID $TargetID '$($TargetObject.Name)'", "Clone object id $($SourceObject.ObjID) as '$Name'")) {
        #Try to clone the object
        try{
            Write-Log -LogText "Try to clone $($SourceObject.Type) with objID $($SourceObject.ObjID) to target with objID $TargetID. New name of the $($SourceObject.Type) in the target: ""$Name"" ($Server)" -LogType Set -LogScope $Local:logscope -NoFileStatus -DebugOutput
            $Result = Invoke-WebRequest -UseBasicParsing -Uri "$Server/api/duplicateobject.htm" -Method Get -Body $body -Verbose:$false -Debug:$false
        }catch{
            Write-Log -LogText "Failed to clone object $($_.exception.message)" -LogType Error -LogScope $Local:logscope -Error -NoFileStatus
            return 
        }
        Write-Log -LogText "$($SourceObject.Type) cloned to targetID $TargetID. Try to recieve new object from prtg ($Server)" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
        
        # Pluralise the type. Needed for receiving the copied object by "type"
        $TypePlural = $SourceObject.Type+'s'
        # Fetch the ID of the object we just added
        [array]$result = (Receive-PRTGObject -numResults 100 -columns "objid,name,type,tags,active,status" -SortBy "objid" -content $TypePlural -Filters @{"filter_name"=$Name} -Server $Server -User $User -Pass $Pass -Verbose:$false).$TypePlural.item | Where-Object objid -ne $ObjectId 
        
        #output the object if result contains an objectID
        if($result.ObjID) {
            #check for duplicated results
            if($Result.Count -gt 1) {
                Write-Log -LogText "Recieve $($Result.Count) $TypePlural from prtg ($Server). Assume highest ID as the new $($SourceObject.Type)." -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
                $result = $result | Sort-Object -Property objid -Descending | Select-Object -First 1
            } else {
                Write-Log -LogText "Recieve $($Result.Count) $($SourceObject.Type) ($($Result.objid)) from prtg ($Server)." -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
            }
            
            $newChild = $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($ObjectID)]").CloneNode($true)
            $newObjectInSensorTree = $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($TargetID)]").AppendChild( $newChild )
            $newObjectInSensorTree.SetAttribute("id", $Result.objID)
            $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($TargetID)]//*[id=$($ObjectID)]/name").InnerText = $Result.name
            $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($TargetID)]//*[id=$($ObjectID)]/url").InnerText = $newObjectInSensorTree.url.Split('=')[0] + '=' + $Result.objID
            $SensorTree.SelectSingleNode("/prtg/sensortree/nodes/group//*[id=$($TargetID)]//*[id=$($ObjectID)]/id").InnerText = $Result.objID
            
            $Result = Get-PRTGObject -ObjectID $Result.objID -SensorTree $SensorTree -Verbose:$false

            Write-Output $Result
        } else {
            #if result contains an empty item
            Write-Log -LogText "No items recieved after cloning! Unkown issue ($Server)." -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
            Remove-Variable result -Force -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false -WhatIf:$false
            return
        }        
    }
}
