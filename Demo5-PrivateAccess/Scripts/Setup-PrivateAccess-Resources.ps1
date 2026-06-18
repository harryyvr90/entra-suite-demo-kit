# ============================================================================
#  Setup-PrivateAccess-Resources.ps1
#  Run this ON the gsa-appsrv server (the one you Remote Desktop into).
#  It sets up all THREE Demo 5 resources automatically:
#     1. Internal web app (IIS)  -> http://gsa-appsrv
#     2. File share (SMB)        -> \\gsa-appsrv\share
#     3. Remote Desktop (RDP)    -> gsa-appsrv:3389
#  Just double-click Run-Setup-PrivateAccess-Resources.bat (same folder).
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "[1/3] Installing the IIS web server..." -ForegroundColor Cyan
Install-WindowsFeature -Name Web-Server -IncludeManagementTools | Out-Null

Write-Host "      Creating the internal web page..." -ForegroundColor Cyan
$html = '<html><body style="font-family:Segoe UI;text-align:center;padding-top:60px;background:#f3f9fd"><h1 style="color:#0078D4">Internal Sales Portal</h1><p>This site lives on a private server with no public internet exposure.</p><p>Reached through Microsoft Entra Private Access - no VPN.</p></body></html>'
Set-Content -Path C:\inetpub\wwwroot\index.html -Value $html

Write-Host "[2/3] Creating the file share..." -ForegroundColor Cyan
New-Item -Path C:\DemoShare -ItemType Directory -Force | Out-Null
Set-Content -Path C:\DemoShare\Pricing-2026.txt -Value "Confidential internal pricing list - reachable only through Entra Private Access."
if (-not (Get-SmbShare -Name "share" -ErrorAction SilentlyContinue)) {
    New-SmbShare -Name "share" -Path C:\DemoShare -FullAccess "Everyone" | Out-Null
    Write-Host "      Share 'share' created." -ForegroundColor Green
} else {
    Write-Host "      Share 'share' already exists - skipped." -ForegroundColor Yellow
}

Write-Host "[3/3] Making sure Remote Desktop is enabled..." -ForegroundColor Cyan
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " DONE - all three resources are ready on this server:" -ForegroundColor Green
Write-Host "   Web app    : http://localhost   (test it in the browser now)" -ForegroundColor White
Write-Host "   File share : \\gsa-appsrv\share" -ForegroundColor White
Write-Host "   RDP        : gsa-appsrv : 3389" -ForegroundColor White
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
