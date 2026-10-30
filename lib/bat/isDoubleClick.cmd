@ECHO OFF
REM ==================================================================
REM Checks if launched via double-click ^& sets ERRORLEVEL ( 0: double-click | 1: terminal | 2: error )
REM Syntax:	%~nx0 [ScriptName]
REM Notes:	For Windows XP and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & EXIT /b 2 )

	SET "SCRIPT_NAME=%~1"
	SET "IS_DC=0"

	IF "%SCRIPT_NAME%"=="" GOTO :NO_SCRIPT_NAME
	SET "CLEAN_CMD=%CMDCMDLINE:"= % "
	ECHO %CLEAN_CMD% | FINDSTR /I /C:"\%SCRIPT_NAME% " /C:" %SCRIPT_NAME% " >NUL && SET "IS_DC=1"
	GOTO :CHECK_PS

:NO_SCRIPT_NAME
	ECHO %CMDCMDLINE% | FINDSTR /I /C:" /c " >NUL && SET "IS_DC=1"

:CHECK_PS

	REM Skip if running inside PowerShell (PowerShell 7+ or Windows PowerShell)
	ECHO %PSModulePath% | FINDSTR /I /C:"\PowerShell\Modules" >NUL && SET "IS_DC=0"
	ECHO %PSModulePath% | FINDSTR /I /C:"Documents\WindowsPowerShell\Modules" >NUL && SET "IS_DC=0"

	IF "%IS_DC%"=="1" ( ENDLOCAL & EXIT /b 0 )
ENDLOCAL & EXIT /b 1
