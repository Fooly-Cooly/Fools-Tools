@ECHO OFF
REM ==================================================================
REM Sanity test for getArch.cmd
REM Tests: Missing parameter, CPU architecture detection
REM Syntax:	%~nx0
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

REM ------------------------------------------------------------------
REM Test 1: Missing parameter handling
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getArch.cmd" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameter handled gracefully
	) ELSE (
		ECHO FAIL: Missing parameter caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Standard CPU architecture retrieval
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getArch.cmd" "CPU_BITNESS"
	IF "%CPU_BITNESS%"=="64" (
		ECHO PASS: Detected 64-bit architecture
	) ELSE IF "%CPU_BITNESS%"=="" (
		ECHO PASS: Detected 32-bit architecture
	) ELSE (
		ECHO FAIL: Unexpected architecture "%CPU_BITNESS%"
	)

ENDLOCAL & PAUSE