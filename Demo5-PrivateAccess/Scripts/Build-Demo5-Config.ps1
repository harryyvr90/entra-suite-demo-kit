<#
  Build-Demo5-Config.ps1
  ----------------------------------------------------------------------------
  Configures the GSA Private Access "Quick Access" app for Demo 5:
    1. Creates the 3 IP application segments (web 80 / SMB 445 / RDP 3389)
       pointing at the resource server.
    2. Assigns the demo user to the Quick Access app.

  WHAT THIS DOES *NOT* DO (by design / not scriptable):
    - It does NOT create the Quick Access app shell. Create it ONCE in the portal:
        Global Secure Access > Applications > Quick Access >
        name it "Quick Access", pick the Default connector group, Save (no segments).
    - It does NOT set up the in-VM resources. Run Setup-Resources-ONECLICK.bat
      on gsa-appsrv for that.
    - It does NOT register the connector (interactive MFA sign-in - do that once).
    - It does NOT enable the Private/Microsoft traffic-forwarding profiles
      (toggle + assign the user in the portal: Connect > Traffic forwarding).

  PREREQUISITES:
    - Roles: Global Secure Access Administrator + Application Administrator.
    - Module: Microsoft.Graph (install: Install-Module Microsoft.Graph -Scope CurrentUser).
    - Uses Microsoft Graph BETA endpoints (subject to change - may need a tweak).
  ----------------------------------------------------------------------------
#>

# ===========================================================================
#  CONFIGURE FOR YOUR TENANT — change these values before running
# ===========================================================================
param(
  [string]  $QuickAccessAppName = "Quick Access",             # Quick Access app name (keep default unless you renamed it)
  [string]  $ResourceIP         = "192.168.50.4",            # ← CHANGE to your gsa-appsrv private IP
  [string[]]$Ports              = @("80-80","445-445","3389-3389"),
  [string]  $AssignUserUpn      = "admin@yourtenant.onmicrosoft.com" # ← CHANGE to the UPN that needs access
)

$ErrorActionPreference = "Stop"

Write-Host "Connecting to Microsoft Graph (sign in as a GSA + Application admin)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Application.ReadWrite.All","AppRoleAssignment.ReadWrite.All","Directory.Read.All","User.Read.All" -NoWelcome

# 1) Find the Quick Access app (must already exist)
$app = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/applications?`$filter=displayName eq '$QuickAccessAppName'").value | Select-Object -First 1
if (-not $app) { throw "App '$QuickAccessAppName' not found. Create the empty Quick Access app once in the portal first, then re-run." }
$appId = $app.id
Write-Host "Found '$QuickAccessAppName' (objectId $appId)" -ForegroundColor Green

# 2) Create the IP application segments
$segBase = "https://graph.microsoft.com/beta/applications/$appId/onPremisesPublishing/segmentsConfiguration/microsoft.graph.ipSegmentConfiguration/applicationSegments"
foreach ($p in $Ports) {
  $body = @{ destinationHost = $ResourceIP; destinationType = "ipAddress"; ports = @($p); protocol = "tcp" } | ConvertTo-Json
  try {
    Invoke-MgGraphRequest -Method POST -Uri $segBase -Body $body -ContentType "application/json" | Out-Null
    Write-Host "  + segment  $ResourceIP : $p  (tcp)" -ForegroundColor Green
  } catch {
    Write-Host "  ! segment  $ResourceIP : $p  FAILED - $($_.Exception.Message)" -ForegroundColor Yellow
  }
}

# 3) Assign the user to the app
$sp = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/servicePrincipals?`$filter=appId eq '$($app.appId)'").value | Select-Object -First 1
if (-not $sp) { throw "Service principal for '$QuickAccessAppName' not found." }
$user = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$AssignUserUpn"
$assignBody = @{ principalId = $user.id; resourceId = $sp.id; appRoleId = "00000000-0000-0000-0000-000000000000" } | ConvertTo-Json
try {
  Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/appRoleAssignedTo" -Body $assignBody -ContentType "application/json" | Out-Null
  Write-Host "Assigned $AssignUserUpn to '$QuickAccessAppName'" -ForegroundColor Green
} catch {
  Write-Host "Assignment note (may already exist): $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== DONE (GSA config). Remaining manual steps ===" -ForegroundColor Cyan
Write-Host "  1. Resources on gsa-appsrv  -> run Setup-Resources-ONECLICK.bat there"
Write-Host "  2. Connector registered + Active (one-time interactive sign-in)"
Write-Host "  3. Traffic forwarding: enable Private (+ Microsoft) profile and assign the user (portal)"
Write-Host "  4. Test  http://$ResourceIP  from the client VM"
Disconnect-MgGraph | Out-Null
