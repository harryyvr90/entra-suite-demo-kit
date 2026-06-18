@echo off
REM ===========================================================================
REM  Rebuild-VerifiedID-SalesOnboarding.bat
REM  Launcher for Rebuild-VerifiedID-SalesOnboarding.ps1
REM  Rebuilds the "Sales Onboarding - Face Check Demo" access package
REM  (permanent access). Keep this .bat in the SAME folder as the .ps1 file.
REM ===========================================================================
echo.
echo Rebuilding the "Sales Onboarding - Face Check Demo" access package...
echo (permanent access to the Sales Team site)
echo A Microsoft sign-in prompt will appear. Sign in as Global Admin.
echo.
echo When the script finishes it will print one last portal step -
echo adding the Verified ID + Face Check rule. Follow those on-screen lines.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rebuild-VerifiedID-SalesOnboarding.ps1"
echo.
pause
