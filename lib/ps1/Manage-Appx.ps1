<#
.SYNOPSIS
    UWP & AppX Package Management Engine for FoolsTools.

.DESCRIPTION
    Lists, searches, and safely uninstalls Universal Windows Platform (UWP)
    and AppX Store applications for current user or all users.
    Supports Windows 8, 8.1, 10, and 11.

.PARAMETER List
    Lists removable UWP / AppX packages in a clean console table.

.PARAMETER Search
    Searches installed packages by wildcard pattern or substring.

.PARAMETER Remove
    Removes packages matching the specified name pattern.

.PARAMETER AllUsers
    Removes packages for all user accounts and de-provisions from the OS image.
    Requires Administrator privileges.

.PARAMETER IncludeSystem
    Includes system and framework packages in discovery (disabled by default for safety).

.PARAMETER NoColor
    Disables console color formatting.

.EXAMPLE
    Manage-Appx.ps1
    Launches the interactive console menu.

.EXAMPLE
    Manage-Appx.ps1 -Search "Xbox"
    Searches for installed Xbox-related packages.

.EXAMPLE
    Manage-Appx.ps1 -Remove "*ZuneVideo*"
    Removes the Movies & TV package.

Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
Contact: foolycooly1764@gmail.com
#>

Set-StrictMode -Off

