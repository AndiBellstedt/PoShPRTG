﻿function Set-TypesNamesToPRTGObject {
    <#
    .Synopsis
       Set-TypesNamesToPRTGObject

    .DESCRIPTION
       Add module specific type names to result objects of a function.

    .NOTES
       Author: Andreas Bellstedt

    .EXAMPLE
        Set-TypesNamesToPRTGObject $PRTGObject
        Work on the specified object
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding(ConfirmImpact="low", SupportsShouldProcess=$false)]
    param(
        # Object to work on
        $PRTGObject
    )

    begin {}

    process {
        foreach ($item in $PRTGObject) {
            if ($item.pstypenames[0] -eq "PRTG.Object.Compare") { $null = $item.pstypenames.Remove("PRTG.Object.Compare") }

            switch ($item.LocalName) {
                'probenode' {
                    if ($item.pstypenames -notcontains "PRTG.Object.Probenode") {
                        $item.pstypenames.Insert(0, "PRTG.Object.Probenode")
                    }
                }

                'group' {
                    if ($item.pstypenames -notcontains "PRTG.Object.Group") {
                        $item.pstypenames.Insert(0, "PRTG.Object.Group")
                    }
                }

                'device' {
                    if ($item.pstypenames -notcontains "PRTG.Object.Device") {
                        $item.pstypenames.Insert(0, "PRTG.Object.Device")
                    }
                }

                'sensor' {
                    if ($item.pstypenames -notcontains "PRTG.Object.Sensor") {
                        $item.pstypenames.Insert(0, "PRTG.Object.Sensor")
                    }
                }
            }

            if ($item.pstypenames -notcontains "PRTG.Object") { $item.pstypenames.Insert(1, "PRTG.Object") }
            if ($item.pstypenames -notcontains "PRTG") { $item.pstypenames.Insert(2, "PRTG") }

            $item
        }
    }

    end {}
}
