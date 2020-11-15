<#PSScriptInfo
.VERSION 1.0.0.4
.GUID 32a4f2d6-b021-4a38-8b6a-d76ceef2b02d
.AUTHOR Jeffrey Snover
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>
function Compare-ObjectProperty {
    <#

    .DESCRIPTION
        Determine the difference in properties between two objects.

        NOTE - if a property's type does not have a CompareTo() function, the property is converted to a
        string for the comparison

    .EXAMPLE
        $o1= @{a1=1;a2=2;b1=3;b2=4}
        PS C:\> $o2= @{a1=1;a2=2;b1=3;b2=5}
        PS C:\> Compare-ObjectProperty $o1 $o2

        Property Value SideIndicator
        -------- ----- -------------
        b2           4 <=
        b2           5 =>

    .EXAMPLE
        $o1= @{a1=1;a2=2;b1=3;b2=4}
        PS C:\> $o2= @{a1=1;a2=2;b1=3;b2=5}
        PS C:\> Compare-ObjectProperty $o1 $o2 -PropertyFilter a*

    .EXAMPLE
        $o1= @{a1=1;a2=2;b1=3;b2=4}
        PS C:\> $o2= @{a1=1;a2=2;b1=3;b2=5}
        PS C:\> Compare-ObjectProperty $o1 $o2 -IncludeEqual
        Property Value SideIndicator
        -------- ----- -------------
        a1           1 ==
        a2           2 ==
        b1           3 ==
        b2           4 <=
        b2           5 =>
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]
        ${ReferenceObject},

        [Parameter(Mandatory = $true)]
        [object]
        ${DifferenceObject},

        #You can specify which properties to compare using a wildcard (using the -LIKE operator)
        [String[]]
        ${PropertyFilter} = "*",

        #Don't include any properties that are different
        [switch]
        ${ExcludeDifferent},

        #Include the properties which are equal
        [switch]
        ${IncludeEqual}
    )


    #region Helper Routines
    function Convert-PropertyToHash {
        param([Parameter(Position = 0)]$inputObject)

        if ($null -eq $inputObject) {
            return @{}
        } elseif ($inputObject -is [HashTable]) {
            # We have to clone the hashtable because we are going to Remove Keys and if we don't
            # clone it, we'll modify the original object
            return $inputObject.clone()
        } else {
            $h = @{}
            foreach ($p in (Get-Member -InputObject $inputObject -MemberType Properties).Name) {
                $h.$p = $inputObject.$p
            }
            return $h
        }
    }
    #endregion

    $refH = Convert-PropertyToHash $ReferenceObject
    $diffH = Convert-PropertyToHash $DifferenceObject

    foreach ($filter in $PropertyFilter) {
        foreach ($p in $refH.keys | Where-Object { $_ -like $filter }) {
            if (! ($diffH.Contains($p)) -and !($ExcludeDifferent)) {
                Write-Output (New-Object PSObject -Property @{ SideIndicator = "<="; Property = $p; Value = $($refH.$p) })
            } else {
                # We convert these to strings and do a string comparison because there are all sorts of .NET
                # objects whose comparison functions don't yeild the expected results.
                if ($refH.$p -AND ($refH.$p | Get-Member -MemberType Method -Name CompareTo)) {
                    $Different = $refH.$p -ne $diffH.$p
                } else {
                    $Different = ("" + $refH.$p) -ne ("" + $diffH.$p)
                }
                if ($Different -and !($ExcludeDifferent)) {
                    Write-Output (New-Object PSObject -Property @{ SideIndicator = "<="; Property = $p; Value = $($refH.$p) })
                    Write-Output (New-Object PSObject -Property @{ SideIndicator = "=>"; Property = $p; Value = $($diffH.$p) })
                } elseif ($IncludeEqual) {
                    Write-Output (New-Object PSObject -Property @{ SideIndicator = "=="; Property = $p; Value = $($refH.$p) })
                }
                $diffH.Remove($p)
            }
        }
    }

    if (-not $ExcludeDifferent) {
        foreach ($p in $diffH.keys | Where-Object { $_ -like $PropertyFilter }) {
            New-Object PSObject -Property @{ SideIndicator = "=>"; Property = $p; Value = $($diffH.$p) }
        }
    }
}