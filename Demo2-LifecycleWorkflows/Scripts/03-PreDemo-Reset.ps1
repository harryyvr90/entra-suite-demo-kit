<#
.SYNOPSIS
    Resets the Lifecycle Workflow demo environment to a clean state.

.DESCRIPTION
    Run this BEFORE every demo (about 1 hour before client meeting).
    The script resets all state that gets consumed by demo runs:

      Carol Newhire:
        - employeeHireDate = today + 7 days   (triggers joiner workflow scope)
        - department       = DemoSales

      Dave Leaver:
        - employeeLeaveDateTime = today        (triggers leaver workflow scope)
        - department            = DemoSales
        - accountEnabled        = true         (in case previous leaver run disabled it)
        - usageLocation         = US           (required before license assignment)
        - M365 E5 license       = assigned directly (in case previous run stripped it)
        - Group membership      = re-added to Demo-LifecycleWorkflow-Users

    All operations are idempotent — safe to run multiple times.

.PARAMETER UsageLocation
    Two-letter country code for Dave's usageLocation. Required for license
    assignment. Default = "US". Change if your tenant uses a different region.

.PARAMETER LicenseSkuPartNumber
    The license SKU to assign to Dave.
    Default = "Microsoft_365_E5_(no_Teams)" — the SKU available in this tenant.
    Pass a different value only if the tenant SKU changes.

.PARAMETER DemoGroupName
    The group Dave is added back to. Default = "Demo-LifecycleWorkflow-Users".

.EXAMPLE
    .\03-PreDemo-Reset.ps1

.EXAMPLE
    .\03-PreDemo-Reset.ps1 -UsageLocation "CA" -LicenseSkuPartNumber "ENTERPRISEPREMIUM"

.NOTES
    Author : Entra Suite Demo Kit
    Demo   : Lifecycle Workflows
    Step   : 3 of 4 (run before every demo)
    Requires: Connect-MgGraph already completed (run 02-Connect-Graph.ps1 first)
#>

param(
    [string]$UsageLocation        = "US",
    [string]$LicenseSkuPartNumber = "Microsoft_365_E5_(no_Teams)",
    [string]$DemoGroupName        = "Demo-LifecycleWorkflow-Users"
)

# -------------------------------------------------------------------
#  Preflight
# -------------------------------------------------------------------
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Pre-Demo Reset - Lifecycle Workflows" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$ctx = Get-MgContext
if (-not $ctx) {
    Write-Host "ERROR: Not connected to Graph. Run 02-Connect-Graph.ps1 first." -ForegroundColor Red
    exit 1
}
Write-Host "Connected as : $($ctx.Account)" -ForegroundColor Green
Write-Host "Tenant       : $($ctx.TenantId)" -ForegroundColor Green
Write-Host ""

# -------------------------------------------------------------------
#  1. Reset Carol (joiner)
# -------------------------------------------------------------------
Write-Host "--- [1/3] Resetting Carol Newhire (joiner) ---" -ForegroundColor Cyan

