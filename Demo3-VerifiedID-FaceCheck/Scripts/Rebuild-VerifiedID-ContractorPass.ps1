# ============================================================================
#  Rebuild-VerifiedID-ContractorPass.ps1
#  Rebuilds the "Contractor Pass" access package if it ever gets deleted.
#
#  Same shape as the Sales Onboarding rebuild, with ONE key difference:
#  this package is TEMPORARY - access auto-expires after 1 day (the visitor
#  pass story), instead of being permanent.
#
#  WHAT THIS SCRIPT DOES (the safe, scriptable parts):
#    1. Finds the "General" catalog
#    2. Finds the existing "Contractors" M365 group
#    3. Adds Contractors to the catalog as a resource (if not already there)
#    4. Creates the "Contractor Pass - Face Check Demo" access package
#    5. Adds the Member role of Contractors
#    6. Creates a self-request, NO-approval, EXPIRES-AFTER-1-DAY policy
#
#  WHAT THIS SCRIPT DELIBERATELY DOES NOT DO:
#    - It does NOT add the "Require Verified ID + Face Check" rule to the
#      policy. You finish that one toggle in the portal in ~30 seconds -
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
# 2. Find the Contractors group
# ---------------------------------------------------------------------------
Write-Host "Looking for the 'Contractors' group..." -ForegroundColor Cyan
$group = Get-MgGroup -Filter "displayName eq 'Contractors'" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $group) {
    throw "Stop: could not find a group named 'Contractors'. Run Setup-VerifiedID-Demo-Resources.ps1 first."
}
Write-Host "  Found group 'Contractors' ($($group.Id))." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Add Contractors to the catalog as a resource (skip if already present)
# ---------------------------------------------------------------------------
Write-Host "Making sure 'Contractors' is a resource in the catalog..." -ForegroundColor Cyan
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
    Write-Host "  Submitted request to add Contractors to the catalog. Waiting for it to land..." -ForegroundColor Yellow
    Start-Sleep -Seconds 20
} else {
    Write-Host "  Contractors is already a catalog resource." -ForegroundColor Green
}

# Re-fetch the resource so we can grab the Member role
$resource = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $catalog.Id -All -ExpandProperty roles `
    | Where-Object { $_.OriginId -eq $group.Id } | Select-Object -First 1
if (-not $resource) {
    throw "Stop: Contractors did not show up as a catalog resource yet. Wait a minute and re-run."
}

$memberRole = $resource.Roles | Where-Object { $_.DisplayName -eq "Member" } | Select-Object -First 1
if (-not $memberRole) {
    throw "Stop: could not find the 'Member' role on the Contractors resource."
}
Write-Host "  Got the 'Member' role." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 4. Create the access package
# ---------------------------------------------------------------------------
Write-Host "Creating the 'Contractor Pass - Face Check Demo' access package..." -ForegroundColor Cyan
$pkgBody = @{
    displayName = "Contractor Pass - Face Check Demo"
    description = "Temporary visitor pass. Self-request, Face Check required, access auto-expires after 1 day."
    catalog     = @{ id = $catalog.Id }
}
$package = New-MgEntitlementManagementAccessPackage -BodyParameter $pkgBody
Write-Host "  Created package ($($package.Id))." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 5. Attach the Member role of Contractors to the package
# ---------------------------------------------------------------------------
Write-Host "Attaching the Contractors 'Member' role to the package..." -ForegroundColor Cyan
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
# 6. Create a self-request, no-approval, EXPIRES-AFTER-1-DAY policy
# ---------------------------------------------------------------------------
Write-Host "Creating the self-request (no approval, expires after 1 day) policy..." -ForegroundColor Cyan
$policyBody = @{
    displayName       = "Contractor Pass - self request"
    description       = "Anyone in the directory can self-request. No approval. Auto-expires after 1 day."
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
    expiration = @{
        type     = "afterDuration"
        duration = "P1D"
    }
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
Write-Host " The package, the Contractors resource, and the self-request" -ForegroundColor White
Write-Host " policy are all built. The ONLY thing left is the Verified ID" -ForegroundColor White
Write-Host " + Face Check requirement, which you add in the portal:" -ForegroundColor White
Write-Host ""
Write-Host "   1. entra.microsoft.com  ->  Identity Governance" -ForegroundColor White
Write-Host "   2. Entitlement management  ->  Access packages" -ForegroundColor White
Write-Host "   3. Open 'Contractor Pass - Face Check Demo'" -ForegroundColor White
Write-Host "   4. Policies  ->  open 'Contractor Pass - self request'  ->  Edit" -ForegroundColor White
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
