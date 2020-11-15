#Author: Andreas Bellstedt

#region  PRTG
$TypeName = "PRTG"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName ObjID -Value { [int32]$this.id[0] } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Type -Value { $this.LocalName.substring(0, 1).toupper() + $this.LocalName.substring(1).tolower() } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Status -Value {
    switch ($this.status_raw) {
        '1' { "Unknown" }
        '2' { "Scanning" }
        '3' { "Up" }
        '4' { "Warning" }
        '5' { "Down" }
        '6' { "No Probe" }
        '7' { "Paused by User" }
        '8' { "Paused by Dependency" }
        '9' { "Paused by Schedule" }
        '10' { "Unusual" }
        '11' { "Not Licensed" }
        '12' { "Paused Until" }
        Default { $null }
    }
} -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName CommentExist -Value { [boolean]$this.Hascomment } -Force
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, Tags, Active, Priority, CommentExist, URL -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force
<#
Get-TypeData -TypeName $TypeName
Remove-TypeData -TypeName $TypeName
#>

#endregion  PRTG


#region  PRTG.SENSORTREE
$TypeName = "PRTG.SensorTree"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName ObjID -Value { [int32]$this.prtg.sensortree.nodes.group.id[0] } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Type -Value { $this.prtg.sensortree.nodes.group.LocalName } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Name -Value { $this.prtg.sensortree.nodes.group.name } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName URL -Value { $this.prtg.sensortree.nodes.group.url } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Priority -Value { $this.prtg.sensortree.nodes.group.priority } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Status_raw -Value { $this.prtg.sensortree.nodes.group.status_raw } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Active -Value { $this.prtg.sensortree.nodes.group.active } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Probes -Value { $this.prtg.sensortree.nodes.group.probenode } -Force
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Tags -Value { $this.prtg.sensortree.nodes.group.tags } -Force
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, Tags, Probes -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force
<#
Get-TypeData -TypeName $TypeName
Remove-TypeData -TypeName $TypeName
#>

#endregion  PRTG.SENSORTREE


#region  PRTG.OBJECT
$TypeName = "PRTG.Object"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -Force -MemberName Fullname -Value {
    $x = $this.id[0]
    $count = 0
    $local:FullName = "{$($this.Name)}"
    if ($x -ne 0) {
        if ($this.ParentNode) { $parent = $this.ParentNode }
        do {
            $x = $parent.id[0]
            if ($x -ne 0) {
                $local:FullName = "{$($parent.name)}." + $local:FullName
                if ($parent.ParentNode) { $parent = $parent.ParentNode }
                $count++
            }
        } until($x -eq 0)
    }
    return $FullName
}
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -Force -MemberName tagsInherited -Value {
    $x = $this.id[0]
    $count = 0
    $local:tags = ""
    if ($x -ne 0) {
        if ($this.ParentNode) { $parent = $this.ParentNode }
        do {
            $x = $parent.id[0]
            if ($x -ne 0) {
                $local:tags = "$($parent.tags)$(if($parent.tags){" "})" + $local:tags
                if ($parent.ParentNode) { $parent = $parent.ParentNode }
                $count++
            }
        } until($x -eq 0)
    }
    return $local:tags.Trim()
}
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -Force -MemberName tagsAll -Value {
    return ($this.tagsInherited + " " + $this.tags).Trim()
}
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -Force -MemberName Hierarchy -Value {
    $x = $this.id[0]
    $count = 1
    if ($x -ne 0) {
        if ($this.ParentNode) { $parent = $this.ParentNode }
        do {
            $x = $parent.id[0]
            if ($x -ne 0) {
                if ($parent.ParentNode) { $parent = $parent.ParentNode }
                $count++
            }
        } until($x -eq 0)
    }
    return $count
}
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -Force -MemberName Parent -Value { $this.ParentNode.Name }
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName ObjID -Value { [int32]$this.id[0] } -Force
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, Tags, TagsInherited, Active, Priority, CommentExist, URL, Hierarchy, Fullname -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force
<#
Get-TypeData -TypeName $TypeName
Remove-TypeData -TypeName $TypeName
#>

