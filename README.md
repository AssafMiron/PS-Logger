# PS-Logger
A Powershell module for logging any Powershell script
Simply import this module at the beginning of any of your Powershell scripts and use the methods to log anything easily.

## Main abilities
- Print a nice Header, Sub header and Footer lines
- Capture Debug and Verbose messages
- Capture Exception messages (even chained exceptions caused by other methods)

## Available Methods
- Set-DebugLogging
    * Set the debug Logging from the Script parameters
- Get-LogFilePath
	* Get the current Log File Path
	* By default, using the Script name (with '.log' extension)
- Set-LogFilePath
	* Set the Log File Path
- Write-LogMessage
	* Write a log message in different Logging Types (Info, Warning, Error, Debug, Verbose)
- Join-ExceptionMessage
	* In case of an exception, use this method to capture all exceptions that happened in that call

## Usage Examples
### Write Info and Debug messages
Script example:
```powershell
[CmdletBinding(DefaultParameterSetName="")]
param
()

# Import the PS-Logger to the script
Import-Module .\PS-Logger -Debug:$False -Verbose:$False
# Set the debug logging (if needed)
Set-DebugLogging -ScriptBoundParameters $PSBoundParameters

# Script Version
$ScriptVersion = "1.0"

Write-LogMessage -Type Info -MSG "Starting script (v$ScriptVersion)" -Header
Write-LogMessage -Type Debug -MSG "Running PowerShell version $($PSVersionTable.PSVersion.Major) compatible of versions $($PSVersionTable.PSCompatibleVersions -join ", ")" -LogFile $LOG_FILE_PATH
$machineName = $ENV:ComputerName
Write-LogMessage -Type Debug -MSG "Machine Name: $machineName"
$revMachineName = $machineName.ToCharArray()
[array]::Reverse($revMachineName)
$revMachineName = -Join($revMachineName)

Write-LogMessage -Type Warning -MSG "Reversing Machine name ($machineName)..."
Write-LogMessage -Type Info -MSG "Reversed Machine name: $revMachineName"

Write-LogMessage -Type Info -MSG "Script ended" -Footer
Remove-Module PS-Logger -Debug:$False -Verbose:$False
```

On screen:
```batch
PS C:\Temp> .\temp.ps1 -Debug -Verbose
=======================================
Starting script (v1.0)
Reversing Machine name (VM-A9B0F407)...
Reverse Machine name: 704F0B9A-MV
Script ended
=======================================
```

Log file:
```text
[2020-08-16 01:58:25]	[DEBUG] Running in Debug Mode
[2020-08-16 01:58:25]	[VERBOSE]   Running in Verbose Mode
=======================================
[2020-08-16 01:58:25]	[INFO]	Starting script (v1.0)
[2020-08-16 01:58:25]	[DEBUG]	Running PowerShell version 5 compatible of versions 1.0, 2.0, 3.0, 4.0, 5.0, 5.1.14393.1944
[2020-08-16 01:58:25]	[DEBUG]	Machine Name: VM-A9B0F407
[2020-08-16 01:58:25]	[WARNING]	Reversing Machine name (VM-A9B0F407)...
[2020-08-16 01:58:25]	[INFO]	Reverse Machine name: 704F0B9A-MV
[2020-08-16 01:58:25]	[INFO]	Script ended
=======================================
```

### Write Errors
Script example:
```powershell
[CmdletBinding(DefaultParameterSetName="")]
param
()

# Import the PS-Logger to the script
Import-Module .\PS-Logger
Set-DebugLogging -ScriptBoundParameters $PSBoundParameters

try{
	try{
		Write-LogMessage -Type Info "Starting to throw errors..."
		Throw "This is the first Error!"
	}
	catch{
		Throw $(New-Object System.Exception ("Throwing a second error with the previous exception"),$_.Exception)
	}
}
catch{
	Write-LogMessage -Type Error -Msg "There was a script error.`nError Details:`n $(Join-ExceptionMessage $_.Exception)"
}
Write-LogMessage -Type Info -MSG "Script ended" -Footer
Remove-Module PS-Logger
```

On screen:
```batch
PS C:\Temp> .\temp.ps1
Starting to throw errors...
There was a script error.
Error Details:
 Source:; Message: Throwing a second error with the previous exception
        ->Source:; Message: This is the first Error!
Script ended
=======================================
```

Log file:
```text
[2020-08-16 03:04:38]	[INFO]	Starting to throw errors...
[2020-08-16 03:04:38]	[ERROR]	There was a script error.
Error Details:
 Source:; Message: Throwing a second error with the previous exception
	->Source:; Message: This is the first Error!
[2020-08-16 03:04:38]	[INFO]	Script ended
=======================================
```