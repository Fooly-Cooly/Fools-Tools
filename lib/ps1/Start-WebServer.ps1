<#
.SYNOPSIS
    Lightweight, zero-dependency local web server for Fool's Tools.

.DESCRIPTION
    Serves static files and directory listings from any folder using .NET System.Net.HttpListener.
    Includes built-in support for CORS, comprehensive MIME types, path traversal security,
    and optional HTTPS (when elevated).

.EXAMPLE
    webserver
    Serves the current directory at http://localhost:8080/

.EXAMPLE
    webserver 9000
    Serves the current directory on port 9000.

.EXAMPLE
    webserver 8080 "C:\MySite" -Cors
    Serves C:\MySite on port 8080 with CORS enabled.

.EXAMPLE
    webserver -Cors
    Serves the current directory with CORS headers enabled.
#>

Set-StrictMode -Off

# ==============================================================================
# 1. Parameter Guards & Normalization (Robust $args parsing)
# ==============================================================================
$Port = 8080
$Path = (Get-Location).Path
$Cors = $false
$Https = $false

$HelpSwitches = @('/?', '-?', '-h', '/h', '--help', '/help', 'help')

function Show-Usage {
    Write-Host @"

Syntax: webserver [[Port] Directory] [Options]

   Options / Flags:
      [Port]         : Port number to listen on (Default: 8080)
      [Directory]    : Root directory to serve (Default: current directory)
      -Cors, /CORS   : Enable Cross-Origin Resource Sharing headers
      -Https, /HTTPS : Enable HTTPS (requires Administrator elevation)

   Examples:
      webserver
      webserver 9000
      webserver 8080 "C:\MySite"
      webserver 8080 -Cors
      webserver -Cors

"@
}

$posIndex = 0
while ($posIndex -lt $args.Count) {
    $token = $args[$posIndex]

    if ($HelpSwitches -contains $token.ToLower()) {
        Show-Usage
        exit 0
    }

    # If it starts with - or /
    if ($token -match '^[\-\/]') {
        $clean = $token.TrimStart('-', '/').ToLower()
        switch ($clean) {
            { $_ -in @('cors', 'c') } {
                $Cors = $true
            }
            { $_ -in @('https', 'ssl') } {
                $Https = $true
            }
            { $_ -in @('port', 'p') } {
                $posIndex++
                if ($posIndex -ge $args.Count) {
                    Write-Host "[ERROR] Missing value for option '$token'." -ForegroundColor Red
                    exit 1
                }
                $val = $args[$posIndex]
                if ($val -notmatch '^\d+$') {
                    Write-Host "[ERROR] Invalid port number: '$val'. Must be a positive integer." -ForegroundColor Red
                    exit 1
                }
                $Port = [int]$val
            }
            { $_ -in @('path', 'dir', 'd') } {
                $posIndex++
                if ($posIndex -ge $args.Count) {
                    Write-Host "[ERROR] Missing value for option '$token'." -ForegroundColor Red
                    exit 1
                }
                $Path = $args[$posIndex]
            }
            default {
                Write-Host "[ERROR] Unknown option: '$token'" -ForegroundColor Red
                Write-Host "Type 'webserver /?' for available options." -ForegroundColor Yellow
                exit 1
            }
        }
    }
    elseif ($token -match '^\d+$') {
        $Port = [int]$token
    }
    else {
        # Positional directory path
        if (-not (Test-Path -LiteralPath $token -PathType Container)) {
            Write-Host "[ERROR] Directory not found: '$token'" -ForegroundColor Red
            exit 1
        }
        $Path = $token
    }

    $posIndex++
}

# Port check
if ($Port -lt 1 -or $Port -gt 65535) {
    Write-Host "[ERROR] Invalid port number: $Port. Must be between 1 and 65535." -ForegroundColor Red
    exit 1
}

# Root path validation
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    Write-Host "[ERROR] Directory not found: '$Path'" -ForegroundColor Red
    exit 1
}

