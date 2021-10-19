[CmdletBinding()]
param()

$SCRIPT_LOCATION = $(Split-Path -Parent $MyInvocation.InvocationName)
try
{
    Import-Module -Name .\PS-Logger\PS-Logger.psd1
    if(Get-Command "Write-LogMessage")
    {
        # Set the relevant debugging level based on the Script Common Parameters
        Set-DebugLogging $PSBoundParameters
        # Write a debug message that the module loaded successfully
        Write-LogMessage -Type Debug -Msg "PS-Logger Module loaded successfully"
    }
    else {
        throw "PS-Logger Module did not load"
    }
}
catch
{
    Write-Error $_.Exception.Message
    return
}

# ---- Start script ----
Write-LogMessage -Type Info -Header -Msg "Write messages (Testing PS-Logger module)"

$secretMessage = @"
This will show how a message that can contain passwords and secrets will be masked.
{
    user:MyUser,
    password:MyV4ry`$ecuredP@s`$w0rd1"
}
"@

Write-LogMessage -Type Info -Msg $secretMessage

try
{
    # Changing to German localization to write German Messages
    Write-LogMessage -Type Verbose "Changing Messages to German (DE)"
    Set-ResourceCulture -CultureID "de" -ResourceFile "Resources.psd1" -ResourceFolderPath $SCRIPT_LOCATION
    Write-LocalizedMessage -type Info -MSGID "Msg1"
    Write-LocalizedMessage -type Info -MSGID "Msg2"
    Write-LocalizedMessage -type Info -MSGID "Msg3.1"
}
catch
{
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

try
{
    # Changing to a non-existing culture
    Write-LogMessage -Type Verbose "Changing Messages to a culture that does not exit (ZE) - expecting to fail"
    Set-ResourceCulture -CultureID "ze" -ResourceFile "Resources.psd1"
    Write-LocalizedMessage -type Info -MSGID "Msg1"
}
catch
{
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

try
{
    # Wrong Resource File
    Write-LogMessage -Type Verbose "Providing wrong/non-existing resource file name - expecting to fail"
    Set-ResourceCulture -CultureID "en" -ResourceFile "Resources1.psd1"
    Write-LocalizedMessage -type Info -MSGID "Msg1"
}
catch
{
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

try
{
    # Changing to English localization to write English Messages
    Write-LogMessage -Type Verbose "Changing Messages to specific locale English US (en-US)"
    Set-ResourceCulture -CultureID "en-US" -ResourceFile "Resources.psd1"
    Write-LocalizedMessage -type Info -MSGID "Msg1"
    Write-LocalizedMessage -type Info -MSGID "Msg2"
    Write-LocalizedMessage -type Info -MSGID "Msg3.2"
}
catch
{
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

Write-LogMessage -Type Info -Footer -Msg "The End!"

Remove-Module PS-Logger
# ---- End script ----