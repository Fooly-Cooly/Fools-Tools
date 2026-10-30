@ECHO OFF
SETLOCAL
	powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\lib\ps1\Extract-Icon.ps1" %*
ENDLOCAL