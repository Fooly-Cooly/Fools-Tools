<#
.SYNOPSIS
    Windows System Registry Tweaks & Shell Extension Engine for FoolsTools.

.DESCRIPTION
    Applies, removes, and manages curated Windows registry tweaks, shell context
    menu extensions, and privacy/usability settings defined in tweaks.json.
    Supports interactive multi-selection, search/filter, and non-interactive CLI flags.
    Requires Administrator privileges. Supports Windows 7 through Windows 11.

.PARAMETER List
    Lists all available registry tweaks and their current installation status.

.PARAMETER Apply
    Applies tweaks matching the specified ID or wildcard pattern.

.PARAMETER Remove
    Removes tweaks matching the specified ID or wildcard pattern.

.PARAMETER Status
    Queries the current status of tweaks matching the specified ID or pattern.

.PARAMETER RestartExplorer
    Restarts Windows Explorer (explorer.exe) to apply shell changes immediately.

.PARAMETER NoColor
    Disables console color output formatting.

.EXAMPLE
    Manage-RegistryTweaks.ps1
    Launches the interactive console menu.

.EXAMPLE
    Manage-RegistryTweaks.ps1 -List

.EXAMPLE
    Manage-RegistryTweaks.ps1 -Apply Disable_Cortana

.EXAMPLE
    Manage-RegistryTweaks.ps1 -Remove "*Menu*"

Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
Contact: foolycooly1764@gmail.com
#>

Set-StrictMode -Off

# Ensure UTF-8 output encoding
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
try { [Console]::OutputEncoding = $utf8NoBom } catch {}

# ==============================================================================
# 1. Parameter Normalization
# ==============================================================================
$DoList            = $false
$DoApply           = $false
$DoRemove          = $false
$DoStatus          = $false
$DoRestartExplorer = $false
$TargetPattern     = $null
$NoColor           = $false

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', '-help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: reg-tweaks [Options]

   Applies, removes, and manages curated Windows registry tweaks,
   shell context menu extensions, and OS privacy/usability settings.
   Invoking without parameters opens an interactive selection menu.
   (Note: Requires Administrator privileges).

   Options / Flags:
      -List, -l, /L              : List all available tweaks and current status
      -Apply, -a <ID|pattern>    : Apply specified tweak(s) non-interactively
      -Remove, -r <ID|pattern>   : Remove specified tweak(s) non-interactively
      -Status, -s <ID|pattern>   : Check status of specified tweak(s)
      -RestartExplorer           : Restart Windows Explorer to apply changes immediately
      -NoColor, -nc              : Disable color output
      -?, -h, --help             : Display this syntax help

   Examples:
      reg-tweaks
      reg-tweaks -List
      reg-tweaks -Apply Disable_Cortana
      reg-tweaks -Apply "*Notepad*"
      reg-tweaks -Remove Take_Ownership_Context_Menu
      reg-tweaks -Status "*Menu*"
      reg-tweaks -RestartExplorer

Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
Contact: foolycooly1764@gmail.com

"@
}

$argList = [System.Collections.ArrayList]@($args)
$i = 0

while ($i -lt $argList.Count) {
    $token = [string]$argList[$i]
    $lower = $token.ToLower()

    if ($HelpSwitches -contains $lower) {
        Show-Usage
        exit 0
    }
    elseif (@('-list', '/l', '-l', '--list') -contains $lower) {
        $DoList = $true
    }
    elseif (@('-apply', '/a', '-a', '--apply') -contains $lower) {
        $DoApply = $true
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $TargetPattern = $next
                $i++
            }
        }
    }
    elseif (@('-remove', '/r', '-r', '--remove') -contains $lower) {
        $DoRemove = $true
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $TargetPattern = $next
                $i++
            }
        }
    }
    elseif (@('-status', '/s', '-s', '--status') -contains $lower) {
        $DoStatus = $true
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $TargetPattern = $next
                $i++
            }
        }
    }
    elseif (@('-restartexplorer', '--restartexplorer') -contains $lower) {
        $DoRestartExplorer = $true
    }
    elseif (@('-nocolor', '-nc', '/nc', '--nocolor') -contains $lower) {
        $NoColor = $true
    }
    else {
        if (-not $TargetPattern -and -not $DoApply -and -not $DoRemove) {
            $TargetPattern = $token
            $DoStatus = $true
        } else {
            Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
            Write-Host "Type 'reg-tweaks /?' for available options." -ForegroundColor Yellow
            exit 1
        }
    }
    $i++
}

