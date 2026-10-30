@ECHO OFF
REM ==================================================================
REM Retrieves config value ^& sets OutputVar
REM Syntax:	%~nx0 [OutputVar] [CFG_FileName] [CFG_Area] [CFG_Key]
REM Notes:	For Windows 2000 and later
REM
REM Copyright ^(C^) 2026 Fooly Cooly https://github.com/Fooly-Cooly
REM Licensed with GPL v3 https://www.gnu.org/licenses/gpl-3.0.txt
REM Contact: foolycooly1764@gmail.com
REM ==================================================================
SETLOCAL EnableExtensions EnableDelayedExpansion
	IF NOT DEFINED SystemRoot ( ECHO Error: Unsupported OS & GOTO :EOF )
	IF "%~1"=="" ( ECHO Error: Missing Parameters & GOTO :EOF )

	SET "FILE=%~2"
	SET "SEC_A=[%~3]"
	SET "KEY_A=%~4"

	FOR /F "usebackq eol=? delims=" %%A IN ("!FILE!") DO (
		SET "LINE=%%A"
		IF "!LINE:~0,1!"=="[" (
			SET "SEC_B=!LINE!"
		) ELSE (
			FOR /F "eol=? tokens=1,* delims==" %%B IN ("!LINE!") DO (
				SET "KEY_B=%%B"
				IF "!SEC_A!"=="!SEC_B!" IF "!KEY_A!"=="!KEY_B!" (
					SET "RETURN=%%C"
					GOTO :END
				)
			)
		)
	)

	:END
ENDLOCAL & SET "%~1=%RETURN%"