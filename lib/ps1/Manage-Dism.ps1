<#
.SYNOPSIS
    Windows DISM Servicing Package & Component Store Engine for FoolsTools.

.DESCRIPTION
    Lists, searches, and removes Windows servicing updates (.cab/.msu) and
    optimizes the WinSxS component store using native DISM capabilities.
    Requires Administrator privileges. Supports Windows 7, 8, 8.1, 10, and 11.

.PARAMETER List
    Lists installed Windows servicing packages in a formatted table.

.PARAMETER Search
    Searches packages by keyword, KB number, or wildcard pattern.

.PARAMETER Remove
    Removes packages matching the specified name or KB pattern.

.PARAMETER Superseded
    Finds and offers to remove all superseded Windows updates.

.PARAMETER Clean
    Executes DISM WinSxS component store cleanup (/StartComponentCleanup).

.PARAMETER ResetBase
    Used with -Clean to discard delta files for superseded components (/ResetBase).
    Reclaims maximum disk space, but prevents uninstalling past updates.

.PARAMETER Analyze
    Analyzes the component store to report actual WinSxS size and reclaimable space.

.PARAMETER NoColor
    Disables console color formatting.

.EXAMPLE
    Manage-Dism.ps1
    Launches the interactive console menu.

.EXAMPLE
    Manage-Dism.ps1 -List

.EXAMPLE
    Manage-Dism.ps1 -Clean -ResetBase

.EXAMPLE
    Manage-Dism.ps1 -Remove "Package_for_KB5000000*"

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
$DoSuperseded   = $false
$DoClean        = $false
$DoResetBase    = $false
$DoAnalyze      = $false
$SearchQuery    = $null
$RemoveQuery    = $null
$NoColor        = $false

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', '-help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: dism-pkg [Options]

   Manages Windows servicing packages, removes superseded updates, and
   reclaims disk space from the WinSxS component store via DISM.
   Invoking without parameters opens an interactive management menu.
   (Note: Requires Administrator privileges).

   Options / Flags:
      -List, -l, /L              : List all installed servicing packages
      -Search, -s, /S <pattern>  : Search packages by KB number or keyword
      -Remove, -r, /R <pattern>  : Remove matching package(s) non-interactively
      -Superseded                : Find and remove all superseded updates
      -Analyze                   : Analyze WinSxS component store size & savings
      -Clean, -c, /C             : Clean superseded components from WinSxS
      -ResetBase                 : Combine with -Clean to reset component base (max space)
      -NoColor, -nc              : Disable color output
      -?, -h, --help             : Display this syntax help

   Examples:
      dism-pkg
      dism-pkg -List
      dism-pkg -Search "KB500"
      dism-pkg -Analyze
      dism-pkg -Clean
      dism-pkg -Clean -ResetBase
      dism-pkg -Remove "Package_for_KB5000000~31bf3856ad364e35~amd64~~10.0.1.1"

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
    elseif (@('-superseded', '--superseded') -contains $lower) {
        $DoSuperseded = $true
    }
    elseif (@('-clean', '/c', '-c', '--clean') -contains $lower) {
        $DoClean = $true
    }
    elseif (@('-resetbase', '--resetbase') -contains $lower) {
        $DoResetBase = $true
    }
    elseif (@('-analyze', '--analyze') -contains $lower) {
        $DoAnalyze = $true
    }
    elseif (@('-nocolor', '-nc', '/nc', '--nocolor') -contains $lower) {
        $NoColor = $true
    }
    else {
        if (-not $SearchQuery -and -not $DoRemove) {
            $SearchQuery = $token
            $DoSearch = $true
        } else {
            Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
            Write-Host "Type 'dism-pkg /?' for available options." -ForegroundColor Yellow
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
        Write-Color "[ERROR] Administrative permissions are required to run DISM." Red
        Write-Color "Please run from an elevated command prompt or PowerShell session." Yellow
        exit 1
    }
}

