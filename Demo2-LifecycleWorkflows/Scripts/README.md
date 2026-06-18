# Entra Suite Demo – Lifecycle Workflow Scripts

PowerShell automation for the **Identity Lifecycle (Joiner / Leaver)** portion of the Entra Suite demo. Scripts handle environment reset so every client demo starts from a clean, known state.

---

## Scripts in this folder

| # | File | When to run | What it does |
|---|---|---|---|
| 🚀 | **`RUN-DEMO-PREP.bat`** | **Demo day — double-click this** | One-click launcher — runs Connect, Reset, and Verify in sequence |
| 0 | `00-RunDemoPrep.ps1` | (Called by BAT — don't run manually) | Wrapper script orchestrating the prep sequence |
| 1 | `01-Install-GraphModule.ps1` | **Once** per machine | Installs Microsoft.Graph PowerShell module, trusts PSGallery, sets up TLS |
| 2 | `02-Connect-Graph.ps1` | (Called by BAT, or run manually) | Signs in to Microsoft Graph with the required scopes |
| 3 | `03-PreDemo-Reset.ps1` | (Called by BAT, or run manually) | Resets Carol/Dave state: dates, licenses, account enabled, group membership |
| 4 | `04-Verify-DemoState.ps1` | (Called by BAT, or run manually) | Read-only health check confirming everything is ready |

---

## Demo day workflow (start to finish)

### Step 1 — One-time setup (skip if already done on this machine)

```powershell
cd "$env:USERPROFILE\Documents\Entra Suite demo - Lifecycle workflow scripts"
.\01-Install-GraphModule.ps1
```

### Step 2 — Each demo day (THE EASY WAY)

**Just double-click `RUN-DEMO-PREP.bat`** from File Explorer.

It opens a PowerShell window, signs you in (browser popup), resets the environment, and verifies state — all automatically. Watch for green PASS lines. If anything fails, just close the window and double-click the BAT again.

### Step 2 (Alternative) — Each demo session, manual mode

If you'd rather run the steps individually from an existing PowerShell window:

```powershell
# Authenticate
.\02-Connect-Graph.ps1

# Reset demo environment (~1 hour before client meeting)
.\03-PreDemo-Reset.ps1

# Sanity-check everything is good
.\04-Verify-DemoState.ps1
```

### Step 3 — Manual portal checks (5 min)

After the verify script shows all PASS:

- **entra.microsoft.com → Protection → Authentication methods → Policies → Temporary Access Pass** — confirm **Enabled = Yes**
- **Lifecycle Workflows → Demo - Pre-hire onboarding** — confirm exists
- **Lifecycle Workflows → Demo - Last day offboarding** — confirm exists
- **Manager Demo mailbox** — sign in to `outlook.office.com` once to confirm accessible
- (If using Demo 1) **Identity Protection → Risky users** — dismiss any lingering risk

### Step 4 — Rehearsal run (15 min before client)

Run **Run on demand** on Carol in the joiner workflow to verify the TAP email arrives in Manager's mailbox. Skip rehearsing Dave to avoid having to reset again — the verify script already confirmed he's ready.

---

## Customizing for your tenant

The reset script accepts parameters if your tenant differs from defaults:

```powershell
# Different country code for license usage location
.\03-PreDemo-Reset.ps1 -UsageLocation "CA"

# Different license SKU
.\03-PreDemo-Reset.ps1 -LicenseSkuPartNumber "ENTERPRISEPREMIUM"

# Different demo group name
.\03-PreDemo-Reset.ps1 -DemoGroupName "Demo-Users-LCW"

# All three at once
.\03-PreDemo-Reset.ps1 -UsageLocation "IN" -LicenseSkuPartNumber "SPE_E5" -DemoGroupName "MyDemoGroup"
```

### Common SKU part numbers

| SKU part number | Friendly name |
|---|---|
| `SPE_E5` | Microsoft 365 E5 (default) |
| `SPE_E3` | Microsoft 365 E3 |
| `ENTERPRISEPREMIUM` | Office 365 E5 |
| `ENTERPRISEPACK` | Office 365 E3 |
| `AAD_PREMIUM_P2` | Entra ID P2 standalone |
| `EMSPREMIUM` | EMS E5 |

If the script can't find your specified SKU, it will print a list of all SKUs available in your tenant — copy one of those names and re-run with `-LicenseSkuPartNumber`.

---

## What the reset script does NOT touch

To avoid surprises, these stay untouched:

- Workflow definitions (tasks, scopes, triggers)
- Conditional Access policies
- Identity Protection settings
- TAP authentication method policy
- Manager Demo's account
- Group membership for users other than Dave
- Your colleague's dynamic Sales group

---

## Demo user reference

| User | Display Name | Department | Role |
|---|---|---|---|
| Carol | Carol Newhire | DemoSales | Joiner — fires pre-hire workflow |
| Dave | Dave Leaver | DemoSales | Leaver — fires offboarding workflow |
| Manager | Manager Demo | DemoSales | Receives TAP + offboarding emails |

**Why `DemoSales` and not `Sales`?** Production Sales users are in a colleague's dynamic group that auto-assigns licenses. Using `DemoSales` keeps demo users isolated so license removal works cleanly in the leaver workflow.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Update-MgUser` fails with "Insufficient privileges" | Connected with wrong account or missing scopes | Re-run `02-Connect-Graph.ps1` as Global Admin |
| License assignment fails with "User has no usage location" | UsageLocation not set first | The reset script sets this — if still failing, run `Update-MgUser -UserId $dave.Id -UsageLocation "US"` manually |
| Reset says "SKU not found" | Tenant uses different SKU name | Script will list available SKUs — re-run with `-LicenseSkuPartNumber <correct name>` |
| Verify says hire date is wrong by a few hours | Time-zone display vs storage | Cosmetic — workflow scope only checks the date, not the time |
| Carol's workflow still triggers via colleague's Sales group | Department wasn't actually changed | Run `Get-MgUser -UserId $carol.Id -Property Department` to confirm |
| Workflow on-demand run shows "0 users in scope" | Workflow scope rule still references `Sales` | Edit workflow → Execution conditions → change to `DemoSales` |

---

## Quick reference — what each script outputs

`03-PreDemo-Reset.ps1` prints lines like:
```
  OK  Dave account     = enabled
  OK  Dave leave date  = 2026-05-28
  OK  Dave department  = DemoSales
  OK  Dave usage loc   = US
  OK  Dave license     = SPE_E5 assigned
  OK  Dave added to    = Demo-LifecycleWorkflow-Users
```

`04-Verify-DemoState.ps1` prints lines like:
```
  [PASS] Hire date ~7d out             2026-06-04 (6.9 days)
  [PASS] Department = DemoSales        DemoSales
  [PASS] Account enabled               True
  [PASS] Has license assigned          SPE_E5
```

If anything says **FAIL**, fix the underlying issue and re-run the reset.

---

## Version

Demo : Entra Suite – Identity Lifecycle (Joiner / Leaver)
Coverage : Lifecycle Workflows (Microsoft Entra ID Governance)
Out of scope (separate demos) : Conditional Access, PIM, Identity Protection, Access Reviews, Verified ID, Internet/Private Access
