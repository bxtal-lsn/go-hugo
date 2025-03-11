# NSSM Service Utility

**Deploy and run NSSM Service**

  

### About

  

Includes helper functions for the Windows Powershell to deploy and run a Windows Service, using the Non-Sucking Service Manager (NSSM) tool.

  

This tool is useful if running the application in a containerized environment is not possbile, i.e. a Windows Server which is most of the Sev infrastructure.
  

### Install

  

At the root of this repo, load the install.ps1 file to the current pwoershell terminal session

  

```powershell

. ./install.ps1

```

  

The installment requires a path to store the module and an optional path to write stdout logs.

Saving the installment to the default modules path will load the modules for every session

  

```powershell

# Users modulepath

$modulePath = $env:PSModulePath.Split(";")[0]

  

# Log folder

$stdoutPath = "C:/Temp/logs"

  

Install-NssmServiceUtility $modulePath $stdoutPath

```

  

Run the `Get-Command` cmdlet to confirm the install

  

```powershell

Get-Command -module NssmServiceUtility

  

#> CommandType     Name                            Version  

#> -----------     ----                            ----

#> Function        New-GolangAppNssmService        0.0  

#> Function        New-NssmService                 0.0  

#> Function        Test-NssmPath                   0.0  

```

  

### Requirements

  

NSSM executable must be available to the user running the commands and the path to this service must be set to the environment variable "PATH"

  

Run the following command to test the requirements

  

```powershell

Test-NssmPath

  

#> True

```

  

### Installing a service

  

Use `New-NssmService` to install a new service

  

```powershell

$logPath = (Resolve-Path "./logs/app.log").Path

New-NssmService `

    -ServiceName "Test App"  `

    -PathToExecutable "./app.exe"  `

    -ServiceParameters "-logpath=`"$logPath`" -env=`"DEV`""`

    -ServiceUser "user" `

    -ServiceUserPassword "wordpass" `

    -GrantUserAccess $true `

    -OverwriteService $true `

```

  

ServiceName and PathToExecutable are required. The rest is optional. If GranUserAccess is true,the user in ServiceUser will be given write access to the root folder of the executable (For logging) and execution permission on the executable.

  

OverwriteService will delete an existing service that matches the ServiceName before install a new one.

  

### Build, Install and run Golang app as a Service

  

`New-GolangAppNssmService` is a wrapper function that builds a go binary, installs a service and runs it in one command.

  

```powershell

New-GolangAppNssmService `

    -AppExecutableName "goapp.exe" `

    -AppDirectory "." `

    -ServiceName "GO Application Service" `

    -ServiceUser "user" `

    -ServiceUserPwd "ssapdrow" `

    -ServiceParameters "-config=`"C:\Temp\default.json`""

```
