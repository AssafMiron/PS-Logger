# Get Debug / Verbose parameters for Script
$global:_InDebug = $False
$global:_InVerbose = $False

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-DebugLogging
# Description....: Sets the relevant debugging level
# Parameters.....: The Script bound parameters
# Return Values..: None
# =================================================================================================================================
Function Set-DebugLogging
{
	param($ScriptBoundParameters)
	
	$global:_InDebug = $ScriptBoundParameters.Debug.IsPresent
	$global:_InVerbose = $ScriptBoundParameters.Verbose.IsPresent
	
	if ($_InDebug) { Write-LogMessage -Type Debug -MSG "Running in Debug Mode" -LogFile $LOG_FILE_PATH }
	if ($_InVerbose) { Write-LogMessage -Type Verbose -MSG "Running in Verbose Mode" -LogFile $LOG_FILE_PATH }
}
Export-ModuleMember -Function Set-DebugLogging

# ------ SET Files and Folders Paths ------
# Set Log file path
$global:LOG_FILE_PATH = $MyInvocation.ScriptName.Replace(".ps1", ".log")
$global:SCRIPT_PATH = Split-Path -Path $MyInvocation.ScriptName -Parent

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
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
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
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[AllowEmptyString()]
		[String]$MSG,
		[Parameter(Mandatory = $false)]
		[Switch]$Header,
		[Parameter(Mandatory = $false)]
		[Switch]$SubHeader,
		[Parameter(Mandatory = $false)]
		[Switch]$Footer,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Info", "Warning", "Error", "Debug", "Verbose")]
		[String]$type = "Info",
		[Parameter(Mandatory = $false)]
		[String]$LogFile = $LOG_FILE_PATH
	)
	Try
	{
		If ($Header)
		{
			"=======================================" | Out-File -Append -FilePath $LogFile 
			Write-Host "======================================="
		}
		ElseIf ($SubHeader)
		{ 
			"------------------------------------" | Out-File -Append -FilePath $LogFile 
			Write-Host "------------------------------------"
		}
		
		$msgToWrite = "[$(Get-Date -Format "yyyy-MM-dd hh:mm:ss")]`t"
		$writeToFile = $true
		# Replace empty message with 'N/A'
		if ([string]::IsNullOrEmpty($Msg)) { $Msg = "N/A" }
		
		# Mask Passwords
        $maskingPattern = '(?:(?:["\s\/\\](password|secret|NewCredentials|credentials|answer)(?!s))\s{0,}["\:= ]{1,}\s{0,}["]{0,})(?=([\w`~!@#$%^&*()\-_\=\+\\\/\|\,\;\:\.\[\]\{\}]+))'
        $maskingResult = $Msg | Select-String $maskingPattern -AllMatches
        if ($maskingResult.Matches.Count -gt 0)
        {
            foreach ($item in $maskingResult.Matches)
            {
                if ($item.Success)
                {
                    # Avoid replacing a single comma, space or semi-colon 
                    if($item.Groups[2].Value -NotMatch '^(,| |;)$')
                    {
                        $Msg = $Msg.Replace($item.Groups[2].Value, "****")
                    }
                }
            }
        }
		# Check the message type
		switch ($type)
		{
			"Info"
   			{ 
				Write-Host $MSG.ToString()
				$msgToWrite += "[INFO]`t$Msg"
			}
			"Warning"
			{
				Write-Host $MSG.ToString() -ForegroundColor DarkYellow
				$msgToWrite += "[WARNING]`t$Msg"
			}
			"Error"
			{
				Write-Host $MSG.ToString() -ForegroundColor Red
				$msgToWrite += "[ERROR]`t$Msg"
			}
			"Debug"
			{ 
				if ($_InDebug -or $_InVerbose)
				{
					Write-Debug $MSG
					$msgToWrite += "[DEBUG]`t$Msg"
				}
				else { $writeToFile = $False }
			}
			"Verbose"
			{ 
				if ($_InVerbose)
				{
					Write-Verbose -Msg $MSG
					$msgToWrite += "[VERBOSE]`t$Msg"
				}
				else { $writeToFile = $False }
			}
		}

		If ($writeToFile) { $msgToWrite | Out-File -Append -FilePath $LogFile }
		If ($Footer)
		{ 
			"=======================================" | Out-File -Append -FilePath $LogFile 
			Write-Host "======================================="
		}
	}
	catch
	{
		Throw $(New-Object System.Exception ("Cannot write message"), $_.Exception)
	}
}
Export-ModuleMember -Function Write-LogMessage

