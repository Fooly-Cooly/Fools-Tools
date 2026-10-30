@ECHO OFF
REM ==================================================================
REM Sanity test for archive.cmd
REM Tests: Syntax display, invalid extension, invalid switch,
REM        and functional archive creation
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
REM Test 1: Missing parameters must display syntax
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\archive.cmd" < NUL
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameters displayed syntax
	) ELSE (
		ECHO FAIL: archive.cmd failed on syntax display
	)

REM ------------------------------------------------------------------
REM Test 2: Unsupported extension must be rejected
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\archive.cmd" "invalid_ext" AFIS /AAA < NUL > NUL 2>&1
	IF %ERRORLEVEL% NEQ 0 (
		ECHO PASS: Unsupported extension rejected
	) ELSE (
		ECHO FAIL: Unsupported extension was unexpectedly accepted
	)

REM ------------------------------------------------------------------
REM Test 3: Invalid switch must display syntax
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\archive.cmd" "zip" AFIS /XYZ < NUL
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Invalid switch displayed syntax
	) ELSE (
		ECHO FAIL: Invalid switch test failed
	)

REM ------------------------------------------------------------------
REM Test 4: Functional archive creation (ZIP)
REM ------------------------------------------------------------------
	SET "TEST_DIR=%TEMP%\archive_test_%RANDOM%"
	IF EXIST "%TEST_DIR%" RMDIR /S /Q "%TEST_DIR%"
	MKDIR "%TEST_DIR%"
	ECHO Hello World > "%TEST_DIR%\testfile.txt"

	SET "ORIG_DIR=%CD%"
	CD /D "%TEST_DIR%"
	CALL "%~dp0..\bat\archive.cmd" zip AFIS /IAS < NUL > NUL 2>&1
	CD /D "%ORIG_DIR%"

	IF EXIST "%TEST_DIR%\testfile.zip" (
		ECHO PASS: Archive created successfully
	) ELSE (
		ECHO FAIL: Archive testfile.zip was not created
	)

	IF EXIST "%TEST_DIR%" RMDIR /S /Q "%TEST_DIR%"

ENDLOCAL & PAUSE
