@ECHO OFF
REM ==================================================================
REM Sanity test for reg-tweaks.cmd & Manage-RegistryTweaks.ps1
REM Tests: Syntax help, list tweaks, query status, pattern matching,
REM and graceful handling of unknown tweak IDs.
REM Syntax:	%~nx0
REM Notes:	For Windows 7 and later (requires PowerShell 5.1+)
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "SCRIPT_DIR=%~dp0"
	SET "TOOL_CMD=%SCRIPT_DIR%..\..\cmd\reg-tweaks.cmd"
	SET "SANDBOX=%TEMP%\reg_tweaks_test_%RANDOM%"

	IF NOT EXIST "%TOOL_CMD%" (
		ECHO FAIL: Tool not found at "%TOOL_CMD%"
		GOTO :END
	)

	MD "%SANDBOX%" 2>NUL

REM ------------------------------------------------------------------
REM Test 1: Syntax / Help Output
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" -? > "%SANDBOX%\help.txt" 2>&1
	IF %ERRORLEVEL% EQU 0 (
		FINDSTR /I /C:"Syntax: reg-tweaks" "%SANDBOX%\help.txt" > NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			ECHO PASS: Syntax help displayed correctly
		) ELSE (
			ECHO FAIL: Syntax help text missing expected header
		)
	) ELSE (
		ECHO FAIL: Tool returned error code %ERRORLEVEL% on -?
	)

REM ------------------------------------------------------------------
REM Test 2: List Tweaks (-List -nc)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" -List -nc > "%SANDBOX%\list.txt" 2>&1
	IF %ERRORLEVEL% EQU 0 (
		FINDSTR /I /C:"Disable_Cortana" "%SANDBOX%\list.txt" > NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			ECHO PASS: List command successfully enumerated tweaks manifest
		) ELSE (
			ECHO FAIL: List command output missing expected tweak IDs
		)
	) ELSE (
		ECHO FAIL: List command returned error code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 3: Status Query for Single Known Tweak (-Status Disable_Cortana -nc)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" -Status Disable_Cortana -nc > "%SANDBOX%\status.txt" 2>&1
	IF %ERRORLEVEL% EQU 0 (
		FINDSTR /I /C:"Disable_Cortana" "%SANDBOX%\status.txt" > NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			ECHO PASS: Status query successfully reported tweak state
		) ELSE (
			ECHO FAIL: Status query missing tweak information
		)
	) ELSE (
		ECHO FAIL: Status query returned error code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 4: Status Query with Wildcard Pattern (-Status "*Notepad*" -nc)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" -Status "*Notepad*" -nc > "%SANDBOX%\pattern.txt" 2>&1
	IF %ERRORLEVEL% EQU 0 (
		FINDSTR /I /C:"Notepad" "%SANDBOX%\pattern.txt" > NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			ECHO PASS: Wildcard pattern matching resolved multiple tweaks
		) ELSE (
			ECHO FAIL: Wildcard pattern did not match expected tweaks
		)
	) ELSE (
		ECHO FAIL: Wildcard status query returned error code %ERRORLEVEL%
	)

REM ------------------------------------------------------------------
REM Test 5: Graceful Handling of Unknown Tweak ID
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" -Status NonExistent_Tweak_XYZ -nc > "%SANDBOX%\unknown.txt" 2>&1
	FINDSTR /I /C:"No tweaks found" "%SANDBOX%\unknown.txt" > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		ECHO PASS: Unknown tweak ID handled gracefully
	) ELSE (
		ECHO FAIL: Unknown tweak ID did not return expected user message
	)

:END
	IF EXIST "%SANDBOX%" RD /S /Q "%SANDBOX%" > NUL 2>&1
	CALL "%SCRIPT_DIR%..\bat\isDoubleClick.cmd" "%~nx0"
	IF %ERRORLEVEL% EQU 0 (
		ECHO.
		PAUSE
	)
	ENDLOCAL & EXIT /B 0
