@echo off
REM ===========================================================================
REM  Remove-VerifiedID-AccessPackages.bat
REM  Launcher for Remove-VerifiedID-AccessPackages.ps1
REM  *** DESTRUCTIVE TEARDOWN - deletes both access packages permanently ***
REM  The script will ask you to type DELETE to confirm.
REM  Keep this .bat in the SAME folder as the .ps1 file.
REM ===========================================================================
echo.
echo WARNING: This permanently DELETES the Sales Onboarding and Contractor Pass
echo access packages. You will be asked to type DELETE to confirm.
echo A Microsoft sign-in prompt will appear. Sign in as Global Admin.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Remove-VerifiedID-AccessPackages.ps1"
echo.
pause
