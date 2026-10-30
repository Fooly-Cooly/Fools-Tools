<#
.SYNOPSIS
    Unified Hashing Engine for Fool's Tools.

.DESCRIPTION
    Calculates checksums (CRC32, MD5, SHA1, SHA256, SHA384, SHA512, XXHSUM)
    for single files, wildcards, directory batches, and synchronizes directory manifests.

.PARAMETER Target
    Positional parameter 1: Algorithm name, target file/pattern, or mode switch (/A or /SYNC).

.PARAMETER Target2
    Positional parameter 2: Target file/pattern, /A, /SYNC, or /PURGE.

.PARAMETER Target3
    Positional parameter 3: /PURGE or secondary target/flag.

.PARAMETER Target4
    Positional parameter 4: Additional options.

.PARAMETER Algorithm
    Hashing algorithm to use: CRC32, MD5, SHA1, SHA256, SHA384, SHA512, XXHSUM.
    Default is SHA256.

.PARAMETER Path
    Path to target file or wildcard pattern. Defaults to current directory or resolved target.

.PARAMETER Append
    (-a) Appends the calculated hash into the filename, e.g. "file [HASH].ext".

.PARAMETER Save
    (-s) Appends the calculated hash to a checksum manifest file in format "<HASH> *<FILE>".

.PARAMETER Sync
    (/SYNC) Synchronizes directory manifest against disk. Keeps missing files by default (Audit mode).

.PARAMETER Purge
    (/PURGE) Used with -Sync to permanently purge missing files from the manifest.

.PARAMETER OutputFile
    Filename for the manifest when using -Sync. Defaults to "hashes.txt".

.EXAMPLE
    .\Manage-Hashes.ps1 myimage.iso
    Hashes 'myimage.iso' using SHA256.

.EXAMPLE
    .\Manage-Hashes.ps1 MD5 myimage.iso -Append
    Hashes 'myimage.iso' using MD5 and appends hash to filename.

.EXAMPLE
    .\Manage-Hashes.ps1 -Sync -Purge
    Synchronizes directory manifest, purging missing entries.
#>
param (
    $Target,
    $Target2,
    $Target3,
    $Target4,
    $Algorithm,
    $Path,
    [Alias("a")]
    [switch]$Append,
    [Alias("s")]
    [switch]$Save,
    [switch]$Sync,
    [switch]$Purge,
    $OutputFile = "hashes.txt"
)

Set-StrictMode -Off

# ==============================================================================
# 1. High-Performance Hashing Engine (Compiled C#)
# ==============================================================================
if (-not ("FastHash" -as [type])) {
    $csharpSource = @'
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class FastHash {
    private static readonly uint[] Crc32Table;

    static FastHash() {
        uint poly = 0xEDB88320u;
        Crc32Table = new uint[256];
        for (uint i = 0; i < 256; i++) {
            uint crc = i;
            for (int j = 0; j < 8; j++) {
                crc = (crc & 1) != 0 ? (crc >> 1) ^ poly : (crc >> 1);
            }
            Crc32Table[i] = crc;
        }
    }

    public static string ComputeCrc32(string filePath) {
        uint crc = 0xFFFFFFFFu;
        byte[] buffer = new byte[65536];
        using (var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read, 65536)) {
            int bytesRead;
            while ((bytesRead = stream.Read(buffer, 0, buffer.Length)) > 0) {
                for (int i = 0; i < bytesRead; i++) {
                    crc = (crc >> 8) ^ Crc32Table[(crc ^ buffer[i]) & 0xFF];
                }
            }
        }
        return (crc ^ 0xFFFFFFFFu).ToString("X8");
    }

    public static string ComputeHash(string filePath, string algoName) {
        using (var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read, 65536))
        using (var algo = HashAlgorithm.Create(algoName)) {
            if (algo == null) throw new ArgumentException("Unsupported hash algorithm: " + algoName);
            byte[] hash = algo.ComputeHash(stream);
            var sb = new StringBuilder(hash.Length * 2);
            for (int i = 0; i < hash.Length; i++) {
                sb.Append(hash[i].ToString("X2"));
            }
            return sb.ToString();
        }
    }
}
'@
    Add-Type -TypeDefinition $csharpSource
}

