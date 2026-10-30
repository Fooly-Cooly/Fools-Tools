@ECHO OFF
REM ==================================================================
REM Sanity test for extract-icon.cmd & Extract-Icon.ps1
REM Tests: ICO extraction, PNG extraction, dual format, and size splitting
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
	SET "TOOL_CMD=%SCRIPT_DIR%..\..\cmd\extract-icon.cmd"
	SET "SANDBOX=%TEMP%\extract_icon_test_%RANDOM%"

	IF NOT EXIST "%TOOL_CMD%" (
		ECHO FAIL: Tool not found at "%TOOL_CMD%"
		GOTO :END
	)

	REM Find a reliable Windows system binary containing icon resources
	SET "SRC_BIN=%SystemRoot%\System32\cmd.exe"
	IF NOT EXIST "%SRC_BIN%" SET "SRC_BIN=%SystemRoot%\explorer.exe"

	IF NOT EXIST "%SRC_BIN%" (
		ECHO FAIL: Could not locate system binary for icon testing
		GOTO :END
	)

	MD "%SANDBOX%" 2>NUL

REM ------------------------------------------------------------------
REM Test 1: Extract ICO format (Default)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SRC_BIN%" "%SANDBOX%\test1" -Format ICO > NUL 2>&1
	SET "FOUND_ICO="
	FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\test1\*.ico" 2^>NUL`) DO (
		IF NOT DEFINED FOUND_ICO SET "FOUND_ICO=%%F"
	)
	IF NOT "%FOUND_ICO%"=="" (
		ECHO PASS: Extracted ICO icon [%FOUND_ICO%]
	) ELSE (
		ECHO FAIL: ICO extraction failed
	)

REM ------------------------------------------------------------------
REM Test 2: Extract PNG format
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SRC_BIN%" "%SANDBOX%\test2" -Format PNG > NUL 2>&1
	SET "FOUND_PNG="
	FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\test2\*.png" 2^>NUL`) DO (
		IF NOT DEFINED FOUND_PNG SET "FOUND_PNG=%%F"
	)
	IF NOT "%FOUND_PNG%"=="" (
		ECHO PASS: Extracted PNG icon [%FOUND_PNG%]
	) ELSE (
		ECHO FAIL: PNG extraction failed
	)

REM ------------------------------------------------------------------
REM Test 3: Extract Both formats (ICO & PNG)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SRC_BIN%" "%SANDBOX%\test3" -Format Both > NUL 2>&1
	SET "HAS_BOTH_ICO="
	SET "HAS_BOTH_PNG="
	FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\test3\*.ico" 2^>NUL`) DO (
		IF NOT DEFINED HAS_BOTH_ICO SET "HAS_BOTH_ICO=%%F"
	)
	FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\test3\*.png" 2^>NUL`) DO (
		IF NOT DEFINED HAS_BOTH_PNG SET "HAS_BOTH_PNG=%%F"
	)
	IF NOT "%HAS_BOTH_ICO%"=="" IF NOT "%HAS_BOTH_PNG%"=="" (
		ECHO PASS: Extracted both ICO ^& PNG formats
	) ELSE (
		ECHO FAIL: Dual format extraction failed
	)

REM ------------------------------------------------------------------
REM Test 4: Split Icon Sizes
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SRC_BIN%" "%SANDBOX%\test4" -Format PNG -SplitSizes > NUL 2>&1
	SET "SPLIT_COUNT=0"
	FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\test4\*.png" 2^>NUL`) DO (
		SET /A SPLIT_COUNT+=1
	)
	IF %SPLIT_COUNT% GTR 0 (
		ECHO PASS: Extracted %SPLIT_COUNT% split-size PNG icons
	) ELSE (
		ECHO FAIL: Split size extraction produced no images
	)

REM ------------------------------------------------------------------
REM Cleanup
REM ------------------------------------------------------------------
	RD /S /Q "%SANDBOX%" > NUL 2>&1

:END
ENDLOCAL & PAUSE
