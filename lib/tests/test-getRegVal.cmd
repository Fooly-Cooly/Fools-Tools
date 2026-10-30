@ECHO OFF
REM ==================================================================
REM Sanity test for getRegVal.cmd
REM Tests: Missing parameter, named value, default value, non-existent value
REM Syntax:	%~nx0
REM Notes:	For Windows XP SP3 / Server 2003 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions EnableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

REM ------------------------------------------------------------------
REM Test 1: Missing parameter handling
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getRegVal.cmd" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameter handled gracefully
	) ELSE (
		ECHO FAIL: Missing parameter caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Standard named registry value retrieval
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getRegVal.cmd" "REG_VAL" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion" "ProgramFilesDir"
	IF DEFINED REG_VAL (
		ECHO PASS: Retrieved ProgramFilesDir: [!REG_VAL!]
	) ELSE (
		ECHO FAIL: Failed to retrieve ProgramFilesDir
	)

REM ------------------------------------------------------------------
REM Test 3: Default registry value retrieval (/ve)
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getRegVal.cmd" "REG_VAL_DEF" "HKCR\.bat"
	IF DEFINED REG_VAL_DEF (
		ECHO PASS: Retrieved default value for HKCR\.bat: [!REG_VAL_DEF!]
	) ELSE (
		ECHO FAIL: Failed to retrieve default value for HKCR\.bat
	)

REM ------------------------------------------------------------------
REM Test 4: Non-existent registry value handling
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getRegVal.cmd" "REG_VAL_NON" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion" "NonExistent_%RANDOM%" > NUL 2>&1
	IF NOT DEFINED REG_VAL_NON (
		ECHO PASS: Non-existent value handled correctly
	) ELSE (
		ECHO FAIL: Non-existent value was unexpectedly defined
	)

ENDLOCAL & PAUSE
