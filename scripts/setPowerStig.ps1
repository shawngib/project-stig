# Install/Import PowerStig
Install-Module -Name PowerStig -force
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force # Windows 10 only
 Import-Module PowerStig -Force

# Enable WSMan / WinRm
Test-WSMan
Set-WSManQuickConfig -Force
Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192 # PowerSTIG DSC requires larger envelope size. TODO: get correct size
Disable-PSRemoting # PowerShell remoting required so disable it.

$audit = Test-DscConfiguration -ComputerName localhost -ReferenceConfiguration "\\tsclient\F\OneDrive\OneDrive - Microsoft\GitHub\project-stig\scripts\localhost.mof"

$winClientStigs = Get-Stig -Technology WindowsClient
