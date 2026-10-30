@ECHO OFF
REM ==================================================================
REM Sanity test for isFile.cmd (ERRORLEVEL contract)
REM Tests: File (0), folder (1), non-existent (2), missing path (2)
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
REM Test 1: Existing file must exit 0
REM ------------------------------------------------------------------
	IF NOT EXIST "%SystemRoot%\System32\cmd.exe" (
		ECHO FAIL: cmd.exe missing, cannot test. & GOTO :EOF
	)

	CALL "%~dp0..\bat\isFile.cmd" "%SystemRoot%\System32\cmd.exe" > NUL
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: File detected as 0
	) ELSE (
		ECHO FAIL: File misdetected (got %ERRORLEVEL%)
	)

REM ------------------------------------------------------------------
REM Test 2: Existing folder must exit 1
REM ------------------------------------------------------------------
	IF NOT EXIST "%SystemRoot%\System32" (
		ECHO FAIL: System32 missing, cannot test. & GOTO :EOF
	)

	CALL "%~dp0..\bat\isFile.cmd" "%SystemRoot%\System32" > NUL
	IF %ERRORLEVEL% EQU 1 (
		ECHO PASS: Folder detected as 1
	) ELSE (
		ECHO FAIL: Folder misdetected (got %ERRORLEVEL%)
	)

REM ------------------------------------------------------------------
REM Test 3: Non-existent path must exit 2
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\isFile.cmd" "%SystemRoot%\NoSuchPath12345" > NUL
	IF %ERRORLEVEL% EQU 2 (
		ECHO PASS: Non-existent path handled as 2
	) ELSE (
		ECHO FAIL: Non-existent path not handled (got %ERRORLEVEL%)
	)

REM ------------------------------------------------------------------
REM Test 4: Missing path parameter must exit 2
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\isFile.cmd" "" > NUL
	IF %ERRORLEVEL% EQU 2 (
		ECHO PASS: Missing path handled as 2
	) ELSE (
		ECHO FAIL: Missing path not handled (got %ERRORLEVEL%)
	)

ENDLOCAL & PAUSE
