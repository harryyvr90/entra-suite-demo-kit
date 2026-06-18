@echo off
REM ===========================================================================
REM  Reset-VerifiedID-AccessPackageAssignments.bat
REM  Launcher for Reset-VerifiedID-AccessPackageAssignments.ps1 (CLEAR OLD GRANTS)
REM  Keep this .bat in the SAME folder as the .ps1 file.
REM ===========================================================================
echo.
echo Clearing existing grants from the Sales Onboarding and Contractor Pass packages...
echo A Microsoft sign-in prompt will appear. Sign in as Global Admin.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reset-VerifiedID-AccessPackageAssignments.ps1"
echo.
pause
