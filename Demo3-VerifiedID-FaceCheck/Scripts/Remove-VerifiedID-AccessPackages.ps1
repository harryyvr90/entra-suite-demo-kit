<#
    Remove-VerifiedID-AccessPackages.ps1
    ------------------------------------
    *** DESTRUCTIVE TEARDOWN - not part of the normal demo reset ***
    Permanently DELETES the "Sales Onboarding" and "Contractor Pass" access
    packages. After this you must rebuild and re-test them before you can demo
    onboarding / visitor pass again.

    Deletion fails while a package still has active assignments, so this script
    clears assignments first, waits, then deletes the package and its policies.

    Required scope: EntitlementManagement.ReadWrite.All
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

Write-Host "This will PERMANENTLY DELETE these access packages:" -ForegroundColor Red
$packages.Keys | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
$confirm = Read-Host "Type DELETE to continue"
if ($confirm -ne "DELETE") {
    Write-Host "Cancelled - nothing was deleted." -ForegroundColor Green
    return
}

foreach ($name in $packages.Keys) {
    $apId = $packages[$name]

    # 1. Clear any active assignments (deletion is blocked otherwise)
    $assignments = Get-MgEntitlementManagementAssignment `
        -Filter "accessPackage/id eq '$apId' and state eq 'Delivered'" -All -ErrorAction SilentlyContinue
    foreach ($a in $assignments) {
        $body = @{ requestType = "adminRemove"; assignment = @{ id = $a.Id } }
        try { New-MgEntitlementManagementAssignmentRequest -BodyParameter $body -ErrorAction Stop | Out-Null }
        catch { Write-Warning "[$name] assignment removal failed: $($_.Exception.Message)" }
    }
    if ($assignments.Count -gt 0) {
        Write-Host "[$name] cleared $($assignments.Count) assignment(s) - waiting for processing..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }

    # 2. Delete assignment policies attached to the package
    $policies = Get-MgEntitlementManagementAssignmentPolicy `
        -Filter "accessPackage/id eq '$apId'" -All -ErrorAction SilentlyContinue
    foreach ($p in $policies) {
        try {
            Remove-MgEntitlementManagementAssignmentPolicy -AccessPackageAssignmentPolicyId $p.Id -ErrorAction Stop
            Write-Host "[$name] deleted policy: $($p.DisplayName)" -ForegroundColor Yellow
        }
        catch { Write-Warning "[$name] policy delete failed: $($_.Exception.Message)" }
    }

    # 3. Delete the access package itself
    try {
        Remove-MgEntitlementManagementAccessPackage -AccessPackageId $apId -ErrorAction Stop
        Write-Host "[$name] DELETED." -ForegroundColor Red
    }
    catch {
        Write-Warning "[$name] package delete failed (likely still has assignments - re-run in a minute): $($_.Exception.Message)"
    }
}

Write-Host "`nTeardown complete." -ForegroundColor Cyan
