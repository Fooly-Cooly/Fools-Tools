@ECHO OFF
REM ==================================================================
REM Sanity test for getFileCount.cmd
REM Tests: Missing parameter, non-existent folder, file target, valid count
REM Syntax:	%~nx0
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	REM Setup temporary test directory and files
	SET "TEST_DIR=%TEMP%\file_count_test_%RANDOM%"
	IF EXIST "%TEST_DIR%" RMDIR /S /Q "%TEST_DIR%"
	MKDIR "%TEST_DIR%"
	ECHO dummy > "%TEST_DIR%\file1.txt"
	ECHO dummy > "%TEST_DIR%\file2.txt"
	MKDIR "%TEST_DIR%\subfolder"

REM ------------------------------------------------------------------
REM Test 1: Missing target folder parameter
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileCount.cmd" "FILE_CNT" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing target folder handled gracefully
	) ELSE (
		ECHO FAIL: Missing target folder caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Non-existent folder target
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileCount.cmd" "FILE_CNT" "%TEST_DIR%\nonexistent" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Non-existent folder handled gracefully
	) ELSE (
		ECHO FAIL: Non-existent folder caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 3: Target is a file instead of a directory
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileCount.cmd" "FILE_CNT" "%TEST_DIR%\file1.txt" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: File passed as folder target handled gracefully
	) ELSE (
		ECHO FAIL: File target caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 4: Valid folder target count (files only, ignores subfolders)
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileCount.cmd" "FILE_CNT" "%TEST_DIR%"
	IF "%FILE_CNT%"=="2" (
		ECHO PASS: File count correctly detected as 2
	) ELSE (
		ECHO FAIL: Expected 2 files, detected "%FILE_CNT%"
	)

	REM Cleanup
	IF EXIST "%TEST_DIR%" RMDIR /S /Q "%TEST_DIR%"

ENDLOCAL & PAUSE