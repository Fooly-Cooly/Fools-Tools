@ECHO OFF
REM ==================================================================
REM Retrieves IP address ^& sets OutputVar (or prints to stdout)
REM Syntax:	%~nx0 [OutputVar] [Type]
REM Types:	InternalIPv4 (default) | InternalIPv6 | ExternalIPv4 | ExternalIPv6 | All
REM Notes:	For Windows XP and later (requires PowerShell 2.0+)
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS. & GOTO :EOF )

	SET "OUT_VAR=%~1"
	SET "TYPE=%~2"
	IF "%TYPE%"=="" SET "TYPE=InternalIPv4"

	SET "FLAG="
	IF /I "%TYPE%"=="InternalIPv4" SET "FLAG=-InternalOnly -IPv4 -Raw"
	IF /I "%TYPE%"=="InternalIPv6" SET "FLAG=-InternalOnly -IPv6 -Raw"
	IF /I "%TYPE%"=="ExternalIPv4" SET "FLAG=-ExternalOnly -IPv4 -Raw"
	IF /I "%TYPE%"=="ExternalIPv6" SET "FLAG=-ExternalOnly -IPv6 -Raw"
	IF /I "%TYPE%"=="All"          SET "FLAG=-NoColor"

	IF "%FLAG%"=="" (
		ECHO Error: Invalid Type "%TYPE%". Valid types: InternalIPv4, InternalIPv6, ExternalIPv4, ExternalIPv6, All
		GOTO :EOF
	)

	SET "RETURN="
	FOR /F "usebackq delims=" %%A IN (`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\ps1\Get-IPAddress.ps1" %FLAG% 2^>NUL`) DO (
		IF NOT DEFINED RETURN SET "RETURN=%%A"
	)

	IF "%OUT_VAR%"=="" (
		ECHO %RETURN%
		GOTO :EOF
	)
ENDLOCAL & SET "%OUT_VAR%=%RETURN%"
