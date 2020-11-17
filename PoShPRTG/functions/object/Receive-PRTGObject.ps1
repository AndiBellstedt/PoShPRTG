function Receive-PRTGObject {
    <#
    .Synopsis
       Receive-PRTGObject

    .DESCRIPTION
       Query an object directly from PRTGserver and returns.
       Difference to Get-PRTGObject is, that "Get-PRTGObject" is working on a modfified sensortree variable in the memory and not on livedata from PRTGServer

    .NOTES
       Author: Andreas Bellstedt

       adopted from PSGallery Module "PSPRTG"
       Author: Sam-Martin
       Github: https://github.com/Sam-Martin/prtg-powershell

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       PS C:\>Receive-PRTGObject

       Receive devices live from PRTG server (not using the cached sensor tree info)

    .EXAMPLE
       PS C:\>Receive-PRTGObject -Content sensors

       Receive sensors live from PRTG server (not using the cached sensor tree info)

       #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'low'
    )]
    Param(
        # Number of maximal results
        [int]
        $NumResults = 99999,

        # Properties to query
        [string]
        $Columns = "objid,type,name,tags,active,host",

        # Type of device to query
        [ValidateSet("sensortree", "groups", "sensors", "devices", "tickets", "messages", "values", "channels", "reports", "storedreports", "ticketdata")]
        [string]
        $Content = "devices",

        # sorting the output
        [string]
        $SortBy = "objid",

        # Direction to sort the output
        [ValidateSet("Desc", "Asc")]
        [string]
        $SortDirection = "Desc",

        # Filter hashtable to filter out objects from the query
        [hashtable]
        $Filters,

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
        $Pass = $script:PRTGPass
    )

    $SortDirectionPRTGStyle = if ($SortDirection -eq "Desc") { "-" }else { '' }
    $body = @{
        content  = $content;
        count    = $numResults;
        output   = "xml";
        columns  = $columns;
        sortby   = "$SortDirectionPRTGStyle$SortBy";
        username = $User
        passhash = $Pass
    }

    foreach ($FilterName in $Filters.keys) {
        $body.Add($FilterName, $Filters.$FilterName)
    }

    # Try to get the PRTG device tree
    try {
        $prtgDeviceTree = Invoke-RestMethod -UseBasicParsing -Uri "$Server/api/table.xml" -Method Get -Body $Body -Verbose:$false -Debug:$false -ErrorAction Stop
    } catch {
        Write-Log -LogText "Failed to get PRTG Device tree $($_.exception.message)" -LogType Error -LogScope $MyInvocation.MyCommand.Name -NoFileStatus -Error
        return
    }

    $prtgDeviceTree
}