# ==============================================================================
# 3. Package Discovery Engine
# ==============================================================================
function Get-DismPackagesSafe([string]$FilterPattern = $null) {
    Assert-Admin

    $packages = @()

    # Try native Dism module first (Windows 8+)
    if (Get-Command "Get-WindowsPackage" -ErrorAction SilentlyContinue) {
        try {
            $raw = Get-WindowsPackage -Online -ErrorAction Stop
            foreach ($p in $raw) {
                $pkgObj = [PSCustomObject]@{
                    PackageName = $p.PackageName
                    State       = [string]$p.PackageState
                    ReleaseType = [string]$p.ReleaseType
                    InstallTime = if ($p.InstallTime) { $p.InstallTime.ToString("yyyy-MM-dd HH:mm") } else { "N/A" }
                }
                $packages += $pkgObj
            }
        } catch {
            # Fall back to dism.exe CLI if cmdlet encounters error
            $packages = @()
        }
    }

    # Fallback to DISM.exe CLI parsing (Windows 7 / legacy PowerShell)
    if ($packages.Count -eq 0) {
        $dismOut = & dism.exe /Online /Get-Packages /Format:Table 2>$null
        $headerPassed = $false
        foreach ($line in $dismOut) {
            if ($line -match '^-+') {
                $headerPassed = $true
                continue
            }
            if (-not $headerPassed) { continue }
            if ($line -match '^\s*$') { continue }

            # Table columns: Package Identity | State | Release Type | Install Time
            $parts = $line -split '\|'
            if ($parts.Count -ge 2) {
                $pkgName = $parts[0].Trim()
                $state   = $parts[1].Trim()
                $relType = if ($parts.Count -ge 3) { $parts[2].Trim() } else { "Update" }
                $insTime = if ($parts.Count -ge 4) { $parts[3].Trim() } else { "N/A" }

                if ($pkgName -ne "") {
                    $packages += [PSCustomObject]@{
                        PackageName = $pkgName
                        State       = $state
                        ReleaseType = $relType
                        InstallTime = $insTime
                    }
                }
            }
        }
    }

    if ($FilterPattern) {
        $wildcard = "*$FilterPattern*"
        $packages = @($packages | Where-Object { $_.PackageName -like $wildcard -or $_.State -like $wildcard })
    }

    return @($packages | Sort-Object -Property PackageName)
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
# 5. Removal & WinSxS Cleanup Operations
# ==============================================================================
function Remove-DismPackageList([array]$PackagesToRemove) {
    Assert-Admin
    if ($PackagesToRemove.Count -eq 0) {
        Write-Color "No packages selected for removal." Yellow
        return
    }

    Write-Host ""
    Write-Color "Windows servicing packages to remove ($($PackagesToRemove.Count)):" Yellow
    foreach ($p in $PackagesToRemove) {
        $stateTag = if ($p.State -eq "Superseded") { " [SUPERSEDED]" } else { " ($($p.State))" }
        Write-Color "   - $($p.PackageName)$stateTag" Cyan
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
        Write-Host "Removing $($pkg.PackageName)..." -ForegroundColor Yellow
        $proc = Start-Process -FilePath "dism.exe" -ArgumentList @("/Online", "/Remove-Package", "/PackageName:$($pkg.PackageName)", "/NoRestart") -NoNewWindow -PassThru -Wait
        if ($proc.ExitCode -eq 0) {
            Write-Color "[OK] Successfully removed $($pkg.PackageName)" Green
            $okCount++
        } else {
            Write-Color "[FAIL] Exit code $($proc.ExitCode) for $($pkg.PackageName)" Red
            $failCount++
        }
    }

    Write-Host ""
    Write-Color "Summary: $okCount removed, $failCount failed." Green
    Write-Color "[NOTICE] A system restart may be required for servicing changes to take full effect." DarkGray
}

function Invoke-ComponentStoreCleanup([bool]$ResetBaseFlag = $false) {
    Assert-Admin
    Write-Host ""
    if ($ResetBaseFlag) {
        Write-Color "============================================================" Yellow
        Write-Color "  WARNING: /ResetBase permanently removes superseded updates." Yellow
        Write-Color "  Past Windows Updates cannot be uninstalled after this." Yellow
        Write-Color "============================================================" Yellow
        $confirm = Read-Host "Proceed with /StartComponentCleanup /ResetBase? (Y/N)"
        if ($confirm -notmatch '^[Yy]$') {
            Write-Color "Operation cancelled." Yellow
            return
        }
        Write-Host "`nExecuting: dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase" -ForegroundColor Cyan
        & dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    } else {
        Write-Host "`nExecuting: dism.exe /Online /Cleanup-Image /StartComponentCleanup" -ForegroundColor Cyan
        & dism.exe /Online /Cleanup-Image /StartComponentCleanup
    }
    Write-Host ""
}

function Invoke-AnalyzeComponentStore {
    Assert-Admin
    Write-Host "`nAnalyzing Component Store (WinSxS)... Please wait..." -ForegroundColor Cyan
    & dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
    Write-Host ""
}

# ==============================================================================
# 6. Interactive Console Menu
# ==============================================================================
function Show-ConsoleMenu {
    Assert-Admin
    $currentFilter = $null

    while ($true) {
        Clear-Host
        Write-Color "============================================================" Cyan
        Write-Color "     Fool's Tools - DISM Servicing & Component Store" Yellow
        Write-Color "============================================================" Cyan
        Write-Color "  [1] List All Installed Packages" Gray
        Write-Color "  [2] List & Remove Superseded Updates Only" Gray
        Write-Color "  [3] Analyze Component Store (WinSxS) Disk Usage" Gray
        Write-Color "  [4] Clean Component Store (StartComponentCleanup)" Gray
        Write-Color "  [5] Deep Clean Component Store (/ResetBase - Max Space)" Gray
        Write-Color "  [6] Interactive Package Selection & Removal" Gray
        Write-Color "  [Q] Quit" Gray
        Write-Color "============================================================" Cyan
        Write-Host ""

        $choice = Read-Host "Select an option [1-6, Q]"
        $choiceTrim = $choice.Trim().ToUpper()

        if ($choiceTrim -eq 'Q') {
            break
        }
        elseif ($choiceTrim -eq '1') {
            $pkgs = Get-DismPackagesSafe
            Write-Host ""
            Write-Color "Installed Windows Servicing Packages ($($pkgs.Count)):" Yellow
            Write-Host ""
            foreach ($p in $pkgs) {
                $color = if ($p.State -eq 'Superseded') { [System.ConsoleColor]::Magenta } else { [System.ConsoleColor]::Cyan }
                Write-Host "   - " -NoNewline -ForegroundColor DarkGray
                Write-Host "$($p.PackageName)" -NoNewline -ForegroundColor $color
                Write-Host " [$($p.State)]" -ForegroundColor Gray
            }
            Write-Host ""
            Read-Host "Press Enter to return to menu"
        }
        elseif ($choiceTrim -eq '2') {
            $superseded = @(Get-DismPackagesSafe | Where-Object { $_.State -eq 'Superseded' })
            if ($superseded.Count -eq 0) {
                Write-Host ""
                Write-Color "No superseded packages found on this system." Green
                Write-Host ""
                Read-Host "Press Enter to return to menu"
            } else {
                Remove-DismPackageList $superseded
                Write-Host ""
                Read-Host "Press Enter to return to menu"
            }
        }
        elseif ($choiceTrim -eq '3') {
            Invoke-AnalyzeComponentStore
            Read-Host "Press Enter to return to menu"
        }
        elseif ($choiceTrim -eq '4') {
            Invoke-ComponentStoreCleanup $false
            Read-Host "Press Enter to return to menu"
        }
        elseif ($choiceTrim -eq '5') {
            Invoke-ComponentStoreCleanup $true
            Read-Host "Press Enter to return to menu"
        }
        elseif ($choiceTrim -eq '6') {
            # Sub-menu for package selection
            Show-PackageSelectionSubmenu
        }
    }
}

function Show-PackageSelectionSubmenu {
    $currentFilter = $null

    while ($true) {
        Clear-Host
        Write-Color "============================================================" Cyan
        Write-Color "          DISM Package Selection & Removal" Yellow
        Write-Color "============================================================" Cyan
        if ($currentFilter) {
            Write-Color "Active Filter: '$currentFilter'" Magenta
        }

        $packages = Get-DismPackagesSafe $currentFilter
        $total = $packages.Count

        if ($total -eq 0) {
            Write-Color "No packages found matching filter." Yellow
        } else {
            Write-Host ""
            $padWidth = [string]$total.Length

            for ($idx = 0; $idx -lt $total; $idx++) {
                $pkg = $packages[$idx]
                $numStr = ("{0," + $padWidth + "}") -f ($idx + 1)
                $color = if ($pkg.State -eq 'Superseded') { [System.ConsoleColor]::Magenta } else { [System.ConsoleColor]::Cyan }

                Write-Host "  [$numStr] " -ForegroundColor Yellow -NoNewline
                Write-Host "$($pkg.PackageName)" -ForegroundColor $color -NoNewline
                Write-Host " [$($pkg.State)]" -ForegroundColor DarkGray
            }
            Write-Host ""
        }

        Write-Color "============================================================" Cyan
        Write-Host "Commands:" -ForegroundColor Gray
        Write-Host "  - Enter number(s) to remove (e.g. 1, 3, 5-8)" -ForegroundColor Gray
        Write-Host "  - 'S' to search / filter by name or KB" -ForegroundColor Gray
        if ($currentFilter) {
            Write-Host "  - 'C' to clear filter" -ForegroundColor Gray
        }
        Write-Host "  - 'B' to return to main menu" -ForegroundColor Gray
        Write-Host ""

        $choice = Read-Host "Select packages or command"
        $choiceTrim = $choice.Trim()

        if ($choiceTrim -match '^[BbQq]$') {
            break
        }
        elseif ($choiceTrim -match '^[Cc]$') {
            $currentFilter = $null
            continue
        }
        elseif ($choiceTrim -match '^[Ss]$') {
            $query = Read-Host "Enter search keyword (e.g. KB number or package name)"
            if ($query) { $currentFilter = $query.Trim() }
            continue
        }

        $selectedIndices = Parse-SelectionRange $choiceTrim $total
        if ($selectedIndices.Count -gt 0) {
            $chosenPkgs = @()
            foreach ($si in $selectedIndices) {
                $chosenPkgs += $packages[$si - 1]
            }
            Remove-DismPackageList $chosenPkgs
            Write-Host ""
            Read-Host "Press Enter to return to package list"
        } else {
            Write-Color "Invalid input. Please enter package numbers, 'S', 'C', or 'B'." Yellow
            Start-Sleep -Seconds 1
        }
    }
}

# ==============================================================================
# 7. Main Dispatcher
# ==============================================================================
if ($DoAnalyze) {
    Invoke-AnalyzeComponentStore
    exit 0
}

if ($DoClean) {
    Invoke-ComponentStoreCleanup $DoResetBase
    exit 0
}

if ($DoSuperseded) {
    $superseded = @(Get-DismPackagesSafe | Where-Object { $_.State -eq 'Superseded' })
    if ($superseded.Count -eq 0) {
        Write-Color "No superseded packages found." Green
        exit 0
    }
    Remove-DismPackageList $superseded
    exit 0
}

if ($DoRemove -and $RemoveQuery) {
    $targets = Get-DismPackagesSafe $RemoveQuery
    if ($targets.Count -eq 0) {
        Write-Color "[WARNING] No servicing packages found matching pattern: '$RemoveQuery'" Yellow
        exit 0
    }
    Remove-DismPackageList $targets
    exit 0
}

if ($DoSearch -or $SearchQuery) {
    $results = Get-DismPackagesSafe $SearchQuery
    Write-Host ""
    Write-Color "Found $($results.Count) servicing packages matching '$SearchQuery':" Yellow
    Write-Host ""
    foreach ($r in $results) {
        $color = if ($r.State -eq 'Superseded') { [System.ConsoleColor]::Magenta } else { [System.ConsoleColor]::Cyan }
        Write-Host "   - " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($r.PackageName)" -ForegroundColor $color -NoNewline
        Write-Host " [$($r.State)]" -ForegroundColor Gray
    }
    Write-Host ""
    exit 0
}

if ($DoList) {
    $allPkgs = Get-DismPackagesSafe
    Write-Host ""
    Write-Color "Installed Windows Servicing Packages ($($allPkgs.Count)):" Yellow
    Write-Host ""
    foreach ($p in $allPkgs) {
        $color = if ($p.State -eq 'Superseded') { [System.ConsoleColor]::Magenta } else { [System.ConsoleColor]::Cyan }
        Write-Host "   - " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($p.PackageName)" -ForegroundColor $color -NoNewline
        Write-Host " [$($p.State)]" -ForegroundColor Gray
    }
    Write-Host ""
    exit 0
}

# Default: Interactive console menu
Show-ConsoleMenu
