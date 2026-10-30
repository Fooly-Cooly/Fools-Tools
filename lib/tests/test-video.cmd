@ECHO OFF
REM ==================================================================
REM Sanity test for video.cmd
REM Tests: MP3 audio extraction, thumbnail generation, frame extraction,
REM        GIF conversion, and video muting
REM Syntax:	%~nx0
REM Notes:	For Windows 7 and later (requires FFmpeg)
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "SCRIPT_DIR=%~dp0"
	SET "TOOL_CMD=%SCRIPT_DIR%..\..\cmd\video.cmd"
	SET "SANDBOX=%TEMP%\video_test_%RANDOM%"

	IF NOT EXIST "%TOOL_CMD%" (
		ECHO FAIL: Tool not found at "%TOOL_CMD%"
		GOTO :END
	)

	MD "%SANDBOX%" 2>NUL

	REM Generate sample 1-second video with audio track
	WHERE ffmpeg.exe >NUL 2>&1
	IF %ERRORLEVEL% NEQ 0 (
		ECHO SKIP: FFmpeg not available on PATH
		GOTO :CLEANUP
	)

	ffmpeg.exe -hide_banner -loglevel error -f lavfi -i testsrc=duration=1:size=160x120:rate=10 -f lavfi -i sine=frequency=1000:duration=1 -c:v libx264 -c:a aac -pix_fmt yuv420p "%SANDBOX%\clip.mp4" -y > NUL 2>&1

	IF NOT EXIST "%SANDBOX%\clip.mp4" (
		ECHO FAIL: Failed to generate sample video in sandbox
		GOTO :CLEANUP
	)

REM ------------------------------------------------------------------
REM Test 1: MP3 Audio Extraction (-mp3)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\clip.mp4" -mp3 > NUL 2>&1
	IF EXIST "%SANDBOX%\clip.mp3" (
		FOR %%Z IN ("%SANDBOX%\clip.mp3") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Extracted MP3 audio [%%~zZ bytes]
			) ELSE (
				ECHO FAIL: Extracted MP3 was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: MP3 extraction failed
	)

REM ------------------------------------------------------------------
REM Test 2: Thumbnail Generation (-thumb)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\clip.mp4" -thumb 00:00:00 > NUL 2>&1
	IF EXIST "%SANDBOX%\clip_thumb.jpg" (
		FOR %%Z IN ("%SANDBOX%\clip_thumb.jpg") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Generated video thumbnail [%%~zZ bytes]
			) ELSE (
				ECHO FAIL: Thumbnail image was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: Thumbnail generation failed
	)

REM ------------------------------------------------------------------
REM Test 3: Frame Extraction (-fps)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\clip.mp4" -fps 5 > NUL 2>&1
	SET "FRAME_COUNT=0"
	IF EXIST "%SANDBOX%\clip_frames" (
		FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\clip_frames\*.png" 2^>NUL`) DO (
			SET /A FRAME_COUNT+=1
		)
	)
	IF %FRAME_COUNT% GTR 0 (
		ECHO PASS: Extracted %FRAME_COUNT% video frames to subfolder
	) ELSE (
		ECHO FAIL: Frame extraction failed
	)

REM ------------------------------------------------------------------
REM Test 4: Convert Video to Animated GIF (-gif)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\clip.mp4" -gif > NUL 2>&1
	IF EXIST "%SANDBOX%\clip.gif" (
		FOR %%Z IN ("%SANDBOX%\clip.gif") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Converted video to animated GIF [%%~zZ bytes]
			) ELSE (
				ECHO FAIL: Output GIF was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: GIF conversion failed
	)

REM ------------------------------------------------------------------
REM Test 5: Mute Video (-mute)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\clip.mp4" -mute > NUL 2>&1
	IF EXIST "%SANDBOX%\clip_muted.mp4" (
		FOR %%Z IN ("%SANDBOX%\clip_muted.mp4") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Created muted video stream [%%~zZ bytes]
			) ELSE (
				ECHO FAIL: Muted video was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: Video muting failed
	)

:CLEANUP
	RD /S /Q "%SANDBOX%" > NUL 2>&1

:END
ENDLOCAL & PAUSE
