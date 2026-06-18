<#
  Setup-VerifiedID-Demo-Resources.ps1
  -----------------------------------
  Fills your TWO existing Microsoft 365 groups' SharePoint sites with
  demo folders + sample files. If a group is missing it will create it.

    Group 1: "Sales Team"   -> new-hire ONBOARDING demo  (permanent access)
    Group 2: "Contractors"  -> contractor VISITOR PASS demo (temporary access)

  Because these are M365 groups, the SharePoint site comes with the group and
  every group MEMBER automatically gets access to the site. So when an access
  package adds a user to the group, they instantly get the site + files.

  Run as a SharePoint/Global Admin in the demo tenant (yourtenant.onmicrosoft.com).

  ---------------------------------------------------------------------------
  ONE-TIME PREREQ (run once, then never again):

    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

  That is the ONLY install you need. No app registration, no Client Id,
  no PnP. Connect-MgGraph uses Microsoft's own sign-in app and just asks
  you to sign in + consent (you can, you're Global Admin).

  This script works in BOTH Windows PowerShell 5.1 and PowerShell 7.
  ---------------------------------------------------------------------------
#>

# ===========================================================================
#  CONFIGURE FOR YOUR TENANT — change the line below before running
# ===========================================================================
$AdminUpn = "admin@yourtenant.onmicrosoft.com"   # ← CHANGE to your Global Admin UPN
# ===========================================================================

# Group + content definitions
$Groups = @(
  @{
    Display  = "Sales Team"
    Nickname = "salesteam"
    Desc     = "Sales team resources - Verified ID onboarding demo (permanent access)"
    Folders  = @("Sales Playbook", "Pricing", "Templates")
    Files    = @(
      @{ Path = "Sales Playbook/Welcome to Sales.txt"; Body = "Welcome to the Sales team! This file is only visible to verified Sales members. If you can read this, your Verified ID + Face Check onboarding worked." }
      @{ Path = "Pricing/Price List 2026.csv";         Body = "Product,Price`r`nWidget,100`r`nGadget,250`r`nPlatform License,5000" }
      @{ Path = "Templates/Proposal Template.txt";     Body = "[Customer Name] Proposal - prepared by the [Your Organization] Sales team." }
    )
  },
  @{
    Display  = "Contractors"
    Nickname = "contractors"
    Desc     = "Vendor/contractor resources - Verified ID visitor pass demo (temporary access)"
    Folders  = @("Vendor Guidelines", "Shared With Vendors")
    Files    = @(
      @{ Path = "Vendor Guidelines/Visitor Guidelines.txt"; Body = "Vendor guidelines. Temporary access granted only after a real-time Face Check. This pass expires automatically." }
      @{ Path = "Shared With Vendors/Site Map.txt";         Body = "Building site map and visit information for approved contractors." }
    )
  }
)

# ===================== CONNECT TO MICROSOFT GRAPH =====================
Write-Host "Signing in to Microsoft Graph (a browser/sign-in prompt will appear)..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Group.ReadWrite.All","Sites.ReadWrite.All","Files.ReadWrite.All","User.Read.All" | Out-Null

# Look up the owner's object id
$ownerId = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/users/$AdminUpn").id
Write-Host "Owner resolved: $AdminUpn" -ForegroundColor Green

foreach ($g in $Groups) {

  # ---------- Create the group (reuse if it already exists) ----------
  $filter   = [uri]::EscapeDataString("mailNickname eq '$($g.Nickname)'")
  $existing = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=$filter").value

  if ($existing -and $existing.Count -gt 0) {
    Write-Host "Group '$($g.Display)' already exists - reusing it." -ForegroundColor Yellow
    $groupId = $existing[0].id
  }
  else {
    Write-Host "Creating group '$($g.Display)' ..." -ForegroundColor Cyan
    $body = @{
      displayName     = $g.Display
      description     = $g.Desc
      mailEnabled     = $true
      mailNickname    = $g.Nickname
      securityEnabled = $false
      groupTypes      = @("Unified")
      visibility      = "Private"
      "owners@odata.bind"  = @("https://graph.microsoft.com/v1.0/directoryObjects/$ownerId")
      "members@odata.bind" = @("https://graph.microsoft.com/v1.0/directoryObjects/$ownerId")
    }
    $group   = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/groups" -Body ($body | ConvertTo-Json)
    $groupId = $group.id
  }

  # ---------- Wait for the SharePoint site (drive) to finish provisioning ----------
  $driveId = $null
  for ($i = 0; $i -lt 18 -and -not $driveId; $i++) {
    try {
      $driveId = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$groupId/drive").id
    } catch {
      Start-Sleep -Seconds 10
    }
  }
  if (-not $driveId) {
    Write-Warning "Site for '$($g.Display)' isn't ready yet. Re-run this script in a minute to add the files."
    continue
  }
  Write-Host "  Site ready for '$($g.Display)'." -ForegroundColor Green

  # ---------- Add folders ----------
  foreach ($folder in $g.Folders) {
    $fbody = @{
      name = $folder
      folder = @{}
      "@microsoft.graph.conflictBehavior" = "replace"
    }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/drives/$driveId/root/children" -Body ($fbody | ConvertTo-Json) | Out-Null
    Write-Host "  + folder: $folder"
  }

  # ---------- Upload sample files ----------
  foreach ($f in $g.Files) {
    # Encode each path segment but keep the slashes
    $encoded = ($f.Path -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
    $uri     = "https://graph.microsoft.com/v1.0/drives/$driveId/root:/$encoded`:/content"
    Invoke-MgGraphRequest -Method PUT -Uri $uri -Body $f.Body -ContentType "text/plain" | Out-Null
    Write-Host "  + file:   $($f.Path)"
  }
}

Write-Host "`nDone! Two groups + sites created with demo content:" -ForegroundColor Green
Write-Host "  - Sales Hub     -> onboarding demo (permanent)"
Write-Host "  - Vendor Portal -> visitor pass demo (temporary)"
Write-Host "`nNext: in each access package, point the resource role at these groups" -ForegroundColor Cyan
Write-Host "  (Onboarding package -> Sales Hub,  Contractor Pass -> Vendor Portal)."
