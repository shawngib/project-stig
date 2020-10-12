# Creating a logging function to enter steps in the process are logged
$path = "c:\imageBuilder"
$logFile = "$path\setLgpoLog.txt"
function LogMessage
{
    param([string]$message)
    
    ((Get-Date).ToString() + " - " + $message) >> $logFile;
}

# Using PowerShell New-Item asks permission, these command do not.
mkdir -Path $path
cd -Path $path

LogMessage -message "Starting setPowerStig.ps1"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install/Import PowerStig
LogMessage -message "**** Installing PowerStig Module"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PowerStig -Force
Install-Module ProcessMitigations -Force
(Get-Module PowerStig -ListAvailable).RequiredModules | % {
    $PSItem | Install-Module -Force
 } 
LogMessage -message "**** Setting execution policy"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force # Windows 10 only
LogMessage -message "**** Importing PowerStig Module"
Import-Module PowerStig -Force

# Enable WSMan / WinRm
LogMessage -message "**** Installing WSMAN, setting MaxEvelopeSize and disabling PSremoting"
Set-WSManQuickConfig -Force
Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192 # PowerSTIG DSC requires larger envelope size. 
Disable-PSRemoting # PowerShell remoting required so disable it.

LogMessage -message "**** Running DscConfiguration Test"
$audit = Test-DscConfiguration -ComputerName localhost -ReferenceConfiguration "c:\localhost.mof"  -ErrorAction SilentlyContinue

if($audit){
    LogMessage -message "**** Resources in Desired State"
    $audit.ResourcesInDesiredState >> $logFile
    LogMessage -message "**** Resources not in Desired State"
    $audit.ResourcesNotInDesiredState >> $logFile
    #$winClientStigs = Get-Stig -Technology WindowsClient
} else {
    LogMessage -message "**** Audit returned no results. Check for error."
}
