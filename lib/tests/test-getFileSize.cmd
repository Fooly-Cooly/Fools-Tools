@ECHO OFF
REM ==================================================================
REM Sanity test for getFileSize.cmd
REM Tests: Directory target, non-existent file, valid file size check
REM Syntax:	%~nx0
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	REM Setup temporary test file
	SET "TEST_FILE=%TEMP%\filesize_test_%RANDOM%.txt"
	ECHO 1234567890> "%TEST_FILE%"
	FOR %%A IN ("%TEST_FILE%") DO SET "EXPECTED_SIZE=%%~zA"

REM ------------------------------------------------------------------
REM Test 1: Target is a directory instead of a file
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileSize.cmd" "FILE_SIZE" "%TEMP%" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Directory target handled gracefully
	) ELSE (
		ECHO FAIL: Directory target caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Target file does not exist
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileSize.cmd" "FILE_SIZE" "%TEMP%\nonexistent_%RANDOM%.txt" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Non-existent file handled gracefully
	) ELSE (
		ECHO FAIL: Non-existent file caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 3: Valid file size check
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getFileSize.cmd" "FILE_SIZE" "%TEST_FILE%"
	IF "%FILE_SIZE%"=="%EXPECTED_SIZE%" (
		ECHO PASS: File size correctly detected as %FILE_SIZE% bytes
	) ELSE (
		ECHO FAIL: Expected %EXPECTED_SIZE% bytes, got "%FILE_SIZE%"
	)

	REM Cleanup
	IF EXIST "%TEST_FILE%" DEL /F /Q "%TEST_FILE%"

ENDLOCAL & PAUSE