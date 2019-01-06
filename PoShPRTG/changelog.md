# Changelog
# 1.6.0.0
- Upd: Refactoring module
    - Refactoring directory and file structure, to meet my current standard
    - Start to implement PSFramework module for logging purpose and maybe more
- Upd: Change variable scopes from "global" to "script"
    - PRTGServer, PRTGUser, PRTGPass, PRTGSensorTree
- Upd: Command Connect-PRTGServer
    - Implement new switch "DoNotQuerySensorTree" (alias 'QuickConnect', 'NoSensorTree') to allow faster connection to PRTG Server when only live queries are needed to do.
- Fix: Issue #1 - Set-PRTGObjectAlamAcknowledgement is missplelt
    - Rename command to "Set-PRTGObjectAlarmAcknowledgement" and set an alias for the wrong name to avoid bracking change

# 1.5.0.0 - Inital module release
Published Version 1.5.0.0 as the initial online available release of PoShPRTG