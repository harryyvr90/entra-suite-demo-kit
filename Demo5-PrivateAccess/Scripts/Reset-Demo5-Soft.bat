@echo off
REM ===========================================================================
REM  Reset-Demo5-Soft.bat
REM  SOFT reset of the Demo 5 GSA config (keeps VMs + the Quick Access shell):
REM    - deletes the IP segments from the Quick Access app
REM    - removes the demo user's assignment
REM  Re-run Build-Demo5-Config.bat afterwards to rebuild.
REM  Run from an admin workstation that has the Microsoft.Graph module.
REM ===========================================================================
echo.
echo Soft-resetting the Demo 5 Private Access configuration...
echo A Microsoft sign-in window will appear - sign in as a GSA + Application admin.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Reset-Demo5-Soft.ps1"
echo.
pause
