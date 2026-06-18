@echo off
REM ===========================================================================
REM  Setup-VerifiedID-Demo-Resources.bat
REM  Launcher for Setup-VerifiedID-Demo-Resources.ps1 (RUN ONCE - initial build)
REM  Keep this .bat in the SAME folder as the .ps1 file.
REM ===========================================================================
echo.
echo Building the Verified ID demo groups, SharePoint sites, and sample files...
echo A Microsoft sign-in prompt will appear. Sign in as Global Admin.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-VerifiedID-Demo-Resources.ps1"
echo.
pause
