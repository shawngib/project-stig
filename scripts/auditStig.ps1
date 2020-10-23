Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192
$audit = Test-DscConfiguration -ComputerName localhost -ReferenceConfiguration "c:\localhost.mof" 
# Audit runtime
$TimeStampField = (Get-Date).ToString()

[xml] $STIGxml = Get-Content 'C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.5.1\StigData\Processed\WindowsServer-2019-MS-1.5.xml'
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

# Workspace ID - TestSubdeploy-eastusWS
$customerId = $env:WORKSPACE_ID

# Primary Key
$sharedKey = $env:WORKSPACE_KEY

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

$json = $computerJsonPayload | ConvertTo-Json

Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

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
            Computer = $computerInfo.Name
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
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonPayload)) -logType $stiglogType

$manual = @()
$jsonPayload = ""
foreach($manualRule in $STIGxml.DISASTIG.ManualRule.Rule)
{
     $object = @{
        Computer = $computerInfo.Name
        DesiredState = ""
        ResourceName = ""
        Type = "ManualRuleEntry"
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
    }
    $manual += $object
}
$jsonPayload = $manual | ConvertTo-Json
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonPayload)) -logType $stiglogType
