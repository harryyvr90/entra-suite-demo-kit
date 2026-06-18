<#
  Reset-Demo5-Soft.ps1
  ----------------------------------------------------------------------------
  SOFT reset of the Demo 5 GSA config (keeps the VMs and the Quick Access app shell):
    1. Deletes all IP application segments from the Quick Access app.
    2. Removes the demo user's assignment from the Quick Access app.

  After this, re-run Build-Demo5-Config.ps1 to rebuild the segments + assignment.
  The VMs, connector, and the empty Quick Access app shell are left in place.
  (To stop Azure cost, deallocate the gsa-appsrv + gsa-connector VMs in the portal.)

  PREREQUISITES:
    - Roles: Global Secure Access Administrator + Application Administrator.
    - Module: Microsoft.Graph.  Uses Microsoft Graph BETA endpoints (subject to change).
  ----------------------------------------------------------------------------
#>

# ===========================================================================
#  CONFIGURE FOR YOUR TENANT — change these values before running
# ===========================================================================
param(
  [string]$QuickAccessAppName = "Quick Access",
  [string]$AssignUserUpn      = "admin@yourtenant.onmicrosoft.com" # ← CHANGE to the same UPN used in Build-Demo5-Config.ps1
)

$ErrorActionPreference = "Stop"

Write-Host "Connecting to Microsoft Graph (sign in as a GSA + Application admin)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All","AppRoleAssignment.ReadWrite.All","Directory.Read.All","User.Read.All" -NoWelcome

$app = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/applications?`$filter=displayName eq '$QuickAccessAppName'").value | Select-Object -First 1
if (-not $app) { throw "App '$QuickAccessAppName' not found - nothing to reset." }
$appId = $app.id
Write-Host "Found '$QuickAccessAppName' (objectId $appId)" -ForegroundColor Green

# 1) Delete all IP application segments
$segBase = "https://graph.microsoft.com/beta/applications/$appId/onPremisesPublishing/segmentsConfiguration/microsoft.graph.ipSegmentConfiguration/applicationSegments"
$segs = (Invoke-MgGraphRequest -Method GET -Uri $segBase).value
if ($segs) {
  foreach ($s in $segs) {
    try {
      Invoke-MgGraphRequest -Method DELETE -Uri "$segBase/$($s.id)" | Out-Null
      Write-Host "  - removed segment  $($s.destinationHost) : $($s.ports -join ',')" -ForegroundColor Yellow
    } catch {
      Write-Host "  ! could not remove segment $($s.id) - $($_.Exception.Message)" -ForegroundColor Red
    }
  }
} else { Write-Host "  (no segments to remove)" }

# 2) Remove the user's assignment
$sp = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/servicePrincipals?`$filter=appId eq '$($app.appId)'").value | Select-Object -First 1
if ($sp) {
  $user = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$AssignUserUpn"
  $assignments = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo").value
  foreach ($a in ($assignments | Where-Object { $_.principalId -eq $user.id })) {
    Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo/$($a.id)" | Out-Null
    Write-Host "  - removed assignment for $AssignUserUpn" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "Soft reset complete. Quick Access shell, connector, and VMs are untouched." -ForegroundColor Green
Write-Host "Re-run Build-Demo5-Config.ps1 to rebuild the demo config." -ForegroundColor Cyan
Disconnect-MgGraph | Out-Null
