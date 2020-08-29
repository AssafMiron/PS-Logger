
# Get Debug / Verbose parameters for Script
$global:_InDebug = $False
$global:_InVerbose = $False
Function Set-DebugLogging
{
	param($ScriptBoundParameters)
	
	$global:_InDebug = $ScriptBoundParameters.Debug.IsPresent
	$global:_InVerbose = $ScriptBoundParameters.Verbose.IsPresent
	
	if($_InDebug) { Write-LogMessage -Type Debug -MSG "Running in Debug Mode" -LogFile $LOG_FILE_PATH }
	if($_InVerbose) { Write-LogMessage -Type Verbose -MSG "Running in Verbose Mode" -LogFile $LOG_FILE_PATH }
}
Export-ModuleMember -Function Set-DebugLogging

# ------ SET Files and Folders Paths ------
# Set Log file path
$global:LOG_FILE_PATH = $MyInvocation.ScriptName.Replace(".ps1",".log")
# @FUNCTION@ ======================================================================================================================
# Name...........: Set-LogFilePath
# Description....: Sets the log file name and path
# Parameters.....: New Log File path
# Return Values..: The Newly set Log file path
# =================================================================================================================================
Function Set-LogFilePath
{
<# 
.SYNOPSIS 
	Method to set the log file name and path
	
.PARAMETER LogFilePath
#>
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[Alias("Path")]
		[String]$LogFilePath
	)
	Set-Variable -Scope Global -Name LOG_FILE_PATH -Value $LogFilePath
	
	return $LOG_FILE_PATH
}
Export-ModuleMember -Function Set-LogFilePath

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-LogFilePath
# Description....: Gets the log file name and path
# Parameters.....: None
# Return Values..: The Log file path
# =================================================================================================================================
Function Get-LogFilePath
{
<# 
.SYNOPSIS 
	Method to get the log file name and path
#>
	param(
	)
		
	return $LOG_FILE_PATH
}
Export-ModuleMember -Function Get-LogFilePath

[string]$global:g_DateTimePattern = "$([System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentCulture.DateTimeFormat.LongTimePattern)"
# @FUNCTION@ ======================================================================================================================
# Name...........: Write-LogMessage
# Description....: Writes the message to log and screen
# Parameters.....: LogFile, MSG, (Switch)Header, (Switch)SubHeader, (Switch)Footer, Type
# Return Values..: None
# =================================================================================================================================
Function Write-LogMessage
{
<# 
.SYNOPSIS 
	Method to log a message on screen and in a log file
	
.DESCRIPTION
	Logging The input Message to the Screen and the Log File. 
	The Message Type is presented in colours on the screen based on the type

.PARAMETER LogFile
	The Log File to write to. By default using the LOG_FILE_PATH
.PARAMETER MSG
	The message to log
.PARAMETER Header
	Adding a header line before the message
.PARAMETER SubHeader
	Adding a Sub header line before the message
.PARAMETER Footer
	Adding a footer line after the message
.PARAMETER Type
	The type of the message to log (Info, Warning, Error, Debug)
.EXAMPLE
	Write-LogMessage -Type Info -Msg "Hello World!" -Header
	Write-LogMessage -Type Info -Msg "How are you?" -SubHeader
	Write-LogMessage -Type Info -Msg "I'm fine :)"
	Write-LogMessage -Type Warning -Msg "Wait, something is happening..."
	Write-LogMessage -Type Error -Msg "World! Something went wrong!"
	Write-LogMessage -Type Debug -Msg "Something happened, this is the reason..."
	Write-LogMessage -Type Info -Msg "Goodbye!" -Footer
#>
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[AllowEmptyString()]
		[String]$MSG,
		[Parameter(Mandatory=$false)]
		[Switch]$Header,
		[Parameter(Mandatory=$false)]
		[Switch]$SubHeader,
		[Parameter(Mandatory=$false)]
		[Switch]$Footer,
		[Parameter(Mandatory=$false)]
		[ValidateSet("Info","Warning","Error","Debug","Verbose")]
		[String]$type = "Info",
		[Parameter(Mandatory=$false)]
		[String]$LogFile = $LOG_FILE_PATH
	)
	Try{
		If ($Header) {
			"=======================================" | Out-File -Append -FilePath $LogFile 
			Write-Host "======================================="
		}
		ElseIf($SubHeader) { 
			"------------------------------------" | Out-File -Append -FilePath $LogFile 
			Write-Host "------------------------------------"
		}
		
		$msgToWrite = "[$((Get-Date -Format $g_DateTimePattern).Replace("/","-"))]`t"
		$writeToFile = $true
		# Replace empty message with 'N/A'
		if([string]::IsNullOrEmpty($Msg)) { $Msg = "N/A" }
		
		# Mask Passwords
		if($Msg -match '((?:"password":|password=|"secret":|"NewCredentials":|"credentials":)\s{0,}["]{0,})(?=([\w`~!@#$%^&*()-_\=\+\\\/|;:\.,\[\]{}]+))')
		{
			$Msg = $Msg.Replace($Matches[2],"****")
		}
		# Check the message type
		switch ($type)
		{
			"Info" { 
				Write-Host $MSG.ToString()
				$msgToWrite += "[INFO]`t$Msg"
			}
			"Warning" {
				Write-Host $MSG.ToString() -ForegroundColor DarkYellow
				$msgToWrite += "[WARNING]`t$Msg"
			}
			"Error" {
				Write-Host $MSG.ToString() -ForegroundColor Red
				$msgToWrite += "[ERROR]`t$Msg"
			}
			"Debug" { 
				if($_InDebug -or $_InVerbose)
				{
					Write-Debug $MSG
					$msgToWrite += "[DEBUG]`t$Msg"
				}
				else { $writeToFile = $False }
			}
			"Verbose" { 
				if($_InVerbose)
				{
					Write-Verbose -Msg $MSG
					$msgToWrite += "[VERBOSE]`t$Msg"
				}
				else { $writeToFile = $False }
			}
		}

		If($writeToFile) { $msgToWrite | Out-File -Append -FilePath $LogFile }
		If ($Footer) { 
			"=======================================" | Out-File -Append -FilePath $LogFile 
			Write-Host "======================================="
		}
	}
	catch{
		Throw $(New-Object System.Exception ("Cannot write message"),$_.Exception)
	}
}
Export-ModuleMember -Function Write-LogMessage

# @FUNCTION@ ======================================================================================================================
# Name...........: Join-ExceptionMessage
# Description....: Formats exception messages
# Parameters.....: Exception
# Return Values..: Formatted String of Exception messages
# =================================================================================================================================
Function Join-ExceptionMessage
{
<# 
.SYNOPSIS 
	Formats exception messages
.DESCRIPTION
	Formats exception messages
.PARAMETER Exception
	The Exception object to format
#>
	param(
		[Exception]$e
	)

	Begin {
	}
	Process {
		$msg = "Source:{0}; Message: {1}" -f $e.Source, $e.Message
		while ($e.InnerException) {
		  $e = $e.InnerException
		  $msg += "`n`t->Source:{0}; Message: {1}" -f $e.Source, $e.Message
		}
		return $msg
	}
	End {
	}
}
Export-ModuleMember -Function Join-ExceptionMessage