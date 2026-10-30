@ECHO OFF
REM ==================================================================
REM Retrieves folder file count ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar] [Folder]
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS. & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: Missing OutputVar parameter. & GOTO :EOF )
	IF "%~2"=="" ( ECHO Error: Missing target folder parameter. & GOTO :EOF )
	IF NOT EXIST "%~2" ( ECHO Error: Target "%~2" does not exist. & GOTO :EOF )
	IF NOT EXIST "%~2\*" ( ECHO Error: Target "%~2" is not a directory. & GOTO :EOF )

	SET "RETURN=0"
	FOR /F "eol=? delims=" %%A IN ('2^>NUL DIR "%~2" /A-D-S-H /B') DO SET /A "RETURN+=1"
ENDLOCAL & SET "%~1=%RETURN%"