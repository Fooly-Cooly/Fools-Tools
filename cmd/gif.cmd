@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM GIF Multi-Tool (Optimization, Video Conversion & Extraction)
	REM Syntax: gif [TargetFile] [Options]
	REM Notes:	For Windows XP and later. Uses bundled Gifsicle & FFmpeg.
	REM
	REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
	REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
	REM Contact: foolycooly1764@gmail.com
	REM ==================================================================

	SET "SCRIPT_DIR=%~dp0"
	SET "SCRIPT_NAME=%~nx0"
	SET "EXIT_CODE=0"
	SET "ACTION="
	SET "MODE="
	SET "TARGET_FILE="
	SET "COUNT_TOTAL=0"
	SET "COUNT_OK=0"
	SET "COUNT_FAIL=0"

	REM ------------------------------------------------------------------
	REM 1. Empty Check & Help Parameter Routing
	REM ------------------------------------------------------------------
	IF "%~1"=="" GOTO :SYNTAX
	IF /I "%~1"=="/?" GOTO :SYNTAX
	IF /I "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/h" GOTO :SYNTAX
	IF /I "%~1"=="-h" GOTO :SYNTAX
	IF /I "%~1"=="/help" GOTO :SYNTAX
	IF /I "%~1"=="--help" GOTO :SYNTAX

	REM ------------------------------------------------------------------
	REM 2. Discover Binaries (Gifsicle & FFmpeg)
	REM ------------------------------------------------------------------
	CALL "%SCRIPT_DIR%..\lib\bat\getArch.cmd" ARC

	SET "GIFSICLE_EXE="
	IF EXIST "%SCRIPT_DIR%..\bin\gifsicle%ARC%.exe" SET "GIFSICLE_EXE=%SCRIPT_DIR%..\bin\gifsicle%ARC%.exe"
	IF NOT DEFINED GIFSICLE_EXE IF EXIST "%SCRIPT_DIR%..\bin\gifsicle.exe" SET "GIFSICLE_EXE=%SCRIPT_DIR%..\bin\gifsicle.exe"
	IF NOT DEFINED GIFSICLE_EXE FOR /F "delims=" %%I IN ('WHERE gifsicle.exe 2^>NUL') DO IF NOT DEFINED GIFSICLE_EXE SET "GIFSICLE_EXE=%%I"

	SET "FFMPEG_EXE="
	IF EXIST "%SCRIPT_DIR%..\bin\ffmpeg.exe" SET "FFMPEG_EXE=%SCRIPT_DIR%..\bin\ffmpeg.exe"
	IF NOT DEFINED FFMPEG_EXE IF EXIST "%SCRIPT_DIR%..\bin\ffmpeg%ARC%\ffmpeg.exe" SET "FFMPEG_EXE=%SCRIPT_DIR%..\bin\ffmpeg%ARC%\ffmpeg.exe"
	IF NOT DEFINED FFMPEG_EXE FOR /F "delims=" %%I IN ('WHERE ffmpeg.exe 2^>NUL') DO IF NOT DEFINED FFMPEG_EXE SET "FFMPEG_EXE=%%I"

	REM ------------------------------------------------------------------
	REM 3. Drag-and-Drop & Single Target Menu Detection
	REM ------------------------------------------------------------------
	REM If a single file argument is passed without flags, display Action Menu
	IF NOT "%~1"=="" IF "%~2"=="" (
		IF NOT "%~1"=="/A" IF NOT "%~1"=="-A" IF NOT "%~1"=="/R" IF NOT "%~1"=="-R" IF NOT "%~1"=="/S" IF NOT "%~1"=="-S" (
			IF EXIST "%~1" (
				SET "TARGET_FILE=%~1"
				GOTO :ACTION_MENU
			)
		)
	)

	REM ------------------------------------------------------------------
	REM 4. Parse Command-Line Arguments
	REM ------------------------------------------------------------------
