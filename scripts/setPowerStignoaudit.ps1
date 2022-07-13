# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$path = "c:\imageBuilder"
$logFile = "$path\setupLog.txt"
function LogMessage
{
    param([string]$message)
    
    ((Get-Date).ToString() + " - " + $message) >> $logFile;
}

mkdir -Path $path
cd -Path $path

LogMessage -message "Starting setPowerStig.ps1"
Get-ExecutionPolicy -List >> $logFile

LogMessage -message "**** Retrieving computer info and env variables"
$computerInfo = Get-ComputerInfo
$powerStigVersion = $env:POWERSTIG_VER
$domainRole = $env:STIG_OSROLE
$windowsInstallationType = $computerInfo.WindowsInstallationType
$model = $env:STIG_OSVER
$stigVersion = $env:STIG_VER

LogMessage -message "**** Setting TLS"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
 if($windowsInstallationType -eq 'Client') 
 {
    LogMessage -message "**** Setting execution policy for client type"
    ### TODO: Potentially set to signed scripts only and sign scripts
    Set-ExecutionPolicy Unrestricted -Force 2>>$logFile # Windows 10 only
    Get-ExecutionPolicy -List >> $logFile
 }

LogMessage -message "**** Installing NuGet"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force  2>>$logFile
# Install/Import PowerStig
LogMessage -message "**** Installing PowerStig Module"
Install-Module PowerStig -RequiredVersion $powerStigVersion 2>>$logFile -Force

LogMessage -message "**** Installing additional PowerStig Module requirements"
(Get-Module PowerStig -ListAvailable).RequiredModules | % {
    $PSItem | Install-Module -Force 2>>$logFile
 }
LogMessage -message "**** Importing PowerStig Module"
Import-Module PowerStig -Force 2>>$logFile

# Enable WSMan / WinRm
LogMessage -message "**** Installing WSMAN, setting MaxEvelopeSize and disabling PSremoting"
Set-WSManQuickConfig -Force
Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192 # PowerSTIG DSC requires larger envelope size. 
#Disable-PSRemoting # PowerShell remoting required so disable it.

LogMessage -message "**** Running DscConfiguration and logging to verbose.txt"
$null = Start-DscConfiguration -Path "c:\" -Force -Wait -Verbose 4>&1 >> c:\imagebuilder\verbose.txt

LogMessage -message "**** Setting up logging to LA Workspace sender"
$TimeStampField = (Get-Date).ToString()
