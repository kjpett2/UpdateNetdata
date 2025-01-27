
cd C:\Script\UpdateNetdata # change to the directory where this script is located

$netdataToken = "<CHANGE TO YOUR TOKEN>"
$netdataRoomId = "<CHANGE TO YOUR ROOM ID>"

$timestamp = "{0:yyyyMMdd}T{0:HHmmss}" -f (Get-Date)
$logFile = "log\\log_$timestamp.txt"
$installLogFile = "log\\installLog_$timestamp.txt"
New-Item -ItemType File -Path $logFile -Force -ErrorAction Stop
Set-Content -Path $logFile -Value "Log - $timestamp"

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
	Add-Content -Path $logFile -Value "Error: This script needs to be run As Admin."
	Write-Host "This script needs to be run As Admin."	
	Break
}

try {
	
	if (-not(Test-Path -Path version.txt))
	{
		Add-Content -Path $logFile -Value " - Version file not found. Trying to create it"
		New-Item -ItemType File -Path version.txt -Force -ErrorAction Stop
		Set-Content -Path version.txt -Value '0.0.0'
	}
	
	$version = (Invoke-RestMethod -uri https://api.github.com/repos/netdata/netdata/releases/latest).Tag_Name -replace 'v'
	Add-Content -Path $logFile -Value " - Latest version: $version"
	
	$oldVersion = Get-Content -Path version.txt -TotalCount 1
	Add-Content -Path $logFile -Value " - Old version: $oldVersion"
	
	if ([System.Version]$version -gt [System.Version]$oldVersion)
	{
		Add-Content -Path $logFile -Value " - Need to update"
		Write-Host "Need to update"
		
		Add-Content -Path $logFile -Value " - Downloading latest version"
		Write-Host "Downloading latest version"
		Invoke-WebRequest https://github.com/netdata/netdata/releases/latest/download/netdata-x64.msi -OutFile "netdata-x64.msi"; 
		
		Add-Content -Path $logFile -Value " - Installing latest version"
		Write-Host "Installing latest version"
		msiexec /l* $installLogFile /qn /i netdata-x64.msi TOKEN=$netdataToken ROOMS=$netdataRoomId | Out-Default
		
		$exitCode = $lastexitcode
		Write-Host $exitCode
		Add-Content -Path $logFile -Value " - Installation exit code: $exitCode"
		
		if ($exitCode -eq 0) {
			Add-Content -Path $logFile -Value " - Updating version file with latest version"
			Set-Content -Path version.txt -Value $version
		} else {		
			Add-Content -Path $logFile -Value " - Failed to update to latest version ($exitCode)"
		}
		
	} else {
		Add-Content -Path $logFile -Value " - Running the same or newer version"
		Write-Host "Running the same or newer version"
	}
} catch {
	Add-Content -Path $logFile -Value " - Error: $_.Exception.Message"
}
