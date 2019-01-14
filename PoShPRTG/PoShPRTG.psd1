@{
    # Script module or binary module file associated with this manifest
    ModuleToProcess       = 'PoShPRTG.psm1'

    # Version number of this module.
    ModuleVersion         = '1.6.0.0'

    # ID used to uniquely identify this module
    GUID                  = '2dd57587-dbe7-4f17-a5fb-3c9d9999af76'

    # Author of this module
    Author                = 'Andreas Bellstedt'

    # Company or vendor of this module
    CompanyName           = ''

    # Copyright statement for this module
    Copyright             = 'Copyright (c) 2019 Andreas Bellstedt'

    # Description of the functionality provided by this module
    Description           = @'
    PoShPRTG is a comprehensive module for administering PRTG NETWORK MONITOR (www.paessler.com/prtg).

    It eases the rollout-/deployment process for new machines and managment of existing machines with all there sensors.
    The shipped cmdlets are used to call the PRTG API (http://prtg.paessler.com/api.htm?username=demo&password=demodemo)

    All cmdlets are build with
    - powershell regular verbs
    - mostly with pipeling availabilties
    - comprehensive logging on verbose and debug channel
'@

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion     = '3.0'

    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules       = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '0.9.25.107' }
    )

    # Processor architecture (None, X86, Amd64) required by this module
    ProcessorArchitecture = 'None'

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @('bin\PoShPRTG.dll')

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @('xml\PoShPRTG.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @('xml\PoShPRTG.Format.ps1xml')

    # Functions to export from this module
    FunctionsToExport     = @(
        #basic functions
        # Basic functions are mostly adopted from the PRTG API documentation.
        # Some of the basic functions are adopted from PSGallery Module "PSPRTG"
        # Author: Sam-Martin
        # Github: https://github.com/Sam-Martin/prtg-powershell
        'Connect-PRTGServer',
        'Get-PRTGSensorTree',
        'Get-PRTGProbe',
        'Get-PRTGObject',
        'Receive-PRTGObject',
        'Copy-PRTGObject',
        'Set-PRTGObjectProperty',
        'Disable-PRTGObject',
        'Enable-PRTGObject',
        'Remove-PRTGObject',
        'Rename-PRTGObject',
        'Get-PRTGObjectProperty',
        'Receive-PRTGObjectProperty',
        'Receive-PRTGObjectStatus',
        'Get-PRTGDevice',
        'Get-PRTGSensor',
        'Get-PRTGGroup',
        'Disconnect-PRTGServer',
        'Set-PRTGObjectPriority',
        'Invoke-PRTGSensorTreeRefresh',
        'Test-PRTGObjectNotification',
        'Receive-PRTGObjectDetail',
        'Invoke-PRTGObjectRefresh',
        'Set-PRTGObjectAlarmAcknowledgement',
        'Move-PRTGObjectPosition',
        'Get-PRTGObjectTAG',
        'Add-PRTGObjectTAG',
        'Remove-PRTGObjectTAG',
        'Find-PRTGObject',
        'Show-PRTGTemplateSummaryFromObjectTAG',
        'Compare-PRTGDeviceSensorsFromTemplateTAG',

        # Rollout- / Deployment functions
        'New-PRTGDefaultFolderStructureToProbe.ps1',
        'New-PRTGDeviceFromTemplate.ps1'
    )

    # Cmdlets to export from this module
    CmdletsToExport       = ''

    # Variables to export from this module
    VariablesToExport     = ''

    # Aliases to export from this module
    AliasesToExport       = @()

    # List of all modules packaged with this module
    ModuleList            = @()

    # List of all files packaged with this module
    FileList              = @()

    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData           = @{

        #Support for PowerShellGet galleries.
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('PoShPRTG', 'PSPRTG', 'PRTG', 'PRTGNetworkMonitor', 'PRTG_Network_Monitor', 'PowerShell', 'Automation', 'Management', 'Monitoring')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/AndiBellstedt/PoShPRTG/blob/master/license'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/AndiBellstedt/PoShPRTG'

            # A URL to an icon representing this module.
            IconUri      = 'https://github.com/AndiBellstedt/PoShPRTG/blob/master/asstes/PoShPrtg_128x128.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/AndiBellstedt/PoShPRTG/blob/master/PoShPRTG/changelog.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI           = 'https://github.com/AndiBellstedt/PoShPRTG'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}