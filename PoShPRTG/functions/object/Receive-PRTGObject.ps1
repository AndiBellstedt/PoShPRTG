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
       Receive-PRTGObject

    .EXAMPLE
       Receive-PRTGObject -Server "https://prtg.corp.customer.com" -User "admin" -Pass "1111111"
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        ConfirmImpact = 'low'
    )]
    Param(
        [int]
        $numResults = 99999,

        [string]
        $columns = "objid,type,name,tags,active,host",

        [ValidateSet("sensortree", "groups", "sensors", "devices", "tickets", "messages", "values", "channels", "reports", "storedreports", "ticketdata")]
        [string]
        $content = "devices",

        [string]
        $SortBy = "objid",

        [ValidateSet("Desc", "Asc")]
        [string]
        $SortDirection = "Desc",

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
