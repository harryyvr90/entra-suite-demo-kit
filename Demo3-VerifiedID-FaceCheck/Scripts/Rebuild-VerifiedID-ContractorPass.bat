@echo off
REM ===========================================================================
REM  Rebuild-VerifiedID-ContractorPass.bat
REM  Launcher for Rebuild-VerifiedID-ContractorPass.ps1
REM  Rebuilds the "Contractor Pass - Face Check Demo" access package
REM  (temporary - auto-expires after 1 day). Keep this .bat in the SAME
REM  folder as the .ps1 file.
REM ===========================================================================
echo.
echo Rebuilding the "Contractor Pass - Face Check Demo" access package...
echo (temporary visitor access - auto-expires after 1 day)
echo A Microsoft sign-in prompt will appear. Sign in as Global Admin.
echo.
echo When the script finishes it will print one last portal step -
echo adding the Verified ID + Face Check rule. Follow those on-screen lines.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rebuild-VerifiedID-ContractorPass.ps1"
echo.
pause
