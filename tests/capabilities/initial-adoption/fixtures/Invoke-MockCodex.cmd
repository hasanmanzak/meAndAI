@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "mock_script=%~dp0Invoke-MockCodex.ps1"
set "mock_arguments="

:collect
if "%~1"=="" goto run
if "%~1"=="-" if "%~2"=="" goto run
set mock_arguments=%mock_arguments% ^"%~1^"
shift
goto collect

:run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%mock_script%" %mock_arguments%
exit /b %ERRORLEVEL%
