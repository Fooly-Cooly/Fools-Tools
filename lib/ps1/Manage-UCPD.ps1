#Requires -RunAsAdministrator

# --- Compatibility Guard ---
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$buildNumber = [int]$os.BuildNumber

# UCPD was introduced in Windows 10/11 build 19041 and later (v2004+)
if ($buildNumber -lt 19041) {
    Write-Error "UCPD management is only relevant for Windows 10/11 (Build 19041) or higher. Current build: $buildNumber"
    Read-Host "Press Enter to exit..."
    exit
}

# --- Configuration Constants ---
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\UCPD"
$TaskPath     = "\Microsoft\Windows\AppxDeploymentClient\"
$TaskName     = "UCPD velocity"

# --- Helper Functions ---
function Get-UCPDStatus {
    Write-Host "`n--- Current System Status ---" -ForegroundColor Cyan
    
    # 1. Check Registry Status
    if (Test-Path $RegistryPath) {
        $regValue = (Get-ItemProperty -Path $RegistryPath -Name "Start" -ErrorAction SilentlyContinue).Start
        switch ($regValue) {
            4       { Write-Host "UCPD Service Start Type : Disabled (4)" -ForegroundColor Green }
            2       { Write-Host "UCPD Service Start Type : Automatic (2) [Default]" -ForegroundColor Yellow }
            3       { Write-Host "UCPD Service Start Type : Manual (3)" -ForegroundColor Yellow }
            Default { Write-Host "UCPD Service Start Type : Unknown ($regValue)" -ForegroundColor Red }
        }
    } else {
        Write-Host "UCPD Registry Key Not Found!" -ForegroundColor Red
    }

    # 2. Check Scheduled Task Status
    $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        if ($task.State -eq "Disabled") {
            Write-Host "UCPD Scheduled Task    : Disabled" -ForegroundColor Green
        } else {
            Write-Host "UCPD Scheduled Task    : Enabled ($($task.State)) [Default]" -ForegroundColor Yellow
        }
    } else {
        Write-Host "UCPD Scheduled Task    : Not Found" -ForegroundColor Red
    }
    Write-Host "----------------------------`n"
}

function Show-Menu {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "       User Choice Protection Driver Manager       " -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "Disabling UCPD prevents Windows from forcing default"
    Write-Host "app association resets (e.g., PDF, browser defaults)."
    
    Get-UCPDStatus

    Write-Host "What would you like setup to do?"
    Write-Host "1) Disable UCPD & Scheduled Task (Apply Tweak)"
    Write-Host "2) Enable UCPD & Scheduled Task (Restore Defaults)"
    Write-Host "3) Refresh Status"
    Write-Host "4) Exit"
    Write-Host ""
}

function Disable-UCPD {
    Clear-Host
    Write-Host "Disabling UCPD Service and Task..." -ForegroundColor Yellow

    try {
        # Set Service Start Type to Disabled (4)
        New-ItemProperty -Path $RegistryPath -Name "Start" -Value 4 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        Write-Host "[SUCCESS] Set UCPD registry start value to 4 (Disabled)." -ForegroundColor Green
        
        # Disable the Scheduled Task
        Disable-ScheduledTask -TaskPath $TaskPath -TaskName$TaskName -ErrorAction Stop | Out-Null
        Write-Host "[SUCCESS] Disabled scheduled task '\Microsoft\Windows\AppxDeploymentClient\UCPD velocity'." -ForegroundColor Green
        
        Write-Host "`nNote: A system restart is required for driver service changes to take full effect." -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR] Failed to disable UCPD: $_" -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue..."
}

function Enable-UCPD {
    Clear-Host
    Write-Host "Restoring UCPD Service and Task to Defaults..." -ForegroundColor Yellow

    try {
        # Restore Service Start Type to Automatic (2)
        New-ItemProperty -Path $RegistryPath -Name "Start" -Value 2 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null
        Write-Host "[SUCCESS] Restored UCPD registry start value to 2 (Automatic)." -ForegroundColor Green
        
        # Enable the Scheduled Task
        Enable-ScheduledTask -TaskPath $TaskPath -TaskName$TaskName -ErrorAction Stop | Out-Null
        Write-Host "[SUCCESS] Enabled scheduled task '\Microsoft\Windows\AppxDeploymentClient\UCPD velocity'." -ForegroundColor Green

        Write-Host "`nNote: A system restart is required for driver service changes to take full effect." -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR] Failed to enable UCPD: $_" -ForegroundColor Red
    }

    Read-Host "`nPress Enter to continue..."
}

# --- Main Program Loop ---
Set-Location -Path $PSScriptRoot

do {
    Show-Menu
    $selection = Read-Host "Enter option number"
    switch ($selection) {
        "1" { Disable-UCPD }
        "2" { Enable-UCPD }
        "3" { continue }
        "4" { exit }
    }
} while ($true)