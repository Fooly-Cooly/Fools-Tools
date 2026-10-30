<#
.SYNOPSIS
    System Clean-Up & Maintenance Engine for FoolsTools.

.DESCRIPTION
    Provides high-performance disk maintenance including safe depth-first
    temporary file deletion, empty file & directory pruning, and Windows
    icon/thumbnail cache rebuilding.
    Supports Windows XP through Windows 11 (PowerShell 2.0+ and PowerShell 5.1/7+).

.PARAMETER Temp
    Cleans user and system temporary file directories.

.PARAMETER Empty
    Recursively scans and removes 0-byte empty files and empty directory trees.

.PARAMETER IconCache
    Rebuilds the Windows desktop icon cache and Explorer thumbnail cache.

.PARAMETER All
    Executes all clean-up maintenance tasks sequentially.

.PARAMETER Path
    Specifies the target root directory for the -Empty scan (defaults to current directory).

.PARAMETER DaysOld
    Preserves temp files modified within this many days (default: 0 = all unlocked files).

.PARAMETER NoColor
    Disables console color formatting for plain text output.

.EXAMPLE
    Clean-System.ps1 -Temp
    Safely removes unlocked temporary files and reports reclaimed disk space.

.EXAMPLE
    Clean-System.ps1 -Empty -Path "C:\Projects\Target"
    Recursively prunes 0-byte files and empty folders in the target directory.

.EXAMPLE
    Clean-System.ps1 -All
    Runs full maintenance: Temp cleaning, Empty pruning, and Icon cache reset.

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
$DoTemp      = $false
$DoEmpty     = $false
$DoIconCache = $false
$DoAll       = $false
$NoColor     = $false
$DaysOld     = 0
$TargetPath  = $null

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', '-help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: clean-up [Options]

   Performs system disk maintenance, safe temporary file purging,
   empty file/folder pruning, and Windows icon cache rebuilding.

   Options / Flags:
      -Temp, -t, /T              : Clean user (%TEMP%) & system temp files
      -Empty, -c, /C [Path]      : Clean 0-byte files & empty folders (default: CD)
      -IconCache, -i, /I         : Rebuild Windows icon & thumbnail cache
      -All, -a, /A               : Execute all clean-up routines
      -DaysOld <N>               : Preserve temp files newer than N days (default: 0)
      -NoColor, -nc              : Disable color output
      -?, -h, --help             : Display this syntax help

   Examples:
      clean-up
      clean-up /T
      clean-up /C "D:\Media"
      clean-up /I
      clean-up /A

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
    elseif (@('-temp', '/t', '-t', '--temp') -contains $lower) {
        $DoTemp = $true
    }
    elseif (@('-empty', '/c', '-c', '--empty') -contains $lower) {
        $DoEmpty = $true
        if (($i + 1) -lt $argList.Count) {
            $next = [string]$argList[$i + 1]
            if (-not $next.StartsWith('-') -and -not $next.StartsWith('/')) {
                $TargetPath = $next
                $i++
            }
        }
    }
    elseif (@('-path', '/path', '--path', '-p', '/p') -contains $lower) {
        if (($i + 1) -lt $argList.Count) {
            $TargetPath = [string]$argList[$i + 1]
            $i++
        }
    }
    elseif (@('-iconcache', '-icon', '/i', '-i', '--icon', '--iconcache') -contains $lower) {
        $DoIconCache = $true
    }
    elseif (@('-all', '/a', '-a', '--all', '/all') -contains $lower) {
        $DoAll = $true
    }
    elseif (@('-nocolor', '-nc', '/nc', '--nocolor') -contains $lower) {
        $NoColor = $true
    }
    elseif ($lower -eq '-daysold') {
        if (($i + 1) -lt $argList.Count) {
            $DaysOld = [int]$argList[$i + 1]
            $i++
        }
    }
    elseif (-not $TargetPath -and (Test-Path -LiteralPath $token)) {
        $TargetPath = $token
        $DoEmpty = $true
    }
    else {
        Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
        Write-Host "Type 'clean-up /?' for available options." -ForegroundColor Yellow
        exit 1
    }
    $i++
}

if ($DoAll) {
    $DoTemp      = $true
    $DoEmpty     = $true
    $DoIconCache = $true
}

# Default to Temp cleaning if no task flag was specified
if (-not $DoTemp -and -not $DoEmpty -and -not $DoIconCache) {
    $DoTemp = $true
}

