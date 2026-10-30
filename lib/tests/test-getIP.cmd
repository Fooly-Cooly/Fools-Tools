@ECHO OFF
REM ==================================================================
REM Sanity test for getIP.cmd
REM Tests: InternalIPv4, ExternalIPv4, stdout mode, invalid type handling
REM Syntax:	%~nx0
REM Notes:	For Windows XP and later (requires PowerShell 2.0+)
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "HELPER=%~dp0..\bat\getIP.cmd"

REM ------------------------------------------------------------------
REM Test 1: InternalIPv4 query (default)
REM ------------------------------------------------------------------
	SET "TEST_LOCAL="
	CALL "%HELPER%" TEST_LOCAL InternalIPv4
	IF NOT "%TEST_LOCAL%"=="" (
		ECHO PASS: Retrieved internal IPv4 [%TEST_LOCAL%]
	) ELSE (
		ECHO FAIL: Failed to retrieve internal IPv4
	)

REM ------------------------------------------------------------------
REM Test 2: ExternalIPv4 query
REM ------------------------------------------------------------------
	SET "TEST_EXT="
	CALL "%HELPER%" TEST_EXT ExternalIPv4
	IF NOT "%TEST_EXT%"=="" (
		ECHO PASS: Retrieved external IPv4 [%TEST_EXT%]
	) ELSE (
		ECHO FAIL: Failed to retrieve external IPv4
	)

REM ------------------------------------------------------------------
REM Test 3: Direct stdout mode (no OutputVar)
REM ------------------------------------------------------------------
	SET "STDOUT_RES="
	FOR /F "usebackq delims=" %%A IN (`CALL "%HELPER%" "" InternalIPv4`) DO (
		IF NOT DEFINED STDOUT_RES SET "STDOUT_RES=%%A"
	)
	IF NOT "%STDOUT_RES%"=="" (
		ECHO PASS: Direct stdout query returned [%STDOUT_RES%]
	) ELSE (
		ECHO FAIL: Direct stdout query returned empty
	)

REM ------------------------------------------------------------------
REM Test 4: Invalid type parameter handling
REM ------------------------------------------------------------------
	SET "INVALID_RES=UNTOUCHED"
	CALL "%HELPER%" INVALID_RES "NoSuchType123" > NUL 2>&1
	IF "%INVALID_RES%"=="UNTOUCHED" (
		ECHO PASS: Invalid type handled gracefully
	) ELSE (
		ECHO FAIL: Invalid type modified target variable
	)

ENDLOCAL & PAUSE