# Ensure UTF-8 output encoding
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ==============================================================================
# 1. Parameter Normalization
# ==============================================================================
$DoList         = $false
$DoSearch       = $false
$DoRemove       = $false
$SearchQuery    = $null
$RemoveQuery    = $null
$AllUsers       = $false
$IncludeSystem  = $false
$NoColor        = $false

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', '-help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: appx [Options]

   Manages and uninstalls Universal Windows Platform (UWP) and AppX packages.
   Invoking without parameters opens an interactive package selection menu.

   Options / Flags:
      -List, -l, /L              : List installed removable UWP packages
      -Search, -s, /S <pattern>  : Search packages by keyword or wildcard
      -Remove, -r, /R <pattern>  : Remove matching packages non-interactively
      -AllUsers, -a, /A          : Remove for all users and de-provision (Requires Admin)
      -IncludeSystem             : Include system and framework packages in list
      -NoColor, -nc              : Disable color output
      -?, -h, --help             : Display this syntax help

   Examples:
      appx
      appx -List
      appx -Search "Xbox"
      appx -Remove "*BingWeather*"
      appx -Remove "*Zune*" -AllUsers

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
    elseif (@('-search', '/s', '-s', '--search') -contains $lower) {
        $DoSearch = $true
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $SearchQuery = $next
                $i++
            }
        }
    }
    elseif (@('-remove', '/r', '-r', '--remove') -contains $lower) {
        $DoRemove = $true
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $RemoveQuery = $next
                $i++
            }
        }
    }
    elseif (@('-allusers', '/a', '-a', '--allusers') -contains $lower) {
        $AllUsers = $true
    }
    elseif (@('-includesystem', '--includesystem') -contains $lower) {
        $IncludeSystem = $true
    }
    elseif (@('-nocolor', '-nc', '/nc', '--nocolor') -contains $lower) {
        $NoColor = $true
    }
    else {
        # Positional search query fallback
        if (-not $SearchQuery -and -not $DoRemove) {
            $SearchQuery = $token
            $DoSearch = $true
        } else {
            Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
            Write-Host "Type 'appx /?' for available options." -ForegroundColor Yellow
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

# ==============================================================================
# 3. Package Discovery Engine
# ==============================================================================
function Get-PackagesSafe([string]$FilterPattern = $null) {
    if (-not (Get-Command "Get-AppxPackage" -ErrorAction SilentlyContinue)) {
        Write-Color "[ERROR] AppX deployment cmdlets not found. Windows 8 or later is required." Red
        exit 1
    }

    $all = @(Get-AppxPackage -ErrorAction SilentlyContinue)

    $filtered = @()
    foreach ($pkg in $all) {
        if (-not $IncludeSystem) {
            # Skip infrastructure frameworks (.NET Native, VCLibs) and non-removable OS core
            if ($pkg.IsFramework -or $pkg.NonRemovable) {
                continue
            }
        }

        if ($FilterPattern) {
            $wildcard = "*$FilterPattern*"
            if ($pkg.Name -notlike $wildcard -and $pkg.PackageFullName -notlike $wildcard) {
                continue
            }
        }

        $filtered += $pkg
    }

    return @($filtered | Sort-Object -Property Name)
}

# ==============================================================================
# 4. Range Parser for Multi-Selection (e.g. "1, 3, 5-8")
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
# 5. Removal Dispatcher
# ==============================================================================
function Remove-PackagesList([array]$PackagesToRemove) {
    if ($PackagesToRemove.Count -eq 0) {
        Write-Color "No packages selected for removal." Yellow
        return
    }

    Write-Host ""
    Write-Color "Packages to remove ($($PackagesToRemove.Count)):" Yellow
    foreach ($p in $PackagesToRemove) {
        Write-Color "   - $($p.Name) ($($p.Version))" Cyan
    }

    if ($AllUsers) {
        Write-Color "`n[NOTICE] -AllUsers mode: Packages will be de-provisioned system-wide." Yellow
        if (-not (Test-IsAdmin)) {
            Write-Color "[WARNING] Removing for All Users requires Administrator privileges!" Red
        }
    }

    Write-Host ""
    $confirm = Read-Host "Are you sure you want to remove these packages? (Y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Color "Operation cancelled." Yellow
        return
    }

    Write-Host ""
    $okCount   = 0
    $failCount = 0

    foreach ($pkg in $PackagesToRemove) {
        Write-Host -NoNewline "Removing $($pkg.Name)... "
        try {
            if ($AllUsers) {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                # Deprovision from OS image if provisioned
                if (Get-Command "Get-AppxProvisionedPackage" -ErrorAction SilentlyContinue) {
                    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | 
                            Where-Object { $_.DisplayName -eq $pkg.Name }
                    if ($prov) {
                        Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            } else {
                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
            }
            Write-Color "[OK]" Green
            $okCount++
        }
        catch {
            Write-Color "[FAIL] ($($_.Exception.Message))" Red
            $failCount++
        }
    }

    Write-Host ""
    Write-Color "Summary: $okCount removed, $failCount failed." Green
}

# ==============================================================================
# 6. Interactive Console Menu
# ==============================================================================
function Show-ConsoleMenu {
    $currentFilter = $null

    while ($true) {
        Clear-Host
        Write-Color "============================================================" Cyan
        Write-Color "             Fool's Tools - UWP App Manager" Yellow
        Write-Color "============================================================" Cyan
        if ($currentFilter) {
            Write-Color "Active Filter: '$currentFilter'" Magenta
        }

        $packages = Get-PackagesSafe $currentFilter
        $total = $packages.Count

        if ($total -eq 0) {
            Write-Color "No removable UWP packages found." Yellow
            if ($currentFilter) {
                Write-Color "Press 'C' to clear filter or 'Q' to quit." Gray
            }
        } else {
            Write-Host ""
            $padWidth = [string]$total.Length

            for ($idx = 0; $idx -lt $total; $idx++) {
                $pkg = $packages[$idx]
                $numStr = ("{0," + $padWidth + "}") -f ($idx + 1)
                $archStr = if ($pkg.Architecture) { " [$($pkg.Architecture)]" } else { "" }
                Write-Host "  [$numStr] " -ForegroundColor Yellow -NoNewline
                Write-Host "$($pkg.Name)" -ForegroundColor Cyan -NoNewline
                Write-Host " (v$($pkg.Version)$archStr)" -ForegroundColor DarkGray
            }
            Write-Host ""
        }

        Write-Color "============================================================" Cyan
        Write-Host "Commands:" -ForegroundColor Gray
        Write-Host "  - Enter number(s) to remove (e.g. 1, 3, 5-8)" -ForegroundColor Gray
        Write-Host "  - 'S' to search / filter by name" -ForegroundColor Gray
        if ($currentFilter) {
            Write-Host "  - 'C' to clear filter" -ForegroundColor Gray
        }
        Write-Host "  - 'R' to refresh list" -ForegroundColor Gray
        Write-Host "  - 'Q' to quit" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Select option or packages"
        $choiceTrim = $choice.Trim()

        if ($choiceTrim -match '^[Qq]$') {
            break
        }
        elseif ($choiceTrim -match '^[Rr]$') {
            continue
        }
        elseif ($choiceTrim -match '^[Cc]$') {
            $currentFilter = $null
            continue
        }
        elseif ($choiceTrim -match '^[Ss]$') {
            $query = Read-Host "Enter search keyword"
            if ($query) { $currentFilter = $query.Trim() }
            continue
        }

        $selectedIndices = Parse-SelectionRange $choiceTrim $total
        if ($selectedIndices.Count -gt 0) {
            $chosenPkgs = @()
            foreach ($si in $selectedIndices) {
                $chosenPkgs += $packages[$si - 1]
            }
            Remove-PackagesList $chosenPkgs
            Write-Host ""
            Read-Host "Press Enter to return to package list"
        } else {
            Write-Color "Invalid input. Please enter package numbers, 'S', 'R', or 'Q'." Yellow
            Start-Sleep -Seconds 1
        }
    }
}

# ==============================================================================
# 7. Main Dispatcher
# ==============================================================================
if ($DoRemove -and $RemoveQuery) {
    $targets = Get-PackagesSafe $RemoveQuery
    if ($targets.Count -eq 0) {
        Write-Color "[WARNING] No packages found matching pattern: '$RemoveQuery'" Yellow
        exit 0
    }
    Remove-PackagesList $targets
    exit 0
}

if ($DoSearch -or $SearchQuery) {
    $results = Get-PackagesSafe $SearchQuery
    Write-Host ""
    Write-Color "Found $($results.Count) packages matching '$SearchQuery':" Yellow
    Write-Host ""
    foreach ($r in $results) {
        Write-Host "   - " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($r.Name)" -ForegroundColor Cyan -NoNewline
        Write-Host " (v$($r.Version))" -ForegroundColor Gray
    }
    Write-Host ""
    exit 0
}

if ($DoList) {
    $allPkgs = Get-PackagesSafe
    Write-Host ""
    Write-Color "Installed Removable UWP Packages ($($allPkgs.Count)):" Yellow
    Write-Host ""
    foreach ($p in $allPkgs) {
        Write-Host "   - " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($p.Name)" -ForegroundColor Cyan -NoNewline
        Write-Host " (v$($p.Version))" -ForegroundColor Gray
    }
    Write-Host ""
    exit 0
}

# Default: Interactive console menu
Show-ConsoleMenu
