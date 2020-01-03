# Cleanup Bloat from AMD Radeon Drivers
# https://github.com/GSDragoon/RadeonSoftwarePostInstallDebloat

# Need to run as Admin, self-elevate the script, if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath "powershell.exe" -Verb Runas -ArgumentList $CommandLine
  Exit
}

# Echos commands as they run
Set-PSDebug -Trace 1


# End the existing Radeon Software and other Radeon Settings processes
Write-Host "Exiting Radeon Software"
Start-Process -FilePath "C:\Program Files\AMD\CNext\CNext\cncmd.exe" -ArgumentList 'exit' -Wait

# NT Services - Stop and disable them
Write-Host "Stopping and Disabling NT Services"
# AMD User Experience Program Launcher (https://www.amd.com/en/corporate/amd-user-experience)
if (Get-Service -Name "AUEPLauncher" -ErrorAction SilentlyContinue)
{
	Stop-Service -Name "AUEPLauncher"
	Set-Service -Name "AUEPLauncher" -StartupType Disabled
}
# AMD External Events Utility (probably want this one)
if (Get-Service -Name "AMD External Events Utility" -ErrorAction SilentlyContinue)
{
	# Probably want this service running
	#Stop-Service -Name "AMD External Events Utility"
	#Set-Service -Name "AMD External Events Utility" -StartupType Disabled
}

# Scheduled Tasks - End and disable them
Write-Host "Ending and Disabling Scheduled Tasks"
# AMDInstallLauncher - Installs AMD User Experience Program (https://www.amd.com/en/corporate/amd-user-experience)
#Start-Process -FilePath "$env:systemroot\system32\schtasks.exe" -ArgumentList '/End /TN "AMDInstallLauncher"' -Wait
#Start-Process -FilePath "$env:systemroot\system32\schtasks.exe" -ArgumentList '/Change /TN "AMDInstallLauncher" /DISABLE' -Wait
.\schtasks.exe /End /TN "AMDInstallLauncher"
.\schtasks.exe /Change /TN "AMDInstallLauncher" /DISABLE
# AMDLinkUpdate - AMD Link Update
.\schtasks.exe /End /TN "AMDLinkUpdate"
.\schtasks.exe /Change /TN "AMDLinkUpdate" /DISABLE
# ModifyLinkUpdate - AMD Link Update Current User
.\schtasks.exe /End /TN "ModifyLinkUpdate"
.\schtasks.exe /Change /TN "ModifyLinkUpdate" /DISABLE
# StartCN - Starts the main RadeonSoftware process, probably want this one
#.\schtasks.exe /End /TN "StartCN"
#.\schtasks.exe /Change /TN "StartCN" /DISABLE
# StartDVR - Radeon Settings Host Service and Radeon Settings Desktop Overlay. For virtual reality devices?
.\schtasks.exe /End /TN "StartDVR"
.\schtasks.exe /Change /TN "StartDVR" /DISABLE

# Uninstall AMD WVR64 (Virtual reality stuff)
Write-Host "Uninstalling AMD WVR64"
# TODO: Look this up in the registry in case the GUID changes?
Start-Process -FilePath "$env:systemroot\system32\msiexec.exe" -ArgumentList '/uninstall "{284967ee-7da2-4fc6-b14a-361266a50448}" /quiet' -Wait
# msiexec.exe /uninstall "{284967ee-7da2-4fc6-b14a-361266a50448}" /quiet

# Rename RSServCmd.exe so it doesn't run when RadeonSoftware.exe runs
# RSServCmd starts the Radeon Settings: Host Service (AMDRSServ.exe) and Radeon Settings: Desktop Overlay (amdow.exe) processes, and probably more depending on the system
Write-Host "Renaming RSServCmd to prevent RadeonSoftware from running additional processes"
if (Test-Path -Path "C:\Program Files\AMD\CNext\CNext\RSServCmd.exe")
{
	# Support being able to run this multiple times without issues
	# If both the original file and the renamed one exist (such as from a new driver install), then delte the old renamed file first (the rename will fail if it already exists)
	if (Test-Path -Path "C:\Program Files\AMD\CNext\CNext\RSServCmd.exe.ChangedToNotRun")
	{	
		Remove-Item -Path "C:\Program Files\AMD\CNext\CNext\RSServCmd.exe.ChangedToNotRun"
	}
	
	Rename-Item -Path "C:\Program Files\AMD\CNext\CNext\RSServCmd.exe" -NewName "RSServCmd.exe.ChangedToNotRun"
}

# Prompt to restart computer when done
Set-PSDebug -Trace 0
Write-Host "Complete. Press any key to reboot."
pause
Restart-Computer
# Restart-Computer -Confirm