# ==============================================================================
# 2. Helper Functions
# ==============================================================================
$ValidAlgorithms = @('CRC32', 'MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512', 'XXHSUM', 'XXHASH', 'XXHASH64', 'XXH32', 'XXH64')

function Show-Usage {
    Write-Host @"

Syntax: hash [[Algorithm] Target] [Options]

    Algorithms:
       CRC32, MD5, SHA1, SHA256 (default), SHA384, SHA512, XXHSUM

    Targets / Modes:
       [File]         : Hash a single file or wildcard (e.g. *.iso, app.exe)
       /A             : Hash all files in current directory
       /SYNC          : Synchronize directory manifest (Audit mode; keeps missing)

    Flags:
       /PURGE         : Used with /SYNC to purge missing files from manifest
       -a             : Append calculated hash to filename [e.g. File [HASH].ext]
       -s             : Save/append hash to checksum file  [e.g. DirName.SHA256]

    Examples:
       hash myimage.iso
       hash MD5 myimage.iso -a
       hash CRC32 *.zip -s
       hash /A -s
       hash /SYNC
       hash SHA256 /SYNC /PURGE

"@
}

function Find-XxHashExe {
    param([string]$ScriptDir)
    $candidates = @(
        (Join-Path $ScriptDir "..\..\bin\xxhsum64.exe"),
        (Join-Path $ScriptDir "..\bin\xxhsum64.exe"),
        (Join-Path $ScriptDir "bin\xxhsum64.exe"),
        "xxhsum64.exe",
        "xxhsum.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            return (Resolve-Path $cand).Path
        }
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }
    return $null
}

