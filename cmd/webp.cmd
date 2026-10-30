@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Batch WebP Converter (Lossless / High-Efficiency Image Conversion)
	REM Syntax: webp [[Options] TargetFiles...]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	IF "%~1"=="" GOTO :SYNTAX

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "COUNT_TOTAL=0"
	SET "COUNT_OK=0"
	SET "COUNT_SKIP=0"
	SET "COUNT_FAIL=0"
	SET "DO_RECYCLE=0"
	SET "MODE="

	CALL "%SCRIPT_DIR%..\lib\bat\getArch.cmd" ARC

	SET "BIN_DIR=%SCRIPT_DIR%..\bin"
	SET "CWEBP_EXE=%BIN_DIR%\webp%ARC%\cwebp.exe"
	SET "GIF2WEBP_EXE=%BIN_DIR%\webp%ARC%\gif2webp.exe"
	SET "NIRCMD_EXE=%BIN_DIR%\nircmdc%ARC%.exe"

	IF NOT EXIST "%CWEBP_EXE%" (
		ECHO Error: cwebp.exe not found at "%CWEBP_EXE%".
		EXIT /B 1
	)
	IF NOT EXIST "%GIF2WEBP_EXE%" (
		ECHO Error: gif2webp.exe not found at "%GIF2WEBP_EXE%".
		EXIT /B 1
	)
	IF NOT EXIST "%NIRCMD_EXE%" (
		ECHO Error: nircmdc.exe not found at "%NIRCMD_EXE%".
		EXIT /B 1
	)

	:PARSE_ARGS
		IF "%~1"=="" GOTO :EXECUTE
		SET "ARG=%~1"

		IF /I "%ARG%"=="/?" GOTO :SYNTAX
		IF /I "%ARG%"=="-?" GOTO :SYNTAX
		IF /I "%ARG%"=="-h" GOTO :SYNTAX
		IF /I "%ARG%"=="/h" GOTO :SYNTAX
		IF /I "%ARG%"=="--help" GOTO :SYNTAX
		IF /I "%ARG%"=="/help" GOTO :SYNTAX

		REM Options / Flags
		IF "%ARG%"=="-r" ( SET "DO_RECYCLE=1" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="/recycle" ( SET "DO_RECYCLE=1" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="--recycle" ( SET "DO_RECYCLE=1" & SHIFT /1 & GOTO :PARSE_ARGS )

		IF /I "%ARG%"=="/A" ( SET "MODE=ALL" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="-A" ( SET "MODE=ALL" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="--all" ( SET "MODE=ALL" & SHIFT /1 & GOTO :PARSE_ARGS )

		IF /I "%ARG%"=="/R" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF "%ARG%"=="-R" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="/S" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="-S" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
		IF /I "%ARG%"=="--recursive" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )

		REM Target file argument (supports multiple files & drag-and-drop)
		CALL :PROCESS "%~1"
		SHIFT /1
	GOTO :PARSE_ARGS

	:EXECUTE
		IF "%MODE%"=="ALL" (
			FOR %%F IN ("*.png", "*.bmp", "*.gif") DO CALL :PROCESS "%%F"
		) ELSE IF "%MODE%"=="RECURSIVE" (
			FOR /R %%F IN ("*.png", "*.bmp", "*.gif") DO CALL :PROCESS "%%F"
		)
	GOTO :END

	:PROCESS
		IF "%~1"=="" GOTO :EOF
		IF NOT EXIST "%~1" (
			ECHO [SKIP] File not found: "%~f1"
			SET /A "COUNT_SKIP+=1"
			GOTO :EOF
		)
		IF EXIST "%~1\*" GOTO :EOF

		SET /A "COUNT_TOTAL+=1"
		SET "SRC_EXT=%~x1"
		SET "TARGET_WEBP=%~dpn1.webp"
		SET "TEMP_WEBP=%~dpn1.tmp_%RANDOM%.webp"

		IF EXIST "%TARGET_WEBP%" (
			ECHO [SKIP] Already exists: "%TARGET_WEBP%"
			SET /A "COUNT_SKIP+=1"
			GOTO :EOF
		)

		SET "IS_SUPPORTED=0"
		IF /I "%SRC_EXT%"==".png" SET "IS_SUPPORTED=1"
		IF /I "%SRC_EXT%"==".bmp" SET "IS_SUPPORTED=1"
		IF /I "%SRC_EXT%"==".gif" SET "IS_SUPPORTED=1"
		IF "%IS_SUPPORTED%"=="0" (
			ECHO [SKIP] Unsupported extension "%SRC_EXT%": "%~nx1"
			SET /A "COUNT_SKIP+=1"
			GOTO :EOF
		)

		SET "SRC_SIZE=%~z1"

		IF /I "%SRC_EXT%"==".gif" (
			"%GIF2WEBP_EXE%" -m 6 -metadata all -mt -quiet "%~f1" -o "%TEMP_WEBP%"
		) ELSE IF /I "%SRC_EXT%"==".bmp" (
			"%CWEBP_EXE%" -lossless -m 4 -mt -quiet "%~f1" -o "%TEMP_WEBP%"
		) ELSE (
			"%CWEBP_EXE%" -lossless -m 4 -metadata all -mt -quiet "%~f1" -o "%TEMP_WEBP%"
		)

		IF NOT %ERRORLEVEL% EQU 0 GOTO :CONVERT_FAILED
		IF NOT EXIST "%TEMP_WEBP%" GOTO :CONVERT_FAILED

		SET "WEBP_SIZE=0"
		FOR %%Z IN ("%TEMP_WEBP%") DO SET "WEBP_SIZE=%%~zZ"
		IF "%WEBP_SIZE%"=="0" GOTO :CONVERT_FAILED

		MOVE /Y "%TEMP_WEBP%" "%TARGET_WEBP%" >NUL 2>&1
		IF NOT EXIST "%TARGET_WEBP%" GOTO :CONVERT_FAILED

		SET "SAVED_STR="
		SET "PCT="
		IF %SRC_SIZE% GTR 0 (
			SET /A "PCT=(SRC_SIZE - WEBP_SIZE) * 100 / SRC_SIZE"
		)
		IF NOT "%PCT%"=="" IF %PCT% GTR 0 SET "SAVED_STR= (%PCT%%% smaller)"

		ECHO [OK] "%~nx1" -^> "%~n1.webp" (%SRC_SIZE% B -^> %WEBP_SIZE% B%SAVED_STR%)
		SET /A "COUNT_OK+=1"

		IF "%DO_RECYCLE%"=="1" (
			"%NIRCMD_EXE%" moverecyclebin "%~f1"
		)
	GOTO :EOF

	:CONVERT_FAILED
		IF EXIST "%TEMP_WEBP%" DEL "%TEMP_WEBP%" >NUL 2>&1
		ECHO [FAIL] Conversion failed: "%~nx1"
		SET /A "COUNT_FAIL+=1"
	GOTO :EOF

	:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [Options] [Files...]
		ECHO.
		ECHO    Converts BMP, GIF, and PNG images to WebP format with
		ECHO    lossless compression and multi-threaded encoding.
		ECHO.
		ECHO    Options / Flags:
		ECHO       [Files...]       : One or more image files to convert (drag ^& drop supported)
		ECHO       /A, -A, --all    : Convert all supported images in current directory
		ECHO       /R, /S, --recursive : Convert all supported images recursively (current ^& subdirectories)
		ECHO       -r, --recycle    : Move original files to Recycle Bin after conversion
		ECHO       -?, -h, --help   : Display this syntax help
		ECHO.
		ECHO    Supported Formats:
		ECHO       BMP, GIF (including animated GIFs), PNG
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0 "photo.png"
		ECHO       %~nx0 -r "photo.png"
		ECHO       %~nx0 /A
		ECHO       %~nx0 /R -r
		ECHO.
		ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
		ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
		ECHO Contact: foolycooly1764@gmail.com
		ECHO.
		SET "EXIT_CODE=0"
	GOTO :END

	:END
		IF NOT "%COUNT_TOTAL%"=="" IF %COUNT_TOTAL% GTR 0 (
			ECHO.
			ECHO --------------------------------------------------
			ECHO Summary: %COUNT_TOTAL% processed, %COUNT_OK% converted, %COUNT_SKIP% skipped, %COUNT_FAIL% failed
			ECHO --------------------------------------------------
			ECHO.
		)

		SET "FINAL_EXIT=0"
		IF NOT "%COUNT_FAIL%"=="" IF %COUNT_FAIL% GTR 0 SET "FINAL_EXIT=1"

		CALL "%SCRIPT_DIR%..\lib\bat\isDoubleClick.cmd" "%SCRIPT_NAME%"
		IF %ERRORLEVEL% EQU 0 (
			ECHO.
			PAUSE
		)
ENDLOCAL & EXIT /B %FINAL_EXIT%
