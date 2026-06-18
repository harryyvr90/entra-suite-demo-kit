@echo off
REM ===========================================================================
REM  Reset-VerifiedID-GroupMembers.bat
REM  Launcher for Reset-VerifiedID-GroupMembers.ps1 (NORMAL PRE-DEMO RESET)
REM  Keep this .bat in the SAME folder as the .ps1 file.
REM ===========================================================================
echo.
echo Resetting the "Sales Team" and "Contractors" groups for the next demo run...
echo A Microsoft sign-in prompt will appear. Sign in as Global Admin.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reset-VerifiedID-GroupMembers.ps1"
echo.
pause
