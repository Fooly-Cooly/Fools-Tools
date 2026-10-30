@ECHO OFF
SETLOCAL EnableExtensions DisableDelayedExpansion
	REM ==================================================================
	REM Unified Hashing Tool for Fool's Tools
	REM Syntax: hash [[Algorithm] Target] [Options]
	REM ==================================================================

	:: Fast exit for help syntax
	IF "%~1"=="" GOTO :SYNTAX
	IF "%~1"=="/?" GOTO :SYNTAX
	IF "%~1"=="-?" GOTO :SYNTAX
	IF /I "%~1"=="/H" GOTO :SYNTAX
	IF /I "%~1"=="-H" GOTO :SYNTAX
	IF /I "%~1"=="/HELP" GOTO :SYNTAX
	IF /I "%~1"=="--HELP" GOTO :SYNTAX

	powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\lib\ps1\Manage-Hashes.ps1" %*
	EXIT /B %ERRORLEVEL%

	:SYNTAX
		ECHO.
		ECHO Syntax: %~nx0 [[Algorithm] Target] [Options]
		ECHO.
		ECHO    Algorithms:
		ECHO       CRC32, MD5, SHA1, SHA256 (default), SHA384, SHA512, XXHSUM
		ECHO.
		ECHO    Targets / Modes:
		ECHO       [File]         : Hash a single file or wildcard (e.g. *.iso, app.exe)
		ECHO       /A             : Hash all files in current directory
		ECHO       /SYNC          : Synchronize directory manifest (Audit mode; keeps missing)
		ECHO.
		ECHO    Flags:
		ECHO       /PURGE         : Used with /SYNC to purge missing files from manifest
		ECHO       -a             : Append calculated hash to filename [e.g. File [HASH].ext]
		ECHO       -s             : Save/append hash to checksum file  [e.g. DirName.SHA256]
		ECHO.
		ECHO    Examples:
		ECHO       %~nx0 myimage.iso
		ECHO       %~nx0 MD5 myimage.iso -a
		ECHO       %~nx0 CRC32 *.zip -s
		ECHO       %~nx0 /A -s
		ECHO       %~nx0 /SYNC
		ECHO       %~nx0 SHA256 /SYNC /PURGE
		ECHO.
		ECHO Copyright (C) 2026 Fooly Cooly https://github.com/Fooly-Cooly
		ECHO Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
		ECHO Contact: foolycooly1764@gmail.com
		ECHO.
	EXIT /B 0
ENDLOCAL
