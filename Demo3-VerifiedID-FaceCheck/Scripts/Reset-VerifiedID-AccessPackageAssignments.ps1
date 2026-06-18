<#
    Reset-VerifiedID-AccessPackageAssignments.ps1
    ---------------------------------------------
    Pre-demo cleanup for Demo 3 (Verified ID + Face Check).
    Removes existing GRANTS (assignments) from the two access packages so a
    requester can request them again from scratch. The packages themselves are
    kept - this is the "keep everything long" reset.

    Use this when a tester (e.g. [your admin] / Manager Demo) already holds an
    assignment and the access package would otherwise say "you already have access".

    Required scope: EntitlementManagement.ReadWrite.All

    Note: admin-remove is processed asynchronously by Entra - the membership
    drops a few moments after the script finishes.
#>

Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All" -NoWelcome

# ===========================================================================
#  CONFIGURE FOR YOUR TENANT — change these values before running
# ===========================================================================
# Find these GUIDs in: Entra admin center → Identity Governance → Access packages
#   → open each package → copy the ID from the URL or Overview blade.
$packages = [ordered]@{
    "Sales Onboarding" = "<YOUR-SALES-ONBOARDING-PACKAGE-ID>"  # ← CHANGE
    "Contractor Pass"  = "<YOUR-CONTRACTOR-PASS-PACKAGE-ID>"   # ← CHANGE
}

foreach ($name in $packages.Keys) {
    $apId = $packages[$name]

    $assignments = Get-MgEntitlementManagementAssignment `
        -Filter "accessPackage/id eq '$apId' and state eq 'Delivered'" `
        -ExpandProperty target -All -ErrorAction SilentlyContinue

    if (-not $assignments -or $assignments.Count -eq 0) {
        Write-Host "[$name] no active assignments - nothing to remove." -ForegroundColor Green
        continue
    }

    foreach ($a in $assignments) {
        $who = $a.Target.AdditionalProperties["email"]
        if (-not $who) { $who = $a.Target.AdditionalProperties["displayName"] }
        if (-not $who) { $who = $a.Id }
        $body = @{
            requestType = "adminRemove"
            assignment  = @{ id = $a.Id }
        }
        try {
            New-MgEntitlementManagementAssignmentRequest -BodyParameter $body -ErrorAction Stop | Out-Null
            Write-Host "[$name] removal requested for: $who" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "[$name] could not remove $who : $($_.Exception.Message)"
        }
    }
}

Write-Host "`nDone. Grants cleared - the packages are ready to be requested fresh." -ForegroundColor Cyan
