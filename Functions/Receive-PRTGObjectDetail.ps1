function Receive-PRTGObjectDetail {
    <#
    .Synopsis
       Receive-PRTGObjectDetail

    .DESCRIPTION
       Query status information for an object directly from PRTGserver.
       (function not working on sensortree variable in memory)
    
    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Receive-PRTGObjectDetail -ObjectId 1 

       Receive-PRTGObjectDetail -ID 1 

    .EXAMPLE
       Receive-PRTGObjectDetail -ObjectId 1 -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
    #>
    [CmdletBinding(DefaultParameterSetName='Default', 
                  SupportsShouldProcess=$false, 
                  ConfirmImpact='low')]
    param(
        # ID of the object to pause/resume
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -gt 0})]
        [Alias('ObjId','ID')]
            [int]$ObjectId,
        
        # Name of the object's property to get
        [Parameter(Mandatory=$false,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
            [string]$PropertyName,

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
            username = $User 
            passhash = $Pass
        }
    }

    Process {
        foreach($ID in $ObjectID) {
            $body.id = $ID
            Write-Log -LogText "Get details for object ID $ID. ($Server)" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
            try{
                $Object = (Invoke-RestMethod -Uri "$Server/api/getsensordetails.xml" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop).sensordata
            }catch{
                Write-Log -LogText "Failed to get details for object from prtg. ($Server) Message:$($_.exception.message)" -LogType Error -LogScope $Local:logscope -NoFileStatus -Error
            }

            $ObjectProperty = $Object | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
            $hash = @{}
            if($PropertyName) { #Parameterset: Name
                foreach($item in $PropertyName) {
                    $PropertiesToQuery = $ObjectProperty | Where-Object { $_ -like $item }
                    foreach($PropertyItem in $PropertiesToQuery) { 
                        if($hash.$PropertyItem) { 
                            Write-Log -LogText "Property $PropertyItem already existis! Skipping this one." -LogType Warning -LogScope $Local:logscope -NoFileStatus -DebugOutput
                        } else {
                            Write-Log -LogText "Get property $PropertyItem from object ID $ID" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
                            $hash.Add($PropertyItem, $object.$PropertyItem)
                        }
                    }
                }
                $result = New-Object -TypeName PSCustomObject -Property $hash
            } else { #Parameterset: ReturnAll
                Write-Log -LogText "Get all properties from object ID $ID" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
                foreach($PropertyItem in $ObjectProperty) { 
                    $hash.Add($PropertyItem, $object.$PropertyItem.'#cdata-section')
                }
            }
            $result = New-Object -TypeName PSCustomObject -Property $hash

            Write-Log -LogText "Found $($result.count) $(if($result.count -eq 1){"property"}else{"properties"}) in object ID $ID" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
            Write-Output $result
        }
    }
}
