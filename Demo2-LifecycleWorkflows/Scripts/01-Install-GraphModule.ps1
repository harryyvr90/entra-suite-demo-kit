<#
.SYNOPSIS
    One-time installation of Microsoft Graph PowerShell module.

.DESCRIPTION
    Trusts the PSGallery, installs NuGet provider if needed, then installs
    the Microsoft.Graph module. Run this ONCE on any machine you'll use
    for Lifecycle Workflow demos.

.NOTES
    Author : Entra Suite Demo Kit
    Demo   : Lifecycle Workflows
    Step   : 1 of 4 (run once, then reuse)
    Tested : Windows PowerShell 5.1 and PowerShell 7.x
#>

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Lifecycle Workflow Demo - Module Installer" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Ensure TLS 1.2 for older Windows PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "[1/4] TLS 1.2 enabled for this session" -ForegroundColor Green

# 2. Trust PSGallery so install runs without prompts
try {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    Write-Host "[2/4] PSGallery set to Trusted" -ForegroundColor Green
} catch {
    Write-Host "[2/4] Could not change PSGallery trust (may already be Trusted)" -ForegroundColor Yellow
}

# 3. Install NuGet provider
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
    Write-Host "[3/4] NuGet provider installed/verified" -ForegroundColor Green
} catch {
    Write-Host "[3/4] NuGet provider issue: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Install Microsoft.Graph module
Write-Host "[4/4] Installing Microsoft.Graph module (this may take 2-5 min)..." -ForegroundColor Yellow
try {
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
    $version = (Get-Module Microsoft.Graph -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Host "[4/4] Microsoft.Graph $version installed" -ForegroundColor Green
} catch {
    Write-Host "[4/4] FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running PowerShell as Administrator and re-run this script." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Done! Next step: run 02-Connect-Graph.ps1" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