# @FUNCTION@ ======================================================================================================================
# Name...........: Write-LocalizedMessage
# Description....: Writes a localized message to log and screen
# Parameters.....: LogFile, MSG ID, (Switch)Header, (Switch)SubHeader, (Switch)Footer, Type
# Return Values..: None
# =================================================================================================================================
Function Write-LocalizedMessage
{
	<# 
.SYNOPSIS 
	Method to log a localized message on screen and in a log file
	
.DESCRIPTION
	Logging The input Message ID in the relevant selected localization to the Screen and the Log File. 
	The Message Type is presented in colours on the screen based on the type
	This method uses the Write-LogMessage function

.PARAMETER LogFile
	The Log File to write to. By default using the LOG_FILE_PATH
.PARAMETER MSGID
	The localized message ID to log
.PARAMETER Header
	Adding a header line before the message
.PARAMETER SubHeader
	Adding a Sub header line before the message
.PARAMETER Footer
	Adding a footer line after the message
.PARAMETER Type
	The type of the message to log (Info, Warning, Error, Debug)
.EXAMPLE
	Write-LocalizedMessage -Type Info -MsgID "Hello_World!"
	>When in English localization:
	Hello World!
	>When in Spanish localization:
	Hola Mundo!
	>When in German localization:
	Hallo Welt!
#>
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[AllowEmptyString()]
		[String]$MSGID,
		[Parameter(Mandatory = $false)]
		[Switch]$Header,
		[Parameter(Mandatory = $false)]
		[Switch]$SubHeader,
		[Parameter(Mandatory = $false)]
		[Switch]$Footer,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Info", "Warning", "Error", "Debug", "Verbose")]
		[String]$type = "Info",
		[Parameter(Mandatory = $false)]
		[String]$LogFile = $LOG_FILE_PATH
	)
	try
 {
		Write-LogMessage -Type $Type -Header:$Header -SubHeader:$SubHeader -Footer:$Footer -LogFile $LogFile -Msg $(Get-LocalizedMessage -id $MSGID)
	}
	catch
	{
		Throw $(New-Object System.Exception ("Cannot write localized message"), $_.Exception)
	}
}
Export-ModuleMember -Function Write-LocalizedMessage

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

	Begin
	{
	}
	Process
	{
		$msg = "Source:{0}; Message: {1}" -f $e.Source, $e.Message
		while ($e.InnerException)
		{
			$e = $e.InnerException
			$msg += "`n`t->Source:{0}; Message: {1}" -f $e.Source, $e.Message
		}
		return $msg
	}
	End
	{
	}
}
Export-ModuleMember -Function Join-ExceptionMessage

#region localization
$script:m_CultureID = $null
$script:m_ResourceFile = $null
$script:m_ResourceFolder = $null
$script:m_Script_Resources = $null

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-ResourceCulture
# Description....: Gets the current resource culture
# Parameters.....: None
# Return Values..: The current resource culture
# =================================================================================================================================
Function Get-ResourceCulture
{
	<# 
.SYNOPSIS 
	Returns the current culture ID
.DESCRIPTION
	Returns the current culture ID
#>
	return $m_CultureID
}
Export-ModuleMember -Function Get-ResourceCulture

