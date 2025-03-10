# Cause

After a machine reboot, Docker Desktop Engine would not start and prompted a application error like this: 
```
wsl update failed: update failed: updating wsl: exit code: 4294967295: running WSL command wsl.exe C:\Windows\System32\wsl.exe --update --web-download: Downloading: Windows Subsystem for Linux

Installing: Windows Subsystem for Linux

The provided package is already installed, and reinstallation of the package was blocked. Check the AppXDeployment-Server event log for details.

: exit status 0xffffffff
```

Recommended course of action from docker desktop was to manually update wsl using `wsl --update` but this resulted in the cryptic error of `Catastrophic Failure`.

# Diagnosing the problem

All commands were run as Administrator, unless stated otherwise.
Trying to run `wsl --update --web-download` gives more information about what is causing the error. 

```
The provided package is already installed, and reinstallation of the package was blocked. Check the AppXDeployment-Server event log for details
```

The AppX logs can be accessed with this command `Get-AppxLog`

**Beware: AppX commands would not work on Powershell 7.4. Using the pre installed Windows Powershell did work however.**

Multiple entries were shown where the last entry showed this: 
```
AppX Deployment operation failed for package MicrosoftCorporationII.WindowsSubsystemForLinux_2.3.24.0_neutral_~_8wekyb3d8bbwe with error 0x80073D19. 
The specific error text for this failure is: Deployment of package
MicrosoftCorporationII.WindowsSubsystemForLinux_2.3.24.0_x64__8wekyb3d8bbwe was
blocked because the provided package has the same identity as an
already-installed package but the contents are different. Increment the version
number of the package to be installed, or remove the old package for every user
on the system before installing this package.
```

The problem is a faulty WSL installation on the wrong user.

# Solution

Easiest solution was to just completely remove and reinstall WSL again on the correct user.

All installations of the WSL can be listed using `Get-AppxPackage -AllUsers *WindowsSubsystemForLinux*`
This indeed showed a wsl installation for the non-administrator user of the machine.

An attempt to remove this installation using the Administrator account will fail. You must run the following command as the user which the WSL installation belongs to, to remove it.
`Get-AppxPackage -AllUsers *WindowsSubsystemForLinux* | Remove-AppxPackage -AllUsers`

Rerun the `Get-AppxPackage` command to see if removal was successful.
`Get-AppxPackage -AllUsers *WindowsSubsystemForLinux*` 

If it returns nothing, then no WSL installation is in the system.

For good measure Docker Desktop was uninstalled and then the `wsl --update --web-download` command was run. 

This returned the message `Windows Subsystem for Linux has been installed.` and running `wsl --status` confirmed the success with it returning `Default Version: 2`. 

*Docker Desktop Installer.exe* was then run as administrator. After installation, the application was started and the Docker Engine started successfully
