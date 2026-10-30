<!-- : Begin batch script
@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
		NET FILE >NUL 2>&1
		IF NOT %ERRORLEVEL% == 0 (
			ECHO Administrator permission is required^!
			ECHO Please click [Yes] on the UAC dialog.
			TIMEOUT 5
			SET "PAR=%*"
			SET "PAR=!PAR:"=*!"
			cscript //nologo "%~f0?.wsf" "%CD%" "!PAR!" //job:Admin
			EXIT /B
		)
ENDLOCAL

----- Begin wsf script --->
<package>
	<job id="Admin">
		<script language="VBScript">
			DIR = WScript.Arguments(0)
			PAR = WScript.Arguments(1)
			PAR = Replace(PAR, "*", """")
			Set UAC = CreateObject("Shell.Application")
			UAC.ShellExecute "cmd", "/C CD /D "& DIR &" & "& PAR, "", "runas", 1
		</script>
	</job>
</package>