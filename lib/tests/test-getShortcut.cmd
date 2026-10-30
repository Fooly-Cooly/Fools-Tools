@ECHO OFF
REM ==================================================================
REM Sanity test for getShortcut.cmd
REM Tests: Missing parameter, non-existent target, valid shortcut retrieval
REM Syntax:	%~nx0
REM Notes:	For Windows 2000 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	REM Setup temporary test shortcut
	SET "TEST_LNK=%TEMP%\test_shortcut_%RANDOM%.lnk"
	powershell -NoProfile -ExecutionPolicy Bypass -Command "$ws=New-Object -ComObject WScript.Shell;$s=$ws.CreateShortcut($env:TEST_LNK);$s.TargetPath=\"$env:SystemRoot\System32\notepad.exe\";$s.Save()" > NUL 2>&1

REM ------------------------------------------------------------------
REM Test 1: Missing parameter handling
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getShortcut.cmd" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Missing parameter handled gracefully
	) ELSE (
		ECHO FAIL: Missing parameter caused unexpected exit code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 2: Non-existent shortcut target handling
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getShortcut.cmd" "SC_NON" "%TEMP%\nonexistent_%RANDOM%.lnk" > NUL 2>&1
	IF NOT DEFINED SC_NON (
		ECHO PASS: Non-existent shortcut handled gracefully
	) ELSE (
		ECHO FAIL: Non-existent shortcut was unexpectedly defined
	)

REM ------------------------------------------------------------------
REM Test 3: Standard shortcut target retrieval
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getShortcut.cmd" "SC_TARGET" "%TEST_LNK%"
	IF /I "%SC_TARGET%"=="%SystemRoot%\System32\notepad.exe" (
		ECHO PASS: Resolved shortcut target correctly: [%SC_TARGET%]
	) ELSE (
		ECHO FAIL: Expected [%SystemRoot%\System32\notepad.exe], got [%SC_TARGET%]
	)

	REM Cleanup
	IF EXIST "%TEST_LNK%" DEL /F /Q "%TEST_LNK%"

ENDLOCAL & PAUSE
