function Get-PRTGObjectTAG {
    <#
    .Synopsis
       Get-PRTGObjectTAG

    .DESCRIPTION
       Get the tags property from an PRTG object out of the sensor tree and returns a string array

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Get-PRTGObjectTAG -ObjectId 1

    #>
    [CmdletBinding(DefaultParameterSetName='ReturnAll', 
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='Low')]
    [OutputType([String[]])]
    Param(
        # ID of the object to pause/resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('objID','ID')]
            [int]$ObjectID,
        
        # SensorTree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $global:PRTGSensorTree
    )
    $Local:logscope = $MyInvocation.MyCommand.Name
        
    #Get the object
    Write-Log -LogText "Get object tags from object ID $ObjectID." -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput 
    try {
        $Object = Get-PRTGObject -ID $ObjectID -SensorTree $SensorTree -Verbose:$false -ErrorAction Stop
    } catch {
        Write-Log -LogText $_.exception.message -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
        return 
    }
    
    if($Object.tags) {
        [Array]$result = $Object.tags.Split(' ')
    } else {
        Write-Log -LogText "No tags in object ""$($Object.name)"" (ID:$($ObjectID))" -LogType Warning -LogScope $Local:logscope -NoFileStatus -Warning
        return
    }

    Write-Log -LogText "Found $($result.count) $(if($result.count -eq 1){"tag"}else{"tags"}) in object ID $ObjectID" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
    return $result
}
