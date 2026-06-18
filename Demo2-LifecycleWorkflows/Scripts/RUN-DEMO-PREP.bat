@echo off
REM ====================================================================
REM   Entra Suite Demo - Lifecycle Workflows
REM   One-click demo day prep launcher
REM
REM   Double-click this file to run the full prep sequence:
REM     1. Unblock script files
REM     2. Connect to Microsoft Graph
REM     3. Reset demo environment
REM     4. Verify demo state
REM ====================================================================

REM Switch to the folder this BAT file lives in (works regardless of where launched from)
cd /d "%~dp0"

REM Launch PowerShell with execution policy bypass, run the wrapper, keep window open on errors
powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -File ".\00-RunDemoPrep.ps1"
