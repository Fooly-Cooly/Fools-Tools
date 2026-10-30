@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM System Clean-Up & Maintenance (Temp, Empty Folders, Icon Cache)
	REM Syntax: clean-up [[Options] Target]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "ENGINE_PS1=%SCRIPT_DIR%..\lib\ps1\Clean-System.ps1"
	SET "EXIT_CODE=0"

	IF NOT EXIST "%ENGINE_PS1%" (
		ECHO Error: Clean-System.ps1 not found at "%ENGINE_PS1%".
		EXIT /B 1
	)

	REM Interactive menu mode when launched without parameters
	IF "%~1"=="" GOTO :MENU

	REM Help routing
	IF /I "%~1"=="/?" GOTO :SYNTAX
	IF /I "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/h" GOTO :SYNTAX
	IF /I "%~1"=="-h" GOTO :SYNTAX
	IF /I "%~1"=="/help" GOTO :SYNTAX
	IF /I "%~1"=="--help" GOTO :SYNTAX

	REM Forward CLI arguments directly to the PowerShell engine
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" %*
	SET "EXIT_CODE=%ERRORLEVEL%"
	GOTO :END

	:MENU
		CLS
		ECHO ============================================================
		ECHO              Fool's Tools - System Clean-Up
		ECHO ============================================================
		ECHO.
		ECHO   [1] Clean Temporary Files (User %%TEMP%% ^& System Temp)
		ECHO   [2] Clean Empty Files ^& Folders (Current Directory)
		ECHO   [3] Rebuild Windows Icon ^& Thumbnail Cache
		ECHO   [4] Run All Clean-Up Tasks
		ECHO   [Q] Quit / Exit
		ECHO.
		ECHO ============================================================
		ECHO.

		REM Check for CHOICE command (available on Vista/7/8/10/11)
		WHERE choice.exe >NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			CHOICE /C 1234Q /N /M "Select an option [1-4, Q]: "
			IF ERRORLEVEL 5 GOTO :MENU_QUIT
			IF ERRORLEVEL 4 GOTO :MENU_ALL
			IF ERRORLEVEL 3 GOTO :MENU_ICON
			IF ERRORLEVEL 2 GOTO :MENU_EMPTY
			IF ERRORLEVEL 1 GOTO :MENU_TEMP
		)

		REM Windows XP fallback via SET /P
		SET "MENU_OPT="
		SET /P "MENU_OPT=Select an option [1-4, Q]: "
		IF /I "%MENU_OPT%"=="1" GOTO :MENU_TEMP
		IF /I "%MENU_OPT%"=="2" GOTO :MENU_EMPTY
		IF /I "%MENU_OPT%"=="3" GOTO :MENU_ICON
		IF /I "%MENU_OPT%"=="4" GOTO :MENU_ALL
		IF /I "%MENU_OPT%"=="Q" GOTO :MENU_QUIT
		GOTO :MENU

		:MENU_TEMP
			powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" -Temp
			SET "EXIT_CODE=%ERRORLEVEL%"
			GOTO :END

		:MENU_EMPTY
			powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" -Empty
			SET "EXIT_CODE=%ERRORLEVEL%"
			GOTO :END

		:MENU_ICON
			powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" -IconCache
			SET "EXIT_CODE=%ERRORLEVEL%"
			GOTO :END

		:MENU_ALL
			powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" -All
			SET "EXIT_CODE=%ERRORLEVEL%"
			GOTO :END

		:MENU_QUIT
			SET "EXIT_CODE=0"
			GOTO :END

	:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [Options]
		ECHO.
		ECHO    Performs system disk maintenance, safe temporary file purging,
		ECHO    empty file/folder pruning, and Windows icon cache rebuilding.
		ECHO    Invoking without parameters opens an interactive menu.
		ECHO.
		ECHO    Options / Flags:
		ECHO       /T, -t, --temp             : Clean user (%%TEMP%%) ^& system temp files
		ECHO       /C, -c, --empty [Path]     : Clean 0-byte files ^& empty folders (default: CD)
		ECHO       /I, -i, --icon             : Rebuild Windows icon ^& thumbnail cache
		ECHO       /A, -a, --all              : Execute all clean-up routines
		ECHO       -DaysOld ^<N^>               : Preserve temp files newer than N days (default: 0)
		ECHO       -nc, --no-color            : Disable console color formatting
		ECHO       -?, -h, --help             : Display this syntax help
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0
		ECHO       %~nx0 /T
		ECHO       %~nx0 /C "D:\Media"
		ECHO       %~nx0 /I
		ECHO       %~nx0 /A
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
