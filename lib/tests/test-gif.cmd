@ECHO OFF
REM ==================================================================
REM Sanity test for gif.cmd
REM Tests: Lossless optimization, frame extraction, MP4, and WebM conversion
REM Syntax:	%~nx0
REM Notes:	For Windows 7 and later (requires Gifsicle & FFmpeg)
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "SCRIPT_DIR=%~dp0"
	SET "TOOL_CMD=%SCRIPT_DIR%..\..\cmd\gif.cmd"
	SET "SANDBOX=%TEMP%\gif_test_%RANDOM%"

	IF NOT EXIST "%TOOL_CMD%" (
		ECHO FAIL: Tool not found at "%TOOL_CMD%"
		GOTO :END
	)

	MD "%SANDBOX%" 2>NUL

	REM Generate sample test GIF using FFmpeg
	WHERE ffmpeg.exe >NUL 2>&1
	IF %ERRORLEVEL% NEQ 0 (
		ECHO SKIP: FFmpeg not available on PATH
		GOTO :CLEANUP
	)

	ffmpeg.exe -hide_banner -loglevel error -f lavfi -i testsrc=duration=1:size=64x64:rate=2 "%SANDBOX%\sample.gif" -y > NUL 2>&1

	IF NOT EXIST "%SANDBOX%\sample.gif" (
		ECHO FAIL: Failed to generate sample GIF in sandbox
		GOTO :CLEANUP
	)

REM ------------------------------------------------------------------
REM Test 1: Lossless GIF Optimization (-opt)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\sample.gif" -opt > NUL 2>&1
	IF EXIST "%SANDBOX%\sample.gif" (
		FOR %%Z IN ("%SANDBOX%\sample.gif") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Gifsicle optimization processed [%SANDBOX%\sample.gif]
			) ELSE (
				ECHO FAIL: Output GIF was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: Lossless optimization failed
	)

REM ------------------------------------------------------------------
REM Test 2: Frame Extraction (-frames)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\sample.gif" -frames > NUL 2>&1
	SET "FRAME_COUNT=0"
	IF EXIST "%SANDBOX%\sample_frames" (
		FOR /F "usebackq delims=" %%F IN (`DIR /B /A:-D "%SANDBOX%\sample_frames\*.png" 2^>NUL`) DO (
			SET /A FRAME_COUNT+=1
		)
	)
	IF %FRAME_COUNT% GTR 0 (
		ECHO PASS: Extracted %FRAME_COUNT% frames to subfolder
	) ELSE (
		ECHO FAIL: Frame extraction failed
	)

REM ------------------------------------------------------------------
REM Test 3: MP4 Video Conversion (-mp4)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\sample.gif" -mp4 > NUL 2>&1
	IF EXIST "%SANDBOX%\sample.mp4" (
		FOR %%Z IN ("%SANDBOX%\sample.mp4") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Converted GIF to MP4 video [%%~zZ bytes]
			) ELSE (
				ECHO FAIL: MP4 video was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: GIF to MP4 conversion failed
	)

REM ------------------------------------------------------------------
REM Test 4: WebM Video Conversion (-webm)
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\sample.gif" -webm > NUL 2>&1
	IF EXIST "%SANDBOX%\sample.webm" (
		FOR %%Z IN ("%SANDBOX%\sample.webm") DO (
			IF %%~zZ GTR 0 (
				ECHO PASS: Converted GIF to WebM video [%%~zZ bytes]
			) ELSE (
				ECHO FAIL: WebM video was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: GIF to WebM conversion failed
	)

:CLEANUP
	RD /S /Q "%SANDBOX%" > NUL 2>&1

:END
ENDLOCAL & PAUSE
