@ECHO OFF
REM ==================================================================
REM Sanity test for pig-latin.cmd & Translate-PigLatin.ps1
REM Tests: Standard translation, hyphenated syntax, reverse translation,
REM        casing, punctuation, contractions, and file output
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
	SET "TOOL_CMD=%SCRIPT_DIR%..\..\cmd\pig-latin.cmd"

	IF NOT EXIST "%TOOL_CMD%" (
		ECHO FAIL: Tool not found at "%TOOL_CMD%"
		GOTO :END
	)

REM ------------------------------------------------------------------
REM Test 1: Standard English to Pig Latin (amelay, appleway)
REM ------------------------------------------------------------------
	SET "OUT_RES="
	FOR /F "usebackq delims=" %%A IN (`CALL "%TOOL_CMD%" "lame apple" -nc`) DO (
		IF NOT DEFINED OUT_RES SET "OUT_RES=%%A"
	)
	IF /I "%OUT_RES%"=="amelay appleway" (
		ECHO PASS: Standard conversion [%OUT_RES%]
	) ELSE (
		ECHO FAIL: Expected 'amelay appleway', got [%OUT_RES%]
	)

REM ------------------------------------------------------------------
REM Test 2: Hyphenated English to Pig Latin (ame-lay, apple-way)
REM ------------------------------------------------------------------
	SET "OUT_RES="
	FOR /F "usebackq delims=" %%A IN (`CALL "%TOOL_CMD%" "lame apple" -hyphen -nc`) DO (
		IF NOT DEFINED OUT_RES SET "OUT_RES=%%A"
	)
	IF /I "%OUT_RES%"=="ame-lay apple-way" (
		ECHO PASS: Hyphenated conversion [%OUT_RES%]
	) ELSE (
		ECHO FAIL: Expected 'ame-lay apple-way', got [%OUT_RES%]
	)

REM ------------------------------------------------------------------
REM Test 3: Reverse Pig Latin to English (-from)
REM ------------------------------------------------------------------
	SET "OUT_RES="
	FOR /F "usebackq delims=" %%A IN (`CALL "%TOOL_CMD%" "ame-lay apple-way" -from -nc`) DO (
		IF NOT DEFINED OUT_RES SET "OUT_RES=%%A"
	)
	IF /I "%OUT_RES%"=="lame apple" (
		ECHO PASS: Reverse hyphenated translation [%OUT_RES%]
	) ELSE (
		ECHO FAIL: Expected 'lame apple', got [%OUT_RES%]
	)

REM ------------------------------------------------------------------
REM Test 4: Sentence capitalization, punctuation & contractions
REM ------------------------------------------------------------------
	SET "OUT_RES="
	FOR /F "usebackq delims=" %%A IN (`CALL "%TOOL_CMD%" "Don't worry, world!" -hyphen -nc`) DO (
		IF NOT DEFINED OUT_RES SET "OUT_RES=%%A"
	)
	IF /I "%OUT_RES%"=="On't-day orry-way, orld-way!" (
		ECHO PASS: Contractions, punctuation ^& casing [%OUT_RES%]
	) ELSE (
		ECHO FAIL: Expected 'On't-day orry-way, orld-way!', got [%OUT_RES%]
	)

REM ------------------------------------------------------------------
REM Test 5: Round-trip sentence reversal
REM ------------------------------------------------------------------
	SET "OUT_RES="
	FOR /F "usebackq delims=" %%A IN (`CALL "%TOOL_CMD%" "On't-day orry-way, orld-way!" -from -nc`) DO (
		IF NOT DEFINED OUT_RES SET "OUT_RES=%%A"
	)
	IF /I "%OUT_RES%"=="Don't worry, world!" (
		ECHO PASS: Round-trip sentence reversal [%OUT_RES%]
	) ELSE (
		ECHO FAIL: Expected 'Don't worry, world!', got [%OUT_RES%]
	)

REM ------------------------------------------------------------------
REM Test 6: File output handling (-o)
REM ------------------------------------------------------------------
	SET "TMP_IN=%TEMP%\pig_test_in_%RANDOM%.txt"
	SET "TMP_OUT=%TEMP%\pig_test_out_%RANDOM%.txt"

	ECHO The quick brown fox jumps over the lazy dog.> "%TMP_IN%"
	CALL "%TOOL_CMD%" "%TMP_IN%" -hyphen -o "%TMP_OUT%" -nc > NUL 2>&1

	IF NOT EXIST "%TMP_OUT%" (
		ECHO FAIL: Output file was not created
		GOTO :CLEANUP_TEST6
	)

	SET "FILE_CONTENT="
	FOR /F "usebackq delims=" %%B IN ("%TMP_OUT%") DO (
		IF NOT DEFINED FILE_CONTENT SET "FILE_CONTENT=%%B"
	)

	IF NOT "%FILE_CONTENT%"=="" (
		ECHO PASS: File translation output created successfully
	) ELSE (
		ECHO FAIL: Output file was empty
	)

:CLEANUP_TEST6
	IF EXIST "%TMP_IN%" DEL /F /Q "%TMP_IN%" > NUL 2>&1
	IF EXIST "%TMP_OUT%" DEL /F /Q "%TMP_OUT%" > NUL 2>&1

:END
ENDLOCAL & PAUSE