try {
    $carol = Get-MgUser -Filter "displayName eq 'Carol Newhire'" -ErrorAction Stop
    if (-not $carol) { throw "Carol Newhire not found" }

    $newHireDate = (Get-Date).AddDays(7)

    # Each property update is a separate call for max reliability
    Update-MgUser -UserId $carol.Id -EmployeeHireDate $newHireDate -ErrorAction Stop
    Update-MgUser -UserId $carol.Id -Department "DemoSales"          -ErrorAction Stop

    Write-Host "  OK Carol hire date  = $($newHireDate.ToString('yyyy-MM-dd'))"  -ForegroundColor Green
    Write-Host "  OK Carol department = DemoSales"                                -ForegroundColor Green
}
catch {
    Write-Host "  FAIL Carol reset: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# -------------------------------------------------------------------
#  2. Reset Dave (leaver) - the complicated one
# -------------------------------------------------------------------
Write-Host "--- [2/3] Resetting Dave Leaver (leaver) ---" -ForegroundColor Cyan

try {
    $dave = Get-MgUser -UserId (Get-MgUser -Filter "displayName eq 'Dave Leaver'").Id `
                       -Property Id,DisplayName,UsageLocation,AccountEnabled,EmployeeLeaveDateTime,Department `
                       -ErrorAction Stop

    if (-not $dave) { throw "Dave Leaver not found" }

    # 2a. Account enabled - do this FIRST so subsequent ops work
    try {
        Update-MgUser -UserId $dave.Id -AccountEnabled:$true -ErrorAction Stop
        Write-Host "  OK Dave account     = enabled"                              -ForegroundColor Green
    } catch {
        Write-Host "  FAIL Dave account enable: $($_.Exception.Message)"          -ForegroundColor Red
    }

    # 2b. Leave date + department
    try {
        $today = Get-Date
        Update-MgUser -UserId $dave.Id -EmployeeLeaveDateTime $today -ErrorAction Stop
        Update-MgUser -UserId $dave.Id -Department "DemoSales"       -ErrorAction Stop
        Write-Host "  OK Dave leave date  = $($today.ToString('yyyy-MM-dd'))"     -ForegroundColor Green
        Write-Host "  OK Dave department  = DemoSales"                            -ForegroundColor Green
    } catch {
        Write-Host "  FAIL Dave date/dept: $($_.Exception.Message)"               -ForegroundColor Red
    }

    # 2c. Usage location - REQUIRED before license assignment
    try {
        if (-not $dave.UsageLocation -or $dave.UsageLocation -ne $UsageLocation) {
            Update-MgUser -UserId $dave.Id -UsageLocation $UsageLocation -ErrorAction Stop
            Write-Host "  OK Dave usage loc   = $UsageLocation"                   -ForegroundColor Green
        } else {
            Write-Host "  -- Dave usage loc already $($dave.UsageLocation)"        -ForegroundColor Gray
        }
    } catch {
        Write-Host "  FAIL Dave usage loc: $($_.Exception.Message)"               -ForegroundColor Red
    }

    # 2d. License assignment
    try {
        $targetSku = Get-MgSubscribedSku -All -ErrorAction Stop |
                     Where-Object SkuPartNumber -eq $LicenseSkuPartNumber |
                     Select-Object -First 1

        if (-not $targetSku) {
            Write-Host "  FAIL SKU '$LicenseSkuPartNumber' not found in tenant"  -ForegroundColor Red
        }
        elseif (($targetSku.PrepaidUnits.Enabled - $targetSku.ConsumedUnits) -le 0) {
            Write-Host "  FAIL No free $LicenseSkuPartNumber seats ($($targetSku.ConsumedUnits)/$($targetSku.PrepaidUnits.Enabled) consumed)" -ForegroundColor Red
        }
        else {
            $currentLicenses = Get-MgUserLicenseDetail -UserId $dave.Id -ErrorAction Stop
            if ($currentLicenses.SkuId -contains $targetSku.SkuId) {
                Write-Host "  -- Dave already has $LicenseSkuPartNumber"          -ForegroundColor Gray
            } else {
                Set-MgUserLicense -UserId $dave.Id `
                                  -AddLicenses    @(@{ SkuId = $targetSku.SkuId }) `
                                  -RemoveLicenses @() `
                                  -ErrorAction Stop | Out-Null
                Write-Host "  OK Dave license     = $LicenseSkuPartNumber assigned" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  FAIL Dave license: $($_.Exception.Message)"                 -ForegroundColor Red
    }

    # 2e. Group membership
    try {
        $demoGroup = Get-MgGroup -Filter "displayName eq '$DemoGroupName'" -ErrorAction Stop
        if (-not $demoGroup) {
            Write-Host "  WARN Group '$DemoGroupName' not found. Skipping group membership."  -ForegroundColor Yellow
        } else {
            $existingMembers = Get-MgGroupMember -GroupId $demoGroup.Id -All -ErrorAction Stop
            if ($existingMembers.Id -contains $dave.Id) {
                Write-Host "  -- Dave already member of $DemoGroupName"           -ForegroundColor Gray
            } else {
                New-MgGroupMember -GroupId $demoGroup.Id -DirectoryObjectId $dave.Id -ErrorAction Stop
                Write-Host "  OK Dave added to    = $DemoGroupName"               -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "  FAIL Dave group: $($_.Exception.Message)"                   -ForegroundColor Red
    }
}
catch {
    Write-Host "  FAIL Dave reset: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# -------------------------------------------------------------------
#  3. Manager Demo - just verify
# -------------------------------------------------------------------
Write-Host "--- [3/3] Verifying Manager Demo ---" -ForegroundColor Cyan

try {
    $manager = Get-MgUser -Filter "displayName eq 'Manager Demo'" -ErrorAction Stop
    if ($manager) {
        Update-MgUser -UserId $manager.Id -Department "DemoSales" -ErrorAction Stop
        Write-Host "  OK Manager department = DemoSales" -ForegroundColor Green
    }
}
catch {
    Write-Host "  FAIL Manager check: $($_.Exception.Message)" -ForegroundColor Red
}

# -------------------------------------------------------------------
#  Summary
# -------------------------------------------------------------------
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Reset complete" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Recommended next steps:" -ForegroundColor Yellow
Write-Host "  1. Wait ~2 minutes for changes to replicate"
Write-Host "  2. Run 04-Verify-DemoState.ps1 to confirm everything is ready"
Write-Host "  3. Do a rehearsal Run on demand on Carol in the portal"
Write-Host "  4. (Optional) Dismiss any risky users from Demo 1 if testing ID Protection"
Write-Host ""
