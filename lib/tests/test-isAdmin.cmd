@ECHO OFF
REM ==================================================================
REM Sanity test for isAdmin.cmd (ERRORLEVEL contract)
REM Tests: Administrator privilege check (0: admin | 1: standard | 2: error)
REM Syntax:	%~nx0
REM Notes:	For Windows Vista and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

REM ------------------------------------------------------------------
REM Test 1: Administrator privilege check execution
REM ------------------------------------------------------------------
	NET FILE > NUL 2>&1
	SET "IS_ELEVATED=%ERRORLEVEL%"

	CALL "%~dp0..\bat\isAdmin.cmd"
	SET "ACTUAL_LEVEL=%ERRORLEVEL%"

	IF %IS_ELEVATED% EQU 0 (
		IF %ACTUAL_LEVEL% EQU 0 (
			ECHO PASS: Correctly detected as 0 [Administrator]
		) ELSE (
			ECHO FAIL: Elevated session misdetected [got %ACTUAL_LEVEL%]
		)
	) ELSE (
		IF %ACTUAL_LEVEL% EQU 1 (
			ECHO PASS: Correctly detected as 1 [Standard User]
		) ELSE (
			ECHO FAIL: Standard user session misdetected [got %ACTUAL_LEVEL%]
		)
	)

ENDLOCAL & PAUSE
