@ECHO OFF
SETLOCAL

FOR /F "tokens=2,* eol=@" %%A IN ('reg query "HKCU\Environment" /v Path') DO SET "ENV=%%B"
CALL SET "STR=%%ENV:%~dp0cmd\;%~dp0bin\;=%%"
IF "x%ENV%"=="x%STR%" (
	SETX PATH "%ENV%%~dp0cmd\;%~dp0bin\;"
) ELSE (
	ECHO Error: Path Entries already present.
)
PAUSE

ENDLOCAL