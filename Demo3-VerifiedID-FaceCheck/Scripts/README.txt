=============================================================================
 DEMO 3 - VERIFIED ID + FACE CHECK
 PowerShell Scripts - README
 Tenant: yourtenant.onmicrosoft.com
=============================================================================

This folder holds the 4 scripts that build and reset the resources behind the
Verified ID + Face Check demo. They all use the Microsoft Graph PowerShell
module - no app registration, no client ID, no PnP. Connect-MgGraph just asks
you to sign in and consent (you can, you're Global Admin).

The demo itself has three scenarios:
  1. Helpdesk recovery  - public Woodgrove test app (aka.ms/vcempver). STATELESS,
                          nothing to set up or reset. Run it as many times as you like.
  2. Onboarding         - new hire requests the "Sales Onboarding" access package,
                          passes Face Check, lands in the "Sales Team" group
                          (and its SharePoint site). PERMANENT access.
  3. Visitor pass       - contractor requests the "Contractor Pass" access package,
                          passes Face Check, lands in the "Contractors" group.
                          TEMPORARY - auto-expires after 1 day.

Only scenarios 2 and 3 use these scripts. Scenario 1 needs nothing.

-----------------------------------------------------------------------------
 ONE-TIME PREREQUISITE (run once on your machine, then never again)
-----------------------------------------------------------------------------

    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

That is the only install. Works in both Windows PowerShell 5.1 and PowerShell 7.
Each script calls Connect-MgGraph itself and prompts you to sign in.


=============================================================================
 THE 4 SCRIPTS
=============================================================================

-----------------------------------------------------------------------------
 1. Setup-VerifiedID-Demo-Resources.ps1          [ RUN ONCE - initial build ]
-----------------------------------------------------------------------------
WHAT IT DOES
  Builds the two demo groups and fills their SharePoint sites with sample
  content:
    - "Sales Team"  (onboarding / permanent)  -> folders: Sales Playbook,
                                                  Pricing, Templates + sample files
    - "Contractors" (visitor pass / temporary) -> folders: Vendor Guidelines,
                                                  Shared With Vendors + sample files
  Because these are M365 groups, each one comes with its own SharePoint site,
  and every group member automatically gets the site + files. So when an access
  package adds a user to the group, they instantly see the content.

WHEN TO RUN
  Once, when first standing up the demo (already done). Re-run only if you need
  to rebuild the groups, sites, or sample files from scratch.

SIGN-IN SCOPES
  Group.ReadWrite.All, Sites.ReadWrite.All, Files.ReadWrite.All, User.Read.All

EDIT BEFORE RUNNING
  One line near the top sets the group owner:
    $AdminUpn = "admin@yourtenant.onmicrosoft.com"


-----------------------------------------------------------------------------
 2. Reset-VerifiedID-GroupMembers.ps1           [ NORMAL PRE-DEMO RESET ]
-----------------------------------------------------------------------------
WHAT IT DOES
  Removes ALL members from "Sales Team" and "Contractors". Non-destructive -
  the groups, access packages, SharePoint sites, and sample files all stay.

WHEN TO RUN
  Before each demo run, so the onboarding and visitor-pass scenarios start from
  a clean, empty group. This is the script you'll use most often.

SIGN-IN SCOPES
  Group.Read.All, GroupMember.ReadWrite.All


-----------------------------------------------------------------------------
 3. Reset-VerifiedID-AccessPackageAssignments.ps1   [ CLEAR OLD GRANTS ]
-----------------------------------------------------------------------------
WHAT IT DOES
  Removes existing assignments (grants) from the two access packages:
    - Sales Onboarding   (replace <YOUR-SALES-ONBOARDING-PACKAGE-ID> with your own package GUID)
    - Contractor Pass    (replace <YOUR-CONTRACTOR-PASS-PACKAGE-ID> with your own package GUID)

  FINDING YOUR PACKAGE GUIDS:
    Entra admin center → Identity Governance → Entitlement management
    → Access packages → open the package → copy the ID from the URL or Overview blade.
  The packages themselves are kept.

WHEN TO RUN
  Only if a tester already holds an assignment and the portal says "you already
  have access" when you try to re-request. Removal is processed asynchronously,
  so the access drops a few moments after the script finishes.

SIGN-IN SCOPES
  EntitlementManagement.ReadWrite.All


-----------------------------------------------------------------------------
 4. Remove-VerifiedID-AccessPackages.ps1        [ *** DESTRUCTIVE TEARDOWN *** ]
-----------------------------------------------------------------------------
WHAT IT DOES
  PERMANENTLY DELETES the "Sales Onboarding" and "Contractor Pass" access
  packages. It clears assignments, deletes the policies, then deletes the
  packages. It asks you to type DELETE to confirm first.

WHEN TO RUN
  Only when tearing the demo down for good. After this you must rebuild and
  re-test the packages before you can demo onboarding / visitor pass again.
  This is the nuclear option - NOT part of normal demo prep.

SIGN-IN SCOPES
  EntitlementManagement.ReadWrite.All


=============================================================================
 QUICK GUIDE - WHAT TO RUN, WHEN
=============================================================================

  First-time setup (done):           Setup-VerifiedID-Demo-Resources.ps1
  Before every demo:                 Reset-VerifiedID-GroupMembers.ps1
  If "you already have access":      Reset-VerifiedID-AccessPackageAssignments.ps1
  Helpdesk recovery scenario:        nothing - it's stateless
  Tear the whole demo down:          Remove-VerifiedID-AccessPackages.ps1

  Reminder: the visitor pass auto-expires after 1 day on its own, so most of
  the time Reset-VerifiedID-GroupMembers.ps1 is all you need before a run.

=============================================================================
