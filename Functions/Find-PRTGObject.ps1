function Find-PRTGObject {
    <#
    .Synopsis
       Find-PRTGObject

    .DESCRIPTION
       Find objects from sensortree by various criteria

    .NOTES
       Author: Andreas Bellstedt

    .LINK
       https://github.com/AndiBellstedt/PoShPRTG

    .EXAMPLE
       Find-PRTGObject -ByTAGName "Server"
       Find-PRTGObject -ByTAGName "Template_*" -IncludeInherited

       Find-PRTGObject -ByTAGName "Template_*", "Server"

    .EXAMPLE
       Find-PRTGObject -ByStatus "Warning"
       Find-PRTGObject -ByStatus 'Paused by User', "Down"
    
    .EXAMPLE
       Find-PRTGObject -BySensorType POP3
       Find-PRTGObject -BySensorType POP3, DNS

    #>
    [CmdletBinding(DefaultParameterSetName='Default',
                   SupportsShouldProcess=$false, 
                   ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$true,
                   ParameterSetName='ByTAGName')]
            [string[]]$ByTAGName,
        
        [Parameter(Mandatory=$false,
                   ParameterSetName='ByTAGName')]
            [switch]$CaseSensitive,

        [Parameter(Mandatory=$false,
                   ParameterSetName='ByTAGName')]
            [switch]$IncludeInherited,

        [Parameter(Mandatory=$true,
                   ParameterSetName='ByStatus')]
        [ValidateSet("Unknown","Scanning","Up","Warning","Down","No Probe","Paused by User","Paused by Dependency","Paused by Schedule","Unusual","Not Licensed", "Paused Until")]
            [string[]]$ByStatus,

        [Parameter(Mandatory=$true,
                   ParameterSetName='BySensorType')]
        [ValidateSet('Cloud HTTP', 'Cloud Ping', 'Serverzustand', 'DNS', 'VMWare Hostserver Hardware-Zustand (SOAP)', 'VMware Hostserver Leistung (SOAP)', 'Exchange Sicherung (Powershell)', 'Exchange Datenbank (Powershell)', 'Exchange Datenbank DAG (Powershell)', 'Exchange Postfach (Powershell)', 'Exchange Nachrichtenwarteschlange (Powershell)', 'Programm/Skript', 'Programm/Skript (Erweitert)', 'Datei-Inhalt', 'Ordner', 'FTP', 'Green IT', 'HTTP', 'HTTP (Erweitert)', 'Hyper-V Freigegebenes Clustervolume', 'IMAP', 'Windows Updates Status (Powershell)', 'Leistungsindikator IIS Anwendungspool', 'Ping', 'POP3', 'Port', 'Zustand der Probe', 'Active Directory Replikationsfehler', 'Windows Druckwarteschlange', 'WSUS-Statistiken', 'RDP (Remote Desktop)', 'Freigaben-Speicherplatz', 'SMTP', 'SNMP Prozessorlast', 'SNMP (Benutzerdef.)', 'SNMP-Zeichenfolge', 'SNMP Dell EqualLogic Physikalischer Datenträger', 'SNMP Dell PowerEdge Physikalischer Datenträger', 'SNMP SonicWALL Systemzustand', 'SNMP Dell PowerEdge Systemzustand', 'SNMP Plattenplatz', 'SNMP-Bibliothek', 'SNMP Linux Durchschnittl. Last', 'SNMP Linux Speicherinfo', 'SNMP Linux Physikalischer Datenträger', 'SNMP Speicher', 'SNMP QNAP Logischer Datenträger', 'SNMP QNAP Physikalischer Datenträger', 'SNMP QNAP Systemzustand', 'SNMP RMON', 'SNMP-Datenverkehr', 'SNMP-Laufzeit', 'SNTP', 'SSL-Sicherheitsüberprüfung', 'SSL-Zertifikatssensor', 'Systemzustand', 'SNMP-Trap-Empfänger', 'VMware Virtual Machine (SOAP)', 'VMware Datastore (SOAP)', 'Ereignisprotokoll (Windows API)', 'WMI Sicherheits-Center', 'WMI Laufwerkskapazität (mehrf.)', 'WMI Ereignisprotokoll', 'WMI Exchange Transportwarteschlange', 'Hyper-V Virtuelle Maschine', 'Hyper-V Host Server', 'Hyper-V Virtuelles Speichergerät', 'Windows IIS-Anwendung', 'WMI Logischer Datenträger E/A BETA', 'WMI Arbeitsspeicher', 'WMI Netzwerkadapter', 'WMI Auslagerungsdatei', 'Windows Physikalischer Datenträger E/A BETA', 'Windows Prozess', 'Windows Prozessorlast', 'WMI Dienst', 'WMI Freigabe', 'WMI Microsoft SQL Server 2012', 'WMI Terminaldienste (Windows 2008+)', 'Windows Systemlaufzeit', 'WMI UTC-Zeit', 'WMI Wichtige Systemdaten (v2)', 'WMI Datenträger')]
            [String[]]$BySensorType,

        # sensortree from PRTG Server 
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
            [xml]$SensorTree = $SCRIPT:PRTGSensorTree 
    )
    Begin {
        $Local:logscope = $MyInvocation.MyCommand.Name
        $StatusMapping = @{
            "Unknown" = 1 
            "Scanning"= 2 
            "Up" =3 
            "Warning" = 4 
            "Down"= 5 
            "No Probe" = 6 
            "Paused by User" = 7 
            "Paused by Dependency" = 8 
            "Paused by Schedule" = 9 
            "Unusual" = 10
            "Not Licensed" = 11
            "Paused Until" = 12
        }
        $SensorTypeMapping = @{
            'Cloud HTTP' = 'cloudhttp'
            'Cloud Ping' = 'cloudping'
            'Serverzustand' = 'corestate'
            'DNS' = 'dns'
            'VMWare Hostserver Hardware-Zustand (SOAP)' = 'esxserverhealthsensorextern'
            'VMware Hostserver Leistung (SOAP)' = 'esxserversensorextern'
            'Exchange Sicherung (Powershell)' = 'exchangepsbackup'
            'Exchange Datenbank (Powershell)' = 'exchangepsdatabase'
            'Exchange Datenbank DAG (Powershell)' = 'exchangepsdatabasedag'
            'Exchange Postfach (Powershell)' = 'exchangepsmailbox'
            'Exchange Nachrichtenwarteschlange (Powershell)' = 'exchangepsmailqueue'
            'Programm/Skript' = 'exe'
            'Programm/Skript (Erweitert)' = 'exexml'
            'Datei-Inhalt' = 'filecontent'
            'Ordner' = 'folder'
            'FTP' = 'ftp'
            'Green IT' = 'green'
            'HTTP' = 'http'
            'HTTP (Erweitert)' = 'httpadvanced'
            'Hyper-V Freigegebenes Clustervolume' = 'hypervcsvdiskfree'
            'IMAP' = 'imap'
            'Windows Updates Status (Powershell)' = 'lastwindowsupdate'
            'Leistungsindikator IIS Anwendungspool' = 'pciisapppool'
            'Ping' = 'ping'
            'POP3' = 'pop3'
            'Port' = 'port'
            'Zustand der Probe' = 'probestate'
            'Active Directory Replikationsfehler' = 'ptfadsreplfailurexml'
            'Windows Druckwarteschlange' = 'ptfprintqueue'
            'WSUS-Statistiken' = 'ptfwsusstatistics'
            'RDP (Remote Desktop)' = 'remotedesktop'
            'Freigaben-Speicherplatz' = 'smbdiskspace'
            'SMTP' = 'smtp'
            'SNMP Prozessorlast' = 'snmpcpu'
            'SNMP (Benutzerdef.)' = 'snmpcustom'
            'SNMP-Zeichenfolge' = 'snmpcustomstring'
            'SNMP Dell EqualLogic Physikalischer Datenträger' = 'snmpdellequallogicphysicaldisk'
            'SNMP Dell PowerEdge Physikalischer Datenträger' = 'snmpdellphysicaldisk'
            'SNMP SonicWALL Systemzustand' = 'snmpdellsonicwallsystemhealth'
            'SNMP Dell PowerEdge Systemzustand' = 'snmpdellsystemhealth'
            'SNMP Plattenplatz' = 'snmpdiskfree'
            'SNMP-Bibliothek' = 'snmplibrary'
            'SNMP Linux Durchschnittl. Last' = 'snmplinuxloadavg'
            'SNMP Linux Speicherinfo' = 'snmplinuxmeminfo'
            'SNMP Linux Physikalischer Datenträger' = 'snmplinuxphysicaldisk'
            'SNMP Speicher' = 'snmpmemory'
            'SNMP QNAP Logischer Datenträger' = 'snmpqnaplogicaldisk'
            'SNMP QNAP Physikalischer Datenträger' = 'snmpqnapphysicaldisk'
            'SNMP QNAP Systemzustand' = 'snmpqnapsystemhealth'
            'SNMP RMON' = 'snmprmon'
            'SNMP-Datenverkehr' = 'snmptraffic'
            'SNMP-Laufzeit' = 'snmpuptime'
            'SNTP' = 'sntp'
            'SSL-Sicherheitsüberprüfung' = 'ssl'
            'SSL-Zertifikatssensor' = 'sslcertificate'
            'Systemzustand' = 'systemstate'
            'SNMP-Trap-Empfänger' = 'udptrap'
            'VMware Virtual Machine (SOAP)' = 'vcenterserverextern'
            'VMware Datastore (SOAP)' = 'vmwaredatastoreextern'
            'Ereignisprotokoll (Windows API)' = 'winapieventlog'
            'WMI Sicherheits-Center' = 'wmiantivirus'
            'WMI Laufwerkskapazität (mehrf.)' = 'wmidiskspace'
            'WMI Ereignisprotokoll' = 'wmieventlog'
            'WMI Exchange Transportwarteschlange' = 'wmiexchangetransportqueues'
            'Hyper-V Virtuelle Maschine' = 'wmihyperv'
            'Hyper-V Host Server' = 'wmihypervserver'
            'Hyper-V Virtuelles Speichergerät' = 'wmihypervvirtualstoragedevice'
            'Windows IIS-Anwendung' = 'wmiiis'
            'WMI Logischer Datenträger E/A BETA' = 'wmilogicaldiskv2'
            'WMI Arbeitsspeicher' = 'wmimemory'
            'WMI Netzwerkadapter' = 'wminetwork'
            'WMI Auslagerungsdatei' = 'wmipagefile'
            'Windows Physikalischer Datenträger E/A BETA' = 'wmiphysicaldiskv2'
            'Windows Prozess' = 'wmiprocess'
            'Windows Prozessorlast' = 'wmiprocessor'
            'WMI Dienst' = 'wmiservice'
            'WMI Freigabe' = 'wmishare'
            'WMI Microsoft SQL Server 2012' = 'wmisqlserver2012'
            'WMI Terminaldienste (Windows 2008+)' = 'wmiterminalservices2008'
            'Windows Systemlaufzeit' = 'wmiuptime'
            'WMI UTC-Zeit' = 'wmiutctime'
            'WMI Wichtige Systemdaten (v2)' = 'wmivitalsystemdata'
            'WMI Datenträger' = 'wmivolume'
        }
    }

    Process {
        switch ($PsCmdlet.ParameterSetName) {
            'ByTAGName' {
                if($CaseSensitive -and (-not $IncludeInherited)) {
                    foreach($TagName in $ByTAGName) {
                        Write-Log -LogText "Search casesensitive only in 'tags'-property for $TagName in SensorTree" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
                        New-Variable -Name result -Force -Confirm:$false -Debug:$false -Verbose:$false -WhatIf:$false
                        $result = $SensorTree.SelectNodes("/prtg/sensortree/nodes/group//*[contains(tags,'$($TagName.Replace('*',''))')]")
                        Write-Output (Set-TypesNamesToPRTGObject -PRTGObject $result)
                    }
                } else {
                    Write-Log -LogText "Search method: caseinsensitive" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    New-Variable -Name objects -Force -Confirm:$false -Debug:$false -Verbose:$false -WhatIf:$false
                    $Objects = Get-PRTGObject -SensorTree $SensorTree -Verbose:$false
                    
                    foreach($Object in $Objects) { 
                        foreach($TagName in $ByTAGName) { 
                            if($IncludeInherited) {
                                Write-Log -LogText "Search caseinsensitive for $TagName in 'tagsAll'-property" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
                                if($Object.tagsAll) {
                                    if($Object.tagsAll.split(' ') -like $TagName) {
                                        Write-Output $Object
                                    }
                                }
                            } else {
                                Write-Log -LogText "Search caseinsensitive for $TagName in 'tags'-property" -LogType Info -LogScope $Local:logscope -NoFileStatus -DebugOutput
                                if($Object.tags) {
                                    if($Object.tags.split(' ') -like $TagName) {
                                        Write-Output $Object
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            'ByStatus' {
                foreach($Status in $ByStatus) { 
                    Write-Log -LogText "Searching for objects by staus $Status" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    New-Variable -Name result -Force -Confirm:$false -Debug:$false -Verbose:$false -WhatIf:$false
                    $result = $SensorTree.SelectNodes("/prtg/sensortree/nodes/group//*[status_raw=$($StatusMapping."$Status")]")
                    Write-Output (Set-TypesNamesToPRTGObject -PRTGObject $result)
                }
            }

            'BySensorType' {
                foreach($SensorType in $BySensorType) {
                    Write-Log -LogText "Searching for objects by type $SensorType" -LogType Query -LogScope $Local:logscope -NoFileStatus -DebugOutput
                    New-Variable -Name result -Force -Confirm:$false -Debug:$false -Verbose:$false -WhatIf:$false
                    $result = $SensorTree.SelectNodes("/prtg/sensortree/nodes/group//*[sensortype='$("$SensorType")']")
                    Write-Output (Set-TypesNamesToPRTGObject -PRTGObject $result)
                }
            }
        }
    }

    End {
    }
}
