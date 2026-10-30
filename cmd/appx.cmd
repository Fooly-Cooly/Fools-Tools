@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Universal Windows Platform (UWP) & AppX Package Manager
	REM Syntax: appx [Options]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "ENGINE_PS1=%SCRIPT_DIR%..\lib\ps1\Manage-Appx.ps1"
	SET "EXIT_CODE=0"

	IF NOT EXIST "%ENGINE_PS1%" (
		ECHO [ERROR] Manage-Appx.ps1 not found at "%ENGINE_PS1%".
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

	REM Check Windows Version (Requires Windows 8 / Server 2012 or newer)
	IF NOT EXIST "%SCRIPT_DIR%..\lib\bat\getOSVer.cmd" GOTO :SKIP_OS_CHECK
	CALL "%SCRIPT_DIR%..\lib\bat\getOSVer.cmd" OS_VER
	IF NOT DEFINED OS_VER GOTO :SKIP_OS_CHECK
	FOR /F "tokens=1,2 delims=." %%A IN ("%OS_VER%") DO (
		IF %%A LSS 6 GOTO :OS_UNSUPPORTED
		IF %%A EQU 6 IF %%B LSS 2 GOTO :OS_UNSUPPORTED
	)
	GOTO :SKIP_OS_CHECK

:OS_UNSUPPORTED
	ECHO [ERROR] UWP/AppX packages require Windows 8 or later. Current OS: %OS_VER%
	SET "EXIT_CODE=1"
	GOTO :END

:SKIP_OS_CHECK

	REM Forward CLI arguments or launch interactive menu if no arguments given
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" %*
	SET "EXIT_CODE=%ERRORLEVEL%"
	GOTO :END

:SYNTAX
	ECHO.
	ECHO Syntax: %~nx0 [Options]
	ECHO.
	ECHO    Manages and uninstalls Universal Windows Platform (UWP) and AppX packages.
	ECHO    Invoking without parameters opens an interactive package selection menu.
	ECHO.
	ECHO    Options / Flags:
	ECHO       -List, -l, /L              : List installed removable UWP packages
	ECHO       -Search, -s, /S ^<pattern^>  : Search packages by keyword or wildcard
	ECHO       -Remove, -r, /R ^<pattern^>  : Remove matching packages non-interactively
	ECHO       -AllUsers, -a, /A          : Remove for all users and de-provision (Requires Admin)
	ECHO       -IncludeSystem             : Include system and framework packages in list
	ECHO       -NoColor, -nc              : Disable color output
	ECHO       -?, -h, --help             : Display this syntax help
	ECHO.
	ECHO    Examples:
	ECHO       %~nx0
	ECHO       %~nx0 -List
	ECHO       %~nx0 -Search "Xbox"
	ECHO       %~nx0 -Remove "*BingWeather*"
	ECHO       %~nx0 -Remove "*Zune*" -AllUsers
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
