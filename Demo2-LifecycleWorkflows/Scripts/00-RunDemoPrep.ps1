<#
.SYNOPSIS
    One-shot demo day prep — runs Connect, Reset, and Verify in sequence.

.DESCRIPTION
    This is the wrapper that "RunDemoPrep.bat" invokes when you double-click it.
    Performs the full pre-demo prep sequence:
        1. Unblock all script files (OneDrive flag removal)
        2. Sign in to Microsoft Graph (sign-in window opens)
        3. Reset Carol/Dave/Manager state for the demo
        4. Verify the environment is demo-ready

    You can also run this script directly from PowerShell:
        .\00-RunDemoPrep.ps1

.NOTES
    Author : Entra Suite Demo Kit
    Demo   : Lifecycle Workflows
    Step   : Demo day launcher
#>

# Make sure we run from this script's own folder so relative paths work
Set-Location -LiteralPath $PSScriptRoot

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   ENTRA SUITE DEMO - LIFECYCLE WORKFLOWS" -ForegroundColor Cyan
Write-Host "   One-click demo day prep" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Steps that will run:" -ForegroundColor Yellow
Write-Host "   [1] Unblock script files"
Write-Host "   [2] Connect to Microsoft Graph (sign in as your demo tenant admin)"
Write-Host "   [3] Reset demo environment"
Write-Host "   [4] Verify everything is ready"
Write-Host ""
Write-Host " IMPORTANT: When the browser opens, sign in with your" -ForegroundColor Yellow
Write-Host " your demo tenant admin account (NOT your work/corporate account)." -ForegroundColor Yellow
Write-Host ""
Read-Host " Press Enter to start"
Write-Host ""

# ---------------------------------------------------------------------
# Step 1 — Unblock files
# ---------------------------------------------------------------------
Write-Host ">>> [1/4] Unblocking script files..." -ForegroundColor Cyan
try {
    Get-ChildItem -Filter *.ps1 -ErrorAction Stop | Unblock-File -ErrorAction Stop
    Write-Host "    Done." -ForegroundColor Green
} catch {
    Write-Host "    Could not unblock (may already be unblocked): $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# ---------------------------------------------------------------------
# Step 2 — Connect to Graph
# ---------------------------------------------------------------------
Write-Host ">>> [2/4] Connecting to Microsoft Graph..." -ForegroundColor Cyan
try {
    & "$PSScriptRoot\02-Connect-Graph.ps1"
    if (-not (Get-MgContext)) { throw "Not connected" }
} catch {
    Write-Host ""
    Write-Host "ERROR: Sign-in failed or was cancelled." -ForegroundColor Red
    Write-Host "Re-run this script and try again." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host ""

# ---------------------------------------------------------------------
# Step 3 — Reset demo environment
# ---------------------------------------------------------------------
Write-Host ">>> [3/4] Resetting demo environment..." -ForegroundColor Cyan
try {
    & "$PSScriptRoot\03-PreDemo-Reset.ps1"
} catch {
    Write-Host ""
    Write-Host "ERROR during reset: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ---------------------------------------------------------------------
# Step 4 — Verify demo state
# ---------------------------------------------------------------------
Write-Host ">>> [4/4] Verifying demo state..." -ForegroundColor Cyan
try {
    & "$PSScriptRoot\04-Verify-DemoState.ps1"
} catch {
    Write-Host ""
    Write-Host "ERROR during verify: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ---------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   Prep complete - review output above" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Next steps:" -ForegroundColor Yellow
Write-Host "   - If everything is PASS, you are demo-ready"
Write-Host "   - If anything FAILED, re-run this script"
Write-Host "   - Manual checks: TAP enabled, workflows exist, Manager mailbox accessible"
Write-Host ""
Read-Host " Press Enter to close this window"
