<!-- : Begin batch script
@ECHO OFF
REM ==================================================================
REM Retrieves shortcut command value ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar] [ShortcutPath]
REM Notes:	For Windows 2000 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions DisableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: Missing OutputVar parameter. & GOTO :EOF )
	IF "%~2"=="" ( ECHO Error: Missing target shortcut parameter. & GOTO :EOF )
	IF NOT EXIST "%~2" ( ECHO Error: Target "%~2" does not exist. & GOTO :EOF )

	SET "RETURN="
	FOR /F "usebackq eol=? delims=" %%A IN (`cscript //nologo "%~f0?.wsf" //job:Read "%~2"`) DO SET "RETURN=%%A"
ENDLOCAL & SET "%~1=%RETURN%" & GOTO :EOF

----- Begin wsf script --->
<package>
  <job id="Read">
	<script language="VBScript">
		SET WshShell = WScript.CreateObject("WScript.Shell")
		SET Lnk = WshShell.CreateShortcut(WScript.Arguments.Unnamed(0))
		wscript.Echo Lnk.TargetPath
	</script>
  </job>
</package>