# ============================================================================
#  Rebuild-VerifiedID-SalesOnboarding.ps1
#  Rebuilds the "Sales Onboarding" access package after it was deleted.
#
#  WHAT THIS SCRIPT DOES (the safe, scriptable parts):
#    1. Finds the "General" catalog
#    2. Finds the existing "Sales Team" M365 group
#    3. Adds Sales Team to the catalog as a resource (if not already there)
#    4. Creates the "Sales Onboarding - Face Check Demo" access package
#    5. Adds the Member role of Sales Team to the package
#    6. Creates a self-request, NO-approval, NEVER-expires policy
#
#  WHAT THIS SCRIPT DELIBERATELY DOES NOT DO:
#    - It does NOT add the "Require Verified ID + Face Check" rule to the
#      policy. That toggle lives in a newer part of the policy and is not
#      safe to script blind. You finish it in the portal in ~30 seconds -
#      the script prints the exact steps at the end.
#
#  PREREQ (one time):  Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
#  SIGN-IN SCOPES:     EntitlementManagement.ReadWrite.All, Group.Read.All
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Connecting to Microsoft Graph (a sign-in window will appear)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All","Group.Read.All" | Out-Null

# ---------------------------------------------------------------------------
# 1. Find the General catalog
# ---------------------------------------------------------------------------
Write-Host "Looking for the 'General' catalog..." -ForegroundColor Cyan
$catalog = Get-MgEntitlementManagementCatalog -Filter "displayName eq 'General'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $catalog) {
    Write-Host "  Could not find a catalog named 'General'. Listing catalogs you DO have:" -ForegroundColor Yellow
    Get-MgEntitlementManagementCatalog -All | Select-Object DisplayName, Id | Format-Table
    throw "Stop: pick the correct catalog name, edit the filter on the line above, and re-run."
}
Write-Host "  Found catalog 'General' ($($catalog.Id))." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Find the Sales Team group
# ---------------------------------------------------------------------------
Write-Host "Looking for the 'Sales Team' group..." -ForegroundColor Cyan
$group = Get-MgGroup -Filter "displayName eq 'Sales Team'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) {
    throw "Stop: could not find a group named 'Sales Team'. Run Setup-VerifiedID-Demo-Resources.ps1 first."
}
Write-Host "  Found group 'Sales Team' ($($group.Id))." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Add Sales Team to the catalog as a resource (skip if already present)
# ---------------------------------------------------------------------------
Write-Host "Making sure 'Sales Team' is a resource in the catalog..." -ForegroundColor Cyan
$existingResource = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $catalog.Id -All -ExpandProperty roles `
    | Where-Object { $_.OriginId -eq $group.Id }

if (-not $existingResource) {
    $addBody = @{
        catalogId   = $catalog.Id
        requestType = "adminAdd"
        resource    = @{
            originId     = $group.Id
            originSystem = "AadGroup"
        }
    }
    New-MgEntitlementManagementResourceRequest -BodyParameter $addBody | Out-Null
    Write-Host "  Submitted request to add Sales Team to the catalog. Waiting for it to land..." -ForegroundColor Yellow
    Start-Sleep -Seconds 20
} else {
    Write-Host "  Sales Team is already a catalog resource." -ForegroundColor Green
}

# Re-fetch the resource so we can grab the Member role
$resource = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $catalog.Id -All -ExpandProperty roles `
    | Where-Object { $_.OriginId -eq $group.Id } | Select-Object -First 1
if (-not $resource) {
    throw "Stop: Sales Team did not show up as a catalog resource yet. Wait a minute and re-run."
}

$memberRole = $resource.Roles | Where-Object { $_.DisplayName -eq "Member" } | Select-Object -First 1
if (-not $memberRole) {
    throw "Stop: could not find the 'Member' role on the Sales Team resource."
}
Write-Host "  Got the 'Member' role." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 4. Create the access package
# ---------------------------------------------------------------------------
Write-Host "Creating the 'Sales Onboarding - Face Check Demo' access package..." -ForegroundColor Cyan
$pkgBody = @{
    displayName = "Sales Onboarding - Face Check Demo"
    description = "New-hire onboarding. Self-request, Face Check required, permanent access to the Sales Team site."
    catalog     = @{ id = $catalog.Id }
}
$package = New-MgEntitlementManagementAccessPackage -BodyParameter $pkgBody
Write-Host "  Created package ($($package.Id))." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 5. Attach the Member role of Sales Team to the package
# ---------------------------------------------------------------------------
Write-Host "Attaching the Sales Team 'Member' role to the package..." -ForegroundColor Cyan
$scopeBody = @{
    role = @{
        originId     = $memberRole.OriginId
        displayName  = $memberRole.DisplayName
        originSystem = $resource.OriginSystem
        resource     = @{ id = $resource.Id }
    }
    scope = @{
        originId     = $group.Id
        displayName  = $group.DisplayName
        originSystem = "AadGroup"
        isRootScope  = $true
    }
}
New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $package.Id -BodyParameter $scopeBody | Out-Null
Write-Host "  Resource role attached." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 6. Create a self-request, no-approval, never-expires policy
# ---------------------------------------------------------------------------
Write-Host "Creating the self-request (no approval, never expires) policy..." -ForegroundColor Cyan
$policyBody = @{
    displayName       = "Sales Onboarding - self request"
    description       = "Anyone in the directory can self-request. No approval. Permanent."
    accessPackage     = @{ id = $package.Id }
    allowedTargetScope = "allMemberUsers"
    requestorSettings = @{
        enableTargetsToSelfAddAccess    = $true
        enableTargetsToSelfUpdateAccess = $false
        enableTargetsToSelfRemoveAccess = $true
    }
    requestApprovalSettings = @{
        isApprovalRequiredForAdd    = $false
        isApprovalRequiredForUpdate = $false
    }
    expiration = @{ type = "noExpiration" }
}
$policy = New-MgEntitlementManagementAssignmentPolicy -BodyParameter $policyBody
Write-Host "  Policy created ($($policy.Id))." -ForegroundColor Green

# ---------------------------------------------------------------------------
# Hand-off: finish the Face Check rule in the portal
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host " ALMOST DONE - one step left, done in the portal (~30 sec)" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host " The package, the Sales Team resource, and the self-request" -ForegroundColor White
Write-Host " policy are all built. The ONLY thing left is the Verified ID" -ForegroundColor White
Write-Host " + Face Check requirement, which you add in the portal:" -ForegroundColor White
Write-Host ""
Write-Host "   1. entra.microsoft.com  ->  Identity Governance" -ForegroundColor White
Write-Host "   2. Entitlement management  ->  Access packages" -ForegroundColor White
Write-Host "   3. Open 'Sales Onboarding - Face Check Demo'" -ForegroundColor White
Write-Host "   4. Policies  ->  open 'Sales Onboarding - self request'  ->  Edit" -ForegroundColor White
Write-Host "   5. Go to the 'Requestor information' / Verified IDs step" -ForegroundColor White
Write-Host "   6. + Add issuer  ->  [Your Org Name]" -ForegroundColor White
Write-Host "        Credential: VerifiedEmployee" -ForegroundColor White
Write-Host "        Turn Face Check ON  ->  claim: photo" -ForegroundColor White
Write-Host "   7. Save." -ForegroundColor White
Write-Host ""
Write-Host " Then test: open My Access (myaccess.microsoft.com), request the" -ForegroundColor White
Write-Host " package, and confirm the Face Check prompt appears." -ForegroundColor White
Write-Host ""

Disconnect-MgGraph | Out-Null
