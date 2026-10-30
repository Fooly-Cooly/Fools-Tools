@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Lightweight Local Web Server for Fool's Tools
	REM Syntax: webserver [[Port] Directory] [Options]
	REM ==================================================================

	IF "%~1"=="/?" GOTO :SYNTAX
	IF "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/H" GOTO :SYNTAX
	IF /I "%~1"=="-H" GOTO :SYNTAX
	IF /I "%~1"=="/HELP" GOTO :SYNTAX
	IF /I "%~1"=="--HELP" GOTO :SYNTAX

	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\lib\ps1\Start-WebServer.ps1" %*
	EXIT /B %ERRORLEVEL%

	:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [[Port] Directory] [Options]
		ECHO.
		ECHO    Options / Flags:
		ECHO       [Port]         : Port number to listen on (Default: 8080)
		ECHO       [Directory]    : Root directory to serve (Default: current directory)
		ECHO       /CORS, -Cors   : Enable Cross-Origin Resource Sharing headers
		ECHO       /HTTPS, -Https : Enable HTTPS (requires Administrator elevation)
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0
		ECHO       %~nx0 9000
		ECHO       %~nx0 8080 "C:\MySite"
		ECHO       %~nx0 8080 -Cors
		ECHO       %~nx0 -Cors
		ECHO.
		ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
		ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
		ECHO Contact: foolycooly1764@gmail.com
		ECHO.
	EXIT /B 0
ENDLOCAL
