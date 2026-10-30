@ECHO OFF
REM ==================================================================
REM Sanity test for getSID.cmd
REM Tests: Missing parameter, resolving SID for current user and target user
REM Syntax:	%~nx0 [UserName]
REM Notes:	Compatible with Windows XP through Windows 11
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
	CALL "%~dp0..\bat\getSID.cmd" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameter handled gracefully
	) ELSE (
		ECHO FAIL: Missing parameter caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Current logged-in user SID retrieval
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getSID.cmd" "TEST_SID_1" "%USERNAME%"
	IF DEFINED TEST_SID_1 (
		ECHO PASS: Resolved SID for %USERNAME%: %TEST_SID_1%
	) ELSE (
		ECHO FAIL: Failed to retrieve SID for %USERNAME%
	)

REM ------------------------------------------------------------------
REM Test 3: Custom / explicit target user SID retrieval
REM ------------------------------------------------------------------
	SET "TARGET_USER=%~1"
	IF NOT DEFINED TARGET_USER SET "TARGET_USER=%USERNAME%"

	CALL "%~dp0..\bat\getSID.cmd" "TEST_SID_2" "%TARGET_USER%"
	IF DEFINED TEST_SID_2 (
		ECHO PASS: Resolved SID for %TARGET_USER%: %TEST_SID_2%
	) ELSE (
		ECHO FAIL: Could not resolve SID for %TARGET_USER%
	)

ENDLOCAL & PAUSE