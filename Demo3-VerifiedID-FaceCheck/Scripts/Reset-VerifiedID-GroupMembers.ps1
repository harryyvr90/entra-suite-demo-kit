<#
    Reset-VerifiedID-GroupMembers.ps1
    -----------------------------------
    Pre-demo cleanup for Demo 3 (Verified ID + Face Check).
    Removes ALL members from the "Sales Team" and "Contractors" groups so the
    onboarding and visitor-pass scenarios can be re-requested from a clean state.

    Non-destructive: the groups, access packages, and SharePoint sites stay intact.
    Run this BEFORE you start the demo.

    Required scope: GroupMember.ReadWrite.All  (Group.Read.All to resolve names)
#>

Connect-MgGraph -Scopes "Group.Read.All","GroupMember.ReadWrite.All" -NoWelcome

$groupNames = @("Sales Team","Contractors")

foreach ($name in $groupNames) {
    $group = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if (-not $group) {
        Write-Warning "Group '$name' not found - skipping."
        continue
    }

    $members = Get-MgGroupMember -GroupId $group.Id -All
    if (-not $members -or $members.Count -eq 0) {
        Write-Host "[$name] already empty - nothing to remove." -ForegroundColor Green
        continue
    }

    foreach ($m in $members) {
        $label = $m.AdditionalProperties["userPrincipalName"]
        if (-not $label) { $label = $m.AdditionalProperties["displayName"] }
        if (-not $label) { $label = $m.Id }
        try {
            Remove-MgGroupMemberByRef -GroupId $group.Id -DirectoryObjectId $m.Id -ErrorAction Stop
            Write-Host "[$name] removed: $label" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "[$name] could not remove $label : $($_.Exception.Message)"
        }
    }
}

Write-Host "`nDone. Both groups are reset for the next demo run." -ForegroundColor Cyan
