@ECHO OFF
REM ==================================================================
REM Retrieves version number ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar]
REM Notes:	For Windows XP SP3 / Server 2003 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS. & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: No Output Variable Given. & GOTO :EOF )
	SET "RETURN="
	FOR /F "tokens=4,5 delims=[]. " %%A IN ('VER') DO SET "RETURN=%%A.%%B"
	IF "%RETURN%"=="" ( ECHO Error: Could not read version. & GOTO :EOF )
ENDLOCAL & SET "%~1=%RETURN%"