# ==============================================================================
# 2. Output & Formatting Helpers
# ==============================================================================
function Write-Color([string]$Text, [System.ConsoleColor]$Color = [System.ConsoleColor]::Gray) {
    if ($NoColor) {
        Write-Host $Text
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Format-FileSize([long]$Bytes) {
    if ($Bytes -ge 1GB) {
        return ("{0:N2} GB" -f ($Bytes / 1GB))
    }
    elseif ($Bytes -ge 1MB) {
        return ("{0:N2} MB" -f ($Bytes / 1MB))
    }
    elseif ($Bytes -ge 1KB) {
        return ("{0:N2} KB" -f ($Bytes / 1KB))
    }
    else {
        return "$Bytes B"
    }
}

# ==============================================================================
# 3. Task: Temporary Files Cleanup (Safe Bottom-Up Traversal)
# ==============================================================================
function Clean-TempDirectory([string]$DirName, [string]$Path, [int]$Days) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    Write-Color "Scanning $DirName - $Path" Cyan
    $cutoff = (Get-Date).AddDays(-$Days)

    $bytesReclaimed = [long]0
    $deletedFiles   = 0
    $skippedFiles   = 0
    $deletedDirs    = 0

    # Single recursive scan to minimize filesystem I/O
    $allItems = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue)
    $files    = @($allItems | Where-Object { -not $_.PSIsContainer })
    $dirs     = @($allItems | Where-Object { $_.PSIsContainer } | Sort-Object -Property @{ Expression = { $_.FullName.Length } } -Descending)

    foreach ($file in $files) {
        if ($Days -gt 0 -and $file.LastWriteTime -ge $cutoff) {
            continue
        }

        try {
            # Strip Read-Only attribute if set
            if ($file.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                $file.Attributes = $file.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
            }

            $size = $file.Length
            $file.Delete()
            $bytesReclaimed += $size
            $deletedFiles++
        }
        catch [System.IO.IOException] {
            $skippedFiles++
        }
        catch [System.UnauthorizedAccessException] {
            $skippedFiles++
        }
        catch {
            $skippedFiles++
        }
    }

    # Phase 2: Prune empty directory shells bottom-up (deepest first)
    foreach ($dir in $dirs) {
        try {
            $entries = [System.IO.Directory]::GetFileSystemEntries($dir.FullName)
            if ($entries.Length -eq 0) {
                $dir.Delete($false)
                $deletedDirs++
            }
        }
        catch {
            # Subdirectory still has locked content or permissions; ignore silently
        }
    }

    $formattedBytes = Format-FileSize $bytesReclaimed
    Write-Color "   [OK] Reclaimed $formattedBytes ($deletedFiles files deleted, $deletedDirs folders pruned, $skippedFiles in-use skipped)" Green

    return @{
        Bytes        = $bytesReclaimed
        DeletedFiles = $deletedFiles
        DeletedDirs  = $deletedDirs
        SkippedFiles = $skippedFiles
    }
}

function Invoke-TempClean {
    Write-Host ""
    Write-Color "==================================================" Cyan
    Write-Color " Task: Temporary Files Clean-Up" Yellow
    Write-Color "==================================================" Cyan

    $totalBytes = [long]0
    $totalFiles = 0
    $totalDirs  = 0
    $totalSkip  = 0

    # User Temp (%TEMP%)
    $userTemp = [System.IO.Path]::GetTempPath()
    $resUser = Clean-TempDirectory "User Temp" $userTemp $DaysOld
    if ($resUser) {
        $totalBytes += $resUser.Bytes
        $totalFiles += $resUser.DeletedFiles
        $totalDirs  += $resUser.DeletedDirs
        $totalSkip  += $resUser.SkippedFiles
    }

    # System Temp (%SystemRoot%\Temp)
    $sysTemp = [System.IO.Path]::Combine($env:SystemRoot, "Temp")
    if (Test-Path -LiteralPath $sysTemp) {
        $resSys = Clean-TempDirectory "System Temp" $sysTemp $DaysOld
        if ($resSys) {
            $totalBytes += $resSys.Bytes
            $totalFiles += $resSys.DeletedFiles
            $totalDirs  += $resSys.DeletedDirs
            $totalSkip  += $resSys.SkippedFiles
        }
    }

    # Crash Dumps (%LOCALAPPDATA%\CrashDumps)
    $crashDumps = [System.IO.Path]::Combine($env:LOCALAPPDATA, "CrashDumps")
    if (Test-Path -LiteralPath $crashDumps) {
        $resCrash = Clean-TempDirectory "Crash Dumps" $crashDumps $DaysOld
        if ($resCrash) {
            $totalBytes += $resCrash.Bytes
            $totalFiles += $resCrash.DeletedFiles
            $totalDirs  += $resCrash.DeletedDirs
            $totalSkip  += $resCrash.SkippedFiles
        }
    }

    Write-Host ""
    Write-Color "Temp Summary: $(Format-FileSize $totalBytes) reclaimed ($totalFiles files removed, $totalDirs folders pruned, $totalSkip in-use skipped)" Green
}

