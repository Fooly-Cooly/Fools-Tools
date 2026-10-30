@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM System Information Fetch Tool (Screenfetch / Archey for Windows)
	REM Syntax: system-information [Options]
	REM ==================================================================

	IF "%~1"=="/?" GOTO :SYNTAX
	IF "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/H" GOTO :SYNTAX
	IF /I "%~1"=="-H" GOTO :SYNTAX
	IF /I "%~1"=="/HELP" GOTO :SYNTAX
	IF /I "%~1"=="--HELP" GOTO :SYNTAX

	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\lib\ps1\Get-SystemInformation.ps1" %*
	SET "EXIT_CODE=%ERRORLEVEL%"
	GOTO :END

	:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [Options]
		ECHO.
		ECHO    Displays system information with colorized Windows ASCII art
		ECHO    (Screenfetch / Archey clone for Windows).
		ECHO.
		ECHO    Options / Flags:
		ECHO       -NoColor, /NOCOLOR : Disable color formatting (plain text)
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0
		ECHO       %~nx0 -NoColor
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
