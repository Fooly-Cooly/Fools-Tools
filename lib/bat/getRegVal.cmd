@ECHO OFF
REM ==================================================================
REM Retrieves registry value ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar] [KeyName] [ValueName]
REM Notes:	For Windows XP SP3 / Server 2003 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS. & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: No Output Variable Given. & GOTO :EOF )
	IF "%~2"=="" ( ECHO Error: No Key Name Given. & GOTO :EOF )

	SET "RETURN="
	SET "FOUND=0"
	REM A ValueName may contain spaces; the inner quotes become part of REG_OPTION.
	IF "%~3"=="" ( SET "REG_OPTION=/ve" ) ELSE ( SET "REG_OPTION=/v "%~3"" )

	REG QUERY "%~2" %REG_OPTION% > NUL 2>&1
	IF ERRORLEVEL 1 ( ECHO Error: Registry value could not be read. & GOTO :EOF )
	FOR /F "tokens=2,* eol=?" %%A IN ('REG QUERY "%~2" %REG_OPTION%') DO (
		SET "RETURN=%%B"
		SET "FOUND=1"
	)
	IF "%FOUND%"=="0" ( ECHO Error: Registry value could not be parsed. & GOTO :EOF )
ENDLOCAL & SET "%~1=%RETURN%"