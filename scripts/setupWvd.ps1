$ErroractionPreference='Stop'
New-Item -Path 'C:\temp' -ItemType Directory -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** INSTALL *** Install FSLogix ***'
# Note: Settings for FSLogix can be configured through GPO's)
Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile 'c:\temp\fslogix.zip'
Expand-Archive -Path 'C:\temp\fslogix.zip' -DestinationPath 'C:\temp\fslogix\'  -Force
Invoke-Expression -Command 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe /install /quiet /norestart'
Start-Sleep -Seconds 10

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** START OS CONFIG *** Update the recommended OS configuration ***'
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEY *** Disable Automatic Updates ***'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Value '1' -PropertyType DWORD -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEY *** Specify Start layout for Windows 10 PCs (optional) ***'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'SpecialRoamingOverrideAllowed' -Value '1' -PropertyType DWORD -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEY *** Set up time zone redirection ***'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -Name 'fEnableTimeZoneRedirection' -Value '1' -PropertyType DWORD -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEY *** Disable Storage Sense ***'
# reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 0 /f
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense' -Name 'AllowStorageSenseGlobal' -Value '0' -PropertyType DWORD -Force | Out-Null

# Note: Remove if not required!
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEY *** For feedback hub collection of telemetry data on Windows 10 Enterprise multi-session ***'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value '3' -PropertyType DWORD -Force | Out-Null

# Note: Remove if not required!
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEYS *** Fix 5k resolution support ***'
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'MaxMonitors' -Value '4' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'MaxXResolution' -Value '5120' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'MaxYResolution' -Value '2880' -PropertyType DWORD -Force | Out-Null
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs' -Name 'MaxMonitors' -Value '4' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs' -Name 'MaxXResolution' -Value '5120' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs' -Name 'MaxYResolution' -Value '2880' -PropertyType DWORD -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** SET OS REGKEY *** Temp fix for 20H1 SXS Bug ***'
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs' -Name 'fReverseConnectMode' -Value '1' -PropertyType DWORD -Force | Out-Null

# Note: It is recommended to set user settings through GPO's.
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** START OFFICE CONFIG *** Config the recommended Office configuration ***'
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG OFFICE Regkeys *** Mount default registry hive ***'
& REG LOAD HKLM\DEFAULT C:\Users\Default\NTUSER.DAT
Start-Sleep -Seconds 5
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG OFFICE *** Set InsiderslabBehavior ***'
New-Item -Path 'HKLM:\DEFAULT\SOFTWARE\Policies\Microsoft\office\16.0\common' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\DEFAULT\SOFTWARE\Policies\Microsoft\office\16.0\common' -Name 'InsiderSlabBehavior' -Value '2' -PropertyType DWORD -Force | Out-Null
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG OFFICE *** Set Outlooks Cached Exchange Mode behavior ***'
New-ItemProperty -Path 'HKLM:\DEFAULT\software\policies\microsoft\office\16.0\outlook\cached mode' -Name 'enable' -Value '1' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\DEFAULT\software\policies\microsoft\office\16.0\outlook\cached mode' -Name 'syncwindowsetting' -Value '1' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\DEFAULT\software\policies\microsoft\office\16.0\outlook\cached mode' -Name 'CalendarSyncWindowSetting' -Value '1' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\DEFAULT\software\policies\microsoft\office\16.0\outlook\cached mode' -Name 'CalendarSyncWindowSettingMonths' -Value '1' -PropertyType DWORD -Force | Out-Null
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG OFFICE Regkeys *** Un-mount default registry hive ***'
[GC]::Collect()
& REG UNLOAD HKLM\DEFAULT
Start-Sleep -Seconds 5

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG OFFICE Regkeys *** Set Office Update Notifiations behavior ***'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate' -Name 'hideupdatenotifications' -Value '1' -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate' -Name 'hideenabledisableupdates' -Value '1' -PropertyType DWORD -Force | Out-Null

# Note: When using the Marketplace Image for Windows 10 Enterprise Multu Session with Office Onedrive is already installed correctly (for 20H1). 
# Write-Host '*** WVD AIB CUSTOMIZER PHASE *** INSTALL ONEDRIVE *** Uninstall Ondrive per-user mode and Install OneDrive in per-machine mode ***'
# Invoke-WebRequest -Uri 'https://aka.ms/OneDriveWVD-Installer' -OutFile 'c:\temp\OneDriveSetup.exe'
# New-Item -Path 'HKLM:\Software\Microsoft\OneDrive' -Force | Out-Null
# Start-Sleep -Seconds 10
# Invoke-Expression -Command 'C:\temp\OneDriveSetup.exe /uninstall'
# New-ItemProperty -Path 'HKLM:\Software\Microsoft\OneDrive' -Name 'AllUsersInstall' -Value '1' -PropertyType DWORD -Force | Out-Null
# Start-Sleep -Seconds 10
# Invoke-Expression -Command 'C:\temp\OneDriveSetup.exe /allusers'
# Start-Sleep -Seconds 10
# Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG ONEDRIVE *** Configure OneDrive to start at sign in for all users. ***'
# New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDrive' -Value 'C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background' -Force | Out-Null
# Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG ONEDRIVE *** Silently configure user account ***'
# New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'SilentAccountConfig' -Value '1' -PropertyType DWORD -Force | Out-Null
# Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG ONEDRIVE *** Redirect and move Windows known folders to OneDrive by running the following command. ***'
# New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive' -Name 'KFMSilentOptIn' -Value $AADTenantID -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** INSTALL *** Install C++ Redist for RTCSvc (Teams Optimized) ***'
Invoke-WebRequest -Uri 'https://aka.ms/vs/16/release/vc_redist.x64.exe' -OutFile 'c:\temp\vc_redist.x64.exe'
Invoke-Expression -Command 'C:\temp\vc_redist.x64.exe /install /quiet /norestart'
Start-Sleep -Seconds 15

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** INSTALL *** Install RTCWebsocket to optimize Teams for WVD ***'
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Teams' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Teams' -Name 'IsWVDEnvironment' -Value '1' -PropertyType DWORD -Force | Out-Null
Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4vkL6' -OutFile 'c:\temp\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi' 
Invoke-Expression -Command 'msiexec /i c:\temp\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi /quiet /l*v C:\temp\MsRdcWebRTCSvc_HostSetup.log ALLUSER=1'
Start-Sleep -Seconds 15

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** INSTALL *** Install Teams in Machine mode ***'
Invoke-WebRequest -Uri 'https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.4461/Teams_windows_x64.msi' -OutFile 'c:\temp\Teams.msi'
Invoke-Expression -Command 'msiexec /i C:\temp\Teams.msi /quiet /l*v C:\temp\teamsinstall.log ALLUSER=1 ALLUSERS=1'
Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG TEAMS *** Configure Teams to start at sign in for all users. ***'
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run -Name Teams -PropertyType Binary -Value ([byte[]](0x01,0x00,0x00,0x00,0x1a,0x19,0xc3,0xb9,0x62,0x69,0xd5,0x01)) -Force
Start-Sleep -Seconds 30

Write-Host '*** WVD AIB CUSTOMIZER PHASE *** CONFIG *** Deleting temp folder. ***'
Get-ChildItem -Path 'C:\temp' -Recurse | Remove-Item -Recurse -Force
Remove-Item -Path 'C:\temp' -Force | Out-Null

Write-Host '*** WVD AIB CUSTOMIZER PHASE ********************* END *************************'