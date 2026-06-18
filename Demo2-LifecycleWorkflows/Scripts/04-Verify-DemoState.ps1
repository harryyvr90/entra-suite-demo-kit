<#
.SYNOPSIS
    Verifies the Lifecycle Workflow demo environment is ready.

.DESCRIPTION
    Read-only health check. Confirms each demo user is in the expected state
    after the reset script ran. Run this after 03-PreDemo-Reset.ps1 and before
    starting the actual demo.

    Checks:
      - Carol's hire date is ~7 days in the future
      - Carol's department is DemoSales
      - Dave's leave date is today
      - Dave's account is enabled
      - Dave has a usage location
      - Dave has at least one license assigned
      - Dave is a member of the demo group
      - Manager has a mailbox license

.NOTES
    Author : Entra Suite Demo Kit
    Demo   : Lifecycle Workflows
    Step   : 4 of 4 (run after reset, before demo)
#>

param(
    [string]$DemoGroupName = "Demo-LifecycleWorkflow-Users"
)

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Verify Demo State - Lifecycle Workflows" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$ctx = Get-MgContext
if (-not $ctx) {
    Write-Host "ERROR: Not connected to Graph. Run 02-Connect-Graph.ps1 first." -ForegroundColor Red
    exit 1
}

$allPassed = $true
function Check {
    param([string]$Label, [bool]$Passed, [string]$Detail)
    $marker = if ($Passed) { "PASS" } else { "FAIL" }
    $color  = if ($Passed) { "Green" } else { "Red" }
    Write-Host ("  [{0}] {1,-30} {2}" -f $marker, $Label, $Detail) -ForegroundColor $color
    if (-not $Passed) { $script:allPassed = $false }
}

# ---------- Carol ----------
Write-Host "Carol Newhire (Joiner)" -ForegroundColor Cyan
try {
    $carol = Get-MgUser -Filter "displayName eq 'Carol Newhire'" `
                        -Property Id,DisplayName,EmployeeHireDate,Department `
                        -ErrorAction Stop

    if ($null -ne $carol.EmployeeHireDate) {
        $daysOut = ($carol.EmployeeHireDate - (Get-Date)).TotalDays
        $hireOK  = $daysOut -ge 6 -and $daysOut -le 8
        Check "Hire date ~7d out"   $hireOK ("{0:yyyy-MM-dd} ({1:N1} days)" -f $carol.EmployeeHireDate, $daysOut)
    } else {
        Check "Hire date ~7d out"   $false "not set"
    }
    Check "Department = DemoSales" ($carol.Department -eq "DemoSales") $carol.Department
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# ---------- Dave ----------
Write-Host "Dave Leaver (Leaver)" -ForegroundColor Cyan
try {
    $dave = Get-MgUser -Filter "displayName eq 'Dave Leaver'" `
                       -Property Id,DisplayName,EmployeeLeaveDateTime,Department,AccountEnabled,UsageLocation `
                       -ErrorAction Stop

    if ($null -ne $dave.EmployeeLeaveDateTime) {
        $daysAgo = ((Get-Date) - $dave.EmployeeLeaveDateTime).TotalDays
        $leaveOK = $daysAgo -ge -1 -and $daysAgo -le 1
        Check "Leave date = today" $leaveOK ("{0:yyyy-MM-dd}" -f $dave.EmployeeLeaveDateTime)
    } else {
        Check "Leave date = today" $false "not set"
    }

    Check "Department = DemoSales"  ($dave.Department -eq "DemoSales")  $dave.Department
    Check "Account enabled"         ($dave.AccountEnabled -eq $true)    "$($dave.AccountEnabled)"
    Check "Usage location set"      ($null -ne $dave.UsageLocation)     "$($dave.UsageLocation)"

    # Licenses
    $licenses = Get-MgUserLicenseDetail -UserId $dave.Id -ErrorAction Stop
    $hasLicense = $licenses.Count -gt 0
    $skuList    = ($licenses.SkuPartNumber -join ", ")
    Check "Has license assigned" $hasLicense $skuList

    # Group membership
    $demoGroup = Get-MgGroup -Filter "displayName eq '$DemoGroupName'" -ErrorAction SilentlyContinue
    if ($demoGroup) {
        $members = Get-MgGroupMember -GroupId $demoGroup.Id -All -ErrorAction SilentlyContinue
        $inGroup = $members.Id -contains $dave.Id
        Check "Member of $DemoGroupName" $inGroup $(if ($inGroup) { "yes" } else { "no" })
    } else {
        Check "Demo group exists" $false "'$DemoGroupName' not found"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# ---------- Manager ----------
Write-Host "Manager Demo" -ForegroundColor Cyan
try {
    $manager = Get-MgUser -Filter "displayName eq 'Manager Demo'" `
                          -Property Id,DisplayName,Mail,Department `
                          -ErrorAction Stop
    Check "Has mail attribute"  ($null -ne $manager.Mail) $manager.Mail

    $mgrLicenses = Get-MgUserLicenseDetail -UserId $manager.Id -ErrorAction Stop
    $hasMgrLic   = $mgrLicenses.Count -gt 0
    Check "Has license"         $hasMgrLic ($mgrLicenses.SkuPartNumber -join ", ")
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# ---------- Summary ----------
Write-Host "===============================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host " ALL CHECKS PASSED - demo environment ready" -ForegroundColor Green
} else {
    Write-Host " SOME CHECKS FAILED - review above and fix"  -ForegroundColor Red
    Write-Host " Re-run 03-PreDemo-Reset.ps1 if needed"      -ForegroundColor Yellow
}
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
