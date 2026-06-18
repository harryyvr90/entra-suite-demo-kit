@echo off
REM ===========================================================================
REM  Fix-Connector-Service.bat
REM  Fixes Error 1920: "Service 'Microsoft Entra private network connector
REM  updater' (WAPCPUpdaterSvc) failed to start."
REM  Cause: the connector's .NET service needs TLS 1.2 / strong crypto turned
REM  on. These keys enable it. Double-click on gsa-appsrv, then click Retry
REM  in the connector setup window.
REM ===========================================================================
echo.
echo Enabling TLS 1.2 / strong crypto so the connector service can start...
echo.

reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" /v SchUseStrongCrypto /t REG_DWORD /d 1 /f

echo.
echo Also enabling TLS 1.2 at the system level...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f

echo.
echo Done. Now go back to the connector Setup window and click RETRY.
echo (If Retry still fails, click Cancel, then run the connector installer
echo  again from scratch - it will work on the fresh run.)
echo.
pause