function Get-CalculatedHash {
    param (
        [string]$FilePath,
        [string]$Algo
    )

    $AlgoUpper = $Algo.ToUpper()

    if ($AlgoUpper -in @("XXHSUM", "XXHASH", "XXHASH64", "XXH64", "XXH32")) {
        $ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
        $xxhExe = Find-XxHashExe -ScriptDir $ScriptDir
        if (-not $xxhExe) {
            throw "Executable 'xxhsum64.exe' was not found in 'bin\' or PATH. Unable to calculate $Algo."
        }
        $variantArg = if ($AlgoUpper -eq "XXH32") { "-H0 `"$FilePath`"" } else { "`"$FilePath`"" }
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $xxhExe
        $psi.Arguments = $variantArg
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($proc.ExitCode -ne 0) {
            throw "xxhsum failed with exit code $($proc.ExitCode): $stderr"
        }
        if ($stdout -match "([0-9a-fA-F]{8,32})") {
            return $matches[1].ToUpper()
        }
        throw "Could not parse xxhsum output: $stdout"
    }

    if ($AlgoUpper -eq "CRC32") {
        return [FastHash]::ComputeCrc32($FilePath)
    }

    return [FastHash]::ComputeHash($FilePath, $AlgoUpper)
}

# ==============================================================================
# 3. Parameter Guards & Normalization
# ==============================================================================
$rawPositional = [System.Collections.Generic.List[string]]::new()
foreach ($item in ($Target, $Target2, $Target3, $Target4)) {
    if (-not [string]::IsNullOrWhiteSpace($item)) {
        [void]$rawPositional.Add($item.Trim())
    }
}
foreach ($item in $args) {
    if (-not [string]::IsNullOrWhiteSpace($item)) {
        [void]$rawPositional.Add($item.Trim())
    }
}

# Fast exit for help syntax
if ($rawPositional.Count -gt 0 -and $rawPositional[0] -in @('/?', '-?', '-h', '/h', '--help', '/help', 'help')) {
    Show-Usage
    exit 0
}

$ResolvedAlgorithm = if (-not [string]::IsNullOrWhiteSpace($Algorithm)) { $Algorithm.ToUpper() } else { "" }
$ResolvedPath      = $Path
$ResolvedSync      = $Sync.IsPresent
$ResolvedPurge     = $Purge.IsPresent
$ResolvedBatch     = $false
$ResolvedAppend    = $Append.IsPresent
$ResolvedSave      = $Save.IsPresent

# Resolve positional parameters
$posIdx = 0
if ($posIdx -lt $rawPositional.Count) {
    $first = $rawPositional[0]
    $firstUpper = $first.ToUpper()
    if ($ValidAlgorithms -contains $firstUpper) {
        if (-not $ResolvedAlgorithm) { $ResolvedAlgorithm = $firstUpper }
        $posIdx = 1
    } elseif ($first -match '^[\-\/]' -and ($firstUpper -notin @('/A', '-A', '/SYNC', '-SYNC'))) {
        Write-Host "[ERROR] Unknown option: '$first'" -ForegroundColor Red
        Write-Host "Type 'hash /?' for available options." -ForegroundColor Yellow
        exit 1
    } elseif ($rawPositional.Count -ge 2 -and ($firstUpper -notin @('/A', '/SYNC', '-SYNC')) -and ($rawPositional[1] -notmatch '^-?[asAS]$')) {
        Write-Host "[ERROR] Invalid algorithm: '$first'." -ForegroundColor Red
        Write-Host "Supported algorithms: $($ValidAlgorithms -join ', ')" -ForegroundColor Yellow
        exit 1
    }
}

while ($posIdx -lt $rawPositional.Count) {
    $token = $rawPositional[$posIdx]
    if ($token -in @('/SYNC', '-SYNC', 'SYNC', '/sync', '-sync', 'sync')) {
        $ResolvedSync = $true
    }
    elseif ($token -in @('/PURGE', '-PURGE', 'PURGE', '/purge', '-purge', 'purge')) {
        $ResolvedPurge = $true
    }
    elseif ($token -in @('/A', '/a')) {
        $ResolvedBatch = $true
    }
    elseif ($token -in @('-a', '-A')) {
        $ResolvedAppend = $true
    }
    elseif ($token -in @('-s', '-S', '/s', '/S')) {
        $ResolvedSave = $true
    }
    elseif ($token -match '^[\-\/]') {
        Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
        Write-Host "Type 'hash /?' for available options." -ForegroundColor Yellow
        exit 1
    }
    else {
        if (-not $ResolvedPath -and -not $ResolvedSync -and -not $ResolvedBatch) {
            $ResolvedPath = $token
        } elseif ($ResolvedSync -and (-not $OutputFile -or $OutputFile -eq "hashes.txt")) {
            $OutputFile = $token
        }
    }
    $posIdx++
}

# Default Algorithm if unspecified
if ([string]::IsNullOrWhiteSpace($ResolvedAlgorithm)) {
    $ResolvedAlgorithm = "SHA256"
}

# Validate Algorithm Guard
if ($ValidAlgorithms -notcontains $ResolvedAlgorithm) {
    Write-Host "[ERROR] Invalid algorithm: '$ResolvedAlgorithm'." -ForegroundColor Red
    Write-Host "Supported algorithms: $($ValidAlgorithms -join ', ')" -ForegroundColor Yellow
    exit 1
}

# Guard against /PURGE without /SYNC
if ($ResolvedPurge -and -not $ResolvedSync) {
    Write-Host "[ERROR] /PURGE can only be used with /SYNC." -ForegroundColor Red
    exit 1
}

# Guard against no target provided
if (-not $ResolvedSync -and -not $ResolvedBatch -and [string]::IsNullOrWhiteSpace($ResolvedPath)) {
    Show-Usage
    exit 0
}

# ==============================================================================
# 4. Execution Mode Dispatch
# ==============================================================================

# --- MODE 1: Directory Sync Engine (/SYNC) ---
if ($ResolvedSync) {
    $targetDir = if (-not [string]::IsNullOrWhiteSpace($ResolvedPath)) { $ResolvedPath } else { "." }
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        Write-Host "[ERROR] Target directory not found: '$targetDir'" -ForegroundColor Red
        exit 1
    }

    $ResolvedRoot = (Resolve-Path $targetDir).Path
    $OutputFileResolved = [System.IO.Path]::GetFullPath((Join-Path $ResolvedRoot $OutputFile))

    Write-Host "[SYNC] Processing manifest ($ResolvedAlgorithm) for: $ResolvedRoot" -ForegroundColor Cyan
    if ($ResolvedPurge) {
        Write-Host "       Mode: PURGE (Missing files will be removed)" -ForegroundColor Yellow
    } else {
        Write-Host "       Mode: AUDIT (Missing files will be retained and flagged)" -ForegroundColor Gray
    }

    $ExistingRecords = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # Load existing manifest if present
    if ([System.IO.File]::Exists($OutputFileResolved)) {
        $manifestRegex = [regex]'^(?:#\s*)?([0-9a-fA-F]{8,128})\s+\*?([^\#\r\n]+?)(?:\s+#.*)?$'
        foreach ($line in [System.IO.File]::ReadLines($OutputFileResolved)) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $m = $manifestRegex.Match($line)
            if ($m.Success) {
                $h = $m.Groups[1].Value.ToUpper()
                $p = $m.Groups[2].Value.Trim()
                $ExistingRecords[$p] = $h
            }
        }
    }

    $foundRelPaths  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $manifestLines  = [System.Collections.Generic.List[string]]::new()
    $prefixLen      = $ResolvedRoot.TrimEnd('\').Length + 1
    $processedCount = 0

    $diskFiles = [System.IO.Directory]::EnumerateFiles($ResolvedRoot, "*", [System.IO.SearchOption]::AllDirectories)

    foreach ($filePath in $diskFiles) {
        if ($filePath -eq $OutputFileResolved) { continue }

        $relPath = $filePath.Substring($prefixLen)
        [void]$foundRelPaths.Add($relPath)

        try {
            $hash = Get-CalculatedHash -FilePath $filePath -Algo $ResolvedAlgorithm
            $manifestLines.Add("$hash *$relPath")
            $processedCount++

            if ($ExistingRecords.ContainsKey($relPath)) {
                if ($ExistingRecords[$relPath] -eq $hash) {
                    Write-Host "  [OK] $relPath" -ForegroundColor DarkGray
                } else {
                    Write-Host "  [MODIFIED] $relPath" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [NEW] $relPath" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [ERROR] Failed to hash '$relPath': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Process missing files
    foreach ($oldPath in $ExistingRecords.Keys) {
        if (-not $foundRelPaths.Contains($oldPath)) {
            if ($ResolvedPurge) {
                Write-Host "  [PURGED] $oldPath" -ForegroundColor Red
            } else {
                Write-Host "  [MISSING] $oldPath (Retained in manifest)" -ForegroundColor Red
                $manifestLines.Add("$($ExistingRecords[$oldPath]) *$oldPath # MISSING")
            }
        }
    }

    [System.IO.File]::WriteAllLines($OutputFileResolved, $manifestLines, [System.Text.Encoding]::UTF8)
    Write-Host "`n[SUCCESS] Manifest updated: $OutputFileResolved" -ForegroundColor Green
    Write-Host "Total verified: $processedCount | Tracked entries: $($manifestLines.Count)" -ForegroundColor Cyan
    exit 0
}

# --- MODE 2: Directory Batch Processing (/A) ---
if ($ResolvedBatch -or $ResolvedPath -in @("/A", "-A")) {
    $currentDir = (Get-Location).Path
    Write-Host "[BATCH] Calculating $ResolvedAlgorithm for all files in: $currentDir..." -ForegroundColor Yellow

    $files = [System.IO.Directory]::EnumerateFiles($currentDir)
    $saveLines = [System.Collections.Generic.List[string]]::new()
    $count = 0

    foreach ($filePath in $files) {
        $fileName = [System.IO.Path]::GetFileName($filePath)
        try {
            $hash = Get-CalculatedHash -FilePath $filePath -Algo $ResolvedAlgorithm
            Write-Host "File: $fileName"
            Write-Host "Hash: $hash`n"
            $count++

            if ($ResolvedSave) {
                $saveLines.Add("$hash *$fileName")
            }

            if ($ResolvedAppend) {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
                $ext      = [System.IO.Path]::GetExtension($filePath)

                if ($baseName -match "\[$hash\]$") {
                    Write-Host "  [SKIP] Already contains hash tag: $fileName" -ForegroundColor DarkGray
                } else {
                    $cleanBase = $baseName -replace "\s*\[[0-9a-fA-F]{8,128}\]$", ""
                    $newName   = "$cleanBase [$hash]$ext"
                    Rename-Item -LiteralPath $filePath -NewName $newName
                    Write-Host "  [RENAMED] -> $newName" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "  [ERROR] Failed to hash '$fileName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    if ($ResolvedSave -and $saveLines.Count -gt 0) {
        $dirName = (Get-Item $currentDir).Name
        $outFile = Join-Path $currentDir "$dirName.$ResolvedAlgorithm"
        [System.IO.File]::AppendAllLines($outFile, $saveLines, [System.Text.Encoding]::UTF8)
        Write-Host "[SAVED] Checksums appended to $outFile" -ForegroundColor Green
    }

    Write-Host "[DONE] Processed $count files." -ForegroundColor Cyan
    exit 0
}

# --- MODE 3: Single File or Wildcard Processing ---
$matchedItems = @()

if ($ResolvedPath -match '[\*\?]') {
    $matchedItems = @(Get-ChildItem -Path $ResolvedPath -File -ErrorAction SilentlyContinue)
    if ($matchedItems.Count -eq 0) {
        Write-Host "[ERROR] No files matched wildcard pattern: '$ResolvedPath'" -ForegroundColor Red
        exit 1
    }
} else {
    if (Test-Path -LiteralPath $ResolvedPath -PathType Leaf) {
        $matchedItems = @(Get-Item -LiteralPath $ResolvedPath)
    } elseif (Test-Path -LiteralPath $ResolvedPath -PathType Container) {
        Write-Host "[ERROR] Target '$ResolvedPath' is a directory." -ForegroundColor Red
        Write-Host "Use /A to hash all files in directory, or /SYNC to synchronize manifest." -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "[ERROR] File not found: '$ResolvedPath'" -ForegroundColor Red
        exit 1
    }
}

$saveLines = [System.Collections.Generic.List[string]]::new()

foreach ($item in $matchedItems) {
    Write-Host "File: $($item.Name)"
    Write-Host "Calculating $ResolvedAlgorithm Checksum..."

    try {
        $hash = Get-CalculatedHash -FilePath $item.FullName -Algo $ResolvedAlgorithm
        Write-Host "Hash: $hash`n"

        if ($ResolvedSave) {
            $saveLines.Add("$hash *$($item.Name)")
        }

        if ($ResolvedAppend) {
            $baseName = $item.BaseName
            $ext      = $item.Extension

            if ($baseName -match "\[$hash\]$") {
                Write-Host "  [SKIP] Already contains hash tag: $($item.Name)" -ForegroundColor DarkGray
            } else {
                $cleanBase = $baseName -replace "\s*\[[0-9a-fA-F]{8,128}\]$", ""
                $newName   = "$cleanBase [$hash]$ext"
                Rename-Item -LiteralPath $item.FullName -NewName $newName
                Write-Host "  [RENAMED] -> $newName" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  [ERROR] Failed to process '$($item.Name)': $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($ResolvedSave -and $saveLines.Count -gt 0) {
    $currentDir = (Get-Location).Path
    $dirName = (Get-Item $currentDir).Name
    $outFile = Join-Path $currentDir "$dirName.$ResolvedAlgorithm"
    [System.IO.File]::AppendAllLines($outFile, $saveLines, [System.Text.Encoding]::UTF8)
    Write-Host "[SAVED] Appended to $outFile" -ForegroundColor Green
}

exit 0
