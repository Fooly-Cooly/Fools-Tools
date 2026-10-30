@ECHO OFF
REM ==================================================================
REM Batch processes archives
REM Syntax:	%~nx0 Extension [Target] /FilesActionProfile
REM Notes:	For Windows XP Pro and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion

	SET "FILE_FLG=%~2"
	SET "ACTI_FLG=ACES"
	SET "PROF_FLG=ACS"

	IF "%~3" == "" ( GOTO :SYNTAX ) ELSE ( SET "SWIT=%~3" )
	IF "%SWIT:~3,1%" == "" GOTO :SYNTAX
	IF NOT "%SWIT:~0,1%" == "/" GOTO :SYNTAX

	SET "PROF=%SWIT:~3,1%"
	ECHO %PROF_FLG% | FIND /I "%PROF%" >NUL || GOTO :SYNTAX

	SET "ACTI=%SWIT:~2,1%"
	ECHO %ACTI_FLG% | FIND /I "%ACTI%" >NUL || GOTO :SYNTAX

	SET "PROC=%SWIT:~1,1%"
	ECHO %FILE_FLG% | FIND /I "%PROC%" >NUL || GOTO :SYNTAX

	CALL "%~dp0getArch.cmd" ARC

	SET "EXT=%~1"

	IF /I NOT "%ACTI%" == "E" (
		ECHO ,7z,cb7, | FIND /I ",%EXT%," >NUL && (
			IF /I "%PROF%" == "A" SET "CMD=7za%ARC% a -t7z -mx=9 -ms=16g -m0=LZMA2:d256m:fb256"
			IF /I "%PROF%" == "C" SET "CMD=7za%ARC% a -t7z -mx=9 -ms=8g -m0=LZMA2:d24m:fb24"
			IF /I "%PROF%" == "S" SET "CMD=7za%ARC% a -t7z -mx=0"
		)
		ECHO ,rar,cbr, | FIND /I ",%EXT%," >NUL && (
			CALL "%~dp0getRegVal.cmd" RAR "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WinRAR archiver" InstallLocation
			IF /I "%PROF%" == "A" SET "CMD="%RAR%rar" a -m5 -s -rr20% -ep1 -y -v"
			IF /I "%PROF%" == "C" SET "CMD="%RAR%rar" a -m4 -s -rr10% -cl -cv- -y -v"
			IF /I "%PROF%" == "S" SET "CMD="%RAR%rar" a -m1 -s- -rr5% -ep1 -y -v"
		)
		ECHO ,zip,cbz,bz2,gz, | FIND /I ",%EXT%," >NUL && (
			IF /I "%PROF%" == "A" SET "CMD=7za%ARC% a -tzip -mx=9"
			IF /I "%PROF%" == "C" SET "CMD=7za%ARC% a -tzip -mx=9"
			IF /I "%PROF%" == "S" SET "CMD=7za%ARC% a -tzip -mx=0"
		)
		IF NOT DEFINED CMD (
			ECHO ERROR: Unsupported extension "%EXT%"
			GOTO :EOF
		)
	)

	CALL :FILE_%PROC%
	PAUSE