# @FUNCTION@ ======================================================================================================================
# Name...........: Set-ResourceCulture
# Description....: Sets the Resource Culture ID, file name and base folder path
# Parameters.....: CultureID, ResourceFolderPath, ResourceFile
# Return Values..: None
# =================================================================================================================================
Function Set-ResourceCulture
{
	<# 
.SYNOPSIS 
	Sets the culture ID for the localized messages
.DESCRIPTION
	Sets the culture ID for the localized messages
.PARAMETER CultureID
	The Culture ID to use. Can be set as a high level language (for example: en) or using a specific culture (for example: en-US)	
.PARAMETER ResourceFolderPath
	(Optional)Set the folder location where the culture resource folders are
	If not entered, the current script path will be used
.PARAMETER ResourceFile
	(Optional)Sets the name of the resource file to be used
	If not entered, the default is Resources.psd1
	Files must be with *.psd1 extension	
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)]
		[string]$CultureID = $PSUICulture,
		[Parameter(Mandatory = $False)]
		[string]$ResourceFolderPath = $SCRIPT_PATH,
		[Parameter(Mandatory = $False)]
		[ValidateScript({
				If (![string]::IsNullOrEmpty($_))
				{
					$_ -like "*.psd1"
				}
				Else { $true }
			})]
		[String]$ResourceFile = "Resources.psd1"
	)
	try
	{
		# Check that the input Culture ID is valid
		If ($null -eq ([System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) | Where-Object { $_.Name -like "*$CultureID*" }))
		{
			Throw "Invalid Culture ID '$CultureID'"
		}
			
		# Save the details in relevant script properties
		Set-Variable -Scope Script -Name m_CultureID -Value $CultureID
		Set-Variable -Scope Script -Name m_ResourceFile -Value $ResourceFile
		Set-Variable -Scope Script -Name m_ResourceFolder -Value $ResourceFolderPath
		# Clear the resource variable
		Set-Variable -Scope Script -Name m_Script_Resources -Value $null
	}
	catch
	{
		Throw $(New-Object System.Exception ("There was an error setting culture resource for '$CultureID'.", $_.Exception))
	}
}
Export-ModuleMember -Function Set-ResourceCulture

# @FUNCTION@ ======================================================================================================================
# Name...........: Get-LocalizedMessage
# Description....: Gets the localized message
# Parameters.....: The Message ID
# Return Values..: The localized message
# =================================================================================================================================
Function Get-LocalizedMessage
{
	<# 
.SYNOPSIS 
	Returns the localized message
.DESCRIPTION
	Returns the localized message based on input Message ID
.PARAMETER ID
	The Message ID to use
#>	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[String]$ID
	)
	try
	{
		if ($null -eq $m_Script_Resources)
		{
			Import-ScriptResources
		}
		$resourceString = $null
	
		if ($null -ne $m_Script_Resources -and $null -ne $m_Script_Resources[$ID])
		{
			$resourceString = $m_Script_Resources[$ID]
		}
		else
		{
			Throw "There is no resource ID '$ID' in the selected localization '$(Get-ResourceCulture)'"
		}
	}
 catch
	{
		Throw $(New-Object System.Exception ("There was an error getting the localized message for '$ID'.", $_.Exception))
	}

	return $resourceString
}

# @FUNCTION@ ======================================================================================================================
# Name...........: Import-ScriptResources
# Description....: Imports the selected culture script resources
# Parameters.....: None
# Return Values..: None
# =================================================================================================================================
Function Import-ScriptResources
{
	<# 
.SYNOPSIS 
	Imports the relevant localized resource file
.DESCRIPTION
	Imports the resource file of the selected resource culture from the base resource folder
	Using the parameters entered in Set-ResourceCulture, running Set-ResourceCulture is a prerequisite for running this function
#>
	# Using a local variable _Script_Resources
	try
	{
		If ($null -ne $m_ResourceFile -and $null -ne $m_ResourceFolder)
		{
			Import-LocalizedData -BindingVariable _Script_Resources -FileName $m_ResourceFile -UICulture $(Get-ResourceCulture) -BaseDirectory $m_ResourceFolder -ErrorAction SilentlyContinue
			If ($null -eq $_Script_Resources)
			{
				Throw $Error[0].Exception.Message
			}
		}
		else
		{
			Throw "Run the Set-ResourceCulture function first"
		}
	}
 catch
	{
		Throw $(New-Object System.Exception ("Cannot import '$(Get-ResourceCulture)' culture resource.", $_.Exception))
	}
 finally
	{
		Set-Variable -Name m_Script_Resources -Scope Script -Value $_Script_Resources
	}
}
#endregion