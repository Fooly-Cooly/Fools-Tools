@ECHO OFF
REM ==================================================================
REM Checks if target is a file ^& sets ERRORLEVEL ( 0: file | 1: folder | 2: error )
REM Syntax:	%~nx0 [Path]
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & EXIT /b 2 )
	IF "%~1"=="" ( ECHO Error: Missing path parameter. & EXIT /b 2 )
	IF NOT EXIST "%~1" ( ECHO Error: Target "%~1" does not exist. & EXIT /b 2 )
	IF NOT EXIST "%~1\*" ( ENDLOCAL & EXIT /b 0 )
ENDLOCAL & EXIT /b 1
