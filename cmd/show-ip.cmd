@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Displays local and external IPv4/IPv6 network addresses
	REM Syntax: show-ip [Options]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	IF "%~1"=="/?" GOTO :SYNTAX
	IF "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/H" GOTO :SYNTAX
	IF /I "%~1"=="-H" GOTO :SYNTAX
	IF /I "%~1"=="/HELP" GOTO :SYNTAX
	IF /I "%~1"=="--HELP" GOTO :SYNTAX

	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\lib\ps1\Get-IPAddress.ps1" %*
	SET "EXIT_CODE=%ERRORLEVEL%"
	GOTO :END

	:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [Options]
		ECHO.
		ECHO    Displays local and external IPv4/IPv6 network addresses.
		ECHO.
		ECHO    Options / Flags:
		ECHO       -InternalOnly, -i : Display only internal (LAN) network addresses
		ECHO       -ExternalOnly, -e : Display only external (Public) network addresses
		ECHO       -IPv4, -4         : Restrict discovery to IPv4 addresses
		ECHO       -IPv6, -6         : Restrict discovery to IPv6 addresses
		ECHO       -Raw, -r          : Output raw IP address values only (for scripting)
		ECHO       -Json, -j         : Output results as a structured JSON object
		ECHO       -NoColor, -nc     : Disable console color formatting (plain text)
		ECHO       -?, -h, --help    : Display this syntax help
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0
		ECHO       %~nx0 -InternalOnly -IPv4
		ECHO       %~nx0 -ExternalOnly -Raw
		ECHO       %~nx0 -Json
		ECHO.
		ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
		ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
		ECHO Contact: foolycooly1764@gmail.com
		ECHO.
		SET "EXIT_CODE=0"

	:END
		CALL "%~dp0..\lib\bat\isDoubleClick.cmd" "%~nx0"
		IF %ERRORLEVEL% EQU 0 (
			ECHO.
			PAUSE
		)
		EXIT /B %EXIT_CODE%
ENDLOCAL
