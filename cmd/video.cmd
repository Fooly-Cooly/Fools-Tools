@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Video Multi-Tool & FFmpeg Media Processor
	REM Syntax: video [TargetFile] [Options]
	REM Notes:	For Windows XP and later. Requires FFmpeg.
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
	SET "PARAM_VAL="
	SET "COUNT_TOTAL=0"
	SET "COUNT_OK=0"
	SET "COUNT_FAIL=0"

	REM Supported video extensions for directory and recursive scans
	SET "VID_EXTS=*.mp4 *.mkv *.avi *.webm *.mov *.wmv *.flv *.m4v *.ts"

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
	REM 2. Discover FFmpeg Binary
	REM ------------------------------------------------------------------
	CALL "%SCRIPT_DIR%..\lib\bat\getArch.cmd" ARC
	SET "FFMPEG_EXE=%SCRIPT_DIR%..\bin\ffmpeg.exe"
	IF NOT EXIST "%FFMPEG_EXE%" SET "FFMPEG_EXE=%SCRIPT_DIR%..\bin\ffmpeg%ARC%\ffmpeg.exe"
	IF NOT EXIST "%FFMPEG_EXE%" (
		WHERE ffmpeg.exe >NUL 2>&1
		IF %ERRORLEVEL% EQU 0 SET "FFMPEG_EXE=ffmpeg.exe"
	)

	IF "%FFMPEG_EXE%"=="" (
		ECHO Error: ffmpeg.exe not found in bin\ or system PATH.
		ECHO Please install FFmpeg or place ffmpeg.exe in the FoolsTools bin\ folder.
		SET "EXIT_CODE=1"
		GOTO :END
	)

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

	REM Actions: Audio Extraction
	IF /I "%ARG%"=="-mp3" ( SET "ACTION=MP3" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-audio" ( SET "ACTION=MP3" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--mp3" ( SET "ACTION=MP3" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-copyaudio" ( SET "ACTION=COPYAUDIO" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-copy-audio" ( SET "ACTION=COPYAUDIO" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--copyaudio" ( SET "ACTION=COPYAUDIO" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-demux" ( SET "ACTION=COPYAUDIO" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-wav" ( SET "ACTION=WAV" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--wav" ( SET "ACTION=WAV" & SHIFT /1 & GOTO :PARSE_ARGS )

	REM Actions: Frames & Thumbnails
	IF /I "%ARG%"=="-thumb" GOTO :PARSE_THUMB
	IF /I "%ARG%"=="--thumb" GOTO :PARSE_THUMB
	IF /I "%ARG%"=="-frames" ( SET "ACTION=FRAMES" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--frames" ( SET "ACTION=FRAMES" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-fps" GOTO :PARSE_FPS
	IF /I "%ARG%"=="--fps" GOTO :PARSE_FPS
	IF /I "%ARG%"=="-every" GOTO :PARSE_EVERY
	IF /I "%ARG%"=="--every" GOTO :PARSE_EVERY
	IF /I "%ARG%"=="-interval" GOTO :PARSE_EVERY
	IF /I "%ARG%"=="--interval" GOTO :PARSE_EVERY

	REM Actions: Video Conversions & Utilities
	IF /I "%ARG%"=="-mp4" ( SET "ACTION=MP4" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--mp4" ( SET "ACTION=MP4" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-gif" ( SET "ACTION=GIF" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--gif" ( SET "ACTION=GIF" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-webm" ( SET "ACTION=WEBM" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--webm" ( SET "ACTION=WEBM" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-mute" ( SET "ACTION=MUTE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="-noaudio" ( SET "ACTION=MUTE" & SHIFT /1 & GOTO :PARSE_ARGS )
	IF /I "%ARG%"=="--mute" ( SET "ACTION=MUTE" & SHIFT /1 & GOTO :PARSE_ARGS )

	REM Target file path argument
	IF EXIST "%~1" SET "TARGET_FILE=%~1"
	SHIFT /1
	GOTO :PARSE_ARGS

:PARSE_THUMB
		SET "ACTION=THUMB"
		SHIFT /1
		IF "%~1"=="" GOTO :PARSE_ARGS
		SET "NEXT_ARG=%~1"
		IF "%NEXT_ARG:~0,1%"=="-" GOTO :PARSE_ARGS
		IF "%NEXT_ARG:~0,1%"=="/" GOTO :PARSE_ARGS
		SET "PARAM_VAL=%~1"
		SHIFT /1
		GOTO :PARSE_ARGS

:PARSE_FPS
		SET "ACTION=FPS"
		SHIFT /1
		IF "%~1"=="" GOTO :PARSE_ARGS
		SET "NEXT_ARG=%~1"
		IF "%NEXT_ARG:~0,1%"=="-" GOTO :PARSE_ARGS
		IF "%NEXT_ARG:~0,1%"=="/" GOTO :PARSE_ARGS
		SET "PARAM_VAL=%~1"
		SHIFT /1
		GOTO :PARSE_ARGS

:PARSE_EVERY
		SET "ACTION=EVERY"
		SHIFT /1
		IF "%~1"=="" GOTO :PARSE_ARGS
		SET "NEXT_ARG=%~1"
		IF "%NEXT_ARG:~0,1%"=="-" GOTO :PARSE_ARGS
		IF "%NEXT_ARG:~0,1%"=="/" GOTO :PARSE_ARGS
		SET "PARAM_VAL=%~1"
		SHIFT /1
		GOTO :PARSE_ARGS

	REM ------------------------------------------------------------------
	REM 5. Interactive Action Menu (Drag & Drop or Single Target)
	REM ------------------------------------------------------------------
:ACTION_MENU
		CLS
		ECHO ============================================================
		ECHO            Fool's Tools - Video Multi-Tool
		ECHO ============================================================
		ECHO Target: %TARGET_FILE%
		ECHO.
		ECHO   [1] Extract Audio to MP3 (High-quality VBR)
		ECHO   [2] Extract Audio Losslessly (Stream copy .mka)
		ECHO   [3] Extract Audio to WAV (Lossless PCM)
		ECHO   [4] Capture Thumbnail Image (Poster frame at 00:00:05)
		ECHO   [5] Extract All Frames (Image sequence to subfolder)
		ECHO   [6] Convert to Universal MP4 (H.264 / AAC / FastStart)
		ECHO   [7] Convert to Animated GIF (2-Pass PaletteGen)
		ECHO   [8] Convert to WebM (VP9 / Opus)
		ECHO   [9] Remove Audio Track (Lossless Mute)
		ECHO   [Q] Quit / Exit
		ECHO.
		ECHO ============================================================
		ECHO.

		WHERE choice.exe >NUL 2>&1
		IF %ERRORLEVEL% EQU 0 (
			CHOICE /C 123456789Q /N /M "Select an action [1-9, Q]: "
			IF ERRORLEVEL 10 GOTO :END
			IF ERRORLEVEL 9 ( SET "ACTION=MUTE" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 8 ( SET "ACTION=WEBM" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 7 ( SET "ACTION=GIF" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 6 ( SET "ACTION=MP4" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 5 ( SET "ACTION=FRAMES" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 4 ( SET "ACTION=THUMB" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 3 ( SET "ACTION=WAV" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 2 ( SET "ACTION=COPYAUDIO" & GOTO :DO_SINGLE )
			IF ERRORLEVEL 1 ( SET "ACTION=MP3" & GOTO :DO_SINGLE )
		)

		SET "MENU_OPT="
		SET /P "MENU_OPT=Select an action [1-9, Q]: "
		IF /I "%MENU_OPT%"=="1" ( SET "ACTION=MP3" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="2" ( SET "ACTION=COPYAUDIO" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="3" ( SET "ACTION=WAV" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="4" ( SET "ACTION=THUMB" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="5" ( SET "ACTION=FRAMES" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="6" ( SET "ACTION=MP4" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="7" ( SET "ACTION=GIF" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="8" ( SET "ACTION=WEBM" & GOTO :DO_SINGLE )
		IF /I "%MENU_OPT%"=="9" ( SET "ACTION=MUTE" & GOTO :DO_SINGLE )
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
			FOR %%F IN (%VID_EXTS%) DO CALL :PROCESS "%%F"
		) ELSE IF "%MODE%"=="RECURSIVE" (
			FOR /R %%F IN (%VID_EXTS%) DO CALL :PROCESS "%%F"
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

		IF "%ACTION%"=="MP3" GOTO :ACT_MP3
		IF "%ACTION%"=="COPYAUDIO" GOTO :ACT_COPYAUDIO
		IF "%ACTION%"=="WAV" GOTO :ACT_WAV
		IF "%ACTION%"=="THUMB" GOTO :ACT_THUMB
		IF "%ACTION%"=="FRAMES" GOTO :ACT_FRAMES
		IF "%ACTION%"=="FPS" GOTO :ACT_FPS
		IF "%ACTION%"=="EVERY" GOTO :ACT_EVERY
		IF "%ACTION%"=="MP4" GOTO :ACT_MP4
		IF "%ACTION%"=="GIF" GOTO :ACT_GIF
		IF "%ACTION%"=="WEBM" GOTO :ACT_WEBM
		IF "%ACTION%"=="MUTE" GOTO :ACT_MUTE
		GOTO :ACT_FINISH

:ACT_MP3
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -vn -c:a libmp3lame -q:a 2 -y "%~dpn1.mp3"
			GOTO :ACT_FINISH

:ACT_COPYAUDIO
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -vn -c:a copy -y "%~dpn1.mka"
			GOTO :ACT_FINISH

:ACT_WAV
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -vn -c:a pcm_s16le -y "%~dpn1.wav"
			GOTO :ACT_FINISH

:ACT_THUMB
			SET "THUMB_TIME=00:00:05"
			IF NOT "%PARAM_VAL%"=="" SET "THUMB_TIME=%PARAM_VAL%"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -ss %THUMB_TIME% -i "%~f1" -vframes 1 -q:v 2 -update 1 -y "%~dpn1_thumb.jpg"
			GOTO :ACT_FINISH

:ACT_FRAMES
			IF NOT EXIST "%~dpn1_frames" MKDIR "%~dpn1_frames"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" "%~dpn1_frames\%%06d.png"
			GOTO :ACT_FINISH

:ACT_FPS
			IF NOT EXIST "%~dpn1_frames" MKDIR "%~dpn1_frames"
			SET "FPS_VAL=1"
			IF NOT "%PARAM_VAL%"=="" SET "FPS_VAL=%PARAM_VAL%"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -vf "fps=%FPS_VAL%" "%~dpn1_frames\%%06d.png"
			GOTO :ACT_FINISH

:ACT_EVERY
			IF NOT EXIST "%~dpn1_frames" MKDIR "%~dpn1_frames"
			SET "SEC_VAL=1"
			IF NOT "%PARAM_VAL%"=="" SET "SEC_VAL=%PARAM_VAL%"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -vf "fps=1/%SEC_VAL%" "%~dpn1_frames\%%06d.png"
			GOTO :ACT_FINISH

:ACT_MP4
			SET "OUT_MP4=%~dpn1.mp4"
			IF /I "%~x1"==".mp4" SET "OUT_MP4=%~dpn1_converted.mp4"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k -movflags +faststart -y "%OUT_MP4%"
			GOTO :ACT_FINISH

:ACT_GIF
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 -y "%~dpn1.gif"
			GOTO :ACT_FINISH

:ACT_WEBM
			SET "OUT_WEBM=%~dpn1.webm"
			IF /I "%~x1"==".webm" SET "OUT_WEBM=%~dpn1_converted.webm"
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k -y "%OUT_WEBM%"
			GOTO :ACT_FINISH

:ACT_MUTE
			"%FFMPEG_EXE%" -hide_banner -loglevel warning -stats -i "%~f1" -an -c:v copy -y "%~dpn1_muted%~x1"
			GOTO :ACT_FINISH

:ACT_FINISH
		IF %ERRORLEVEL% EQU 0 (
			ECHO   [OK] Success: "%~nx1"
			SET /A "COUNT_OK+=1"
		) ELSE (
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
		ECHO    Media conversion, audio demuxing, frame extraction,
		ECHO    and utility processing using FFmpeg.
		ECHO    Dragging a video onto %~nx0 opens an interactive Action Menu.
		ECHO.
		ECHO    Audio Extraction:
		ECHO       -mp3, -audio              : Extract audio to MP3 (High-quality VBR)
		ECHO       -copyaudio, -demux        : Losslessly copy audio stream to .mka
		ECHO       -wav                      : Extract uncompressed audio to WAV
		ECHO.
		ECHO    Frames ^& Thumbnails:
		ECHO       -thumb [time]             : Capture poster frame (default: 00:00:05)
		ECHO       -frames                   : Extract all frames to subfolder
		ECHO       -fps ^<N^>                  : Extract N frames per second
		ECHO       -every ^<N^> / -interval ^<N^>: Extract 1 frame every N seconds
		ECHO.
		ECHO    Video Conversion ^& Utilities:
		ECHO       -mp4                      : Universal MP4 (H.264 / AAC / FastStart)
		ECHO       -gif                      : High-quality 2-pass animated GIF
		ECHO       -webm                     : WebM conversion (VP9 / Opus)
		ECHO       -mute, -noaudio           : Remove audio track (Lossless copy)
		ECHO.
		ECHO    Batch Scope:
		ECHO       /A, --all                 : Process all videos in current directory
		ECHO       /R, /S, --recursive       : Process all videos recursively
		ECHO       -?, -h, --help            : Display this syntax help
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0 "video.mkv" -mp3
		ECHO       %~nx0 "clip.mp4" -thumb 00:01:30
		ECHO       %~nx0 "recording.mov" -mp4
		ECHO       %~nx0 "animation.mp4" -gif
		ECHO       %~nx0 "screencast.mp4" -every 5
		ECHO       %~nx0 /A -mp3
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
