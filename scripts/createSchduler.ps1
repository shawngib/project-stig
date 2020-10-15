$STName = "PowerSTIG Audit Task"
$STPath = "\PowerSTIG"
$scheduleObject = New-Object -ComObject schedule.service
$scheduleObject.connect()
$taskRootFolder = $scheduleObject.GetFolder("\")
$taskRootFolder.CreateFolder($STPath)

$STDescription = "A task that will audit PowerSTIG DSC settings and report to Log Analytics."
$STAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\imageBuilder\auditStig.ps1"
$STTrigger = New-ScheduledTaskTrigger -Daily -At 12am
$STSettings = New-ScheduledTaskSettingsSet
$STUserName = "NT AUTHORITY\SYSTEM"
Register-ScheduledTask -TaskPath $STPath -TaskName $STName -Description $STDescription -Action $STAction -Trigger $STTrigger -RunLevel Highest -Settings $STSettings -User $STUserName 
Start-Sleep -Seconds 3

$STModify = Get-ScheduledTask -TaskName $STName
$STModify.Triggers.repetition.Duration = 'P1D'
$STModify.Triggers.repetition.Interval = 'PT20M'
$STModify | Set-ScheduledTask

# Unregister-ScheduledTask -TaskName $STName

# Get-WinEvent -ListLog * | ? logname -match task