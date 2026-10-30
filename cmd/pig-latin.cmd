@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Bi-directional English <-> Pig Latin Translator
	REM Syntax: pig-latin [[Options] Target]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "ENGINE_PS1=%SCRIPT_DIR%..\lib\ps1\Translate-PigLatin.ps1"
	SET "EXIT_CODE=0"

	IF NOT EXIST "%ENGINE_PS1%" (
		ECHO [ERROR] Translate-PigLatin.ps1 not found at "%ENGINE_PS1%".
		EXIT /B 1
	)

	REM Help routing
	IF /I "%~1"=="/?" GOTO :SYNTAX
	IF /I "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/h" GOTO :SYNTAX
	IF /I "%~1"=="-h" GOTO :SYNTAX
	IF /I "%~1"=="/help" GOTO :SYNTAX
	IF /I "%~1"=="--help" GOTO :SYNTAX
	IF /I "%~1"=="help" GOTO :SYNTAX

	REM Forward CLI arguments or launch interactive menu if no arguments given
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ENGINE_PS1%" %*
	SET "EXIT_CODE=%ERRORLEVEL%"
	GOTO :END

:SYNTAX
	ECHO.
	ECHO Syntax: %~nx0 [[Options] Target]
	ECHO.
	ECHO    Bi-directional English ^<^-^> Pig Latin translator. Supports direct text,
	ECHO    text files, drag-and-drop, and interactive prompts.
	ECHO.
	ECHO    Options / Flags:
	ECHO       -to, -e2p                  : Translate English to Pig Latin (default)
	ECHO       -from, -p2e                : Translate Pig Latin to English
	ECHO       -hyphen, -hyp, -dash       : Use hyphenated syntax (e.g. 'ame-lay' vs 'amelay')
	ECHO       -suffix ^<way^|yay^|ay^>       : Vowel suffix for English-^>Pig Latin (default: way)
	ECHO       -o, -out ^<filepath^>        : Save translation to an output file
	ECHO       -clip                      : Copy translated result to Windows clipboard
	ECHO       -nc, -nocolor              : Disable console color formatting
	ECHO       -?, -h, --help             : Display this syntax help
	ECHO.
	ECHO    Examples:
	ECHO       %~nx0 "Hello world! This is a test."
	ECHO       %~nx0 "Hello world!" -hyphen
	ECHO       %~nx0 "Ello-hay orld-way!" -from
	ECHO       %~nx0 notes.txt
	ECHO       %~nx0 notes.txt -hyphen -o notes_pig.txt
	ECHO       %~nx0 "Secret message" -clip
	ECHO.
	ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	ECHO Contact: foolycooly1764@gmail.com
	ECHO.
	SET "EXIT_CODE=0"

:END
	CALL "%SCRIPT_DIR%..\lib\bat\isDoubleClick.cmd" "%SCRIPT_NAME%"
	IF %ERRORLEVEL% EQU 0 (
		ECHO.
		PAUSE
	)
	ENDLOCAL & EXIT /B %EXIT_CODE%
