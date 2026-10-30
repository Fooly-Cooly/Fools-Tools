@ECHO OFF
REM ==================================================================
REM Sanity test for isDoubleClick.cmd (ERRORLEVEL contract)
REM Tests: Double-click detection (0: double-click | 1: terminal | 2: error)
REM Syntax:	%~nx0
REM Notes:	For Windows XP and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "HELPER=%~dp0..\bat\isDoubleClick.cmd"

REM ------------------------------------------------------------------
REM Test 1: Double-click simulation (Explorer environment)
REM When invoked via transient cmd /c with script name outside PowerShell, it must exit 0 [Double-Click]
REM ------------------------------------------------------------------
	SETLOCAL
	SET "PSModulePath=%ProgramFiles%\WindowsPowerShell\Modules;%SystemRoot%\system32\WindowsPowerShell\v1.0\Modules"
	cmd.exe /c call "%HELPER%" isDoubleClick.cmd
	SET "CODE=%ERRORLEVEL%"
	ENDLOCAL & SET "RESULT_DC=%CODE%"

	IF "%RESULT_DC%"=="0" (
		ECHO PASS: Transient cmd /c execution detected as 0 [Double-Click]
	) ELSE (
		ECHO FAIL: Transient cmd /c misdetected [got %RESULT_DC%]
	)

REM ------------------------------------------------------------------
REM Test 2: Unmatched script name
REM When script name is not in cmdcmdline, it must exit 1 [Terminal]
REM ------------------------------------------------------------------
	CALL "%HELPER%" "nonexistent-script-xyz123.cmd"
	SET "RESULT_UNMATCHED=%ERRORLEVEL%"

	IF "%RESULT_UNMATCHED%"=="1" (
		ECHO PASS: Unmatched script name detected as 1 [Terminal]
	) ELSE (
		ECHO FAIL: Unmatched script name misdetected [got %RESULT_UNMATCHED%]
	)

REM ------------------------------------------------------------------
REM Test 3: PowerShell 7 override
REM Under PowerShell 7, it must exit 1 [Terminal] even when cmd /c is used
REM ------------------------------------------------------------------
	WHERE pwsh.exe > NUL 2>&1
	IF NOT %ERRORLEVEL% EQU 0 GOTO :SKIP_PWSH

	pwsh.exe -NoProfile -Command "cmd.exe /c \"`\"%HELPER%`\" isDoubleClick.cmd\"; exit $LASTEXITCODE"
	SET "RESULT_PWSH=%ERRORLEVEL%"

	IF "%RESULT_PWSH%"=="1" (
		ECHO PASS: PowerShell 7 session detected as 1 [Terminal]
	) ELSE (
		ECHO FAIL: PowerShell 7 session misdetected [got %RESULT_PWSH%]
	)
	GOTO :DONE_PWSH

:SKIP_PWSH
	ECHO SKIP: PowerShell 7 not installed, skipping pwsh test.

:DONE_PWSH

REM ------------------------------------------------------------------
REM Test 4: Windows PowerShell override
REM Under Windows PowerShell, it must exit 1 [Terminal] even when cmd /c is used
REM ------------------------------------------------------------------
	WHERE powershell.exe > NUL 2>&1
	IF NOT %ERRORLEVEL% EQU 0 GOTO :SKIP_PS51

	powershell.exe -NoProfile -Command "cmd.exe /c \"`\"%HELPER%`\" isDoubleClick.cmd\"; exit $LASTEXITCODE"
	SET "RESULT_PS51=%ERRORLEVEL%"

	IF "%RESULT_PS51%"=="1" (
		ECHO PASS: Windows PowerShell session detected as 1 [Terminal]
	) ELSE (
		ECHO FAIL: Windows PowerShell session misdetected [got %RESULT_PS51%]
	)
	GOTO :DONE_PS51

:SKIP_PS51
	ECHO SKIP: Windows PowerShell not installed, skipping powershell test.

:DONE_PS51

ENDLOCAL & PAUSE
