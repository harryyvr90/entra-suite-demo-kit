@echo off
REM ===========================================================================
REM  Build-Demo5-Config.bat
REM  Configures the GSA Private Access "Quick Access" app for Demo 5:
REM    - creates the 3 IP segments (web 80 / SMB 445 / RDP 3389) on the app
REM    - assigns the demo user to the app
REM  Run this from an admin workstation that has the Microsoft.Graph module.
REM  The empty "Quick Access" app shell must already exist in the portal.
REM ===========================================================================
echo.
echo Building the Demo 5 Private Access configuration...
echo A Microsoft sign-in window will appear - sign in as a GSA + Application admin.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Demo5-Config.ps1"
echo.
pause