:PARSE_ARGS
	IF "%~1"=="" GOTO :EXECUTE
	SET "ARG=%~1"

	IF /I "%ARG%"=="/?" GOTO :SYNTAX
	IF /I "%ARG%"=="-?" GOTO :SYNTAX
	IF /I "%ARG%"=="-h" GOTO :SYNTAX
	IF /I "%ARG%"=="/h" GOTO :SYNTAX
	IF /I "%ARG%"=="--help" GOTO :SYNTAX
	IF /I "%ARG%"=="/help" GOTO :SYNTAX

	REM Scope Modes
	IF /I "%ARG%"=="/A" ( SET "MODE=ALL" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-A" ( SET "MODE=ALL" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--all" ( SET "MODE=ALL" & SHIFT /1 & GOTO :PARSE_ARGS )

	IF /I "%ARG%"=="/R" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF "%ARG%"=="-R" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="/S" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-S" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--recursive" ( SET "MODE=RECURSIVE" & SHIFT /1 & GOTO :PARSE_ARGS )

	REM Actions
	IF /I "%ARG%"=="-optimize" ( SET "ACTION=OPTIMIZE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-opt" ( SET "ACTION=OPTIMIZE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-o" ( SET "ACTION=OPTIMIZE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--optimize" ( SET "ACTION=OPTIMIZE" & SHIFT /1 & GOTO :PARSE_ARGS )

	IF /I "%ARG%"=="-mp4" ( SET "ACTION=MP4" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--mp4" ( SET "ACTION=MP4" & SHIFT /1 & GOTO :PARSE_ARGS )

	IF /I "%ARG%"=="-webm" ( SET "ACTION=WEBM" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--webm" ( SET "ACTION=WEBM" & SHIFT /1 & GOTO :PARSE_ARGS )

	IF /I "%ARG%"=="-apng" ( SET "ACTION=APNG" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--apng" ( SET "ACTION=APNG" & SHIFT /1 & GOTO :PARSE_ARGS )

	IF /I "%ARG%"=="-frames" ( SET "ACTION=FRAMES" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--frames" ( SET "ACTION=FRAMES" & SHIFT /1 & GOTO :PARSE_ARGS )

	REM Target file argument
	IF EXIST "%~1" SET "TARGET_FILE=%~1"
	SHIFT /1
	GOTO :PARSE_ARGS

	REM ------------------------------------------------------------------
	REM 5. Interactive Action Menu (Drag & Drop or Single Target)
	REM ------------------------------------------------------------------
:ACTION_MENU
		CLS
		ECHO ============================================================
		ECHO             Fool's Tools - GIF Multi-Tool
		ECHO ============================================================
		ECHO Target: %TARGET_FILE%
		ECHO.
		ECHO   [1] Optimize GIF (Lossless Gifsicle -O3)
		ECHO   [2] Convert to Universal MP4 Video (H.264)
		ECHO   [3] Convert to WebM Video (VP9 with Alpha)
		ECHO   [4] Convert to Animated PNG (APNG)
		ECHO   [5] Extract Frames (PNG image sequence to subfolder)
		ECHO   [Q] Quit / Exit
		ECHO.
		ECHO ============================================================
		ECHO.

		WHERE choice.exe >NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			CHOICE /C 12345Q /N /M "Select an action [1-5, Q]: "
			IF ERRORLEVEL 6 GOTO :END
			IF ERRORLEVEL 5 ( SET "ACTION=FRAMES" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 4 ( SET "ACTION=APNG" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 3 ( SET "ACTION=WEBM" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 2 ( SET "ACTION=MP4" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 1 ( SET "ACTION=OPTIMIZE" & GOTO :DO_SINGLE )
		)

		SET "MENU_OPT="
		SET /P "MENU_OPT=Select an action [1-5, Q]: "
		IF /I "%MENU_OPT%"=="1" ( SET "ACTION=OPTIMIZE" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="2" ( SET "ACTION=MP4" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="3" ( SET "ACTION=WEBM" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="4" ( SET "ACTION=APNG" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="5" ( SET "ACTION=FRAMES" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="Q" GOTO :END
		GOTO :ACTION_MENU

:DO_SINGLE
		CALL :PROCESS "%TARGET_FILE%"
		GOTO :END

	REM ------------------------------------------------------------------
	REM 6. Execution Dispatcher
	REM ------------------------------------------------------------------
:EXECUTE
		IF "%ACTION%"=="" (
			ECHO Error: No action specified.
			ECHO Type '%~nx0 /?' for syntax and available actions.
			SET "EXIT_CODE=1"
			GOTO :END
		)

		IF "%MODE%"=="ALL" (
			FOR %%F IN ("*.gif") DO CALL :PROCESS "%%F"
		) ELSE IF "%MODE%"=="RECURSIVE" (
			FOR /R %%F IN ("*.gif") DO CALL :PROCESS "%%F"
		) ELSE IF NOT "%TARGET_FILE%"=="" (
			CALL :PROCESS "%TARGET_FILE%"
		) ELSE (
			ECHO Error: No target file or scope specified.
			ECHO Type '%~nx0 /?' for usage instructions.
			SET "EXIT_CODE=1"
		)
		GOTO :END

	REM ------------------------------------------------------------------
	REM 7. Per-File Processing Subroutine
	REM ------------------------------------------------------------------
:PROCESS
		IF "%~1"=="" GOTO :EOF
		IF NOT EXIST "%~1" (
			ECHO [SKIP] File not found: "%~f1"
			GOTO :EOF
		)
		IF EXIST "%~1\*" GOTO :EOF

		SET /A "COUNT_TOTAL+=1"
		ECHO.
		ECHO --------------------------------------------------
		ECHO Processing: "%~nx1"
		ECHO --------------------------------------------------

		IF "%ACTION%"=="OPTIMIZE" GOTO :ACT_OPTIMIZE
		IF "%ACTION%"=="MP4" GOTO :ACT_MP4
		IF "%ACTION%"=="WEBM" GOTO :ACT_WEBM
		IF "%ACTION%"=="APNG" GOTO :ACT_APNG
		IF "%ACTION%"=="FRAMES" GOTO :ACT_FRAMES
		GOTO :ACT_FINISH

:ACT_OPTIMIZE
			IF NOT DEFINED GIFSICLE_EXE (
				ECHO Error: gifsicle.exe not found in bin\ or system PATH.
				GOTO :ACT_FAIL
			)
			SET "SRC_SIZE=%~z1"
			SET "TEMP_GIF=%~dpn1.tmp_%RANDOM%.gif"
			"%GIFSICLE_EXE%" -O3 -o "%TEMP_GIF%" "%~f1"
			IF %ERRORLEVEL% NEQ 0 GOTO :OPT_FAILED
			IF NOT EXIST "%TEMP_GIF%" GOTO :OPT_FAILED

			SET "NEW_SIZE=0"
			FOR %%Z IN ("%TEMP_GIF%") DO SET "NEW_SIZE=%%~zZ"
			IF "%NEW_SIZE%"=="0" GOTO :OPT_FAILED

			IF %NEW_SIZE% LSS %SRC_SIZE% GOTO :OPT_REPLACE
			IF EXIST "%TEMP_GIF%" DEL "%TEMP_GIF%" >NUL 2>&1
			ECHO   [OK] Already fully optimized (%SRC_SIZE% B)
			SET /A "COUNT_OK+=1"
			GOTO :EOF

			:OPT_REPLACE
			MOVE /Y "%TEMP_GIF%" "%~f1" >NUL 2>&1
			SET "SAVED_STR="
			IF %SRC_SIZE% GTR 0 (
				SET /A "PCT=(SRC_SIZE - NEW_SIZE) * 100 / SRC_SIZE"
			)
			IF DEFINED PCT IF %PCT% GTR 0 SET "SAVED_STR= (%PCT%%% smaller)"
			ECHO   [OK] Optimized: %SRC_SIZE% B -^> %NEW_SIZE% B%SAVED_STR%
			SET /A "COUNT_OK+=1"
			GOTO :EOF

:OPT_FAILED
			IF EXIST "%TEMP_GIF%" DEL "%TEMP_GIF%" >NUL 2>&1
			GOTO :ACT_FAIL

:ACT_MP4
			IF NOT DEFINED FFMPEG_EXE GOTO :NEED_FFMPEG
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -movflags +faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -crf 20 -preset medium -y "%~dpn1.mp4"
			GOTO :ACT_FINISH

:ACT_WEBM
			IF NOT DEFINED FFMPEG_EXE GOTO :NEED_FFMPEG
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -c:v libvpx-vp9 -crf 20 -b:v 0 -auto-alt-ref 0 -metadata:s:v:0 alpha_mode=1 -pix_fmt yuva420p -y "%~dpn1.webm"
			GOTO :ACT_FINISH

:ACT_APNG
			IF NOT DEFINED FFMPEG_EXE GOTO :NEED_FFMPEG
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -plays 0 -y "%~dpn1.apng"
			GOTO :ACT_FINISH

:ACT_FRAMES
			IF NOT DEFINED FFMPEG_EXE GOTO :NEED_FFMPEG
			IF NOT EXIST "%~dpn1_frames" MKDIR "%~dpn1_frames"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" "%~dpn1_frames\%%05d.png"
			GOTO :ACT_FINISH

:NEED_FFMPEG
			ECHO Error: ffmpeg.exe not found in bin\ or system PATH.
			GOTO :ACT_FAIL

:ACT_FINISH
		IF %ERRORLEVEL% EQU 0 (
			ECHO   [OK] Success: "%~nx1"
			SET /A "COUNT_OK+=1"
		) ELSE (
:ACT_FAIL
			ECHO   [FAIL] Failed processing: "%~nx1"
			SET /A "COUNT_FAIL+=1"
		)
		GOTO :EOF

	REM ------------------------------------------------------------------
	REM 8. Syntax Help
	REM ------------------------------------------------------------------
:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [TargetFile] [Options]
		ECHO.
		ECHO    Lossless GIF optimization, video conversion, and frame
		ECHO    extraction using bundled Gifsicle and FFmpeg.
		ECHO    Dragging a GIF onto %~nx0 opens an interactive Action Menu.
		ECHO.
		ECHO    Actions:
		ECHO       -optimize, -opt, -o       : Losslessly optimize GIF using Gifsicle (-O3)
		ECHO       -mp4                      : Convert GIF to universal MP4 video (H.264)
		ECHO       -webm                     : Convert GIF to WebM video (VP9 with Alpha)
		ECHO       -apng                     : Convert GIF to Animated PNG (APNG)
		ECHO       -frames                   : Extract all frames to PNG image sequence
		ECHO.
		ECHO    Batch Scope:
		ECHO       /A, --all                 : Process all GIFs in current directory
		ECHO       /R, /S, --recursive       : Process all GIFs recursively
		ECHO       -?, -h, --help            : Display this syntax help
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0 "animation.gif" -optimize
		ECHO       %~nx0 "sticker.gif" -mp4
		ECHO       %~nx0 "banner.gif" -webm
		ECHO       %~nx0 "avatar.gif" -apng
		ECHO       %~nx0 "clip.gif" -frames
		ECHO       %~nx0 /A -optimize
		ECHO.
		ECHO Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
		ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
		ECHO Contact: foolycooly1764@gmail.com
		ECHO.
		SET "EXIT_CODE=0"

	REM ------------------------------------------------------------------
	REM 9. Exit & Double-Click Handler
	REM ------------------------------------------------------------------
:END
		IF NOT "%COUNT_TOTAL%"=="" IF %COUNT_TOTAL% GTR 0 (
			ECHO.
			ECHO ==================================================
			ECHO Summary: %COUNT_TOTAL% processed, %COUNT_OK% succeeded, %COUNT_FAIL% failed
			ECHO ==================================================
		)

		CALL "%SCRIPT_DIR%..\lib\bat\isDoubleClick.cmd" "%SCRIPT_NAME%"
		IF %ERRORLEVEL% EQU 0 (
			ECHO.
			PAUSE
		)
		ENDLOCAL & EXIT /B %EXIT_CODE%
