# Creating a logging function to enter steps in the process are logged
$path = "c:\imageBuilder"
$logFile = "$path\setLgpoLog.txt"

# Using PowerShell New-Item asks permission, these command do not.
mkdir -Path $path
cd -Path $path

function psudo ([string]$cmd = "echo Hello!") {
    Start-Process -FilePath "powershell" -Verb RunAs -ArgumentList "-NoExit", $cmd
}
function LogMessage
{
    param([string]$message)
    
    ((Get-Date).ToString() + " - " + $message) >> $logFile;
}
LogMessage -message "Starting LGPO.ps1"
# STIGs to support - an array for now
$benchmarks = @("Windows 10","Windows Firewall","Office 2019-Office 365 Pro Plus", "Internet Explorer 11", "Google Chrome", "Windows Defender Antivirus STIG")
# Download and extract Latest GPOs
$stigGpoUrl = "https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/"
$file = "U_STIG_GPO_Package_July_2020.zip"
$lgpoUrl = "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip"

# Get current GPO from web site and extract.
# TODO: Extract only required folders or files
LogMessage -message "Downloading and extracting GPO from cyber.mil"
Invoke-WebRequest -Uri ($stigGpoUrl + $file) -OutFile "gpo.zip"
Expand-Archive -Path "gpo.zip" -Force
del gpo.zip # cleanup

# Download and extract LGPO from Microsoft security tools.
LogMessage -message "Downloading System Security Tool Set from MSFT and and extracting LGPO.exe."
Invoke-WebRequest -Uri $lgpoUrl -OutFile "lgpo.zip"
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead("C:\imageBuilder\lgpo.zip") 
[System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip.Entries[0], "C:\imageBuilder\LGPO.exe", $true)

LogMessage -message "Cleaning up"
$zip.Dispose() # Need to dispose to release locks allow delete ;)
del lgpo.zip # cleanup

# Back up existing GPO
LogMessage -message "Backing up group policy."
mkdir -Path "gpo_backup"
$cmd = ".\LGPO.exe" 
$prm = "/b", "$path\gpo_backup\"
LogMessage -message start-process $cmd $prm
start-process $cmd $prm -Verb runas
#Get-WmiObject Win32_useraccount | Where-Object {$_.SID -like '*-500'} | Select Name, Disabled
#Get-Content -Path $path + "gpo"

LogMessage -message "Loading group policy."
foreach($benchmark in $benchmarks){
   $dir = Get-ChildItem "c:\imageBuilder\gpo" -Filter "*$benchmark*" -Recurse -Directory 
 #  $prm = "/g", "$dir\GPOs"
   #start-process $cmd $prm -Verb runas
}

LogMessage -message "Errors generated from Script: `n ********************************************"

if($Error) {
    foreach($errors in $Error)
    {
        LogMessage -message $error
    }
}