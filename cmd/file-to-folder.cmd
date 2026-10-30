@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Organizes files into individual folders based on filename
	REM Syntax: file-to-folder [[Options] TargetFiles...]
	REM
	REM Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	IF "%~1"=="" GOTO :SYNTAX

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "SCRIPT_FULL=%~f0"

	SET "IS_COPY=0"
	SET "IS_DRYRUN=0"
	SET "DO_ALL=0"
	SET "FILTER_EXT="
	SET "TARGET_COUNT=0"

	SET "COUNT_TOTAL=0"
	SET "COUNT_FOLDER=0"
	SET "COUNT_SUCCESS=0"
	SET "COUNT_SKIP=0"
	SET "COUNT_FAIL=0"
	SET "EXIT_CODE=0"

:PARSE_LOOP
	IF "%~1"=="" GOTO :EXECUTE
	SET "ARG=%~1"

	REM Help routing
	IF /I "%ARG%"=="/?" GOTO :SYNTAX
	IF /I "%ARG%"=="-?" GOTO :SYNTAX
	IF /I "%ARG%"=="/h" GOTO :SYNTAX
	IF /I "%ARG%"=="-h" GOTO :SYNTAX
	IF /I "%ARG%"=="/help" GOTO :SYNTAX
	IF /I "%ARG%"=="--help" GOTO :SYNTAX
	IF /I "%ARG%"=="help" GOTO :SYNTAX

	REM Copy mode
	IF /I "%ARG%"=="-c" ( SET "IS_COPY=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="/c" ( SET "IS_COPY=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="-copy" ( SET "IS_COPY=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="--copy" ( SET "IS_COPY=1" & SHIFT /1 & GOTO :PARSE_LOOP )

	REM Dry-run / Simulate mode
	IF /I "%ARG%"=="-s" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="/s" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="-dry-run" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="--dry-run" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="-dryrun" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="--dryrun" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="-simulate" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="--simulate" ( SET "IS_DRYRUN=1" & SHIFT /1 & GOTO :PARSE_LOOP )

	REM All / Current Directory mode
	IF /I "%ARG%"=="-a" ( SET "DO_ALL=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="/a" ( SET "DO_ALL=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="-all" ( SET "DO_ALL=1" & SHIFT /1 & GOTO :PARSE_LOOP )
	IF /I "%ARG%"=="--all" ( SET "DO_ALL=1" & SHIFT /1 & GOTO :PARSE_LOOP )

	REM Extension filter
	IF /I "%ARG%"=="-ext" GOTO :PARSE_EXT
	IF /I "%ARG%"=="--ext" GOTO :PARSE_EXT
	IF /I "%ARG%"=="-filter" GOTO :PARSE_EXT
	IF /I "%ARG%"=="--filter" GOTO :PARSE_EXT

	REM Positional target (file, folder, or wildcard)
	SET /A TARGET_COUNT+=1
	SET "TARGET_%TARGET_COUNT%=%~1"
	SHIFT /1
	GOTO :PARSE_LOOP

:PARSE_EXT
	SHIFT /1
	IF "%~1"=="" (
		ECHO [ERROR] -ext requires an extension parameter ^(e.g. -ext mkv or -ext .mp4^).
		SET "EXIT_CODE=1"
		GOTO :END
	)
	SET "FILTER_EXT=%~1"
	IF NOT "%FILTER_EXT:~0,1%"=="." SET "FILTER_EXT=.%FILTER_EXT%"
	SHIFT /1
	GOTO :PARSE_LOOP

:EXECUTE
	IF %DO_ALL% EQU 0 IF %TARGET_COUNT% EQU 0 (
		ECHO [NOTICE] No target files specified.
		GOTO :SYNTAX
	)

	IF %IS_DRYRUN% EQU 1 (
		ECHO ============================================================
		ECHO  [SIMULATION] Previewing file-to-folder actions ^(Dry Run^)
		ECHO ============================================================
	)

	REM Process directory mode if -all flag was given
	IF %DO_ALL% EQU 1 (
		CALL :PROCESS_DIR "."
	)

	REM Process all collected target arguments
	IF %TARGET_COUNT% GTR 0 (
		FOR /L %%I IN (1,1,%TARGET_COUNT%) DO (
			CALL :DISPATCH_TARGET "%%TARGET_%%I%%"
		)
	)

	REM Show Summary
	ECHO.
	IF %COUNT_TOTAL% EQU 0 (
		ECHO [WARNING] No matching files were found to process.
	) ELSE IF %IS_DRYRUN% EQU 1 (
		ECHO [SIMULATE] Summary: %COUNT_TOTAL% processed, %COUNT_SUCCESS% simulated, %COUNT_SKIP% skipped, %COUNT_FAIL% failed
	) ELSE IF %IS_COPY% EQU 1 (
		ECHO Summary: %COUNT_TOTAL% processed, %COUNT_FOLDER% folders created, %COUNT_SUCCESS% copied, %COUNT_SKIP% skipped, %COUNT_FAIL% failed
	) ELSE (
		ECHO Summary: %COUNT_TOTAL% processed, %COUNT_FOLDER% folders created, %COUNT_SUCCESS% moved, %COUNT_SKIP% skipped, %COUNT_FAIL% failed
	)
	GOTO :END

:DISPATCH_TARGET
	SET "TGT=%~1"
	IF NOT DEFINED TGT GOTO :EOF
	IF EXIST "%TGT%\*" (
		CALL :PROCESS_DIR "%TGT%"
	) ELSE (
		FOR %%F IN ("%TGT%") DO CALL :PROCESS_FILE "%%~fF"
	)
	GOTO :EOF

:PROCESS_DIR
	SET "DIR_PATH=%~f1"
	IF NOT EXIST "%DIR_PATH%" GOTO :EOF
	FOR /F "delims=" %%D IN ('DIR /B /A:-D "%DIR_PATH%\*" 2^>NUL') DO (
		CALL :PROCESS_FILE "%DIR_PATH%\%%D"
	)
	GOTO :EOF

:PROCESS_FILE
	SET "SRC_FILE=%~f1"
	SET "SRC_NAME=%~nx1"
	SET "SRC_BASE=%~n1"
	SET "SRC_EXT=%~x1"
	SET "SRC_DIR=%~dp1"

	REM Basic existence and file-type validation
	IF NOT EXIST "%SRC_FILE%" GOTO :EOF
	IF EXIST "%SRC_FILE%\*" GOTO :EOF

	REM Self-preservation: Never move the script itself
	IF /I "%SRC_FILE%"=="%SCRIPT_FULL%" GOTO :EOF
	IF /I "%SRC_NAME%"=="%SCRIPT_NAME%" GOTO :EOF

	REM Extension filter check
	IF DEFINED FILTER_EXT (
		IF /I NOT "%SRC_EXT%"=="%FILTER_EXT%" GOTO :EOF
	)

	SET /A COUNT_TOTAL+=1
	SET "DEST_DIR=%SRC_DIR%%SRC_BASE%"
	SET "DEST_FILE=%DEST_DIR%\%SRC_NAME%"

	REM Avoid moving if file is already inside its named folder
	IF /I "%SRC_FILE%"=="%DEST_FILE%" (
		ECHO [SKIP] Already inside folder: "%SRC_NAME%"
		SET /A COUNT_SKIP+=1
		GOTO :EOF
	)

	REM Avoid overwriting existing target file
	IF EXIST "%DEST_FILE%" (
		ECHO [SKIP] Destination already exists: "%DEST_FILE%"
		SET /A COUNT_SKIP+=1
		GOTO :EOF
	)

	REM Dry-run preview
	IF %IS_DRYRUN% EQU 1 (
		IF %IS_COPY% EQU 1 (
			ECHO [SIMULATE] COPY "%SRC_NAME%" -^> "%SRC_BASE%\"
		) ELSE (
			ECHO [SIMULATE] MOVE "%SRC_NAME%" -^> "%SRC_BASE%\"
		)
		SET /A COUNT_SUCCESS+=1
		GOTO :EOF
	)

	REM Create target directory if it doesn't already exist
	IF NOT EXIST "%DEST_DIR%" (
		MD "%DEST_DIR%" 2>NUL
		IF %ERRORLEVEL% EQU 0 (
			SET /A COUNT_FOLDER+=1
		) ELSE (
			ECHO [FAIL] Could not create folder: "%DEST_DIR%"
			SET /A COUNT_FAIL+=1
			GOTO :EOF
		)
	)

	REM Execute Copy or Move
	IF %IS_COPY% EQU 1 (
		COPY /Y "%SRC_FILE%" "%DEST_FILE%" >NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			ECHO [COPY] "%SRC_NAME%" -^> "%SRC_BASE%\"
			SET /A COUNT_SUCCESS+=1
		) ELSE (
			ECHO [FAIL] Error copying "%SRC_NAME%"
			SET /A COUNT_FAIL+=1
		)
	) ELSE (
		MOVE /Y "%SRC_FILE%" "%DEST_FILE%" >NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			ECHO [MOVE] "%SRC_NAME%" -^> "%SRC_BASE%\"
			SET /A COUNT_SUCCESS+=1
		) ELSE (
			ECHO [FAIL] Error moving "%SRC_NAME%"
			SET /A COUNT_FAIL+=1
		)
	)
	GOTO :EOF

:SYNTAX
	ECHO.
	ECHO Syntax: %~nx0 [[Options] TargetFiles...]
	ECHO.
	ECHO    Creates an individual folder for each file based on its filename
	ECHO    and organizes the file into that folder. Drag ^& drop supported.
	ECHO.
	ECHO    Options / Flags:
	ECHO       -c, -copy, --copy         : Copy file into folder instead of moving
	ECHO       -s, -dry-run, --simulate  : Simulate actions without modifying disk
	ECHO       -ext ^<ext^>, -filter ^<ext^>: Only process files with specified extension
	ECHO       -a, -all, --all           : Process all files in the current directory
	ECHO       -?, -h, --help            : Display this syntax help
	ECHO.
	ECHO    Examples:
	ECHO       %~nx0 "movie.mkv"
	ECHO       %~nx0 -a
	ECHO       %~nx0 -c "document.pdf"
	ECHO       %~nx0 -ext mkv -a
	ECHO       %~nx0 -dry-run -all
	ECHO       %~nx0 *.iso
	ECHO       %~nx0 "D:\ROMs\*.zip"
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