$ResolvedRoot = (Resolve-Path -LiteralPath $Path).Path
$Scheme = if ($Https) { "https" } else { "http" }
$Prefix = "$Scheme`://localhost:$Port/"

# ==============================================================================
# 2. HTTPS Certificate Setup (if requested)
# ==============================================================================
$sslBoundByScript = $false
$appGuid = "{a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d}"

if ($Https) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "`n[ERROR] HTTPS requires Administrator privileges in Windows." -ForegroundColor Red
        Write-Host "Windows http.sys kernel driver requires elevation to bind an SSL certificate to port $Port." -ForegroundColor Yellow
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  1. Run cmd or PowerShell as Administrator and run the command again with -Https."
        Write-Host "  2. Use standard HTTP (no admin needed): webserver $Port`n"
        exit 1
    }

    # Check if a cert is already bound to this port
    $netshCheck = netsh http show sslcert ipport="0.0.0.0:$Port" 2>&1 | Out-String
    if ($netshCheck -notmatch "Certificate Hash") {
        Write-Host "[HTTPS] Setting up localhost SSL certificate on port $Port..." -ForegroundColor Cyan

        # Find or create a self-signed certificate for localhost
        $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Subject -like "*CN=localhost*" } | Select-Object -First 1
        if (-not $cert) {
            Write-Host "[HTTPS] Generating self-signed localhost certificate..." -ForegroundColor Gray
            $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "Cert:\LocalMachine\My" -FriendlyName "Fool's Tools Localhost WebServer"
        }

        $thumb = $cert.Thumbprint
        $addOutput = netsh http add sslcert ipport="0.0.0.0:$Port" certhash=$thumb appid=$appGuid 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            $sslBoundByScript = $true
            Write-Host "[HTTPS] Successfully bound certificate ($thumb) to port $Port." -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to bind SSL certificate via netsh: $addOutput" -ForegroundColor Red
            exit 1
        }
    }
}

# ==============================================================================
# 3. MIME Types Configuration
# ==============================================================================
$MimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".mjs"  = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".txt"  = "text/plain; charset=utf-8"
    ".md"   = "text/plain; charset=utf-8"
    ".xml"  = "application/xml; charset=utf-8"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".webp" = "image/webp"
    ".ico"  = "image/x-icon"
    ".bmp"  = "image/bmp"
    ".pdf"  = "application/pdf"
    ".zip"  = "application/zip"
    ".gz"   = "application/gzip"
    ".tar"  = "application/x-tar"
    ".7z"   = "application/x-7z-compressed"
    ".wasm" = "application/wasm"
    ".mp3"  = "audio/mpeg"
    ".wav"  = "audio/wav"
    ".ogg"  = "audio/ogg"
    ".mp4"  = "video/mp4"
    ".webm" = "video/webm"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
    ".otf"  = "font/otf"
    ".map"  = "application/json"
}

# ==============================================================================
# 4. Web Server Execution
# ==============================================================================
$Listener = [System.Net.HttpListener]::new()
$Listener.Prefixes.Add($Prefix)

