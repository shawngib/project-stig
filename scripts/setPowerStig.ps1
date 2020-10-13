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
Install-Module ProcessMitigations -Force -SkipPublisherCheck
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
Start-DscConfiguration -Path "c:\" -Force -Wait -Verbose 4>&1 >> c:\imagebuilder\verbose.txt

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
# Specify the name of the record type that you'll be creating
$LogType = "STIG_Compliance_Computer"

$computerInfo = Get-WmiObject Win32_ComputerSystem

$computerJsonPayload = @{
    Computer = $computerInfo.Name
    Manufacturer = $computerInfo.Manufacturer
    Model = $computerInfo.Model
    PrimaryOwnerName = $computerInfo.PrimaryOwnerName
    DesiredState = $audit.InDesiredState
    Domain = $computerInfo.Domain
}
# Workspace ID - TestSubdeploy-eastusWS
$CustomerId = $env:WORKSPACE_ID
$CustomerId 4>&1 >> c:\imagebuilder\verbose.txt
# Primary Key
$SharedKey = $env:WORKSPACE_ID
$SharedKey 4>&1 >> c:\imagebuilder\verbose.txt
$json = $computerJsonPayload | ConvertTo-Json
$json 4>&1 >> c:\imagebuilder\verbose.txt
#Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

