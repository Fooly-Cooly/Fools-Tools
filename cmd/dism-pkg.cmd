@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Windows Servicing Package & Component Store Manager (DISM)
	REM Syntax: dism-pkg [Options]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "ENGINE_PS1=%SCRIPT_DIR%..\lib\ps1\Manage-Dism.ps1"
	SET "EXIT_CODE=0"

	IF NOT EXIST "%ENGINE_PS1%" (
		ECHO [ERROR] Manage-Dism.ps1 not found at "%ENGINE_PS1%".
		EXIT /B 1
	)

	REM Help routing
	IF /I "%~1"=="/?" GOTO :SYNTAX
	IF /I "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/h" GOTO :SYNTAX
	IF /I "%~1"=="-h" GOTO :SYNTAX
	IF /I "%~1"=="/help" GOTO :SYNTAX
	IF /I "%~1"=="--help" GOTO :SYNTAX
	IF /I "%~1"=="help" GOTO :SYNTAX

	REM Administrator Privilege Check
	IF NOT EXIST "%SCRIPT_DIR%..\lib\bat\isAdmin.cmd" GOTO :SKIP_ADMIN_CHECK
	CALL "%SCRIPT_DIR%..\lib\bat\isAdmin.cmd"
	IF %ERRORLEVEL% NEQ 0 (
		ECHO [ERROR] DISM servicing package management requires Administrator privileges.
		ECHO Please right-click and "Run as administrator", or launch from an elevated console.
		SET "EXIT_CODE=1"
		GOTO :END
	)
:SKIP_ADMIN_CHECK

	REM Forward CLI arguments or launch interactive menu if no arguments given
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" %*
	SET "EXIT_CODE=%ERRORLEVEL%"
	GOTO :END

:SYNTAX
	ECHO.
	ECHO Syntax: %~nx0 [Options]
	ECHO.
	ECHO    Manages Windows servicing packages, removes superseded updates, and
	ECHO    reclaims disk space from the WinSxS component store via DISM.
	ECHO    Invoking without parameters opens an interactive management menu.
	ECHO    (Note: Requires Administrator privileges).
	ECHO.
	ECHO    Options / Flags:
	ECHO       -List, -l, /L              : List all installed servicing packages
	ECHO       -Search, -s, /S ^<pattern^>  : Search packages by KB number or keyword
	ECHO       -Remove, -r, /R ^<pattern^>  : Remove matching package(s) non-interactively
	ECHO       -Superseded                : Find and remove all superseded updates
	ECHO       -Analyze                   : Analyze WinSxS component store size ^& savings
	ECHO       -Clean, -c, /C             : Clean superseded components from WinSxS
	ECHO       -ResetBase                 : Combine with -Clean to reset component base (max space)
	ECHO       -NoColor, -nc              : Disable color output
	ECHO       -?, -h, --help             : Display this syntax help
	ECHO.
	ECHO    Examples:
	ECHO       %~nx0
	ECHO       %~nx0 -List
	ECHO       %~nx0 -Search "KB500"
	ECHO       %~nx0 -Analyze
	ECHO       %~nx0 -Clean
	ECHO       %~nx0 -Clean -ResetBase
	ECHO.
	ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	ECHO Contact: foolycooly1764@gmail.com
	ECHO.
	SET "EXIT_CODE=0"

:END
	CALL "%SCRIPT_DIR%..\lib\bat\isDoubleClick.cmd" "%SCRIPT_NAME%"
	IF %ERRORLEVEL% EQU 0 (
		ECHO.
		PAUSE
	)
	ENDLOCAL & EXIT /B %EXIT_CODE%
