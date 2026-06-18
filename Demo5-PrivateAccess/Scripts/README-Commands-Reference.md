# Demo 5 — Private Access (GSA) — Toolkit & Command Reference

Everything used to build and fix the Private Access demo, in one place.
Two machines are involved:
- **gsa-appsrv** — the resource host (web app, file share, RDP). Private IP `192.168.50.4`.
- **gsa-connector** — the connector (bridge to Microsoft's cloud). Private IP `10.0.0.5`.
- **[your admin]'s Win11 VM** — the test client running the Global Secure Access client.

> ⭐ **THE critical gotcha:** the resource IP must **NOT** fall inside the *client's* local subnet.
> [your admin]'s VM was `10.0.0.7` and the resource was `10.0.0.4` (same `10.0.0.0/24`) → Private Access
> silently refused to tunnel. Moving the resource to `192.168.50.4` (a range the client doesn't own)
> fixed it instantly.

---

## 1. The one-click .bat files (in this folder)

| File | Run on | What it does |
|------|--------|--------------|
| **Setup-Resources-ONECLICK.bat** | gsa-appsrv | Installs IIS + the "Internal Sales Portal" web page, creates the `share` SMB file share with a sample file, and enables Remote Desktop — all three demo resources in one double-click. |
| **Fix-ServerPopups.bat** | any connector VM | Turns OFF Internet Explorer Enhanced Security. This is what blocks the connector sign-in window with the "JavaScript is required to sign in" error. **Run + reboot before registering a connector.** |
| **Fix-Connector-Service.bat** | connector VM | Enables TLS 1.2 / .NET strong crypto. Fixes connector install **Error 1920** ("updater service failed to start"). Run + reboot, then retry the installer. |
| **Check-Connector-Readiness.bat** | connector VM | Allows PowerShell scripts and tests outbound connectivity to the Microsoft sign-in + registration endpoints. A quick pre-flight check. |

> Note: the marketplace connector VM (gsa-connector) came pre-installed, so on that path you mainly
> need **Fix-ServerPopups.bat** (+ reboot) before the manual registration step below.

---

## 2. Register a connector by hand (run on the connector VM, admin PowerShell)

Used when the auto-registration didn't complete (e.g., MFA blocked the silent sign-in):

```powershell
# Import the connector PowerShell module by its full path
Import-Module "C:\Program Files\Microsoft Entra private network connector\Modules\MicrosoftEntraPrivateNetworkConnectorPSModule\MicrosoftEntraPrivateNetworkConnectorPSModule.psd1"

# Register — opens an interactive browser sign-in (MFA works here, unlike the silent install)
Register-MicrosoftEntraPrivateNetworkConnector

# Start the connector services
Start-Service WAPCSvc, WAPCUpdaterSvc
```

---

## 3. The IPv4 fix on the CLIENT (run on [your admin]'s VM, admin PowerShell)

Fixes the GSA client health-check error **"IPv4 is not preferred"** (Private Access needs IPv4 preferred):

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 32 /f
# THEN REBOOT the client VM for it to take effect
```

---

## 4. Diagnostics we used (run on the connector VM)

```powershell
# Are the connector services running?
Get-Service WAPCSvc, WAPCUpdaterSvc | Format-Table Name,Status -Auto

# Is the connector registered? (TrustSettings file present = yes)
Test-Path "$env:ProgramData\Microsoft\Microsoft Entra Private Network Connector\Config\TrustSettings.xml"

# Can the connector reach the resource? (expect True)
"Web 80: "  + (Test-NetConnection 192.168.50.4 -Port 80   -WarningAction SilentlyContinue).TcpTestSucceeded
"SMB 445: " + (Test-NetConnection 192.168.50.4 -Port 445  -WarningAction SilentlyContinue).TcpTestSucceeded
"RDP 3389: "+ (Test-NetConnection 192.168.50.4 -Port 3389 -WarningAction SilentlyContinue).TcpTestSucceeded

# Does the web server actually serve? (expect 200)
(Invoke-WebRequest http://192.168.50.4 -UseBasicParsing -TimeoutSec 10).StatusCode

# Is the connector's relay actually up? (count of live 443 connections to Microsoft — expect many)
$p = (Get-CimInstance Win32_Service -Filter "Name='WAPCSvc'").ProcessId
"Live relay connections (443): " + ((Get-NetTCPConnection -OwningProcess $p -RemotePort 443 -State Established -ErrorAction SilentlyContinue | Measure-Object).Count)
```

---

## 5. Disable a connector on a box (so it's resource-host only)

If a VM accidentally became a second/zombie connector:

```powershell
Stop-Service WAPCSvc -Force
Set-Service  WAPCSvc -StartupType Disabled
```
To re-enable it later: `Set-Service WAPCSvc -StartupType Automatic; Start-Service WAPCSvc`

---

## 6. Where to verify in the portal

- **Connectors:** Entra admin center → Global Secure Access → Connect → Connectors (look for **Active**)
- **Published resources:** Global Secure Access → Applications → Quick Access (segments = resource IP + ports)
- **User assignment:** Quick Access → Users and groups ([your admin])
- **Traffic profiles:** Global Secure Access → Connect → Traffic forwarding (Private + Microsoft + Internet, assigned to [your admin])
- **Client (harry's VM):** Global Secure Access client → all channels Connected; Advanced diagnostics → Health check (all green) and Forwarding profile (Tunnel rules for the resource IP)
