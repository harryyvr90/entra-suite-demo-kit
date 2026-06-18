<#
.SYNOPSIS
    Connects to Microsoft Graph with the scopes needed for Lifecycle Workflow demos.

.DESCRIPTION
    Opens an interactive sign-in window (or uses cached token). After this
    runs successfully you can run any of the other scripts in this folder
    in the same PowerShell session.

.NOTES
    Author : Entra Suite Demo Kit
    Demo   : Lifecycle Workflows
    Step   : 2 of 4 (run at the start of every demo session)
#>

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Connecting to Microsoft Graph" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Scopes required by all the demo scripts
$requiredScopes = @(
    "User.ReadWrite.All",          # Update user properties (dates, dept, account enabled)
    "GroupMember.ReadWrite.All",   # Add/remove Dave from demo group
    "Directory.ReadWrite.All",     # License assignment
    "Organization.Read.All"        # Read tenant SKUs
)

Write-Host "Requesting scopes:" -ForegroundColor Yellow
$requiredScopes | ForEach-Object { Write-Host "  - $_" }
Write-Host ""
Write-Host "A browser window will open for sign-in. Sign in as a Global Admin." -ForegroundColor Yellow
Write-Host ""

try {
    Connect-MgGraph -Scopes $requiredScopes -NoWelcome -ErrorAction Stop

    $ctx = Get-MgContext
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host " Connected successfully" -ForegroundColor Green
    Write-Host "===============================================" -ForegroundColor Green
    Write-Host " Account : $($ctx.Account)"
    Write-Host " Tenant  : $($ctx.TenantId)"
    Write-Host " Scopes  : $($ctx.Scopes.Count) granted"
    Write-Host ""
    Write-Host "Next step: run 03-PreDemo-Reset.ps1" -ForegroundColor Cyan
}
catch {
    Write-Host "FAILED to connect: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
