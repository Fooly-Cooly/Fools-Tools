#Requires -RunAsAdministrator

# --- Compatibility Guard ---
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$buildNumber = [int]$os.BuildNumber

if ($buildNumber -lt 18362) {
    Write-Error "Windows Sandbox requires Windows 10 (Build 18362 / v1903) or later. Current build: $buildNumber"
    Read-Host "Press Enter to exit..."
    exit
}

# --- Functions ---
function Show-Menu {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "               Sandbox Installer                  " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Creating a system backup beforehand is highly recommended!" -ForegroundColor Red
    Write-Host "This ensures you can safely remove Sandbox traces if needed."
    Write-Host "--------------------------------------------------"
    Write-Host "What would you like setup to do?"
    Write-Host "1) Install"
    Write-Host "2) Uninstall"
    Write-Host "3) Exit"
    Write-Host ""
}

function Prompt-Restart {
    Clear-Host
    Write-Host "Would you like to restart the computer now?" -ForegroundColor Yellow
    Write-Host "1) Yes"
    Write-Host "2) No"
    Write-Host ""
    
    $choice = Read-Host "Enter option number"
    if ($choice -eq "1") {
        Restart-Computer -Force
    }
}

function Install-Sandbox {
    Clear-Host
    Write-Host "Installing Windows Sandbox Packages..." -ForegroundColor Green
    
    $packages = Get-ChildItem -Path "$env:SystemRoot\servicing\Packages" -Filter "*Containers*.mum"
    foreach ($package in$packages) {
        Write-Host "Adding package: $($package.Name)" -ForegroundColor Cyan
        Dism.exe /Online /NoRestart /Add-Package:"$($package.FullName)"
    }

    Write-Host "`nEnabling Windows Sandbox Feature..." -ForegroundColor Green
    Dism.exe /Online /Enable-Feature /FeatureName:Containers-DisposableClientVM /LimitAccess /All /NoRestart

    Prompt-Restart
}

function Uninstall-Sandbox {
    Clear-Host
    Write-Host "Disabling Windows Sandbox Feature..." -ForegroundColor Yellow
    Dism.exe /Online /Disable-Feature /FeatureName:Containers-DisposableClientVM /NoRestart

    Write-Host "`nRemoving Windows Sandbox Packages..." -ForegroundColor Yellow
    $packages = Get-ChildItem -Path "$env:SystemRoot\servicing\Packages" -Filter "*Containers*.mum"
    foreach ($package in$packages) {
        Write-Host "Removing package: $($package.Name)" -ForegroundColor Cyan
        Dism.exe /Online /NoRestart /Remove-Package:"$($package.FullName)"
    }

    Prompt-Restart
}

# --- Main Program Loop ---
Set-Location -Path $PSScriptRoot

do {
    Show-Menu
    $selection = Read-Host "Enter option number"
    switch ($selection) {
        "1" { Install-Sandbox; break }
        "2" { Uninstall-Sandbox; break }
        "3" { exit }
    }
} while ($true)