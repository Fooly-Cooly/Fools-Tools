@ECHO OFF
REM ==================================================================
REM Sanity test for getCFGVal.cmd
REM Tests: Parsing config values across sections and special characters
REM Syntax:	%~nx0
REM Notes:	For Windows 2000 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions EnableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "CFG_FILE=%~dp0test-getCFGVal.cfg"
	IF NOT EXIST "!CFG_FILE!" (
		ECHO FAIL: Config fixture "!CFG_FILE!" not found & GOTO :EOF
	)

REM ------------------------------------------------------------------
REM Test 1: Simple value
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "SimpleValue" "%CFG_FILE%" "Paths" "SimpleValue"
	IF "!SimpleValue!"=="hello" (
		ECHO PASS: SimpleValue parsed correctly: [!SimpleValue!]
	) ELSE (
		ECHO FAIL: SimpleValue expected [hello], got [!SimpleValue!]
	)

REM ------------------------------------------------------------------
REM Test 2: Value containing path with spaces
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "PathWithSpace" "%CFG_FILE%" "Paths" "PathWithSpace"
	IF "!PathWithSpace!"=="C:\Program Files\Foo\bar.exe" (
		ECHO PASS: PathWithSpace parsed correctly: [!PathWithSpace!]
	) ELSE (
		ECHO FAIL: PathWithSpace expected [C:\Program Files\Foo\bar.exe], got [!PathWithSpace!]
	)

REM ------------------------------------------------------------------
REM Test 3: URL value with query parameters
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "URL" "%CFG_FILE%" "Paths" "URL"
	IF "!URL!"=="http://example.com/path?a=b" (
		ECHO PASS: URL parsed correctly: [!URL!]
	) ELSE (
		ECHO FAIL: URL expected [http://example.com/path?a=b], got [!URL!]
	)

REM ------------------------------------------------------------------
REM Test 4: Value containing multiple equals signs
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "Multi" "%CFG_FILE%" "Paths" "Multi"
	IF "!Multi!"=="a=b=c" (
		ECHO PASS: Multi parsed correctly: [!Multi!]
	) ELSE (
		ECHO FAIL: Multi expected [a=b=c], got [!Multi!]
	)

REM ------------------------------------------------------------------
REM Test 5: Empty value
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "EmptyValue" "%CFG_FILE%" "Paths" "EmptyValue"
	IF "!EmptyValue!"=="" (
		ECHO PASS: EmptyValue parsed correctly: empty
	) ELSE (
		ECHO FAIL: EmptyValue expected [], got [!EmptyValue!]
	)

REM ------------------------------------------------------------------
REM Test 6: Quoted value
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "Quote" "%CFG_FILE%" "Paths" "Quote"
	IF [!Quote!]==["quoted value with space"] (
		ECHO PASS: Quote parsed correctly: [!Quote!]
	) ELSE (
		ECHO FAIL: Quote expected ["quoted value with space"], got [!Quote!]
	)

REM ------------------------------------------------------------------
REM Test 7: Value containing colons
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "Colon" "%CFG_FILE%" "Paths" "Colon"
	IF "!Colon!"=="Value:with:colons" (
		ECHO PASS: Colon parsed correctly: [!Colon!]
	) ELSE (
		ECHO FAIL: Colon expected [Value:with:colons], got [!Colon!]
	)

REM ------------------------------------------------------------------
REM Test 8: Value from second section
REM ------------------------------------------------------------------
	CALL "%~dp0..\bat\getCFGVal.cmd" "SectionPath" "%CFG_FILE%" "Section2" "SecondPath"
	IF "!SectionPath!"=="C:\Docs\My Documents\file.txt" (
		ECHO PASS: SectionPath parsed correctly: [!SectionPath!]
	) ELSE (
		ECHO FAIL: SectionPath expected [C:\Docs\My Documents\file.txt], got [!SectionPath!]
	)

ENDLOCAL & PAUSE