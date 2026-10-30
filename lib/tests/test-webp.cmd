@ECHO OFF
REM ==================================================================
REM Sanity test for webp.cmd
REM Tests: PNG to WebP, BMP to WebP, batch mode (/A), and recycle flag (-r)
REM Syntax:	%~nx0
REM Notes:	For Windows 7 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )

	SET "SCRIPT_DIR=%~dp0"
	SET "TOOL_CMD=%SCRIPT_DIR%..\..\cmd\webp.cmd"
	SET "SANDBOX=%TEMP%\webp_test_%RANDOM%"

	IF NOT EXIST "%TOOL_CMD%" (
		ECHO FAIL: Tool not found at "%TOOL_CMD%"
		GOTO :END
	)

	MD "%SANDBOX%" 2>NUL

	REM Generate sample test images
	powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { Add-Type -AssemblyName System.Drawing; $b = New-Object System.Drawing.Bitmap 16,16; $g = [System.Drawing.Graphics]::FromImage($b); $g.Clear([System.Drawing.Color]::CornflowerBlue); $b.Save('%SANDBOX%\sample.png', [System.Drawing.Imaging.ImageFormat]::Png); $b.Save('%SANDBOX%\sample.bmp', [System.Drawing.Imaging.ImageFormat]::Bmp); $b.Save('%SANDBOX%\batch1.png', [System.Drawing.Imaging.ImageFormat]::Png); $b.Save('%SANDBOX%\batch2.png', [System.Drawing.Imaging.ImageFormat]::Png); $b.Save('%SANDBOX%\recycle.png', [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose(); }" > NUL 2>&1

	IF NOT EXIST "%SANDBOX%\sample.png" (
		ECHO FAIL: Failed to generate test images in sandbox
		GOTO :CLEANUP
	)

REM ------------------------------------------------------------------
REM Test 1: Convert PNG to WebP
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\sample.png" > NUL 2>&1
	IF EXIST "%SANDBOX%\sample.webp" (
		FOR %%F IN ("%SANDBOX%\sample.webp") DO (
			IF %%~zF GTR 0 (
				ECHO PASS: Converted PNG to WebP [%%~zF bytes]
			) ELSE (
				ECHO FAIL: Output WebP was 0 bytes
			)
		)
	) ELSE (
		ECHO FAIL: PNG to WebP conversion failed
	)

REM ------------------------------------------------------------------
REM Test 2: Convert BMP to WebP
REM ------------------------------------------------------------------
	CALL "%TOOL_CMD%" "%SANDBOX%\sample.bmp" > NUL 2>&1
	IF EXIST "%SANDBOX%\sample.webp" (
		ECHO PASS: Converted BMP to WebP
	) ELSE (
		ECHO FAIL: BMP to WebP conversion failed
	)

REM ------------------------------------------------------------------
REM Test 3: Batch All Conversion (/A)
REM ------------------------------------------------------------------
	PUSHD "%SANDBOX%"
	CALL "%TOOL_CMD%" /A > NUL 2>&1
	POPD
	IF EXIST "%SANDBOX%\batch1.webp" IF EXIST "%SANDBOX%\batch2.webp" (
		ECHO PASS: Batch mode ^(/A^) converted multiple images
	) ELSE (
		ECHO FAIL: Batch mode conversion failed
	)

REM ------------------------------------------------------------------
REM Test 4: Recycle original file (-r)
REM ------------------------------------------------------------------
	powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { Add-Type -AssemblyName System.Drawing; $b = New-Object System.Drawing.Bitmap 16,16; $b.Save('%SANDBOX%\recycle_target.png', [System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose(); }" > NUL 2>&1
	CALL "%TOOL_CMD%" -r "%SANDBOX%\recycle_target.png" > NUL 2>&1
	IF EXIST "%SANDBOX%\recycle_target.webp" (
		IF NOT EXIST "%SANDBOX%\recycle_target.png" (
			ECHO PASS: Recycle flag ^(-r^) converted image and removed original
		) ELSE (
			ECHO FAIL: Original file was not recycled
		)
	) ELSE (
		ECHO FAIL: WebP conversion with -r failed
	)

:CLEANUP
	RD /S /Q "%SANDBOX%" > NUL 2>&1

:END
ENDLOCAL & PAUSE
