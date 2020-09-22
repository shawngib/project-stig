
# Download and extract Latest GPOs
$path = "c:\imageBuilder"
$stigGpoUrl = "https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/"
$file = "U_STIG_GPO_Package_July_2020.zip"
$lgpoUrl = "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip"

# Using PowerShell New-Item asks permission, these command do not.
mkdir -Path $path
cd -Path $path

# Get current GPO from web site and extract.
# TODO: Extract only required folders or files
Invoke-WebRequest -Uri ($stigGpoUrl + $file) -OutFile "gpo.zip"
Expand-Archive -Path "gpo.zip" -Force
del gpo.zip # cleanup

# Download and extract LGPO from Microsoft security tools.
Invoke-WebRequest -Uri $lgpoUrl -OutFile "lgpo.zip"
Add-Type -Assembly System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead("C:\imageBuilder\lgpo.zip") 
[System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip.Entries[0], "C:\imageBuilder\LGPO.exe", $true)
$zip.Dispose() # Need to dispose to release locks allow delete ;)
del lgpo.zip # cleanup

Get-Content -Path $path + "gpo"