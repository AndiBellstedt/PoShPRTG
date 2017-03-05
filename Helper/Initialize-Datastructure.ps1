function Initialize-Datastructure {
    <#
    .Synopsis
       Initialize-Datastructure
    
    .DESCRIPTION
       Create new properties  on each member in the xml datastructure.
       Property: "fullname" is a dot separated namespace structure on the hierachy
       Property: "Parent" is the fullname of the parent object in hierachy
    
    #>
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    Param(
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true)]
            [xml]$PRTGDataStructure,
            
            [int]$StartHierarchy = 0, 

            [string]$Tab='', 

            [string]$Delimiter='.', 

            [string[]]$Type = ('group', 'device', 'sensor'), 

            [switch]$EngageParentNames, 

            [switch]$NotRecursive
    )
    $Local:logscope = $MyInvocation.MyCommand.Name
    
    [int]$script:Count = 0
    [string]$BasePath = '/prtg/sensortree/nodes/group/probenode'
    if($NotRecursive) { [string]$PathDelimiter = "/" } else { [string]$PathDelimiter = "//" }
    foreach($Object in $Type) {
        if($script:Count -eq 0) {
            $SeachString = $BasePath + $PathDelimiter + $Object
        } else {
            $SeachString = $SeachString + ' | ' + $BasePath + $PathDelimiter + $Object
        }
        $script:count ++
    }
    [int]$script:Count = 0
    [int]$script:TotalCount = $PRTGDataStructure.SelectNodes($SeachString).count
    [int]$script:div = ("$script:TotalCount").Length * 4
    
    function ExpandGroupNames ($GroupCollection, [int]$Hierarchy, $Parent='', $Tab='', $Delimiter='.', $SubObject, [switch]$EngageParent) {
        $parent = $tab+$parent
        if( ($script:count % $script:div) -eq 0 ) { Write-Progress -Activity "Parsing data structure" -Status "Progress: $script:count of $script:TotalCount" -PercentComplete ($script:count/$script:TotalCount*100) }
        foreach($group in $groupCollection) { 
            Write-Debug "Parent:<$parent> Group:<$($group.name)> GroupCollectionCount:<$($groupCollection.count)> Delimiter:<$delimiter> Tab:<$tab>"
            [int]$script:count = $script:count + 1
            #$group | Add-Member -Type NoteProperty -Force -Name 'Parent'    -Value ($parent)
            #$group | Add-Member -Type NoteProperty -Force -Name 'Fullname'  -Value ("$($parent.trim())$($delimiter){$($group.name)}")
            $group | Add-Member -Type NoteProperty -Force -Name 'CountID'   -Value ([int]$script:count)
            #$group | Add-Member -Type NoteProperty -Force -Name 'Hierarchy' -Value ($Hierarchy)
            #$group | Add-Member -Type NoteProperty -Force -Name 'ObjID'  -Value ([int]($group.id)[0])
            #$group | Add-Member -Type NoteProperty -Force -Name 'Type'      -Value ([string]($group.url.split("."))[0].replace('/',''))
            Write-Output $group
            foreach($object in $subObject) {
                if ($group.$object) {
                    Write-Debug "Found sub$object, going deeper!"
                    if($EngageParent) {
                        ExpandGroupNames -GroupCollection $group.$object -hierarchy ($hierarchy+1) -Parent $group.fullname -Tab "  $tab" -Delimiter "." -SubObject $subObject -EngageParent
                    } else {
                        ExpandGroupNames -GroupCollection $group.$object -hierarchy ($hierarchy+1) -Parent $group.fullname -Tab "$tab" -Delimiter "." -SubObject $subObject
                    }
                }
            }
        }
    }

    if($EngageParent) {
        $result = ExpandGroupNames -groupCollection $PRTGDataStructure.SelectNodes($BasePath) -Hierarchy $StartHierarchy -parent '' -tab '' -delimiter '.' -subObject $Type -EngageParent
    } else {
        $result = ExpandGroupNames -groupCollection $PRTGDataStructure.SelectNodes($BasePath) -Hierarchy $StartHierarchy -parent '' -tab '' -delimiter '.' -subObject $Type
    }   
    return $PRTGDataStructure
}