# ==============================================================================
# 2. Output & Permission Helpers
# ==============================================================================
function Write-Color([string]$Text, [System.ConsoleColor]$Color = [System.ConsoleColor]::Gray) {
    if ($NoColor) {
        Write-Host $Text
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Color "[ERROR] Administrative permissions are required to manage registry tweaks." Red
        Write-Color "Please run from an elevated command prompt or PowerShell session." Yellow
        exit 1
    }
}

# ==============================================================================
# 3. Environment & Manifest Loader
# ==============================================================================
# Ensure HKCR: PSDrive is mounted for classes root extensions
if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction SilentlyContinue | Out-Null
}

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$ManifestPath = Join-Path -Path $ScriptDir -ChildPath "tweaks.json"

if (-not (Test-Path -Path $ManifestPath)) {
    Write-Color "[ERROR] Could not locate 'tweaks.json' at:" Red
    Write-Color "        $ManifestPath" Yellow
    exit 1
}

try {
    $RawContent = [System.IO.File]::ReadAllText($ManifestPath, [System.Text.Encoding]::UTF8)
    $Tweaks = $RawContent | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Color "[ERROR] Failed to parse 'tweaks.json'. Check for syntax errors:" Red
    Write-Color $_.Exception.Message Yellow
    exit 1
}

if ($null -eq $Tweaks -or $Tweaks.Count -eq 0) {
    Write-Color "[WARNING] 'tweaks.json' was loaded but contains no entries." Yellow
    exit 1
}

