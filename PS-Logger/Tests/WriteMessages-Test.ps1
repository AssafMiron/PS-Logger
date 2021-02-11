[CmdletBinding(DefaultParametersetName="Create")]
param()

Import-Module -Name .\PS-Logger\PS-Logger.psd1
$SCRIPT_LOCATION = $(Split-Path -Parent $MyInvocation.InvocationName)
# Set the relevant debugging level based on the Script Common Parameters
Set-DebugLogging $PSBoundParameters

# ---- Start script ----
Write-LogMessage -Type Info -Header -Msg "Write messages (Testing PS-Logger module)"

try{
    # Changing to German localization to write German Messages
    Write-LogMessage -Type Verbose "Changing Messages to German (DE)"
    Set-ResourceCulture -CultureID "de" -ResourceFile "Resources.psd1" -ResourceFolderPath $SCRIPT_LOCATION
    Write-LocalizedMessage -type Info -MSGID "Msg1"
    Write-LocalizedMessage -type Info -MSGID "Msg2"
    Write-LocalizedMessage -type Info -MSGID "Msg3.1"
} catch {
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

try{
    # Changing to a non-existing culture
    Write-LogMessage -Type Verbose "Changing Messages to a culture that does not exit (ZE) - expecting to fail"
    Set-ResourceCulture -CultureID "ze" -ResourceFile "Resources.psd1"
    Write-LocalizedMessage -type Info -MSGID "Msg1"
} catch {
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

try{
    # Wrong Resource File
    Write-LogMessage -Type Verbose "Providing wrong/non-existing resource file name - expecting to fail"
    Set-ResourceCulture -CultureID "en" -ResourceFile "Resources1.psd1"
    Write-LocalizedMessage -type Info -MSGID "Msg1"
} catch {
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

try{
    # Changing to English localization to write English Messages
    Write-LogMessage -Type Verbose "Changing Messages to specific locale English US (en-US)"
    Set-ResourceCulture -CultureID "en-US" -ResourceFile "Resources.psd1"
    Write-LocalizedMessage -type Info -MSGID "Msg1"
    Write-LocalizedMessage -type Info -MSGID "Msg2"
    Write-LocalizedMessage -type Info -MSGID "Msg3.2"
} catch {
    Write-LogMessage -type Error -Msg "There was an error. Error: $(Join-ExceptionMessage $_.Exception)"
}

Write-LogMessage -Type Info -Footer -Msg "The End!"

Remove-Module PS-Logger
# ---- End script ----