ENDLOCAL & GOTO :EOF

	:SYNTAX
		ECHO Syntax: %~nx0 Extension [Target] /FilesActionProfile
		ECHO.
		ECHO  [File Flags]
		ECHO.
		ECHO.%FILE_FLG% | FIND "A">NUL && ( ECHO    [A : Archive All Files ^& Folders In CD] )
		ECHO.%FILE_FLG% | FIND "F">NUL && ( ECHO    [F : Archive Individual Folders In CD] )
		ECHO.%FILE_FLG% | FIND "I">NUL && ( ECHO    [I : Archive Individual Files In CD] )
		ECHO.%FILE_FLG% | FIND "S">NUL && ( ECHO    [S : Archive Single File - requires Target] )
		ECHO.
		ECHO  [Action Flags]
		ECHO.
		ECHO.%ACTI_FLG% | FIND "A">NUL && ( ECHO    [A : Archive Target] )
		ECHO.%ACTI_FLG% | FIND "C">NUL && ( ECHO    [C : Convert Target to Archive] )
		ECHO.%ACTI_FLG% | FIND "E">NUL && ( ECHO    [E : Extract Target] )
		ECHO.%ACTI_FLG% | FIND "S">NUL && ( ECHO    [S : Convert Target to Self-Extracting] )
		ECHO.
		ECHO  [Profile Flags]
		ECHO.
		ECHO.%PROF_FLG% | FIND "A">NUL && ( ECHO    [A : Archival] )
		ECHO.%PROF_FLG% | FIND "C">NUL && ( ECHO    [C : Comic] )
		ECHO.%PROF_FLG% | FIND "S">NUL && ( ECHO    [S : Store] )
		ECHO.
		ECHO Example: %~nx0 7z /AAA [Add All Files ^& Folders In CD to a .7z Archive using Archival Profile]
		ECHO.
		ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
		ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
		ECHO Contact: foolycooly1764@gmail.com
	GOTO :EOF

	REM Create Archive [ File | Path ]
	:ACTION_A
		ECHO ==============================
		IF NOT EXIST "%~2" (
			ECHO ERROR: "%~2" Not Found
			GOTO :EOF
		)
		%CMD% "%~1.%EXT%" "%~2"
	GOTO :EOF

	REM Convert Archive
	:ACTION_C
		ECHO ==============================
		IF NOT EXIST "%~2" (
			ECHO ERROR: "%~2" Not Found
			GOTO :EOF
		)
		SET "TMP_CONV=%TEMP%\tmp_%~n2"
		IF EXIST "%TMP_CONV%" RD /S /Q "%TMP_CONV%" >NUL 2>&1
		ECHO Creating Temp Extraction Folder...
		MKDIR "%TMP_CONV%" >NUL
		ECHO Extracting Source Archive to Temp Folder...
		7za%ARC% x "%~2" -o"%TMP_CONV%" -y >NUL
		ECHO Archiving Extracted Files to New Format...
		%CMD% "%~1.%EXT%" "%TMP_CONV%\*"
		ECHO Removing Temp Extraction Folder...
		RD /S /Q "%TMP_CONV%"
	GOTO :EOF

	REM Extract Archive [%1 = Name (unused) | %2 = Archive File]
	:ACTION_E
		ECHO ==============================
		IF NOT EXIST "%~2" (
			ECHO ERROR: "%~2" Not Found
			GOTO :EOF
		)
		SET "EXTRACT_PATH=%TEMP%\extract_%RANDOM%"
		MKDIR "%EXTRACT_PATH%"
		7za%ARC% x "%~2" -o"%EXTRACT_PATH%" -aou >NUL
		IF ERRORLEVEL 1 (
			ECHO ERROR: Extraction failed for "%~2"
			RD /S /Q "%EXTRACT_PATH%"
			GOTO :EOF
		)
		ECHO Extracted: "%~2" to "%EXTRACT_PATH%"
	GOTO :EOF

	REM Convert to Self-Extracting [%1 = Title | %2 = Target File]
	:ACTION_S
		ECHO ==============================
		IF "%~1" == "" ECHO Error: Incorrect Title or File Given & GOTO :EOF
		IF NOT EXIST "%~2" ECHO Error: Incorrect Title or File Given & GOTO :EOF
		CALL :ACTION_A "temp" "%~2"
		ECHO Creating Installer...
		(
			ECHO ;!@Install@!UTF-8!
			ECHO Title="%~1 Install"
			ECHO BeginPrompt="Do you want to install %~1?"
			ECHO RunProgram="%~nx2"
			ECHO ;!@InstallEnd@!
		) > config.txt
		COPY /B "%~dp0..\bin\7zSD.sfx" + "config.txt" + "temp.7z" "%~n2.new.exe"
		DEL /Q "temp.7z" "config.txt"
	GOTO :EOF

	REM Process All Files and Folders in Current Directory
	:FILE_A
		REM Send "Full CD Path" and "Full CD Path with Wild Card"
		CALL :ACTION_%ACTI% "%CD%" "%CD%\*"
	GOTO :EOF

	REM Process Individual Folders
	:FILE_F
		REM Loop all folders and send "Full Folder Path" and "Full Folder Path with Wild Card"
		FOR /D %%A IN (*) DO CALL :ACTION_%ACTI% "%%~fA" "%%~fA\*"
	GOTO :EOF

	REM Process Individual Files in Current Directory
	:FILE_I
		REM Loop all files and send "Drive,Path,Filename" and "Fullpath"
		FOR %%A IN (*) DO CALL :ACTION_%ACTI% "%%~dpnA" "%%~fA"
	GOTO :EOF

	REM Process Single File/Folder given as %2 - "Drive,Path,Filename" and "Fullpath"
	:FILE_S
		IF "%~2" == "" GOTO :SYNTAX
		CALL :ACTION_%ACTI% "%~dpn2" "%~f2"
	GOTO :EOF