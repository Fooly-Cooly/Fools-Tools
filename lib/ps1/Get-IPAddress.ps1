<#
.SYNOPSIS
    IP Address Discovery Utility for FoolsTools.

.DESCRIPTION
    Retrieves internal (LAN) and external (WAN) IPv4 and IPv6 network addresses
    using high-performance .NET NetworkInterface probing and dual-stack HTTP discovery.
    Supports Windows 7 and later (PowerShell 2.0+ and PowerShell 5.1/7+).

.PARAMETER InternalOnly
    Restricts discovery to internal (LAN) network addresses.

.PARAMETER ExternalOnly
    Restricts discovery to external (WAN / Public) network addresses.

.PARAMETER IPv4
    Filters results to IPv4 addresses only.

.PARAMETER IPv6
    Filters results to IPv6 addresses only.

.PARAMETER Raw
    Outputs raw IP addresses only (ideal for scripting and pipelines).

.PARAMETER Json
    Outputs discovery results formatted as a JSON object.

.PARAMETER NoColor
    Disables console color formatting for plain-text display.

.EXAMPLE
    Get-IPAddress.ps1
    Displays full colorized overview of internal and external IP addresses.

.EXAMPLE
    Get-IPAddress.ps1 -InternalOnly -IPv4 -Raw
    Outputs the primary internal IPv4 address only.

.EXAMPLE
    Get-IPAddress.ps1 -Json
    Outputs full network IP details as JSON.
#>

Set-StrictMode -Off

# Ensure UTF-8 output encoding
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# Enable TLS 1.2 for external HTTP lookups on older .NET runtimes
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12 -bor 3072
} catch {}

# ==============================================================================
# 1. Parameter Normalization & Guards
# ==============================================================================
$InternalOnly = $false
$ExternalOnly = $false
$IPv4Only     = $false
$IPv6Only     = $false
$RawOutput    = $false
$JsonOutput   = $false
$NoColor      = $false

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: show-ip [Options]

   Displays local and external IPv4/IPv6 network addresses.

   Options / Flags:
      -InternalOnly, -i : Display only internal (LAN) network addresses
      -ExternalOnly, -e : Display only external (Public) network addresses
      -IPv4, -4         : Restrict discovery to IPv4 addresses
      -IPv6, -6         : Restrict discovery to IPv6 addresses
      -Raw, -r          : Output raw IP address values only (for scripting)
      -Json, -j         : Output results as a structured JSON object
      -NoColor, -nc     : Disable console color formatting (plain text)
      -?, -h, --help    : Display this syntax help

   Examples:
      show-ip
      show-ip -InternalOnly -IPv4
      show-ip -ExternalOnly -Raw
      show-ip -Json

"@
}

foreach ($token in $args) {
    if ($HelpSwitches -contains $token.ToLower()) {
        Show-Usage
        exit 0
    }
    elseif ($token -in @('-InternalOnly', '-internal', '/internal', '-i', '/i')) {
        $InternalOnly = $true
    }
    elseif ($token -in @('-ExternalOnly', '-external', '/external', '-e', '/e')) {
        $ExternalOnly = $true
    }
    elseif ($token -in @('-IPv4', '-ipv4', '/ipv4', '-4', '/4')) {
        $IPv4Only = $true
    }
    elseif ($token -in @('-IPv6', '-ipv6', '/ipv6', '-6', '/6')) {
        $IPv6Only = $true
    }
    elseif ($token -in @('-Raw', '-raw', '/raw', '-r', '/r')) {
        $RawOutput = $true
    }
    elseif ($token -in @('-Json', '-json', '/json', '-j', '/j')) {
        $JsonOutput = $true
    }
    elseif ($token -in @('-NoColor', '--nocolor', '/nocolor', '-nc', '/nc')) {
        $NoColor = $true
    }
    else {
        Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
        Write-Host "Type 'show-ip /?' for available options." -ForegroundColor Yellow
        exit 1
    }
}

# If neither Internal nor External was specified, query both
$queryInternal = (-not $ExternalOnly)
$queryExternal = (-not $InternalOnly)

# If neither IPv4 nor IPv6 was specified, query both
$queryIPv4 = (-not $IPv6Only)
$queryIPv6 = (-not $IPv4Only)

# ==============================================================================
# 2. Internal Network Discovery (.NET NetworkInterface & Sockets)
# ==============================================================================
$internalRecords = @()
$primaryLocalIPv4 = $null

