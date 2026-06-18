@echo off
REM ===========================================================================
REM  Fix-ServerPopups.bat
REM  Turns OFF Internet Explorer Enhanced Security Configuration (IE ESC) on
REM  this Windows Server. That lockdown is what blocks the connector's
REM  sign-in window and throws the security popups. Double-click on gsa-appsrv.
REM ===========================================================================
echo.
echo Turning off the Windows Server "Enhanced Security" lockdown...
echo (this is what blocks the connector sign-in page)
echo.

reg add "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" /v IsInstalled /t REG_DWORD /d 0 /f

echo.
echo Done. Enhanced Security is now OFF.
echo.
echo NEXT: close the browser and the connector installer completely,
echo then open them again and re-run the connector install. The sign-in
echo page will now appear normally.
echo.
pause
