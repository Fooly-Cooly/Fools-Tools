@ECHO OFF
REM ==================================================================
REM Checks for Administrator permissions ^& sets ERRORLEVEL ( 0: admin | 1: standard | 2: error )
REM Syntax:	%~nx0
REM Notes:	For Windows Vista and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & EXIT /b 2 )
	NET FILE > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 ( ENDLOCAL & EXIT /b 0 )
ENDLOCAL & EXIT /b 1
