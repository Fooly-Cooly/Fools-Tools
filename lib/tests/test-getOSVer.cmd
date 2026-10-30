@ECHO OFF
REM ==================================================================
REM Sanity test for getOSVer.cmd
REM Tests: Missing parameter, Windows version detection
REM Syntax:	%~nx0
REM Notes:	For Windows XP SP3 / Server 2003 and later
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
	CALL "%~dp0..\bat\getOSVer.cmd" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameter handled gracefully
	) ELSE (
		ECHO FAIL: Missing parameter caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Standard Windows version retrieval
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getOSVer.cmd" "WIN_VER"
	IF DEFINED WIN_VER (
		ECHO PASS: Detected Windows Version: %WIN_VER%
	) ELSE (
		ECHO FAIL: Windows version could not be detected
	)

ENDLOCAL & PAUSE