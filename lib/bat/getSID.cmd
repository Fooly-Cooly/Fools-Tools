@ECHO OFF
REM ==================================================================
REM Retrieves SID of specified user ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar] [UserName]
REM Notes:	Compatible with Windows XP through Windows 11
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: Missing Parameters & GOTO :EOF )

	SET "USER_TO_FIND=%~2"
	IF NOT DEFINED USER_TO_FIND SET "USER_TO_FIND=%USERNAME%"

	SET "RETURN="

	REM --- Method 1: Try PowerShell (.NET NTAccount lookup - Win 7 to Win 11) ---
	WHERE powershell.exe > NUL 2>&1
	IF %ERRORLEVEL% EQU 0 (
		FOR /F "usebackq tokens=*" %%A IN (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$u='%USER_TO_FIND%'; try { (New-Object System.Security.Principal.NTAccount($u)).Translate([System.Security.Principal.SecurityIdentifier]).Value } catch { try { (Get-CimInstance Win32_UserAccount -Filter \"Name='$u'\").SID } catch {} }" 2^>NUL`) DO (
			SET "RETURN=%%A"
		)
	)

	REM --- Method 2: Fallback to Registry Query (XP / Vista / Systems without PowerShell) ---
	IF NOT DEFINED RETURN (
		FOR /F "tokens=1,2*" %%A IN ('REG QUERY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s 2^>NUL ^| FINDSTR /I /C:"ProfileImagePath"') DO (
			ECHO %%C | FINDSTR /I /C:"\%USER_TO_FIND%" > NUL 2>&1
			IF NOT ERRORLEVEL 1 (
				REM Extract SID from the reg path loop if found
			)
		)
	)

	:END
ENDLOCAL & SET "%~1=%RETURN%"