# Retrieve current OS build number
$CurrentBuild = 0
try {
    $CurrentBuild = [int](Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber
} catch {
    $CurrentBuild = [System.Environment]::OSVersion.Version.Build
}

# ==============================================================================
# 4. Registry Status & Operation Routines
# ==============================================================================
function Get-TweakStatus($tweak) {
    if ($CurrentBuild -lt $tweak.MinBuild -or $CurrentBuild -gt $tweak.MaxBuild) {
        return "[UNSUPPORTED]"
    }

    if (-not (Test-Path -LiteralPath $tweak.Path)) {
        return "[NOT APPLIED]"
    }

    # Value-level verification
    if (-not [string]::IsNullOrEmpty($tweak.ValueName)) {
        try {
            $item = Get-ItemProperty -LiteralPath $tweak.Path -Name $tweak.ValueName -ErrorAction SilentlyContinue
            if ($null -eq $item -or -not ($item.PSObject.Properties.Name -contains $tweak.ValueName)) {
                return "[NOT APPLIED]"
            }
            if ($null -ne $tweak.ValueData) {
                $actual = [string]$item.($tweak.ValueName)
                $expected = [string]$tweak.ValueData
                if ($actual -ne $expected) {
                    return "[NOT APPLIED]"
                }
            }
        } catch {
            return "[NOT APPLIED]"
        }
    } else {
        # Check Default value
        if ($null -ne $tweak.ValueData -and "$($tweak.ValueData)" -ne "") {
            try {
                $regKey = Get-Item -LiteralPath $tweak.Path -ErrorAction SilentlyContinue
                $defVal = [string]$regKey.GetValue("")
                $expVal = [string]$tweak.ValueData
                if ($defVal -ne $expVal) {
                    return "[NOT APPLIED]"
                }
            } catch {
                return "[NOT APPLIED]"
            }
        }
    }

    return "[APPLIED]"
}

function Apply-SingleTweak($tweak) {
    Assert-Admin
    $status = Get-TweakStatus $tweak
    if ($status -eq "[UNSUPPORTED]") {
        Write-Color "[SKIP] '$($tweak.Name)' is unsupported on Windows build $CurrentBuild." Yellow
        return $false
    }

    try {
        if (-not (Test-Path -LiteralPath $tweak.Path)) {
            New-Item -Path $tweak.Path -Force | Out-Null
        }

        $propType = if ($tweak.Type) { $tweak.Type } else { "String" }

        if ([string]::IsNullOrEmpty($tweak.ValueName)) {
            Set-ItemProperty -LiteralPath $tweak.Path -Name "(default)" -Value $tweak.ValueData -Force | Out-Null
        } else {
            New-ItemProperty -LiteralPath $tweak.Path -Name $tweak.ValueName -Value $tweak.ValueData -PropertyType $propType -Force | Out-Null
        }

        # Apply any nested subkeys
        if ($tweak.SubKeys) {
            foreach ($sub in $tweak.SubKeys) {
                if (-not (Test-Path -LiteralPath $sub.Path)) {
                    New-Item -Path $sub.Path -Force | Out-Null
                }
                $subType = if ($sub.Type) { $sub.Type } else { "String" }
                if ([string]::IsNullOrEmpty($sub.ValueName)) {
                    Set-ItemProperty -LiteralPath $sub.Path -Name "(default)" -Value $sub.ValueData -Force | Out-Null
                } else {
                    New-ItemProperty -LiteralPath $sub.Path -Name $sub.ValueName -Value $sub.ValueData -PropertyType $subType -Force | Out-Null
                }
            }
        }

        Write-Color "[APPLIED] $($tweak.Name)" Green
        return $true
    } catch {
        Write-Color "[FAIL] Could not apply '$($tweak.Name)': $($_.Exception.Message)" Red
        return $false
    }
}

function Remove-SingleTweak($tweak) {
    Assert-Admin
    try {
        # Clean subkeys first if defined
        if ($tweak.SubKeys) {
            foreach ($sub in $tweak.SubKeys) {
                if (Test-Path -LiteralPath $sub.Path) {
                    if ([string]::IsNullOrEmpty($sub.ValueName)) {
                        Remove-Item -LiteralPath $sub.Path -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        Remove-ItemProperty -LiteralPath $sub.Path -Name $sub.ValueName -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        if (Test-Path -LiteralPath $tweak.Path) {
            if ([string]::IsNullOrEmpty($tweak.ValueName)) {
                # Tweak was an entire custom key (like shell extension context item)
                Remove-Item -LiteralPath $tweak.Path -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Remove-ItemProperty -LiteralPath $tweak.Path -Name $tweak.ValueName -ErrorAction SilentlyContinue
            }
        }

        Write-Color "[REMOVED] $($tweak.Name)" Yellow
        return $true
    } catch {
        Write-Color "[FAIL] Could not remove '$($tweak.Name)': $($_.Exception.Message)" Red
        return $false
    }
}

function Restart-WindowsExplorer {
    Write-Color "Restarting Windows Explorer..." Cyan
    try {
        Stop-Process -Name explorer -Force
        Write-Color "[OK] Windows Explorer restarted." Green
    } catch {
        Write-Color "[WARNING] Could not restart explorer.exe: $($_.Exception.Message)" Yellow
    }
}

# ==============================================================================
# 5. Range Parser for Multi-Selection (e.g. "1, 3, 5-8")
# ==============================================================================
function Parse-SelectionRange([string]$InputStr, [int]$MaxItem) {
    $selected = New-Object System.Collections.Generic.List[int]
    $parts = $InputStr -split '[,; ]' | Where-Object { $_ -ne "" }

    foreach ($part in $parts) {
        if ($part -match '^(\d+)-(\d+)$') {
            $start = [int]$matches[1]
            $end   = [int]$matches[2]
            if ($start -gt $end) { $tmp = $start; $start = $end; $end = $tmp }
            for ($k = $start; $k -le $end; $k++) {
                if ($k -ge 1 -and $k -le $MaxItem -and -not $selected.Contains($k)) {
                    $selected.Add($k)
                }
            }
        }
        elseif ($part -match '^\d+$') {
            $num = [int]$part
            if ($num -ge 1 -and $num -le $MaxItem -and -not $selected.Contains($num)) {
                $selected.Add($num)
            }
        }
    }
    return $selected
}

# ==============================================================================
# 6. Interactive Console Menu
# ==============================================================================
function Show-ConsoleMenu {
    $currentFilter = $null

    while ($true) {
        Clear-Host
        Write-Color "============================================================" Cyan
        Write-Color "             Fool's Tools - Registry Manager" Yellow
        Write-Color "============================================================" Cyan
        Write-Color "Windows Build: $CurrentBuild" DarkGray
        if ($currentFilter) {
            Write-Color "Active Filter: '$currentFilter'" Magenta
        }
        Write-Host ""

        # Filter tweaks if active
        $displayTweaks = @()
        for ($idx = 0; $idx -lt $Tweaks.Count; $idx++) {
            $tw = $Tweaks[$idx]
            if ($currentFilter) {
                $pat = "*$currentFilter*"
                if ($tw.Name -notlike $pat -and $tw.ID -notlike $pat) {
                    continue
                }
            }
            $displayTweaks += [PSCustomObject]@{
                OriginalIndex = $idx
                Tweak         = $tw
            }
        }

        $total = $displayTweaks.Count

        if ($total -eq 0) {
            Write-Color "No tweaks found matching filter." Yellow
        } else {
            $padWidth = [string]$total.Length

            for ($i = 0; $i -lt $total; $i++) {
                $entry = $displayTweaks[$i]
                $tw    = $entry.Tweak
                $numStr = ("{0," + $padWidth + "}") -f ($i + 1)
                $status = Get-TweakStatus $tw

                $statusColor = switch ($status) {
                    "[APPLIED]"     { [System.ConsoleColor]::Green }
                    "[NOT APPLIED]" { [System.ConsoleColor]::DarkGray }
                    "[UNSUPPORTED]" { [System.ConsoleColor]::DarkRed }
                }

                Write-Host "  [$numStr] " -ForegroundColor Yellow -NoNewline
                Write-Host ("{0,-52}" -f $tw.Name) -ForegroundColor Cyan -NoNewline
                Write-Host " $status" -ForegroundColor $statusColor
            }
            Write-Host ""
        }

        Write-Color "============================================================" Cyan
        Write-Host "Commands:" -ForegroundColor Gray
        Write-Host "  - Enter number(s) to toggle (e.g. 1, 3, 5-8)" -ForegroundColor Gray
        Write-Host "  - 'S' to search / filter tweaks" -ForegroundColor Gray
        if ($currentFilter) {
            Write-Host "  - 'C' to clear filter" -ForegroundColor Gray
        }
        Write-Host "  - 'R' to restart Windows Explorer" -ForegroundColor Gray
        Write-Host "  - 'Q' to quit" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Select option or tweak(s)"
        $choiceTrim = $choice.Trim()

        if ($choiceTrim -match '^[Qq]$') {
            break
        }
        elseif ($choiceTrim -match '^[Cc]$') {
            $currentFilter = $null
            continue
        }
        elseif ($choiceTrim -match '^[Rr]$') {
            Restart-WindowsExplorer
            Start-Sleep -Seconds 1
            continue
        }
        elseif ($choiceTrim -match '^[Ss]$') {
            $query = Read-Host "Enter search keyword"
            if ($query) { $currentFilter = $query.Trim() }
            continue
        }

        $selectedIndices = Parse-SelectionRange $choiceTrim $total
        if ($selectedIndices.Count -gt 0) {
            Write-Host ""
            foreach ($si in $selectedIndices) {
                $targetEntry = $displayTweaks[$si - 1]
                $targetTweak = $targetEntry.Tweak
                $currStatus  = Get-TweakStatus $targetTweak

                if ($currStatus -eq "[UNSUPPORTED]") {
                    Write-Color "[SKIP] '$($targetTweak.Name)' is unsupported on this Windows version." Yellow
                } elseif ($currStatus -eq "[APPLIED]") {
                    Remove-SingleTweak $targetTweak | Out-Null
                } else {
                    Apply-SingleTweak $targetTweak | Out-Null
                }
            }
            Write-Host ""
            Read-Host "Press Enter to return to menu"
        } else {
            Write-Color "Invalid input. Please enter tweak number(s), 'S', 'R', or 'Q'." Yellow
            Start-Sleep -Seconds 1
        }
    }
}

# ==============================================================================
# 7. Non-Interactive CLI Dispatcher
# ==============================================================================
if ($DoRestartExplorer) {
    Assert-Admin
    Restart-WindowsExplorer
    exit 0
}

if ($DoList) {
    Write-Host ""
    Write-Color "Available Windows Registry Tweaks ($($Tweaks.Count)):" Yellow
    Write-Host ""
    for ($i = 0; $i -lt $Tweaks.Count; $i++) {
        $tw = $Tweaks[$i]
        $status = Get-TweakStatus $tw
        $statusColor = switch ($status) {
            "[APPLIED]"     { [System.ConsoleColor]::Green }
            "[NOT APPLIED]" { [System.ConsoleColor]::DarkGray }
            "[UNSUPPORTED]" { [System.ConsoleColor]::DarkRed }
        }
        Write-Host "   - " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-52}" -f $tw.Name) -ForegroundColor Cyan -NoNewline
        Write-Host " $status " -ForegroundColor $statusColor -NoNewline
        Write-Host "($($tw.ID))" -ForegroundColor DarkGray
    }
    Write-Host ""
    exit 0
}

if ($DoStatus -and $TargetPattern) {
    $wildcard = "*$TargetPattern*"
    $matches = @($Tweaks | Where-Object { $_.ID -like $wildcard -or $_.Name -like $wildcard })
    if ($matches.Count -eq 0) {
        Write-Color "[WARNING] No tweaks found matching pattern: '$TargetPattern'" Yellow
        exit 1
    }
    Write-Host ""
    foreach ($tw in $matches) {
        $status = Get-TweakStatus $tw
        $statusColor = switch ($status) {
            "[APPLIED]"     { [System.ConsoleColor]::Green }
            "[NOT APPLIED]" { [System.ConsoleColor]::DarkGray }
            "[UNSUPPORTED]" { [System.ConsoleColor]::DarkRed }
        }
        Write-Host "   - " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-52}" -f $tw.Name) -ForegroundColor Cyan -NoNewline
        Write-Host " $status" -ForegroundColor $statusColor
    }
    Write-Host ""
    exit 0
}

if ($DoApply -and $TargetPattern) {
    Assert-Admin
    $wildcard = "*$TargetPattern*"
    $matches = @($Tweaks | Where-Object { $_.ID -like $wildcard -or $_.Name -like $wildcard })
    if ($matches.Count -eq 0) {
        Write-Color "[WARNING] No tweaks found matching pattern: '$TargetPattern'" Yellow
        exit 1
    }
    Write-Host ""
    foreach ($tw in $matches) {
        Apply-SingleTweak $tw | Out-Null
    }
    Write-Host ""
    exit 0
}

if ($DoRemove -and $TargetPattern) {
    Assert-Admin
    $wildcard = "*$TargetPattern*"
    $matches = @($Tweaks | Where-Object { $_.ID -like $wildcard -or $_.Name -like $wildcard })
    if ($matches.Count -eq 0) {
        Write-Color "[WARNING] No tweaks found matching pattern: '$TargetPattern'" Yellow
        exit 1
    }
    Write-Host ""
    foreach ($tw in $matches) {
        Remove-SingleTweak $tw | Out-Null
    }
    Write-Host ""
    exit 0
}

# Default: Interactive console menu
Show-ConsoleMenu
