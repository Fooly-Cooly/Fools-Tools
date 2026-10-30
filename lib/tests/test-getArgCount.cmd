@ECHO OFF
REM ==================================================================
REM Sanity test for getArgCount.cmd
REM Tests: Missing parameter, zero arguments, multiple arguments
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
	CALL "%~dp0..\bat\getArgCount.cmd" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameter handled gracefully
	) ELSE (
		ECHO FAIL: Missing parameter caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Passing zero additional arguments
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getArgCount.cmd" "ARG_CNT"
	IF "%ARG_CNT%"=="0" (
		ECHO PASS: Zero additional arguments counted as 0
	) ELSE (
		ECHO FAIL: Expected 0 arguments, got "%ARG_CNT%"
	)

REM ------------------------------------------------------------------
REM Test 3: Passing 4 additional arguments
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getArgCount.cmd" "ARG_CNT" "apple" "banana" "cherry" "date"
	IF "%ARG_CNT%"=="4" (
		ECHO PASS: 4 additional arguments counted as 4
	) ELSE (
		ECHO FAIL: Expected 4 arguments, got "%ARG_CNT%"
	)

ENDLOCAL & PAUSE