# ==============================================================================
# 4. Task: Empty Files & Folders Pruning
# ==============================================================================
function Invoke-EmptyClean {
    Write-Host ""
    Write-Color "==================================================" Cyan
    Write-Color " Task: Clean Empty Files & Folders" Yellow
    Write-Color "==================================================" Cyan

    $root = $TargetPath
    if (-not $root) {
        $root = (Get-Location).Path
    }

    if (-not (Test-Path -LiteralPath $root)) {
        Write-Color "[ERROR] Target directory not found: '$root'" Red
        return
    }

    $fullRoot = (Get-Item -LiteralPath $root).FullName
    Write-Color "Scanning Target: $fullRoot" Cyan

    $deletedFiles = 0
    $deletedDirs  = 0
    $skippedFiles = 0

    # Single recursive scan to minimize filesystem I/O
    $allItems = @(Get-ChildItem -LiteralPath $fullRoot -Recurse -Force -ErrorAction SilentlyContinue)
    $files    = @($allItems | Where-Object { -not $_.PSIsContainer })
    $dirs     = @($allItems | Where-Object { $_.PSIsContainer } | Sort-Object -Property @{ Expression = { $_.FullName.Length } } -Descending)

    # Clean 0-byte files
    foreach ($file in $files) {
        try {
            if ($file.Length -eq 0) {
                if ($file.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                    $file.Attributes = $file.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
                }
                $file.Delete()
                $deletedFiles++
            }
        }
        catch {
            $skippedFiles++
        }
    }

    # Clean empty directories bottom-up
    foreach ($dir in $dirs) {
        if ($dir.FullName -eq $fullRoot) { continue }
        try {
            $entries = [System.IO.Directory]::GetFileSystemEntries($dir.FullName)
            if ($entries.Length -eq 0) {
                $dir.Delete($false)
                $deletedDirs++
            }
        }
        catch {
            # In use or permissions issue
        }
    }

    Write-Host ""
    Write-Color "Empty Prune Summary: $deletedFiles empty files removed, $deletedDirs empty folders removed" Green
}

# ==============================================================================
# 5. Task: Windows Icon & Thumbnail Cache Rebuild
# ==============================================================================
function Invoke-IconCacheClean {
    Write-Host ""
    Write-Color "==================================================" Cyan
    Write-Color " Task: Rebuild Windows Icon & Thumbnail Cache" Yellow
    Write-Color "==================================================" Cyan

    Write-Color "Stopping Windows Explorer..." Yellow
    try {
        Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Milliseconds 800
    } catch {}

    $purged = 0

    # Legacy IconCache.db (%LOCALAPPDATA%\IconCache.db)
    $legacyDb = [System.IO.Path]::Combine($env:LOCALAPPDATA, "IconCache.db")
    if (Test-Path -LiteralPath $legacyDb) {
        try {
            [System.IO.File]::Delete($legacyDb)
            $purged++
            Write-Color "   [OK] Purged legacy IconCache.db" Green
        } catch {
            Write-Color "   [SKIP] Could not delete $legacyDb" DarkGray
        }
    }

    # Modern Windows 8/10/11 Explorer Databases (%LOCALAPPDATA%\Microsoft\Windows\Explorer)
    $explorerCacheDir = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Microsoft\Windows\Explorer")
    if (Test-Path -LiteralPath $explorerCacheDir) {
        $cacheFiles = @(Get-ChildItem -LiteralPath $explorerCacheDir -Force -ErrorAction SilentlyContinue | 
                        Where-Object { $_.Name -like "iconcache_*.db" -or $_.Name -like "thumbcache_*.db" })

        foreach ($cf in $cacheFiles) {
            try {
                if ($cf.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                    $cf.Attributes = $cf.Attributes -bxor [System.IO.FileAttributes]::ReadOnly
                }
                $cf.Delete()
                $purged++
            } catch {
                # In-use handle or locked by system
            }
        }
        Write-Color "   [OK] Purged modern icon/thumbnail databases in Explorer cache" Green
    }

    # Refresh shell icon cache via ie4uinit
    try {
        $ie4uinit = [System.IO.Path]::Combine($env:SystemRoot, "System32\ie4uinit.exe")
        if (Test-Path -LiteralPath $ie4uinit) {
            # Windows 10/11 uses -show; Windows 7/8/XP uses -ClearIconCache
            Start-Process -FilePath $ie4uinit -ArgumentList "-show" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath $ie4uinit -ArgumentList "-ClearIconCache" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    } catch {}

    # Restart Windows Explorer
    Write-Color "Restarting Windows Explorer..." Yellow
    try {
        $explorerExe = [System.IO.Path]::Combine($env:SystemRoot, "explorer.exe")
        Start-Process -FilePath $explorerExe
        Write-Color "   [OK] Windows Explorer restarted successfully" Green
    } catch {
        Write-Color "   [WARNING] Could not restart Explorer automatically. Run 'explorer.exe' manually." Red
    }

    Write-Host ""
    Write-Color "Icon Cache Summary: $purged cache database items cleared" Green
}

# ==============================================================================
# 6. Main Dispatcher
# ==============================================================================
if ($DoTemp)      { Invoke-TempClean }
if ($DoEmpty)     { Invoke-EmptyClean }
if ($DoIconCache) { Invoke-IconCacheClean }

Write-Host ""
