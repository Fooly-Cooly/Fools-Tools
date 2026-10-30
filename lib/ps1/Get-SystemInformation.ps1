<#
.SYNOPSIS
    System Information Fetch Tool (Screenfetch / Archey clone for Windows).

.DESCRIPTION
    Collects system hardware and OS information using fast .NET WMI queries,
    and displays it alongside a colorized 4-quadrant Windows ASCII art logo.
    Uses native console color attributes for universal compatibility across all
    Windows versions (Windows 11, 10, 8, 7, and XP).

.PARAMETER NoColor
    Disables color formatting for plain-text output.

.EXAMPLE
    system-information
    Displays colorized system specs with Windows logo.

.EXAMPLE
    system-information -NoColor
    Displays plain-text system specs.
#>

Set-StrictMode -Off

# Ensure UTF-8 output in console
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ==============================================================================
# 1. Parameter Guards & Normalization
# ==============================================================================
$NoColor = $false
$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: system-information [Options]

   Displays system hardware and OS specs with colorized Windows ASCII art
   (Screenfetch / Archey clone for Windows).

   Options / Flags:
      -NoColor, /NOCOLOR : Disable color formatting (plain text)
      -?, /?, -h, --help : Display this syntax help

   Examples:
      system-information
      system-information -NoColor

"@
}

foreach ($token in $args) {
    if ($HelpSwitches -contains $token.ToLower()) {
        Show-Usage
        exit 0
    }
    elseif ($token -in @('-NoColor', '--nocolor', '/NOCOLOR', '-nocolor', '/nocolor', '-nc', '/nc')) {
        $NoColor = $true
    }
    else {
        Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
        Write-Host "Type 'system-information /?' for available options." -ForegroundColor Yellow
        exit 1
    }
}

# ==============================================================================
# 2. Fast Hardware & OS Probing (Targeted .NET WMI)
# ==============================================================================
function Query-WmiFirst([string]$query) {
    try {
        $searcher = [System.Management.ManagementObjectSearcher]::new($query)
        foreach ($obj in $searcher.Get()) {
            return $obj
        }
    } catch {}
    return $null
}

function Query-WmiAll([string]$query) {
    $list = [System.Collections.Generic.List[System.Management.ManagementObject]]::new()
    try {
        $searcher = [System.Management.ManagementObjectSearcher]::new($query)
        foreach ($obj in $searcher.Get()) {
            $list.Add($obj)
        }
    } catch {}
    return $list
}

$osObj     = Query-WmiFirst "SELECT Caption, Version, BuildNumber, OSArchitecture, TotalVisibleMemorySize, FreePhysicalMemory, LastBootUpTime FROM Win32_OperatingSystem"
$cpuObj    = Query-WmiFirst "SELECT Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed FROM Win32_Processor"
$gpuItems  = Query-WmiAll   "SELECT Name, AdapterRAM FROM Win32_VideoController"
$moboObj   = Query-WmiFirst "SELECT Manufacturer, Product FROM Win32_BaseBoard"
$ramItems  = Query-WmiAll   "SELECT Capacity, PartNumber FROM Win32_PhysicalMemory"
$diskObj   = Query-WmiFirst "SELECT DeviceID, Size, FreeSpace FROM Win32_LogicalDisk WHERE DeviceID = 'C:'"

$gpuObj = $null
foreach ($g in $gpuItems) {
    if ($g.AdapterRAM -gt 0 -or ($g.Name -and $g.Name -notmatch "Basic|Remote")) {
        $gpuObj = $g
        break
    }
}
if (-not $gpuObj -and $gpuItems.Count -gt 0) { $gpuObj = $gpuItems[0] }

# --- Process Data ---
$userHost = "$($env:USERNAME)@$($env:COMPUTERNAME)"

# OS Caption & Architecture
$osCaption = if ($osObj -and $osObj.Caption) { $osObj.Caption.Trim() } else { "Microsoft Windows" }
$osArch    = if ($osObj -and $osObj.OSArchitecture) { $osObj.OSArchitecture.Trim() } else { "" }
$osBuild   = if ($osObj -and $osObj.BuildNumber) { "Build $($osObj.BuildNumber)" } else { "" }
$osString  = ("$osCaption $osArch ($osBuild)").Replace("  ", " ").Trim()

# Host / Motherboard
$moboMfg  = if ($moboObj -and $moboObj.Manufacturer) { ($moboObj.Manufacturer.Trim() -replace "(Technology|Co\.|Ltd\.|\,)", "").Trim() } else { "" }
$moboProd = if ($moboObj -and $moboObj.Product) { $moboObj.Product.Trim() } else { "" }
$hostString = "$moboMfg $moboProd".Trim().Replace("  ", " ")
if ([string]::IsNullOrWhiteSpace($hostString)) { $hostString = "Windows PC" }

