Function Choice {
    <#
    .DESCRIPTION
    Asks the user to choose from a configurable list of options.
    Loops until a valid option has been chosen or the timout is reached.
    Supports a default option to be chosen in case of timeout of user presses the Enter key.
    Can also be used as a replace for the "pause" command ("Press any key to continue...")
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
    .PARAMETER allowTypeAhead
    When set to $false, the keyboard input buffer is cleared right before the message is displayed.
    This is useful in scenarios where a script pops up while the user is working on something else and might just continue typing.
    When set to $false, script automation via input redirection to a file ("<"-sign in common shells) stops at this point.
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
        [int]$timeOutSeconds = -1,
        [bool]$allowTypeAhead = $true
    )
  
    $regexPattern = ($message | Select-String -Pattern '(?<=\[).(?=\])' -AllMatches).matches.value -join ''
    If ($regexPattern) {
        $regexPattern = "[$regexPattern]"
    } else {
        $regexPattern = '.'
    }
  
    $defaultValue = ($message | Select-String '(?<=\>\[).(?=\])').matches.value -join ''
    $key = $null
  
    if (![string]::IsNullOrEmpty($message)) {
        #Write-Host -NoNewline $message
        $a = $message -split '(\>\[.\])', 2
        for ($i = 0; $i -lt $a.count; $i++) {
            if ($a[$i] -like '>`[J`]') {
                Write-Host $a[$i] -NoNewline -ForegroundColor Green
                #Write-Host $a[$i].substring(2, 1) -NoNewline -ForegroundColor Green
            } else {
                $b = $a[$i] -split '(\[.\])'
                for ($j = 0; $j -lt $b.count; $j++) {
                    if ($b[$j] -match '(\[.\])') {
                        Write-Host $b[$j] -ForegroundColor Yellow -NoNewline
                        #Write-Host $b[$j].substring(1, 1) -ForegroundColor Yellow -NoNewline
                    } elseif ($b[$j] -ne '') {
                        Write-Host $b[$j] -NoNewline
                    }
                }
            }
        }
        if (-not $message.endswith(" ")) { Write-Host " " -NoNewline }
    }

    $queryDelay_ms = 250
    $counter = $timeOutSeconds * (1000 / $queryDelay_ms)
  
    if (-not $allowTypeAhead) {
        while ($Host.UI.RawUI.KeyAvailable) {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
            $key = $null
        }
    }
  
    while ($null -eq $key -and ($timeOutSeconds -lt 0 -or ($counter-- -gt 0))) {
        if (($timeOutSeconds -eq 0) -or $Host.UI.RawUI.KeyAvailable) {
            $key_ = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
            if ($key_.KeyDown -and (($key_.Character -match $regexPattern) -or ($key_.VirtualKeyCode -eq 13))) {
                $key = $key_.Character
            }
        } else {
            Start-Sleep -m $queryDelay_ms
        }
    }
  
    if ($null -ne $key) {
        if ($key_.VirtualKeyCode -eq 13) {
            $key = $defaultValue
            if ($defaultValue -eq '') { Write-Host }
        } else {
            #Write-Host -NoNewline "$($key.Character)"
        }
    } else {
        $key = $defaultValue
        if ($defaultValue -eq '') { Write-Host }
    }
    
    if (($null -eq $key) -or ($key -eq '')) {
        Write-Host
        return $null
    } else {
        Write-Host $key
        return $key
    }
}
