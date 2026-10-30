@ECHO OFF
REM ==================================================================
REM Retrieves size in bytes of file ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar] [File]
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS. & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: Missing OutputVar parameter. & GOTO :EOF )
	IF "%~2"=="" ( ECHO Error: Missing target file parameter. & GOTO :EOF )
	IF NOT EXIST "%~2" ( ECHO Error: Target "%~2" does not exist. & GOTO :EOF )
	IF EXIST "%~2\*" ( ECHO Error: Target "%~2" is a directory, not a file. & GOTO :EOF )

	FOR %%A IN ("%~2") DO SET "RETURN=%%~zA"
ENDLOCAL & SET "%~1=%RETURN%"