try {
    $Listener.Start()
} catch {
    Write-Host "`n[ERROR] Could not start server on $Prefix" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Port $Port may already be in use by another application.`n" -ForegroundColor Gray
    if ($sslBoundByScript) {
        netsh http delete sslcert ipport="0.0.0.0:$Port" 2>&1 | Out-Null
    }
    exit 1
}

Write-Host @"

==================================================================
  Fool's Tools Local Web Server
==================================================================
  Root Directory : $ResolvedRoot
  Server URL     : $Prefix
  CORS Support   : $(if ($Cors) { "ENABLED (Access-Control-Allow-Origin: *)" } else { "DISABLED" })
  Protocol       : $(if ($Https) { "HTTPS (SSL/TLS)" } else { "HTTP" })
==================================================================
Serving requests... Press Ctrl+C to stop.

"@ -ForegroundColor Cyan

try {
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        # Apply CORS headers if requested
        if ($Cors) {
            $Response.Headers.Set("Access-Control-Allow-Origin", "*")
            $Response.Headers.Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, HEAD")
            $Response.Headers.Set("Access-Control-Allow-Headers", "*")
            $Response.Headers.Set("Access-Control-Max-Age", "86400")
        }

        # Handle CORS preflight OPTIONS request
        if ($Request.HttpMethod -eq "OPTIONS") {
            $Response.StatusCode = 204
            $Response.Close()
            Write-Host "OPTIONS 204 $($Request.Url.AbsolutePath)" -ForegroundColor DarkGray
            continue
        }

        $RawUrl = [System.Uri]::UnescapeDataString($Request.Url.AbsolutePath).TrimStart('/')
        $LocalPath = [System.IO.Path]::GetFullPath((Join-Path $ResolvedRoot $RawUrl))

        # Security Guard: Path Traversal Prevention
        if (-not $LocalPath.StartsWith($ResolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $Response.StatusCode = 403
            $msg = [System.Text.Encoding]::UTF8.GetBytes("403 Forbidden: Access is outside root directory.")
            $Response.ContentType = "text/plain; charset=utf-8"
            $Response.OutputStream.Write($msg, 0, $msg.Length)
            $Response.Close()
            Write-Host "403 FORBIDDEN: $($Request.Url.AbsolutePath)" -ForegroundColor Red
            continue
        }

        # Directory handling: look for index.html or generate directory listing
        if (Test-Path -LiteralPath $LocalPath -PathType Container) {
            $indexHtml = Join-Path $LocalPath "index.html"
            $indexHtm  = Join-Path $LocalPath "index.htm"

            if (Test-Path -LiteralPath $indexHtml -PathType Leaf) {
                $LocalPath = $indexHtml
            } elseif (Test-Path -LiteralPath $indexHtm -PathType Leaf) {
                $LocalPath = $indexHtm
            } else {
                # Generate clean HTML directory listing
                $relDir = if ([string]::IsNullOrWhiteSpace($RawUrl)) { "/" } else { "/$RawUrl/" }
                $entries = [System.Collections.Generic.List[string]]::new()

                if ($relDir -ne "/") {
                    $parentUrl = (Split-Path -Path $RawUrl -Parent).Replace("\", "/")
                    $parentLink = if ([string]::IsNullOrWhiteSpace($parentUrl)) { "/" } else { "/$parentUrl/" }
                    $entries.Add("<tr><td>&#128193;</td><td><a href='$parentLink'>.. [Parent Directory]</a></td><td>-</td><td>-</td></tr>")
                }

                $dirs = [System.IO.Directory]::EnumerateDirectories($LocalPath)
                foreach ($d in $dirs) {
                    $dName = [System.IO.Path]::GetFileName($d)
                    $subUrl = "$relDir$dName/".Replace("//", "/")
                    $dirInfo = [System.IO.DirectoryInfo]::new($d)
                    $entries.Add("<tr><td>&#128193;</td><td><a href='$subUrl'>$dName/</a></td><td>$($dirInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))</td><td>-</td></tr>")
                }

                $files = [System.IO.Directory]::EnumerateFiles($LocalPath)
                foreach ($f in $files) {
                    $fName = [System.IO.Path]::GetFileName($f)
                    $fileUrl = "$relDir$fName".Replace("//", "/")
                    $fileInfo = [System.IO.FileInfo]::new($f)
                    $sizeKb = [Math]::Ceiling($fileInfo.Length / 1024)
                    $entries.Add("<tr><td>&#128196;</td><td><a href='$fileUrl'>$fName</a></td><td>$($fileInfo.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))</td><td>$sizeKb KB</td></tr>")
                }

                $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Index of $relDir</title>
    <style>
        body { font-family: -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif; margin: 2rem; background: #1e1e1e; color: #ddd; }
        h1 { font-size: 1.5rem; color: #4ec9b0; border-bottom: 1px solid #333; padding-bottom: 0.5rem; }
        table { border-collapse: collapse; width: 100%; max-width: 900px; margin-top: 1rem; }
        th, td { text-align: left; padding: 0.5rem 0.75rem; }
        th { border-bottom: 2px solid #444; color: #888; font-size: 0.85rem; text-transform: uppercase; }
        tr:hover { background: #2a2a2a; }
        a { color: #569cd6; text-decoration: none; }
        a:hover { text-decoration: underline; color: #9cdcfe; }
        td:nth-child(1) { width: 24px; text-align: center; }
        td:nth-child(3), td:nth-child(4) { color: #888; font-size: 0.9rem; }
        .footer { margin-top: 2rem; font-size: 0.8rem; color: #666; border-top: 1px solid #333; padding-top: 0.5rem; }
    </style>
</head>
<body>
    <h1>Index of $relDir</h1>
    <table>
        <thead><tr><th></th><th>Name</th><th>Last Modified</th><th>Size</th></tr></thead>
        <tbody>
            $($entries -join "`n            ")
        </tbody>
    </table>
    <div class="footer">Fool's Tools Web Server &bull; $Scheme`://localhost:$Port/</div>
</body>
</html>
"@
                $htmlBytes = [System.Text.Encoding]::UTF8.GetBytes($html)
                $Response.ContentType = "text/html; charset=utf-8"
                $Response.StatusCode = 200
                $Response.ContentLength64 = $htmlBytes.Length

                if ($Request.HttpMethod -ne "HEAD") {
                    $Response.OutputStream.Write($htmlBytes, 0, $htmlBytes.Length)
                }
                $Response.Close()
                Write-Host "$($Request.HttpMethod) 200 DIR: $relDir" -ForegroundColor Cyan
                continue
            }
        }

        # Serve static leaf file
        if (Test-Path -LiteralPath $LocalPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($LocalPath).ToLower()
            $Response.ContentType = if ($MimeTypes.ContainsKey($ext)) { $MimeTypes[$ext] } else { "application/octet-stream" }
            $Response.StatusCode = 200

            $fileStream = $null
            try {
                $fileStream = [System.IO.File]::Open($LocalPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
                $Response.ContentLength64 = $fileStream.Length

                if ($Request.HttpMethod -ne "HEAD") {
                    $fileStream.CopyTo($Response.OutputStream)
                }
            } catch {
                $Response.StatusCode = 500
                $errMsg = [System.Text.Encoding]::UTF8.GetBytes("500 Internal Server Error: $($_.Exception.Message)")
                $Response.ContentType = "text/plain; charset=utf-8"
                $Response.OutputStream.Write($errMsg, 0, $errMsg.Length)
                Write-Host "$($Request.HttpMethod) 500 ERR: $($Request.Url.AbsolutePath)" -ForegroundColor Red
            } finally {
                if ($fileStream -ne $null) {
                    $fileStream.Dispose()
                }
                $Response.Close()
            }
            if ($Response.StatusCode -eq 200) {
                Write-Host "$($Request.HttpMethod) 200 OK : $($Request.Url.AbsolutePath)" -ForegroundColor Green
            }
        } else {
            $Response.StatusCode = 404
            $nfMsg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: The requested resource does not exist.")
            $Response.ContentType = "text/plain; charset=utf-8"
            $Response.OutputStream.Write($nfMsg, 0, $nfMsg.Length)
            $Response.Close()
            Write-Host "$($Request.HttpMethod) 404 NF : $($Request.Url.AbsolutePath)" -ForegroundColor Yellow
        }
    }
} finally {
    Write-Host "`nStopping web server..." -ForegroundColor Gray
    $Listener.Stop()
    $Listener.Close()

    if ($sslBoundByScript) {
        Write-Host "[HTTPS] Cleaning up SSL certificate binding for port $Port..." -ForegroundColor Gray
        netsh http delete sslcert ipport="0.0.0.0:$Port" 2>&1 | Out-Null
    }
    Write-Host "Server stopped." -ForegroundColor Gray
}
