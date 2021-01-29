# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192

$TimeStampField = (Get-Date).ToString()

$computerInfo = Get-ComputerInfo
$instanceData = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri http://169.254.169.254/metadata/instance?api-version=2020-06-01
$powerStigVersion = $env:POWERSTIG_VER
$domainRole = $env:STIG_OSROLE
$windowsInstallationType = $computerInfo.WindowsInstallationType
$model = $env:STIG_OSVER
$stigVersion = $env:STIG_VER

If ($windowsInstallationType -eq 'Client')
{
    $xmlPathBuilder = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\$powerStigVersion\StigData\Processed\Windows$windowsInstallationType-$model-$stigVersion.xml"
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
}
Else
{
    $xmlPathBuilder = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\$powerStigVersion\StigData\Processed\Windows$windowsInstallationType-$model-$domainRole-$stigVersion.xml"
}
# Added this check for DSC current status to prevent from failing the audit and moving on only to report manual or document rules
### TODO: Needs a test for timing and break script and report failure
if((Get-DscLocalConfigurationManager).LCMState -eq "Busy") {
    do {
        start-sleep -s 10
        $dscState = (Get-DscLocalConfigurationManager).LCMState
    }until($dscState -ne "Busy")
}

# Audit runtime
### TODO: Audit should test current DSC LCM state and puase if processing another request. ex: 'Get-DscLocalConfigurationManager'
$audit = Test-DscConfiguration -ComputerName localhost -ReferenceConfiguration "c:\localhost.mof" 

[xml] $STIGxml = Get-Content $xmlPathBuilder
$xmlRules = $STIGxml.DISASTIG | Get-Member -MemberType Property | where-object Definition -Like 'System.Xml.XmlElement*'
$rules = @()
foreach($ruleType in $xmlRules.Name)
{
    foreach($rule in $STIGxml.DISASTIG.$ruleType.Rule)
    {
        $rules += $rule
    }
} 
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
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType, $resourceId)
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
        "x-ms-AzureResourceId" = $resourceId;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

# Workspace ID - TestSubdeploy-eastusWS
$customerId = $env:WORKSPACE_ID

# Primary Key
$sharedKey = $env:WORKSPACE_KEY

# Specify the name of the record type that you'll be creating
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
    TagsList = $instanceData.compute.tags
    SecureBoot = $instanceData.compute.securityProfile.secureBootEnabled
    TPM = $instanceData.compute.securityProfile.virtualTpmEnabled
}

$json = $computerJsonPayload | ConvertTo-Json

Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType -resourceId $instanceData.compute.resourceId

$LogType = "STIG_Compliance"
$findings = @()
$jsonPayload = ""
$findingTypes = @("ResourcesInDesiredState", "ResourcesNotInDesiredState")
foreach($findingType in $findingTypes)
{
    foreach($record in $audit.($findingType))
    {
        $object = @()
        $type = ""
        $findingId = ""
        $severity = ""
        $version = ""
        $ResourceID = ""
        $application = ""
        $note = ""

        $ResourceID = [regex]::Matches($record.ResourceId,'(?<=\[).+?(?=\])')
        
        if($ResourceID.Count -le 2)
        {
            try{
                if($record.ResourceId.Split("-")[4].Split(":")[0] -eq 'V')
                {
                    $findingId = "V-"+ $record.ResourceId.Split("-")[5].Split(":")[0]
                } else {
                    $findingId = "V-"+ $record.ResourceId.Split("-")[4].Split(":")[0]
                }                
            } catch {
                $findingId = "null"
            }
            $version = ""
            $baseline = $ResourceId[1].Value
            $application = $record.ResourceId.Split("]")[1].split("[")[0].Split("-")[0]
        } else { 
            $findingId = $ResourceID[1].Value -replace ":",""
            $severity = $ResourceID[2].Value
            $version = $ResourceID[3].Value
            $baseline = $ResourceID[4].Value
                    if($version -eq "[Skip") 
                    {
                        $ResourceID = [regex]::Matches(($record.ResourceId -replace "\[Skip\] ",""),'(?<=\[).+?(?=\])')
                        $note = "Skip"
                        $version = $ResourceID[3].Value
                        $baseline = $ResourceID[4].Value
                    }
                    if($version -eq "[Exception") 
                    {
                        $ResourceID = [regex]::Matches(($record.ResourceId -replace "\[Exception\] ",""),'(?<=\[).+?(?=\])')
                        $note = "Exception"
                        $version = $ResourceID[3].Value
                        $baseline = $ResourceID[4].Value
                    }
        }

        $object = @{
            Computer = $computerInfo.CsName
            DesiredState = $record.InDesiredState
            ResourceName = $record.ResourceName
            Type = $type
            FindingID = $findingId
            Severity = $severity
            Version = $version
            StartDate = $record.StartDate
            ModuleName = $record.ModuleName
            ModuleVersion = $record.ModuleVersion
            ConfigurationName = $record.ConfigurationName
            Error = $record.Error
            FinalState = $record.FinalState
            SourceInfo = $record.SourceInfo
            SetBy = "PowerSTIG"
            Baseline = $baseline
            Application = $application
            Description = ""
            Note = $note
            STIGversion = $stigVersion
        }
        $findings+= $object
    }

}
$allFindings = @()
foreach($trueFinding in $findings)
{
    $ruleFinding = $rules | where-object id -eq $trueFinding.FindingID
    if($ruleFinding)
    {
        $trueFinding.Severity = $ruleFinding.severity
        $trueFinding.Version = $ruleFinding.title
        $trueFinding.Type = $ruleFinding.dscresource
        $trueFinding.Description = $ruleFinding.PolicyName
        $allFindings += $trueFinding
    }   
}
$stiglogType = "STIG_Compliance"
$jsonPayload = $allFindings | ConvertTo-Json
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonPayload)) -logType $stiglogType -resourceId $instanceData.compute.resourceId


$object = $null
[nullable[bool]]$desiredState = $null
$manual = @()
$jsonPayload = ""
$findingRules = @("ManualRule", "DocumentRule")
foreach($findingRule in $findingRules)
{
    foreach($manualRule in $STIGxml.DISASTIG.($findingRule).Rule)
    {
         $object = @{
            Computer = $computerInfo.CsName
            DesiredState = $desiredState
            ResourceName = ""
            Type = $findingRule
            FindingID = $manualRule.id
            Severity = $manualRule.severity
            Version = $manualRule.title
            StartDate = ""
            ModuleName = ""
            ModuleVersion = ""
            ConfigurationName = ""
            Error = ""
            FinalState = ""
            SourceInfo = ""
            SetBy = "PowerSTIG"
            Baseline = ""
            Application = ""
            Description = ""
            Note = ""
            STIGversion = $stigVersion
        }
        $manual += $object
    }
}
$jsonPayload = $manual | ConvertTo-Json
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonPayload)) -logType $stiglogType -resourceId $instanceData.compute.resourceId

