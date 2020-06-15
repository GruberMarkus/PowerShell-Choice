Function Choice {
    <#
    .DESCRIPTION
    Asks the user to choose from a configurable list of options.
    Loops until a valid option has been chosen or the timout is reached.
    Supports a default option to be chosen in case of timeout of user presses the Enter key.

    .PARAMETER message
    Specifies the message to be shown.

    Allowed choices are automatically generated out of every single letter written between square brackets.
    For example: "Continue? [Y]es or [N]o" makes Y and N acceptable choices (not case sensitive).

    The first letter in square brackets preceeded by > is set as default value.
    For example: "Continue? [Y]es or >[N]o" makes N the default choice when the timeout is reached or the user presses Enter.

    When message contains no choices, every keypress is accepted and Enter as default choice.

    The message can be a multi-line string:
    choice "Continue?`n[Y] or >[N]o" -timeOutSeconds -1

    .PARAMETER timeOutSeconds
    The number of seconds until the timeout is reached.
    0 means that the default choice is applied immediately.
    -1 or any other value less than 0 disables the timeout.

    .INPUTS
    The message can be piped:
    "Continue?`n[Y] or >[N]o" | choice -timeOutSeconds -1

    .OUTPUTS
    String containing pressed valid key or default value, else $null.

    .EXAMPLE
    choice "Continue?`n[Y] or [N]o" -timeOutSeconds -1
    "Continue?`n[Y] or >[N]o" | choice -timeOutSeconds -5
    #>

    param (
        [parameter(ValueFromPipeline)]
        [string]$message = $null,
        [int]$timeOutSeconds = -1
    )

    $regexPattern = ($message | Select-String -Pattern '(?<=\[).?(?=\])' -AllMatches).matches.value -join ''
    If ($regexPattern) {
        $regexPattern = "[$regexPattern]"
    }
    else {
        $regexPattern = '.?'
    }

    $defaultValue = ($message | Select-String '(?<=\>\[).?(?=\])').matches.value -join ''
    $key = $null
    $Host.UI.RawUI.FlushInputBuffer()

    if (![string]::IsNullOrEmpty($message)) {
        Write-Host -NoNewline $message
    }

    $counter = $timeOutSeconds * 10


    while ($key -eq $null -and ($timeOutSeconds -lt 0 -or ($counter-- -gt 0))) {
        if (($timeOutSeconds -eq 0) -or $Host.UI.RawUI.KeyAvailable) {
            $key_ = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
            if ($key_.KeyDown -and (($key_.Character -match $regexPattern) -or ($key_.VirtualKeyCode -eq 13))) {
                $key = $key_.Character
            }
        }
        else {
            Start-Sleep -m 100 # milliseconds
        }
    }

    if (-not ($key -eq $null)) {
        if ($key_.VirtualKeyCode -eq 13) {
            $key = $defaultValue
            if ($defaultValue -eq '') { Write-Host }
        }
        else {
            Write-Host -NoNewline "$($key.Character)"
        }
    }
    else {
        $key = $defaultValue
        if ($defaultValue -eq '') { Write-Host }
    }

    return $(if (($key -eq $null) -or ($key -eq "")) { $null } else { $key })
}