if ($queryInternal) {
    # Pinpoint primary gateway-routed local IPv4 via 1ms non-blocking UDP socket route query
    try {
        $udp = [System.Net.Sockets.UdpClient]::new()
        $udp.Connect("1.1.1.1", 53)
        $primaryLocalIPv4 = $udp.Client.LocalEndPoint.Address.ToString()
        $udp.Close()
    } catch {}

    try {
        $adapters = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object {
            $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback'
        }

        foreach ($adapter in $adapters) {
            $props = $adapter.GetIPProperties()
            foreach ($unicast in $props.UnicastAddresses) {
                $addr = $unicast.Address
                if ($addr.AddressFamily -eq 'InterNetwork') {
                    $ipStr = $addr.ToString()
                    # Skip APIPA link-local (169.254.x.x)
                    if (-not $ipStr.StartsWith("169.254.")) {
                        $isPrimary = ($ipStr -eq $primaryLocalIPv4)
                        $internalRecords += [PSCustomObject]@{
                            Family     = "IPv4"
                            IP         = $ipStr
                            Adapter    = $adapter.Name
                            IsPrimary  = $isPrimary
                            IsLinkLocal = $false
                        }
                    }
                }
                elseif ($addr.AddressFamily -eq 'InterNetworkV6') {
                    $ipStr = $addr.ToString()
                    # Skip loopback ::1
                    if ($ipStr -ne "::1") {
                        $internalRecords += [PSCustomObject]@{
                            Family     = "IPv6"
                            IP         = $ipStr
                            Adapter    = $adapter.Name
                            IsPrimary  = $false
                            IsLinkLocal = $addr.IsIPv6LinkLocal
                        }
                    }
                }
            }
        }
    } catch {}
}

# ==============================================================================
# 3. External Network Discovery (HTTP Dual-Stack with Timeout)
# ==============================================================================
$externalIPv4 = $null
$externalIPv6 = $null

function Get-ExternalHttpIP([string]$endpointUrl, [int]$timeoutMs = 2500) {
    try {
        $req = [System.Net.HttpWebRequest]::Create($endpointUrl)
        $req.Timeout = $timeoutMs
        $req.ReadWriteTimeout = $timeoutMs
        $req.UserAgent = "FoolsTools/1.0"
        $resp = $req.GetResponse()
        $stream = $resp.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $result = $reader.ReadToEnd().Trim()
        $reader.Close()
        $stream.Close()
        $resp.Close()
        return $result
    } catch {
        return $null
    }
}

if ($queryExternal) {
    if ($queryIPv4) {
        $externalIPv4 = Get-ExternalHttpIP "https://api.ipify.org" 2500
    }
    if ($queryIPv6) {
        # api64.ipify.org resolves both A and AAAA; if the client has IPv6 route it returns IPv6
        $dualCheck = Get-ExternalHttpIP "https://api64.ipify.org" 2500
        if ($dualCheck -and $dualCheck -match ':') {
            $externalIPv6 = $dualCheck
        }
    }
}

# ==============================================================================
# 4. Output Formatting (Raw, JSON, or Console Display)
# ==============================================================================

# --- RAW Output Mode ---
if ($RawOutput) {
    if ($InternalOnly) {
        if ($IPv4Only) {
            $match = $internalRecords | Where-Object { $_.Family -eq 'IPv4' -and $_.IsPrimary } | Select-Object -First 1
            if (-not $match) { $match = $internalRecords | Where-Object { $_.Family -eq 'IPv4' } | Select-Object -First 1 }
            if ($match) { Write-Output $match.IP }
        } elseif ($IPv6Only) {
            $match = $internalRecords | Where-Object { $_.Family -eq 'IPv6' } | Select-Object -First 1
            if ($match) { Write-Output $match.IP }
        } else {
            foreach ($r in $internalRecords) { Write-Output $r.IP }
        }
    } elseif ($ExternalOnly) {
        if ($IPv4Only) {
            if ($externalIPv4) { Write-Output $externalIPv4 }
        } elseif ($IPv6Only) {
            if ($externalIPv6) { Write-Output $externalIPv6 }
        } else {
            if ($externalIPv4) { Write-Output $externalIPv4 }
            if ($externalIPv6) { Write-Output $externalIPv6 }
        }
    } else {
        if ($queryIPv4) {
            $match = $internalRecords | Where-Object { $_.Family -eq 'IPv4' -and $_.IsPrimary } | Select-Object -First 1
            if ($match) { Write-Output $match.IP }
            if ($externalIPv4) { Write-Output $externalIPv4 }
        }
        if ($queryIPv6) {
            $match = $internalRecords | Where-Object { $_.Family -eq 'IPv6' } | Select-Object -First 1
            if ($match) { Write-Output $match.IP }
            if ($externalIPv6) { Write-Output $externalIPv6 }
        }
    }
    exit 0
}

