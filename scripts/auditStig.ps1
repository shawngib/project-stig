Set-Item -Path WSMan:\localhost\MaxEnvelopeSizekb -Value 8192
$audit = Test-DscConfiguration -ComputerName localhost -ReferenceConfiguration "c:\localhost.mof"  -ErrorAction SilentlyContinue
# Audit runtime
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

# Specify the name of the record type that you'll be creating
$LogType = "STIG_Compliance_STIG"

$jsonPayload = ""

$findings = @()
foreach($record in $audit.ResourcesInDesiredState)
{
    $object = @()
    $type = ""
    $findingId = ""
    $severity = ""
    $version = ""
    $ResourceID = ""
    $

    $ResourceID = [regex]::Matches($record.ResourceId,'(?<=\[).+?(?=\])')
    
   

    if($ResourceID.Count -le 2) # EX: [ProcessMitigation]iexplore.exe-ASLR-ForceRelocateImages-V-77217.b::[WindowsClient]BaseLine
    {
        # Finishing parsing application specific stuff
        try{
            $findingId = "V-"+ ($record.ResourceId.Split("]")[1].split("[")[0].Split("-")[4]) # removed .Split(".")[0] to get .a or .b ect.
        } catch {
            $findingId = "null"
        }
        $version = $record.ResourceId.Split("]")[1].split("[")[0].Split("-")[0]
        $baseline = $ResourceId[1].Value

    } else { # EX [SecurityOption][V-63611][medium][WN10-SO-000010]::[WindowsClient]BaseLine
        $findingId = $ResourceID[1].Value.Split(".")[0] 
        $severity = $ResourceID[2].Value
        $version = $ResourceID[3].Value
    }
    if($version -eq "[Skip")
    {
        $version = "" # TODO: get data from XML and add to telemetry
        $type = "Skip"
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
    }
    $findings+= $object

}

$stiglogType = "STIG_Compliance"
$jsonPayload = $findings | ConvertTo-Json
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonPayload)) -logType $stiglogType

$notfindings = @()
foreach($record in $audit.ResourcesNotInDesiredState)
{
    $object = @()
    $type = ""
    $findingId = ""
    $severity = ""
    $version = ""
    $ResourceID = ""

    $ResourceID = [regex]::Matches($record.ResourceId,'(?<=\[).+?(?=\])')
    
    $type = $ResourceID[0].Value

    if($ResourceID.Count -le 2) # EX: [ProcessMitigation]iexplore.exe-ASLR-ForceRelocateImages-V-77217.b::[WindowsClient]BaseLine
    {
        # Finishing parsing application specific stuff
        try{
            $findingId = "V-"+ ($record.ResourceId.Split("]")[1].split("[")[0].Split("-")[4].Split(".")[0])
        } catch {
            $findingId = "null"
        }
        $version = $record.ResourceId.Split("]")[1].split("[")[0].Split("-")[0]
        $baseline = $ResourceId[1].Value

    } else { # EX [SecurityOption][V-63611][medium][WN10-SO-000010]::[WindowsClient]BaseLine
        $findingId = $ResourceID[1].Value.Split(".")[0] 
        $severity = $ResourceID[2].Value
        $version = $ResourceID[3].Value
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
    }
    $notfindings+= $object

}
$stiglogType = "STIG_Compliance"
$jsonPayload = $notfindings | ConvertTo-Json
Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonPayload)) -logType $stiglogType
