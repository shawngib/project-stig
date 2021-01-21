# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$path = "c:\imageBuilder"
$logFile = "$path\setupLog.txt"
function LogMessage
{
    param([string]$message)
    
    ((Get-Date).ToString() + " - " + $message) >> $logFile;
}

# Using PowerShell New-Item asks permission, these command do not.
mkdir -Path $path
cd -Path $path

$computerInfo = Get-ComputerInfo
$powerStigVersion = $env:POWERSTIG_VER
$domainRole = $env:STIG_OSROLE
$windowsInstallationType = $computerInfo.WindowsInstallationType
$model = $env:STIG_OSVER
$stigVersion = $env:STIG_VER

LogMessage -message "Starting setPowerStig.ps1"

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install/Import PowerStig
LogMessage -message "**** Installing PowerStig Module"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module PowerStig -RequiredVersion $powerStigVersion -Force
#Install-Module ProcessMitigations -Force -SkipPublisherCheck
(Get-Module PowerStig -ListAvailable).RequiredModules | % {
    $PSItem | Install-Module -Force
 } 
 if((Get-ComputerInfo).WindowsInstallationType -eq 'Client') 
 {
    LogMessage -message "**** Setting execution policy"
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force # Windows 10 only
 }
LogMessage -message "**** Importing PowerStig Module"
Import-Module PowerStig -Force

# Enable WSMan / WinRm
LogMessage -message "**** Installing WSMAN, setting MaxEvelopeSize and disabling PSremoting"
Set-WSManQuickConfig -Force
Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192 # PowerSTIG DSC requires larger envelope size. 
#Disable-PSRemoting # PowerShell remoting required so disable it.

LogMessage -message "**** Running DscConfiguration Test"
$null = Start-DscConfiguration -Path "c:\" -Force -Wait -Verbose 4>&1 >> c:\imagebuilder\verbose.txt

LogMessage -message "**** Setting up logging to LA Workspace "
$TimeStampField = (Get-Date).ToString()

Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}
# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}

#$audit = Test-DscConfiguration -ComputerName localhost -ReferenceConfiguration "c:\localhost.mof"  -ErrorAction SilentlyContinue


# Workspace ID - TestSubdeploy-eastusWS
$customerId = $env:WORKSPACE_ID

# Primary Key
$sharedKey = $env:WORKSPACE_KEY

$LogType = "STIG_Compliance_Computer"

$computerJsonPayload = @{
    Computer = $computerInfo.CsName
    Manufacturer = $computerInfo.CsManufacturer
    Model = $computerInfo.CsModel
    PrimaryOwnerName = $computerInfo.CsPrimaryOwnerName
    DesiredState = $audit.InDesiredState
    Domain = $computerInfo.CsDomain
    Role = $computerInfo.CsDomainRole
    OS = $computerInfo.WindowsProductName
    OsVersion = $computerInfo.OsVersion
    PowerSTIG = $powerStigVersion
    STIGversion = $stigVersion
    STIGrole = $domainRole
}
$json = $computerJsonPayload | ConvertTo-Json
$json 4>&1 >> c:\imagebuilder\verbose.txt
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

# Setup scheduled task to run auditing script that reports to LA workspace
### TODO: Consider frequency requirements set here for every 20 minutes for testing but possibly should be simply daily. This also changes dashboard queries which limit to last 30 minutes.
$STName = "PowerSTIG Audit Task"
$STPath = "\PowerSTIG"
$scheduleObject = New-Object -ComObject schedule.service
$scheduleObject.connect()
$taskRootFolder = $scheduleObject.GetFolder("\")
$taskRootFolder.CreateFolder($STPath)

$STDescription = "A task that will audit PowerSTIG DSC settings and report to Log Analytics."
$STAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\auditStig.ps1"
$STTrigger = New-ScheduledTaskTrigger -Daily -At 12am
$STSettings = New-ScheduledTaskSettingsSet
$STUserName = "NT AUTHORITY\SYSTEM" # Try other well known NT AUTHORITY\SYSTEM, NT AUTHORITY\LOCALSERVICE, NT AUTHORITY\NETWORKSERVICE,
Register-ScheduledTask -TaskPath $STPath -TaskName $STName -Description $STDescription -Action $STAction -Trigger $STTrigger -RunLevel Highest -Settings $STSettings -User $STUserName 
Start-Sleep -Seconds 3

$STModify = Get-ScheduledTask -TaskName $STName
$STModify.Triggers.repetition.Duration = 'P1D'
$STModify.Triggers.repetition.Interval = 'PT20M'
$STModify | Set-ScheduledTask <#  #>