# --- JSON Output Mode ---
if ($JsonOutput) {
    $outObj = @{
        Internal = @($internalRecords | Where-Object {
            (-not $IPv4Only -or $_.Family -eq 'IPv4') -and (-not $IPv6Only -or $_.Family -eq 'IPv6')
        })
        External = @{
            IPv4 = if ($queryIPv4) { $externalIPv4 } else { $null }
            IPv6 = if ($queryIPv6) { $externalIPv6 } else { $null }
        }
    }
    Write-Output ($outObj | ConvertTo-Json -Depth 3)
    exit 0
}

# --- Human-Readable Console Output Mode ---
function Write-HeaderLine([string]$title) {
    if ($NoColor) {
        Write-Host ""
        Write-Host $title
        Write-Host ("-" * 70)
    } else {
        Write-Host ""
        Write-Host $title -ForegroundColor Cyan
        Write-Host ("-" * 70) -ForegroundColor DarkGray
    }
}

# Render Internal Network IPs
if ($queryInternal) {
    Write-HeaderLine "Local Network (Internal):"

    $filteredInternal = $internalRecords | Where-Object {
        (-not $IPv4Only -or $_.Family -eq 'IPv4') -and (-not $IPv6Only -or $_.Family -eq 'IPv6')
    } | Sort-Object -Property @{ Expression = { if ($_.Family -eq 'IPv4') { 0 } else { 1 } } }, @{ Expression = "IsPrimary"; Descending = $true }

    if ($filteredInternal.Count -eq 0) {
        if ($NoColor) {
            Write-Host "  No operational network adapters detected."
        } else {
            Write-Host "  No operational network adapters detected." -ForegroundColor DarkYellow
        }
    } else {
        foreach ($rec in $filteredInternal) {
            $padFamily = "$($rec.Family):".PadRight(7)
            $padIP     = $rec.IP.PadRight(30)
            $badge     = "[$($rec.Adapter)]"
            $primary   = if ($rec.IsPrimary) { " [Primary]" } else { "" }
            $linkLocal = if ($rec.IsLinkLocal) { " (Link-Local)" } else { "" }

            if ($NoColor) {
                Write-Host "  $padFamily $padIP $badge$primary$linkLocal"
            } else {
                Write-Host "  $padFamily " -NoNewline
                Write-Host $padIP -ForegroundColor White -NoNewline
                Write-Host " $badge" -ForegroundColor DarkGray -NoNewline
                if ($primary) {
                    Write-Host $primary -ForegroundColor Green -NoNewline
                }
                if ($linkLocal) {
                    Write-Host $linkLocal -ForegroundColor DarkGray -NoNewline
                }
                Write-Host ""
            }
        }
    }
}

# Render External Network IPs
if ($queryExternal) {
    Write-HeaderLine "External Network (Public):"

    if ($queryIPv4) {
        $padLabel = "IPv4:".PadRight(7)
        if ($externalIPv4) {
            if ($NoColor) {
                Write-Host "  $padLabel $externalIPv4"
            } else {
                Write-Host "  $padLabel " -NoNewline
                Write-Host $externalIPv4 -ForegroundColor White
            }
        } else {
            if ($NoColor) {
                Write-Host "  $padLabel Unable to retrieve external IPv4 address (offline/timeout)."
            } else {
                Write-Host "  $padLabel " -NoNewline
                Write-Host "Unable to retrieve external IPv4 address (offline/timeout)." -ForegroundColor DarkYellow
            }
        }
    }

    if ($queryIPv6) {
        $padLabel = "IPv6:".PadRight(7)
        if ($externalIPv6) {
            if ($NoColor) {
                Write-Host "  $padLabel $externalIPv6"
            } else {
                Write-Host "  $padLabel " -NoNewline
                Write-Host $externalIPv6 -ForegroundColor White
            }
        } else {
            if ($NoColor) {
                Write-Host "  $padLabel No external IPv6 address detected (IPv4-only connection)."
            } else {
                Write-Host "  $padLabel " -NoNewline
                Write-Host "No external IPv6 address detected (IPv4-only connection)." -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host ""
exit 0