#endregion  PRTG.OBJECT


#region  PRTG.OBJECT.PROBENODE
$part = "probenode"
$TypeName = "PRTG.Object.$($part.substring(0,1).toupper())$($part.substring(1).tolower())"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Members -Value {
    $collection = @()
    if ($this.device) { $collection += $this.device }
    if ($this.group) { $collection += $this.group }
    return $collection
} -Force
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, Tags, TagsInherited, Active, Priority, CommentExist, DeviceIcon, URL, Group, Device, Hierarchy, Fullname -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force

#endregion  PRTG.OBJECT.PROBENODE


#region  PRTG.OBJECT.GROUP
$part = "group"
$TypeName = "PRTG.Object.$($part.substring(0,1).toupper())$($part.substring(1).tolower())"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -MemberName Members -Value {
    $collection = @()
    if ($this.device) { $collection += $this.device }
    if ($this.group) { $collection += $this.group }
    return $collection
} -Force
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, Tags, TagsInherited, Active, Priority, CommentExist, DeviceIcon, URL, Group, Device, Hierarchy, Fullname -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force

#endregion  PRTG.OBJECT.GROUP


#region  PRTG.OBJECT.DEVICE
$part = "device"
$TypeName = "PRTG.Object.$($part.substring(0,1).toupper())$($part.substring(1).tolower())"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, Host, Tags, TagsInherited, Active, Priority, CommentExist, DeviceIcon, URL, Sensor, Hierarchy, Fullname -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force

#endregion  PRTG.OBJECT.DEVICE


#region  PRTG.OBJECT.SENSOR
$part = "sensor"
$TypeName = "PRTG.Object.$($part.substring(0,1).toupper())$($part.substring(1).tolower())"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -MemberType ScriptProperty -Force -MemberName IntervalText -Value {
    $timespan = [timespan]::fromseconds($this.interval)
    if ($timespan.TotalDays -ge 1) {
        "$($timespan.TotalDays) days"
    } elseif ($timespan.TotalHours -ge 1) {
        "$($timespan.TotalHours) hours"
    } elseif ($timespan.TotalMinutes -ge 1) {
        "$($timespan.TotalMinutes) minutes"
    }
}
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, Type, Status, IntervalText, Interval, Sensorkind, SensorType, DataMode, LastValue, StatusMessage, Tags, TagsInherited, Active, Priority, CommentExist, URL, Parent, Hierarchy, Fullname -DefaultDisplayProperty ObjID -DefaultKeyPropertySet ObjID -Force

#endregion  PRTG.OBJECT.SENSOR


#region  PRTG.OBJECT.COMPARE
$part = "compare"
$TypeName = "PRTG.Object.$($part.substring(0,1).toupper())$($part.substring(1).tolower())"
Write-Verbose "Update TypeData $TypeName"
Update-TypeData -TypeName $TypeName -DefaultDisplayPropertySet ObjID, Name, SideIndicator, SideIndicatorStatus, SideIndicatorDescription, PropertyDifferenceReport, Fullname -DefaultDisplayProperty Name -DefaultKeyPropertySet ObjID -Force



#endregion  PRTG.OBJECT.DEVICE


#region Test
<#
Get-TypeData -TypeName $TypeName
Remove-TypeData -TypeName $TypeName
Get-PRTGObject -Type $part -SensorTree $PRTG | gm
Get-PRTGObject -Type $part -SensorTree $PRTG | select * -Last 1 | fl *
$object = Get-PRTGObject -Type $part -SensorTree $PRTG | select * -Last 1
$object.pstypenames.Insert(0,$TypeName)
$object.pstypenames.Insert(1,"PRTG.Object")
$object.pstypenames.Insert(2,"PRTG")
$object.pstypenames
$object | gm
$object
$object | ft
$object.pstypenames.remove($TypeName)
$object.pstypenames.remove("PRTG.Object")
$object.pstypenames.remove("PRTG")
#>

#endregion Test
