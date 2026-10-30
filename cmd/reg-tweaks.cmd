@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Windows System Registry Tweaks & Shell Extension Manager
	REM Syntax: reg-tweaks [Options]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "ENGINE_PS1=%SCRIPT_DIR%..\lib\ps1\Manage-RegistryTweaks.ps1"
	SET "EXIT_CODE=0"

	IF NOT EXIST "%ENGINE_PS1%" (
		ECHO [ERROR] Manage-RegistryTweaks.ps1 not found at "%ENGINE_PS1%".
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

	REM Allow read-only query operations without elevation
	IF /I "%~1"=="-List" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="--List" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="-l" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="/l" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="-Status" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="--Status" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="-s" GOTO :SKIP_ADMIN_CHECK
	IF /I "%~1"=="/s" GOTO :SKIP_ADMIN_CHECK

	REM Administrator Privilege Check for Modifications and Interactive Menu
	IF NOT EXIST "%SCRIPT_DIR%..\lib\bat\isAdmin.cmd" GOTO :SKIP_ADMIN_CHECK
	CALL "%SCRIPT_DIR%..\lib\bat\isAdmin.cmd"
	IF %ERRORLEVEL% NEQ 0 (
		ECHO [ERROR] System registry tweaks require Administrator privileges.
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
	ECHO    Applies, removes, and manages curated Windows registry tweaks,
	ECHO    shell context menu extensions, and OS privacy/usability settings.
	ECHO    Invoking without parameters opens an interactive selection menu.
	ECHO    (Note: Requires Administrator privileges).
	ECHO.
	ECHO    Options / Flags:
	ECHO       -List, -l, /L              : List all available tweaks and current status
	ECHO       -Apply, -a ^<ID^|pattern^>   : Apply specified tweak(s) non-interactively
	ECHO       -Remove, -r ^<ID^|pattern^>  : Remove specified tweak(s) non-interactively
	ECHO       -Status, -s ^<ID^|pattern^>  : Check status of specified tweak(s)
	ECHO       -RestartExplorer           : Restart Windows Explorer to apply changes immediately
	ECHO       -NoColor, -nc              : Disable color output
	ECHO       -?, -h, --help             : Display this syntax help
	ECHO.
	ECHO    Examples:
	ECHO       %~nx0
	ECHO       %~nx0 -List
	ECHO       %~nx0 -Apply Disable_Cortana
	ECHO       %~nx0 -Apply "*Notepad*"
	ECHO       %~nx0 -Remove Take_Ownership_Context_Menu
	ECHO       %~nx0 -Status "*Menu*"
	ECHO       %~nx0 -RestartExplorer
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