# Kernel
$kernelString = if ($osObj -and $osObj.Version) { "Windows NT $($osObj.Version)" } else { "Windows NT" }

# Uptime
$uptimeString = "N/A"
if ($osObj -and $osObj.LastBootUpTime) {
    try {
        $bootDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($osObj.LastBootUpTime)
        $diff = (Get-Date) - $bootDate
        $uptimeString = "{0}d {1}h {2}m" -f $diff.Days, $diff.Hours, $diff.Minutes
    } catch {}
}

# CPU
$cpuName = if ($cpuObj -and $cpuObj.Name) { ($cpuObj.Name.Trim() -replace '\s+', ' ') } else { "Unknown CPU" }
$cores   = if ($cpuObj -and $cpuObj.NumberOfCores) { $cpuObj.NumberOfCores } else { 0 }
$threads = if ($cpuObj -and $cpuObj.NumberOfLogicalProcessors) { $cpuObj.NumberOfLogicalProcessors } else { 0 }
$coreString = if ($cores -gt 0) { " ($cores" + "C / $threads" + "T)" } else { "" }
$cpuString = "$cpuName$coreString"

# GPU
$gpuString = if ($gpuObj -and $gpuObj.Name) { $gpuObj.Name.Trim() } else { "Unknown GPU" }

# Memory (RAM)
$totalRamGB = if ($osObj -and $osObj.TotalVisibleMemorySize) { [Math]::Round($osObj.TotalVisibleMemorySize / 1MB, 1) } else { 0 }
$freeRamGB  = if ($osObj -and $osObj.FreePhysicalMemory) { [Math]::Round($osObj.FreePhysicalMemory / 1MB, 1) } else { 0 }
$usedRamGB  = [Math]::Round(($totalRamGB - $freeRamGB), 1)
$ramPct     = if ($totalRamGB -gt 0) { [Math]::Round(($usedRamGB / $totalRamGB) * 100) } else { 0 }
$ramParts   = @($ramItems | ForEach-Object { if ($_.PartNumber) { $_.PartNumber.Trim() } } | Where-Object { $_ } | Select-Object -Unique)
$ramPartStr = if ($ramParts.Count -gt 0) { " - " + ($ramParts -join ', ') } else { "" }
$memString  = "$usedRamGB GB / $totalRamGB GB ($ramPct%)$ramPartStr"

# Primary Disk (C:)
$diskString = "N/A"
if ($diskObj -and $diskObj.Size) {
    $totalDk = [Math]::Round($diskObj.Size / 1GB, 1)
    $freeDk  = [Math]::Round($diskObj.FreeSpace / 1GB, 1)
    $usedDk  = [Math]::Round(($totalDk - $freeDk), 1)
    $dkPct   = if ($totalDk -gt 0) { [Math]::Round(($usedDk / $totalDk) * 100) } else { 0 }
    $diskString = "$($diskObj.DeviceID) $usedDk GB / $totalDk GB ($dkPct%)"
}

# ==============================================================================
# 3. Logo Lines Definition
# ==============================================================================
$logoLines = @(
    '              $$$$$$$$$$$$',
    '           $$$$$$$$$$$$$$$$$$$',
    '          $$$$$$$$$$$$$$$$$$$$',
    '          $$$$$$$$$$$$$$$$$$$$   XX',
    '         $$$$$$$$$$$$$$$$$$$$   XXXXXXXX       XXXXXX',
    '         $$$$$$$$$$$$$$$$$$$$   XXXXXXXXXXXXXXXXXXXX',
    '        $$$$$$$$$$$$$$$$$$$$   XXXXXXXXXXXXXXXXXXXXX',
    '        $$$$$$$$$$$$$$$$$$$$   XXXXXXXXXXXXXXXXXXXX',
    '       $$$$$$$$$$$$$$$$$$$$   XXXXXXXXXXXXXXXXXXXX',
    '       $$$$$$$$$$$$$$$$$$$$   XXXXXXXXXXXXXXXXXXXX',
    '      $$$             $$$$   XXXXXXXXXXXXXXXXXXXX',
    '          #########      $   XXXXXXXXXXXXXXXXXXXX',
    '     ##################     XXXXXXXXXXXXXXXXXXXX',
    '    #####################      XXXXXXXXXXXXXXXX',
    '    ####################   RR       XXXXX',
    '   #####################   RRRRRR         RRRRR',
    '   ####################   RRRRRRRRRRRRRRRRRRRR',
    '  #####################  RRRRRRRRRRRRRRRRRRRRR',
    '  ####################   RRRRRRRRRRRRRRRRRRRR',
    ' #####################  RRRRRRRRRRRRRRRRRRRRR',
    ' ####################   RRRRRRRRRRRRRRRRRRRR',
    '#####         ######   RRRRRRRRRRRRRRRRRRRRR',
    '                  ##   RRRRRRRRRRRRRRRRRRRR',
    '                      RRRRRRRRRRRRRRRRRRRRR',
    '                        RRRRRRRRRRRRRRRRRR',
    '                            RRRRRRRR'
)

$logoPadWidth = 55
$startInfoRow = 6
$dash = '-' * $userHost.Length

# Structured info items: each has Type, Label, Value
$infoItems = @(
    @{ Type = "Header"; Value = $userHost },
    @{ Type = "Separator"; Value = $dash },
    @{ Type = "Field"; Label = "OS:"; Value = $osString },
    @{ Type = "Field"; Label = "Host:"; Value = $hostString },
    @{ Type = "Field"; Label = "Kernel:"; Value = $kernelString },
    @{ Type = "Field"; Label = "Uptime:"; Value = $uptimeString },
    @{ Type = "Field"; Label = "CPU:"; Value = $cpuString },
    @{ Type = "Field"; Label = "GPU:"; Value = $gpuString },
    @{ Type = "Field"; Label = "Memory:"; Value = $memString },
    @{ Type = "Field"; Label = "Disk:"; Value = $diskString },
    @{ Type = "Empty" },
    @{ Type = "Palette1" },
    @{ Type = "Palette2" }
)

# ==============================================================================
# 4. Rendering Engine (Unified Native Console Color & Plain-Text)
# ==============================================================================
$blk = [string]([char]0x2588) + [string]([char]0x2588) + [string]([char]0x2588)

Write-Host ""

function Write-LogoLine([string]$line, [int]$padWidth, [bool]$colored) {
    if ($colored) {
        $matches = [regex]::Matches($line, '(\$+)|(X+)|(#+)|(R+)|( +)')
        foreach ($m in $matches) {
            $val = $m.Value
            if ($val.StartsWith('$'))      { Write-Host $val -ForegroundColor Red -NoNewline }
            elseif ($val.StartsWith('X'))  { Write-Host $val -ForegroundColor Green -NoNewline }
            elseif ($val.StartsWith('#'))  { Write-Host $val -ForegroundColor Cyan -NoNewline }
            elseif ($val.StartsWith('R'))  { Write-Host $val -ForegroundColor Yellow -NoNewline }
            else                           { Write-Host $val -NoNewline }
        }
    } else {
        Write-Host $line -NoNewline
    }
    if ($line.Length -lt $padWidth) {
        Write-Host (' ' * ($padWidth - $line.Length)) -NoNewline
    }
}

for ($i = 0; $i -lt $logoLines.Count; $i++) {
    Write-LogoLine $logoLines[$i] $logoPadWidth (-not $NoColor)
    $infoIdx = $i - $startInfoRow

    if ($infoIdx -ge 0 -and $infoIdx -lt $infoItems.Count) {
        $item = $infoItems[$infoIdx]
        Write-Host "  " -NoNewline
        if ($NoColor) {
            switch ($item.Type) {
                "Header"    { Write-Host $item.Value }
                "Separator" { Write-Host $item.Value }
                "Field"     { Write-Host ($item.Label.PadRight(13) + $item.Value) }
                default     { Write-Host "" }
            }
        } else {
            switch ($item.Type) {
                "Header"    { Write-Host $item.Value -ForegroundColor Cyan }
                "Separator" { Write-Host $item.Value -ForegroundColor DarkGray }
                "Field"     {
                    Write-Host $item.Label.PadRight(13) -ForegroundColor Cyan -NoNewline
                    Write-Host $item.Value -ForegroundColor White
                }
                "Empty"     { Write-Host "" }
                "Palette1"  {
                    $cols1 = @('Black', 'DarkRed', 'DarkGreen', 'DarkYellow', 'DarkBlue', 'DarkMagenta', 'DarkCyan', 'Gray')
                    foreach ($c in $cols1) { Write-Host "$blk " -ForegroundColor $c -NoNewline }
                    Write-Host ""
                }
                "Palette2"  {
                    $cols2 = @('DarkGray', 'Red', 'Green', 'Yellow', 'Blue', 'Magenta', 'Cyan', 'White')
                    foreach ($c in $cols2) { Write-Host "$blk " -ForegroundColor $c -NoNewline }
                    Write-Host ""
                }
            }
        }
    } else {
        Write-Host ""
    }
}

Write-Host ""
